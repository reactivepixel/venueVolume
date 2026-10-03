import ARKit
import Observation
import QuartzCore
import RealityKit
import SwiftUI
import VenueVolumeCore

@MainActor @Observable final class RoomScanner {
    let root = Entity()
    private let session = ARKitSession()
    private let world = WorldTrackingProvider()
    private var chunks: [UUID: ScannedMesh.Chunk] = [:]
    private var floorSamples: [UUID: [Float]] = [:]
    private var entities: [UUID: Entity] = [:]
    var status = "Requesting room sensing…"
    var running = false
    var saving = false
    var triangleCount: Int { chunks.values.reduce(0) { $0 + $1.triangles.count/3 } }
    var canSave: Bool { running && triangleCount >= 100 && floorSamples.values.reduce(0, { $0+$1.count }) >= 12 }
    static var supported: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        SceneReconstructionProvider.isSupported && WorldTrackingProvider.isSupported
        #endif
    }

    func run() async {
        guard Self.supported else { status = "Live room scanning requires Apple Vision Pro. Import a room to use it in Simulator."; return }
        let authorization = await session.requestAuthorization(for: [.worldSensing])
        guard authorization[.worldSensing] == .allowed else { status = "Allow World Sensing in Settings → Privacy & Security, then start a new scan."; return }
        let provider = SceneReconstructionProvider(modes: [.classification])
        defer { session.stop(); running = false }
        do {
            try await session.run([world, provider])
            running = true
            status = "Look around slowly. Include the floor, walls, and furniture you want to keep."
            for await update in provider.anchorUpdates {
                try Task.checkCancellation()
                guard !saving else { continue }
                let anchor = update.anchor
                if update.event == .removed {
                    chunks.removeValue(forKey: anchor.id); floorSamples.removeValue(forKey: anchor.id)
                    entities.removeValue(forKey: anchor.id)?.removeFromParent()
                    continue
                }
                let captured = try Self.capture(anchor)
                let proposedCount = triangleCount - (chunks[anchor.id]?.triangles.count ?? 0)/3 + captured.0.triangles.count/3
                guard proposedCount <= 1_000_000, chunks.count < 2048 || chunks[anchor.id] != nil else {
                    status = "Scan size limit reached. Save the captured area or cancel and scan a smaller room."; continue
                }
                chunks[anchor.id] = captured.0; floorSamples[anchor.id] = captured.1
                let entity = try RoomAssets.meshEntity(.init(chunks: [captured.0]))
                for child in entity.children {
                    if var component = child.components[ModelComponent.self] {
                        component.materials = [SimpleMaterial(color: .cyan.withAlphaComponent(0.12), isMetallic: false)]
                        child.components.set(component)
                    }
                }
                entities.removeValue(forKey: anchor.id)?.removeFromParent()
                entities[anchor.id] = entity; root.addChild(entity)
            }
        } catch is CancellationError {
        } catch { status = "Scan stopped: \(error.localizedDescription). Cancel and retry." }
    }

    func save(name: String, store: RoomLibraryStore) async throws -> LibraryRoom {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSave, !saving, !title.isEmpty, title.count <= 120,
              let pose = world.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()), pose.isTracked else {
            throw EnvironmentError.invalid("scan more floor and recover tracking before saving; give the room a name")
        }
        saving = true
        defer { saving = false }
        let samples = floorSamples.values.flatMap { $0 }.sorted()
        let floor = samples[samples.count/2]
        let normalized = chunks.values.map { chunk in
            ScannedMesh.Chunk(vertices: chunk.vertices.map { .init(x: $0.x, y: $0.y-floor, z: $0.z) }, triangles: chunk.triangles)
        }
        let mesh = ScannedMesh(chunks: normalized)
        try mesh.validate()
        let vertices = normalized.flatMap(\.vertices)
        let minimum: [Float] = [vertices.map(\.x).min()!, 0, vertices.map(\.z).min()!]
        let maximum: [Float] = [vertices.map(\.x).max()!, vertices.map(\.y).max()!, vertices.map(\.z).max()!]
        let transform = pose.originFromAnchorTransform
        let spawn = Position3D(x: transform.columns.3.x, y: 0, z: transform.columns.3.z)
        guard mesh.supports(spawn, radius: 0.15), maximum[1] > 1 else {
            throw EnvironmentError.invalid("look down to capture the floor beneath you, then scan the walls before saving")
        }
        let yaw = atan2(transform.columns.2.x, transform.columns.2.z)
        return try await Task.detached(priority: .userInitiated) {
            let data = try JSONEncoder().encode(mesh)
            let manifest = EnvironmentManifest.simple(id: "scan-" + UUID().uuidString.lowercased(), title: title, min: minimum, max: maximum,
                spawn: [spawn.x,0,spawn.z], yaw: yaw, file: "environment.mesh.json",
                checksum: RoomAssets.checksum(data), bytes: data.count, scanned: true)
            let room = LibraryRoom(manifest: manifest, origin: .scanned)
            try store.install(room: room, asset: data)
            return room
        }.value
    }

    private static func capture(_ anchor: MeshAnchor) throws -> (ScannedMesh.Chunk, [Float]) {
        let geometry = anchor.geometry, source = geometry.vertices, faces = geometry.faces
        guard source.format == .float3, faces.primitive == .triangle, [2,4].contains(faces.bytesPerIndex) else {
            throw EnvironmentError.invalid("unsupported scan buffer format")
        }
        let transform = anchor.originFromAnchorTransform
        let vertices = (0..<source.count).map { i -> Position3D in
            let pointer = source.buffer.contents().advanced(by: source.offset+i*source.stride)
            let x = pointer.loadUnaligned(as: Float.self), y = pointer.loadUnaligned(fromByteOffset: 4, as: Float.self)
            let z = pointer.loadUnaligned(fromByteOffset: 8, as: Float.self)
            let p = transform * SIMD4<Float>(x,y,z,1)
            return .init(x: p.x, y: p.y, z: p.z)
        }
        let triangles: [UInt32] = (0..<(faces.count*3)).map { index in
            let pointer = faces.buffer.contents().advanced(by: index*faces.bytesPerIndex)
            return faces.bytesPerIndex == 2 ? UInt32(pointer.loadUnaligned(as: UInt16.self)) : pointer.loadUnaligned(as: UInt32.self)
        }
        var floor: [Float] = []
        if let classifications = geometry.classifications {
            for i in 0..<min(classifications.count, faces.count) {
                let raw = classifications.buffer.contents().load(fromByteOffset: classifications.offset+i*classifications.stride, as: UInt8.self)
                // Stable ARKit floor classification (2), also valid on visionOS 2.
                if raw == 2 { floor.append(vertices[Int(triangles[i*3])].y) }
            }
        }
        return (.init(vertices: vertices, triangles: triangles), floor)
    }
}

