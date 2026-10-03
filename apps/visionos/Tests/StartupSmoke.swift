import Foundation
import VenueVolumeCore

enum StartupSmoke {
    @MainActor static func run() async throws {
        let suite = "venue-startup-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let resources = URL(fileURLWithPath: "VenueVolume/Environments")
        let repository = BundledEnvironmentRepository(directory: resources)
        let source = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        await source.prepareLibrary(repository: repository)
        precondition(source.rooms.count == 3 && source.fixtures.isEmpty, "Launch lists all blank venues before immersion")
        let classroom = source.rooms.first { $0.manifest.id == "img3153-classroom-v1" }!
        source.requestRoom(classroom); source.activate(environment: classroom.manifest); source.canPlace = true
        source.beginPlacement()
        source.place(at: [2.66, 0, -2], surfaceID: "floor")
        let fixtureID = source.fixtures[0].id
        precondition(source.applyPreset(source.presets[0].id, to: fixtureID))
        source.setupName = "Saved launch setup"
        precondition(source.saveSetup())
        source.houseLight = 0.4
        source.flushHistoryEdits()

        let relaunched = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        await relaunched.prepareLibrary(repository: repository)
        precondition(relaunched.canResumeVenue && relaunched.savedSetups.count == 1, "Recent saves and Resume exist before immersion")
        precondition(relaunched.hasUnsavedSetup && relaunched.fixtures == source.fixtures, "Launch preserves working state and detects unsaved changes")
        relaunched.requestNewVenue()
        precondition(relaunched.newVenuePresented && relaunched.fixtures == source.fixtures, "Showing New does not discard current work")
        let mapped = relaunched.rooms.first { $0.manifest.id == "mappedRoom" }!
        relaunched.requestRoom(mapped); relaunched.activate(environment: mapped.manifest)
        precondition(relaunched.activeRoom == mapped && relaunched.fixtures.isEmpty && !relaunched.whiteRoom && relaunched.houseLight == 0.15,
                     "Explicit New overrides saved audit destination and resets blank-room material/light defaults")
        precondition(!relaunched.hasUnsavedSetup)
        relaunched.whiteRoom = true
        precondition(relaunched.hasUnsavedSetup, "Material changes to a blank setup require confirmation")

        let fortress = relaunched.rooms.first { $0.manifest.id == "the-fortress" }!
        relaunched.requestRoom(fortress); relaunched.activate(environment: fortress.manifest)
        precondition(relaunched.fixtures.isEmpty && !relaunched.whiteRoom && !relaunched.hasUnsavedSetup)
        relaunched.requestRoom(mapped)
        let cancelledRequest = relaunched.roomLoadToken
        relaunched.cancelRequestedRoom(cancelledRequest)
        precondition(relaunched.roomRequest == nil && !relaunched.libraryBusy && relaunched.activeRoom == fortress,
                     "Cancelled system entry must leave Resume pointed at the previous venue")
        relaunched.requestRoom(classroom)
        let newerRequest = relaunched.roomLoadToken
        relaunched.cancelRequestedRoom(cancelledRequest)
        precondition(relaunched.roomRequest?.room == classroom && relaunched.libraryBusy,
                     "An old cancellation must not discard a newer room request")
        relaunched.cancelRequestedRoom(newerRequest)
        let asset = try Data(contentsOf: resources.appendingPathComponent("Classroom/environment.usdz"))
        let document = VenueSave(room: classroom, setup: source.savedSetups[0], asset: asset)
        let supersededImport = relaunched.beginVenueImport()!
        relaunched.requestNewVenue()
        do { _ = try relaunched.importVenueSave(document, assetChecksum: classroom.manifest.asset.sha256, intentID: supersededImport); preconditionFailure("Superseded import accepted") }
        catch is CancellationError { precondition(relaunched.savedSetups.count == 1 && relaunched.activeRoom == fortress) }
        let closedWindowImport = relaunched.beginVenueImport()!
        relaunched.cancelVenueImport(closedWindowImport)
        do { _ = try relaunched.importVenueSave(document, assetChecksum: classroom.manifest.asset.sha256, intentID: closedWindowImport); preconditionFailure("Closed-window import accepted") }
        catch is CancellationError { precondition(relaunched.savedSetups.count == 1) }
        let importedRoomFolder = try relaunched.library.roomDirectory(classroom)
        precondition(!FileManager.default.fileExists(atPath: importedRoomFolder.path),
                     "Cancelled imports must not install geometry")
        let unchanged = relaunched.fixtures
        do { _ = try relaunched.importVenueSave(document, assetChecksum: "invalid"); preconditionFailure("Corrupt import accepted") }
        catch { precondition(relaunched.fixtures == unchanged && relaunched.activeRoom == fortress && relaunched.savedSetups.count == 1) }
        var conflictingRoom = document
        conflictingRoom.room.manifest.title = "Contradictory metadata"
        do { _ = try relaunched.importVenueSave(conflictingRoom, assetChecksum: classroom.manifest.asset.sha256); preconditionFailure("Conflicting bundled room metadata accepted") }
        catch { precondition(relaunched.savedSetups.count == 1 && relaunched.activeRoom == fortress) }
        let (_, imported) = try relaunched.importVenueSave(document, assetChecksum: classroom.manifest.asset.sha256)
        precondition(imported.id != document.setup.id && relaunched.savedSetups.count == 2)
        precondition(relaunched.fixtures.isEmpty && relaunched.activeRoom == fortress, "Successful import waits for explicit setup switch")
        print("Startup and portable save checks passed")
    }
}
