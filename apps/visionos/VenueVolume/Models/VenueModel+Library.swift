import SwiftUI
import VenueVolumeCore

extension VenueModel {
    func bootstrapLibrary(defaultRoom: EnvironmentManifest, additionalRooms: [EnvironmentManifest] = []) {
        guard rooms.isEmpty else { return }
        bundledRooms = ([defaultRoom] + additionalRooms).map { LibraryRoom(manifest: $0, origin: .bundled) }
        rooms = bundledRooms
        refreshLibrary()
        guard !isDemoMode else { return }
        do {
            if let saved = try AuditHistory<VenueAuditState>.load(from: historyURL) {
                for node in saved.nodes { try node.state.validate() }
                history = saved
                let state = saved.current.state
                rooms = state.rooms; mergeBundledRooms(); savedSetups = state.setups
                if let room = rooms.first(where: { $0.id == state.roomID }) {
                    historyDestination = (saved.cursor, nil)
                    roomRequest = .init(room: room, setup: nil, blank: true)
                }
            }
        } catch {
            historyBlocked = true
            historyMessage = "History could not be read. Existing log preserved; history recording is disabled: \(error.localizedDescription)"
        }
    }

    /// The launch window needs the room/save library before an immersive scene exists.
    func prepareLibrary(repository providedRepository: (any EnvironmentRepository)? = nil) async {
        guard rooms.isEmpty else { return }
        do {
            let repository: any EnvironmentRepository
            if let providedRepository { repository = providedRepository }
            else {
                guard let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("application resources are missing") }
                repository = BundledEnvironmentRepository(directory: resources.appendingPathComponent("Environments"))
            }
            let defaultRoom = try await repository.resolve(id: "img3153-classroom-v1").manifest
            var additional: [EnvironmentManifest] = []
            for id in ["mappedRoom", "the-fortress"] { additional.append(try await repository.resolve(id: id).manifest) }
            bootstrapLibrary(defaultRoom: defaultRoom, additionalRooms: additional)
            // Present the remembered working setup in the launch UI so replacing
            // unsaved work requires the same confirmation as an in-venue switch.
            if let destination = historyDestination, let state = history?.node(destination.id)?.state {
                applyHistoryState(state)
                historyDestination = nil; roomRequest = nil
            }
        } catch { libraryMessage = "The venue library could not open: \(error.localizedDescription)" }
    }

    var canResumeVenue: Bool { activeRoom != nil || historyDestination != nil }
    func requestNewVenue() {
        guard !libraryBusy else { return }
        cancelPlacementHandoff()
        venueIntentID = UUID()
        newVenuePresented = true
    }

    /// Async file parsing belongs to the initiating window and selection intent.
    /// Newer choices or a closed source window invalidate it before any writes.
    func beginVenueImport() -> UUID? {
        guard !libraryBusy, !isTransitioning else { return nil }
        cancelPlacementHandoff()
        venueIntentID = UUID()
        return venueIntentID
    }

    func cancelVenueImport(_ id: UUID) {
        if venueIntentID == id { venueIntentID = UUID() }
    }

    func cancelRequestedRoom(_ id: UUID) {
        guard roomLoadToken == id, roomRequest != nil else { return }
        if pendingFixturePlacement != nil { cancelPlacementHandoff(message: "Opening the Load Out was cancelled. Open the placement link to try again.") }
        roomRequest = nil; libraryBusy = false
        canPlace = isImmersed && environment != nil
        roomLoadToken = UUID()
    }

    /// Returns true only after full validation and durable import. The active scene
    /// is unchanged until the caller requests this setup and RealityKit loads it.
    func importVenueSave(_ document: VenueSave, assetChecksum: String, intentID: UUID? = nil) async throws -> (LibraryRoom, VenueSetup) {
        if let intentID, intentID != venueIntentID { throw CancellationError() }
        guard !libraryBusy else { throw EnvironmentError.invalid("wait for the current room to finish loading") }
        if let existing = rooms.first(where: { $0.id == document.room.id }), existing.manifest != document.room.manifest {
            throw EnvironmentError.invalid("different room metadata already uses this room version")
        }
        let prepared = try await VenueSaveWorker.shared.prepareImport(document, assetChecksum: assetChecksum, store: library)
        defer { prepared.discard() }
        try Task.checkCancellation()
        if let intentID, intentID != venueIntentID { throw CancellationError() }
        guard !libraryBusy else { throw EnvironmentError.invalid("wait for the current room to finish loading") }
        if let existing = rooms.first(where: { $0.id == document.room.id }), existing.manifest != document.room.manifest {
            throw EnvironmentError.invalid("different room metadata already uses this room version")
        }
        try prepared.commit()
        let imported = (room: prepared.room, setup: prepared.setup)
        let room = rooms.first(where: { $0.manifest == imported.room.manifest }) ?? imported.room
        beginHistoryAction("Import save · \(imported.setup.name)"); defer { endHistoryAction() }
        if !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
        savedSetups.insert(imported.setup, at: 0)
        libraryMessage = "Imported \(imported.setup.name)."
        return (room, imported.setup)
    }

    func currentSetupSnapshot() throws -> VenueSetup {
        guard let room = activeRoom, !libraryBusy else { throw EnvironmentError.invalid("open a venue before exporting") }
        let snapshot = VenueSetup(id: activeSetupID ?? UUID(), name: setupName.trimmingCharacters(in: .whitespacesAndNewlines), room: room,
                                  fixtures: fixtures, presets: presets, revision: revision, whiteRoom: whiteRoom, houseLight: houseLight, tour: touring.active, cues: cueSheet == CueSheet() ? nil : cueSheet)
        try snapshot.validate(room: room)
        return snapshot
    }

    func mergeBundledRooms() {
        for room in bundledRooms where !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
    }

    func refreshLibrary() {
        guard history == nil else { return }
        do {
            let imported = try library.rooms()
            let bundled = rooms.filter { $0.origin == .bundled }
            rooms = bundled + imported.filter { room in !bundled.contains { $0.id == room.id } }
            savedSetups = try library.setups(rooms: rooms)
        } catch { libraryMessage = "Library could not be read: \(error.localizedDescription). Existing files are preserved." }
    }

    func requestRoom(_ room: LibraryRoom, setup: VenueSetup? = nil, blank: Bool = true, configurationID: UUID? = nil, preservingPlacementLink: Bool = false) {
        endTransformDrag(); gizmoVisible = false
        guard !libraryBusy else { return }
        if !preservingPlacementLink { cancelPlacementHandoff() }
        flushHistoryEdits()
        do {
            if let setup { try setup.validate(room: room) }
            else if let configurationID, tour?.show.configurations.contains(where: { $0.id == configurationID }) != true { throw PresetError("Choose an available show configuration.") }
        }
        catch { libraryMessage = error.localizedDescription; return }
        // An explicit launch choice supersedes the remembered audit cursor.
        venueIntentID = UUID()
        historyDestination = nil; preparedHistory = nil
        fixtureDragLease?.cancel(); draggingFixture = nil
        libraryBusy = true; canPlace = false; previewDraft = false; cancelPicking()
        cancelTourPreview()
        roomRequest = .init(room: room, setup: setup, blank: blank, configurationID: configurationID)
        roomLoadToken = UUID()
    }

    @discardableResult func saveSetup(asNew: Bool = false) -> Bool {
        guard let room = activeRoom, !libraryBusy else { return false }
        beginHistoryAction(asNew ? "Save setup as new" : "Save setup"); defer { endHistoryAction() }
        let name = setupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = VenueSetup(id: asNew ? UUID() : (activeSetupID ?? UUID()), name: name, room: room,
                                  fixtures: fixtures, presets: presets, revision: revision, whiteRoom: whiteRoom, houseLight: houseLight, tour: touring.active, cues: cueSheet == CueSheet() ? nil : cueSheet)
        do {
            try library.save(snapshot, room: room)
            activeSetupID = snapshot.id; savedSetup = snapshot; setupName = name
            savedSetups.removeAll { $0.id == snapshot.id }; savedSetups.insert(snapshot, at: 0)
            libraryMessage = "Saved \(name) · \(fixtures.count) fixtures."
            return true
        } catch { libraryMessage = error.localizedDescription; return false }
    }
}
