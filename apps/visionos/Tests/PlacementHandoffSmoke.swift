import Foundation
import VenueVolumeCore

enum PlacementHandoffSmoke {
    @MainActor static func run() async throws {
        let suite = "venue-placement-link.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        let repository = BundledEnvironmentRepository(directory: URL(fileURLWithPath: "VenueVolume/Environments"))
        await model.prepareLibrary(repository: repository)
        let room = model.rooms.first { $0.manifest.id == "img3153-classroom-v1" }!
        model.requestRoom(room); model.activate(environment: room.manifest); model.canPlace = true; model.isImmersed = true
        model.beginPlacement(); model.place(at: [2.66,0,-2], surfaceID: "floor")
        model.setupName = "Linked Load Out"; precondition(model.saveSetup())
        let fixture = model.fixtures[0], setupID = model.activeSetupID!
        let link = FixturePlacementLink(loadOutID: setupID, fixtureID: fixture.id)
        precondition(model.receivePlacementLink(link.url))
        let request = model.pendingFixturePlacement!.id
        precondition(model.preparePlacementHandoff(request) == .ready)
        precondition(model.scenePick == .move(fixture.id) && model.selectedID == fixture.id)
        precondition(model.fixtures == [fixture] && model.pendingFixturePlacement == nil, "Opening a link cannot create or move equipment")
        model.cancelPicking()
        precondition(model.receivePlacementLink(FixturePlacementLink(loadOutID: UUID(), fixtureID: fixture.id).url))
        precondition(model.preparePlacementHandoff(model.pendingFixturePlacement!.id) == .failed)
        precondition(model.activeSetupID == setupID && model.fixtures == [fixture] && model.scenePick == nil)
        precondition(model.placementLinkMessage!.contains("Automatic transfer"))
        precondition(model.receivePlacementLink(FixturePlacementLink(loadOutID: setupID, fixtureID: UUID()).url))
        precondition(model.preparePlacementHandoff(model.pendingFixturePlacement!.id) == .failed)
        precondition(!model.receivePlacementLink(URL(string: "venuevolume://place?loadout=invalid")!))

        // Another room has dirty work: the external URL must not discard it.
        let other = model.rooms.first { $0.manifest.id == "mappedRoom" }!
        model.requestRoom(other); model.activate(environment: other.manifest); model.canPlace = true
        model.setupName = "Unsaved local plan"
        precondition(model.receivePlacementLink(link.url))
        let switchID = model.pendingFixturePlacement!.id
        precondition(model.preparePlacementHandoff(switchID) == .needsSaveDecision)
        precondition(model.activeRoom == other && model.roomRequest == nil)
        precondition(model.saveSetup())
        precondition(model.preparePlacementHandoff(switchID) == .ready)
        precondition(model.scenePick == nil && model.libraryBusy)
        model.activate(environment: room.manifest)
        model.finishPlacementHandoffIfReady()
        precondition(model.scenePick == nil, "Room load alone is not tracking readiness")
        model.canPlace = true; model.finishPlacementHandoffIfReady()
        precondition(model.activeSetupID == setupID && model.scenePick == .move(fixture.id) && model.fixtures.count == 1)
        model.cancelPicking()

        // Cold start resolves the saved IDs, then waits for immersion/tracking.
        let cold = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        precondition(cold.receivePlacementLink(link.url))
        let coldID = cold.pendingFixturePlacement!.id
        await cold.prepareLibrary(repository: repository)
        precondition(cold.pendingFixturePlacement?.id == coldID)
        precondition(cold.preparePlacementHandoff(coldID) == .ready)
        precondition(cold.scenePick == nil)
        cold.isImmersed = true; cold.canPlace = true; cold.finishPlacementHandoffIfReady()
        precondition(cold.scenePick == .move(fixture.id))
        cold.cancelPicking()

        // A manual room choice cancels a prepared link; stale callbacks cannot select in it.
        cold.canPlace = false
        precondition(cold.receivePlacementLink(link.url))
        let staleID = cold.pendingFixturePlacement!.id
        precondition(cold.preparePlacementHandoff(staleID) == .ready)
        cold.requestRoom(other); cold.activate(environment: other.manifest); cold.canPlace = true
        cold.finishPlacementHandoffIfReady()
        precondition(cold.pendingFixturePlacement == nil && cold.scenePick == nil && cold.activeRoom == other)
        precondition(cold.preparePlacementHandoff(staleID) == .failed)
        precondition(cold.receivePlacementLink(link.url))
        let cancelID = cold.pendingFixturePlacement!.id
        precondition(cold.preparePlacementHandoff(cancelID) == .ready)
        let token = cold.roomLoadToken
        cold.cancelRequestedRoom(token)
        precondition(cold.pendingFixturePlacement == nil && !cold.libraryBusy && cold.roomRequest == nil)
        print("Placement link checks passed: exact identity, missing data, cold/warm entry, dirty-work protection, readiness, cancellation and no duplicate fixtures")
    }
}
