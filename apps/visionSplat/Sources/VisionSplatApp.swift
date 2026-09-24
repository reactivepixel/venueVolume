import SwiftUI
import RealityKit
import UniformTypeIdentifiers
import simd

@MainActor
final class ViewerModel: ObservableObject {
    @Published var cloud: SplatCloud?
    @Published var sceneName = "Demo room"
    @Published var status = "Loading bundled room…"
    @Published var scale: Float = 1
    @Published var yaw: Float = 0
    @Published var offset = SIMD3<Float>(repeating: 0)
    @Published var revision = 0

    func loadBundledRoom() async {
        guard let url = Bundle.main.url(forResource: "demo-room", withExtension: "ply") else {
            status = "Bundled demo-room.ply is missing. Check the Xcode target resources."
            return
        }
        await load(url, name: "Demo room", scoped: false)
    }

    func load(_ url: URL, name: String, scoped: Bool = true) async {
        let allowed = !scoped || url.startAccessingSecurityScopedResource()
        guard allowed else { status = "Could not access the selected file."; return }
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            status = "Reading \(name)…"
            guard let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  bytes <= 96 * 1024 * 1024 else { throw PLYError.tooLarge }
            let parsed = try await Task.detached(priority: .userInitiated) {
                try SplatPLY.parse(Data(contentsOf: url, options: .mappedIfSafe))
            }.value
            cloud = parsed
            sceneName = name
            scale = 1
            yaw = 0
            offset = .zero
            revision += 1
            status = "\(parsed.count.formatted()) Gaussians loaded. Walk naturally to explore."
        } catch { status = "Could not load \(name): \(error.localizedDescription)" }
    }

    func recenter() {
        scale = 1
        yaw = 0
        offset = .zero
        revision += 1
    }

    func moveView(x: Float = 0, z: Float = 0) {
        offset.x -= x
        offset.z -= z
    }
}

@main
struct VisionSplatApp: App {
    @StateObject private var model = ViewerModel()
    @State private var immersionStyle: ImmersionStyle = .full

    var body: some Scene {
        WindowGroup {
            ControlsView()
                .environmentObject(model)
                .task { if model.cloud == nil { await model.loadBundledRoom() } }
        }
        ImmersiveSpace(id: "Room") {
            ImmersiveRoomView().environmentObject(model)
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}

struct ControlsView: View {
    @EnvironmentObject private var model: ViewerModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var immersed = false
    @State private var importing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("visionSplat").font(.largeTitle.bold())
            Text("Stand inside a Gaussian splat room and explore with natural head movement.")
            Text(model.sceneName).font(.headline)
            Text(model.status).foregroundStyle(.secondary)
            HStack {
                Button("Open PLY…") { importing = true }
                Button("Reload demo") { Task { await model.loadBundledRoom() } }
                Button(immersed ? "Leave room" : "Enter room") {
                    Task {
                        if immersed { await dismissImmersiveSpace(); immersed = false }
                        else if model.cloud != nil {
                            let result = await openImmersiveSpace(id: "Room")
                            immersed = result == .opened
                            if !immersed { model.status = "Could not open the immersive space." }
                        }
                    }
                }
                .disabled(model.cloud == nil)
            }
            HStack {
                Text("Size")
                Slider(value: $model.scale, in: 0.25...2, step: 0.05)
                Text("\(model.scale, specifier: "%.2f")×").monospacedDigit()
            }
            HStack {
                Text("Rotate")
                Slider(value: $model.yaw, in: -Float.pi...Float.pi)
                Button("Recenter") { model.recenter() }
            }
            HStack {
                Text("Move view")
                Button("← Left") { model.moveView(x: -0.5) }
                Button("Right →") { model.moveView(x: 0.5) }
                Button("↑ Forward") { model.moveView(z: -0.5) }
                Button("↓ Back") { model.moveView(z: 0.5) }
            }
            Text("Movement buttons shift the room in 0.5 m steps. Recenter restores the original room transform. You can always leave using this window or the system Home control.")
                .font(.footnote).foregroundStyle(.secondary)
            #if targetEnvironment(simulator)
            Text("Native Gaussian splats currently require a Vision Pro device; the simulator is for UI and PLY import checks.")
                .font(.footnote).foregroundStyle(.orange)
            #endif
        }
        .padding(28)
        .frame(width: 660)
        .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(filenameExtension: "ply") ?? .data]) { result in
            switch result {
            case .success(let url): Task { await model.load(url, name: url.lastPathComponent) }
            case .failure(let error): model.status = "File picker: \(error.localizedDescription)"
            }
        }
    }
}

struct ImmersiveRoomView: View {
    @EnvironmentObject private var model: ViewerModel

    var body: some View {
        RealityView { content in
            let holder = Entity()
            holder.name = "SplatRoot"
            content.add(holder)
        } update: { content in
            guard let holder = content.entities.first(where: { $0.name == "SplatRoot" }) else { return }
            #if !targetEnvironment(simulator)
            if let cloud = model.cloud, holder.children.first?.name != "revision-\(model.revision)" {
                holder.children.removeAll()
                do {
                    let room = try SplatResourceBuilder.makeEntity(cloud)
                    room.name = "revision-\(model.revision)"
                    room.position = -cloud.center
                    holder.addChild(room)
                } catch {
                    let failure = Entity()
                    failure.name = "revision-\(model.revision)"
                    holder.addChild(failure)
                    let message = error.localizedDescription
                    Task { @MainActor in model.status = "Renderer failed: \(message). Use Leave room to exit." }
                }
            }
            #endif
            // ImmersiveSpace origin starts at the wearer's feet. Put the PLY
            // bounding-box center at approximate standing eye height.
            holder.position = model.offset + SIMD3<Float>(0, 1.5, 0)
            holder.scale = SIMD3<Float>(repeating: model.scale)
            holder.orientation = simd_quatf(angle: model.yaw, axis: SIMD3<Float>(0, 1, 0))
        }
    }
}
