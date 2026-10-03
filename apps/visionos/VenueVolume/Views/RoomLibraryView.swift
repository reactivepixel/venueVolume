import SwiftUI
import UniformTypeIdentifiers
import VenueVolumeCore

struct NewVenueSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("New venue").font(.title.bold())
                Spacer()
                Button("Cancel") { model.newVenuePresented = false; dismiss() }
            }
            Text("Choose an environment. Each new instance starts with no fixtures.").foregroundStyle(.secondary)
            VenueLibraryPicker(showsNewVenues: true) { model.newVenuePresented = false; dismiss() }
        }.padding(28).frame(minWidth: 620, idealWidth: 680, minHeight: 550, idealHeight: 700)
            .task { await model.prepareLibrary() }
    }
}

/// Shared launch/chooser flow keeps confirmation and file loading consistent.
struct VenueLibraryPicker: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    let showsNewVenues: Bool
    var didOpen: () -> Void = {}
    @State private var pending: (LibraryRoom, VenueSetup?)?
    @State private var confirming = false
    @State private var importing = false
    @State private var reading = false
    @State private var importTask: Task<Void, Never>?
    @State private var importIntent: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !showsNewVenues {
                HStack {
                    Button("New venue", systemImage: "plus") { model.requestNewVenue() }.buttonStyle(.borderedProminent)
                    Button("Load save from file", systemImage: "folder") { importing = true }
                }.controlSize(.large)
                Text("RECENT SAVES").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if showsNewVenues {
                        ForEach(model.rooms) { room in
                            venueButton(title: room.displayName, detail: room.detail, symbol: room.origin == .scanned ? "viewfinder" : "building.2") {
                                request(room, setup: nil)
                            }
                        }
                    } else if model.savedSetups.isEmpty {
                        ContentUnavailableView("No saved venues yet", systemImage: "square.stack.3d.up", description: Text("Choose New venue, add fixtures, then save your setup from the wrist toolbox."))
                    } else {
                        ForEach(model.savedSetups) { setup in
                            if let room = model.rooms.first(where: { $0.id == setup.roomID }) {
                                venueButton(title: setup.name, detail: "\(room.displayName) · \(setup.placements.fixtures.count) fixtures · \(setup.modified.formatted(date: .abbreviated, time: .shortened))", symbol: "clock") {
                                    request(room, setup: setup)
                                }
                            }
                        }
                    }
                }
            }.frame(maxHeight: .infinity)
            if reading || model.libraryBusy { ProgressView(reading ? "Checking save…" : "Opening venue…") }
            if let message = model.libraryMessage ?? model.message {
                Text(message).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .disabled(reading || model.libraryBusy || model.isTransitioning)
        .confirmationDialog("Save changes to the current setup?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Save and continue") { if model.saveSetup() { continuePending() } }
            Button("Discard changes and continue", role: .destructive) { continuePending() }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: { Text("Opening another venue replaces the current fixture arrangement.") }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.venueVolumeSave, .json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first, let intent = model.beginVenueImport() else { return }
                importTask?.cancel()
                importIntent = intent
                reading = true
                importTask = Task { @MainActor in
                    defer {
                        if importIntent == intent { reading = false; importIntent = nil; importTask = nil }
                    }
                    do {
                        let document = try await VenueSaveDocument.read(url)
                        try Task.checkCancellation()
                        guard model.venueIntentID == intent else { return }
                        let (room, setup) = try model.importVenueSave(document, assetChecksum: RoomAssets.checksum(document.asset), intentID: intent)
                        request(room, setup: setup)
                    } catch is CancellationError {
                        // Closing the source window or choosing a newer venue is intentional.
                    } catch {
                        if !Task.isCancelled, model.venueIntentID == intent {
                            model.libraryMessage = "Save could not be loaded: \(error.localizedDescription)"
                        }
                    }
                }
            case .failure(let error): model.libraryMessage = "Save could not be loaded: \(error.localizedDescription)"
            }
        }
        .onDisappear {
            importTask?.cancel(); importTask = nil
            if let importIntent { model.cancelVenueImport(importIntent) }
            importIntent = nil; reading = false
        }
    }
    private func venueButton(title: String, detail: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol).font(.title2).frame(width: 32).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
            }.padding(14).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        }.buttonStyle(.plain).hoverEffect(.highlight)
    }
    private func request(_ room: LibraryRoom, setup: VenueSetup?) {
        pending = (room, setup)
        if model.hasUnsavedSetup { confirming = true } else { continuePending() }
    }
    private func continuePending() {
        guard let (room, setup) = pending else { return }
        pending = nil
        model.requestRoom(room, setup: setup)
        let requestID = model.roomLoadToken
        if model.isImmersed { didOpen(); return }
        Task { @MainActor in
            model.isTransitioning = true
            defer { model.isTransitioning = false }
            switch await openSpace(id: "VenueSpace") {
            case .opened: model.isImmersed = true; didOpen()
            case .userCancelled: model.cancelRequestedRoom(requestID)
            case .error: model.cancelRequestedRoom(requestID); model.libraryMessage = "The venue could not open. Select it to try again."
            @unknown default: model.cancelRequestedRoom(requestID); model.libraryMessage = "The system could not open the venue."
            }
        }
    }
}

