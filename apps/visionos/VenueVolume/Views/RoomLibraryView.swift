import SwiftUI
import UniformTypeIdentifiers
import VenueVolumeCore

struct RoomLibraryView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.openImmersiveSpace) private var openSpace
    @State private var importing = false
    @State private var pending: Action?
    @State private var confirm = false
    private enum Action { case open(LibraryRoom, VenueSetup?), scan }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.activeRoom?.manifest.title ?? "Default classroom").font(.headline)
                    Text(model.hasUnsavedSetup ? "Unsaved setup changes" : "Room geometry + independent fixture setups")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Import", systemImage: "square.and.arrow.down") { importing = true }
                Button("Scan", systemImage: "viewfinder") { request(.scan) }.disabled(!RoomScanner.supported)
            }
            HStack {
                TextField("Setup name", text: $model.setupName).textFieldStyle(.roundedBorder)
                Button("Save") { model.saveSetup() }
                Button("Save as new") { model.saveSetup(asNew: true) }
                Button("New blank") { if let room = model.activeRoom { request(.open(room, nil)) } }
            }
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENVIRONMENTS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.rooms) { room in
                                Button { request(.open(room, nil)) } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Label(room.manifest.title, systemImage: room.origin == .scanned ? "viewfinder" : "cube.transparent")
                                        Text(room.origin == .bundled ? "Default · white classroom" : room.origin.rawValue.capitalized)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                }.buttonStyle(.plain).hoverEffect(.highlight)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity)
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("SAVED SETUPS · \(model.savedSetups.count)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if model.savedSetups.isEmpty {
                                Text("Build a fixture layout and save it here. New blank starts another layout in the same room.")
                                    .font(.callout).foregroundStyle(.secondary).padding(.top, 12)
                            }
                            ForEach(model.savedSetups) { setup in
                                if let room = model.rooms.first(where: { $0.id == setup.roomID }) {
                                    Button { request(.open(room, setup)) } label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(setup.name).font(.callout.weight(.semibold))
                                            Text("\(room.manifest.title) · \(setup.placements.fixtures.count) fixtures").font(.caption).foregroundStyle(.secondary)
                                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                    }.buttonStyle(.plain).hoverEffect(.highlight)
                                }
                            }
                        }
                    }
                }.frame(maxWidth: .infinity)
            }.frame(height: 245)
            Text(model.libraryMessage ?? "Import a room bundle folder or a meter-scale USDZ. Live scanning is available on Vision Pro.")
                .font(.caption).foregroundStyle(.secondary).lineLimit(3)
        }
        .disabled(model.libraryBusy)
        .overlay { if model.libraryBusy { ProgressView("Loading room…").padding(24).glassBackgroundEffect() } }
        .confirmationDialog("Save changes to this setup before continuing?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Save and continue") { if model.saveSetup(), let action = pending { perform(action) }; pending = nil }
            Button("Discard changes and continue", role: .destructive) { if let action = pending { perform(action) }; pending = nil }
            Button("Cancel", role: .cancel) { pending = nil }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.folder, .usdz], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                model.libraryBusy = true
                Task { @MainActor in
                    defer { model.libraryBusy = false }
                    do {
                        let room = try await RoomAssets.importRoom(from: url, store: model.library)
                        model.registerRoom(room); model.libraryMessage = "Imported \(room.manifest.title). Select it to open a blank setup."
                    } catch { model.libraryMessage = "Import failed: \(error.localizedDescription)"; model.auditExternal("Room import failed · \(error.localizedDescription)") }
                }
            case .failure(let error): model.libraryMessage = error.localizedDescription
            }
        }
    }

    private func request(_ action: Action) {
        if model.hasUnsavedSetup { pending = action; confirm = true } else { perform(action) }
    }
    private func perform(_ action: Action) {
        switch action {
        case .open(let room, let setup): model.requestRoom(room, setup: setup)
        case .scan:
            model.auditExternal("Start local room scan")
            Task { @MainActor in
                await dismissSpace()
                switch await openSpace(id: "RoomScan") {
                case .opened: break
                default:
                    model.libraryMessage = "Scanning could not open. Try again."
                    _ = await openSpace(id: "VenueSpace")
                }
            }
        }
    }
}

/// A native drop destination lies on each reviewed horizontal placement surface.
/// Its local 2D drop coordinates map directly to room X/Z in meters.
struct FixtureSurfaceDrop: View {
    @Environment(VenueModel.self) private var model
    let surface: EnvironmentManifest.Surface
    @State private var targeted = false
    var body: some View {
        Rectangle().fill(.cyan.opacity(targeted ? 0.20 : 0.035))
            .overlay { Rectangle().stroke(.cyan.opacity(0.4), lineWidth: 2) }
            .frame(width: 400, height: 400)
            .dropDestination(for: String.self) { tokens, location in
                let point = Position3D(x: surface.center[0]+Float(location.x/400-0.5)*surface.size[0],
                                       y: surface.center[1], z: surface.center[2]+Float(location.y/400-0.5)*surface.size[1])
                return model.dropFixture(tokens, at: point, surfaceID: surface.id)
            } isTargeted: { targeted = $0 }
            .accessibilityLabel("Drop fixture on \(surface.role)")
    }
}