struct RoomScanView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @State private var scanner = RoomScanner()
    @State private var name = "New scanned room"
    @State private var error: String?
    @State private var finishing = false
    var body: some View {
        RealityView { content, attachments in
            content.add(scanner.root)
            if let panel = attachments.entity(for: "scan") {
                let head = AnchorEntity(.head); head.addChild(panel); panel.position = [0,-0.2,-1.2]; content.add(head)
            }
        } attachments: {
            Attachment(id: "scan") {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Scan a room", systemImage: "viewfinder").font(.title2)
                    TextField("Room name", text: $name).textFieldStyle(.roundedBorder)
                    Text(error ?? scanner.status).font(.callout)
                    Text("\(scanner.triangleCount.formatted()) triangles · \(scanner.canSave ? "Ready to save" : "Capture floor and walls")").font(.caption)
                    HStack {
                        Button("Cancel") { Task { await finish(room: nil) } }
                        Spacer()
                        Button("Save room & open") {
                            Task {
                                do {
                                    let room = try await scanner.save(name: name, store: model.library)
                                    model.registerRoom(room); await finish(room: room)
                                } catch { self.error = error.localizedDescription; model.auditExternal("Room scan save failed · \(error.localizedDescription)") }
                            }
                        }.buttonStyle(.borderedProminent).disabled(!scanner.canSave || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }.disabled(finishing || scanner.saving)
                    Text("Stores geometry on this device. Scan every surface you need; unseen areas remain missing.").font(.caption).foregroundStyle(.secondary)
                    if scanner.saving { ProgressView("Saving room…") }
                }.padding(24).frame(width: 540).glassBackgroundEffect()
            }
        }
        .task { await scanner.run() }
        .onAppear { dismissWindow(id: "launch") }
        .onDisappear { if !finishing { openWindow(id: "launch") } }
    }
    private func finish(room: LibraryRoom?) async {
        finishing = true
        if room == nil { model.auditExternal("Cancel local room scan") }
        if let room { model.requestRoom(room) }
        await dismissSpace()
        switch await openSpace(id: "VenueSpace") {
        case .opened: break
        default: openWindow(id: "launch")
        }
    }
}