struct RoomLibraryView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dynamicTypeSize) private var textSize
    @ScaledMetric(relativeTo: .body) private var listHeight = 320.0
    @State private var importing = false
    @State private var pending: Action?
    @State private var confirm = false
    private enum Action { case open(LibraryRoom, VenueSetup?), scan }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.activeRoom?.manifest.title ?? "Default classroom").font(.headline)
                    Text(model.hasUnsavedSetup ? "Unsaved setup changes" : "Room geometry + independent fixture setups")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                Button("Import", systemImage: "square.and.arrow.down") { importing = true }
                Button("Scan", systemImage: "viewfinder") { request(.scan) }.disabled(!RoomScanner.supported)
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                TextField("Setup name", text: $model.setupName).textFieldStyle(.roundedBorder).accessibilityLabel("Setup name")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: textSize.isAccessibilitySize ? 320 : 180))], alignment: .leading, spacing: 16) {
                Button("Save") { model.saveSetup() }
                Button("Save as new") { model.saveSetup(asNew: true) }
                ExportVenueSaveButton()
                Button("New venue") { model.requestNewVenue() }
                }
            }
            let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24)) : AnyLayout(HStackLayout(alignment: .top, spacing: 24))
            layout {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENVIRONMENTS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.rooms) { room in
                                Button { request(.open(room, nil)) } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Label(room.displayName, systemImage: room.origin == .scanned ? "viewfinder" : "cube.transparent")
                                        Text(room.detail)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(14).frame(minHeight: 60)
                                }.buttonStyle(.plain).hoverEffect(.highlight)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity).frame(height: listHeight)
                if !textSize.isAccessibilitySize { Divider() }
                VStack(alignment: .leading, spacing: 8) {
                    Text("SAVED SETUPS · \(model.savedSetups.count)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if model.savedSetups.isEmpty {
                                Text("Build a fixture layout and save it here. New starts another setup in any available venue.")
                                    .font(.callout).foregroundStyle(.secondary).padding(.top, 12)
                            }
                            ForEach(model.savedSetups) { setup in
                                if let room = model.rooms.first(where: { $0.id == setup.roomID }) {
                                    Button { request(.open(room, setup)) } label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(setup.name).font(.callout.weight(.semibold))
                                            Text("\(room.manifest.title) · \(setup.placements.fixtures.count) fixtures").font(.caption).foregroundStyle(.secondary)
                                        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).frame(minHeight: 60)
                                    }.buttonStyle(.plain).hoverEffect(.highlight)
                                }
                            }
                        }
                    }
                }.frame(maxWidth: .infinity).frame(height: listHeight)
            }
            Text(model.libraryMessage ?? "Import a room bundle folder or a meter-scale USDZ. Live scanning is available on Vision Pro.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
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
