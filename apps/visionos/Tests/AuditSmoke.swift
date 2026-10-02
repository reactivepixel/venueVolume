import Foundation
import VenueVolumeCore

@MainActor enum AuditSmoke {
    static func run(environment: EnvironmentManifest) async throws {
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
        let name = "audit-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: folder) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        model.activate(environment: environment); model.canPlace = true
        check(model.history?.nodes.count == 1, "Initial state recorded")
        model.beginPlacement(); model.place(at: [2.66,0,-2], surfaceID: "floor")
        let fixture = model.fixtures[0]
        let placed = model.auditState!
        var legacyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(placed)) as! [String: Any]
        legacyJSON.removeValue(forKey: "previewBlackout")
        let legacy = try JSONDecoder().decode(VenueAuditState.self, from: JSONSerialization.data(withJSONObject: legacyJSON))
        try legacy.validate()
        check(legacy.previewBlackout == nil, "Existing audit snapshots without simulation blackout still decode")
        model.undo()
        check(model.fixtures.isEmpty && model.canRedo, "Undo placement")
        model.redo()
        check(model.auditState == placed, "Redo restores exact fixture and selection")

        let beforeGesture = model.history!.nodes.count
        model.beginHistoryAction("Move fixture gesture")
        for i in 0..<30 {
            model.moveFixture(fixture.id, position: .init(x: 2.7+Float(i)*0.01,y: 0,z: -2), yawDegrees: Float(i))
        }
        model.endHistoryAction()
        check(model.history!.nodes.count == beforeGesture+1, "Continuous edits form one step")
        let transformed = model.auditState!
        model.undo(); check(model.auditState == placed, "Undo entire gesture")
        model.redo(); check(model.auditState == transformed, "Redo entire gesture")

        check(model.applyPreset(model.presets[0].id, to: fixture.id), "Apply a preset")
        model.beginRetarget(fixture.id)
        check(model.acceptTarget(.init(x: 2.9,y: 1.8,z: -7.67)), "Retarget")
        check(model.saveTarget(), "Save retarget")
        let aimed = model.auditState!
        model.undo(); model.redo()
        check(model.auditState == aimed, "Undo/Redo restores preset target and fixtures together")
        model.presetDraft.channels[0] = 17; model.flushHistoryEdits()
        let beforeSave = model.auditState!
        check(model.savePreset(), "Save preset")
        let afterSave = model.auditState!
        model.undo(); check(model.auditState == beforeSave, "Undo preset save restores library, fixtures and draft")
        model.redo(); check(model.auditState == afterSave, "Redo preset save")
        model.remove(fixture.id); model.undo()
        check(model.auditState == afterSave, "Undo fixture deletion preserves identity and aim")

        model.setupName = "Show A"; check(model.saveSetup(), "Save setup")
        let show = model.auditState!
        let showNode = model.history!.cursor
        model.undo(); check(model.savedSetups.isEmpty, "Undo named save hides saved instance")
        model.redo(); check(model.auditState == show, "Redo restores named save")
        model.requestRoom(model.activeRoom!); model.activate(environment: environment)
        check(model.fixtures.isEmpty, "Blank scene")
        model.undo(); check(model.auditState == show, "Undo blank restores entire setup")

        var otherManifest = environment
        otherManifest.id = "audit-other-room"; otherManifest.title = "Other room"
        let other = LibraryRoom(manifest: otherManifest, origin: .imported)
        model.registerRoom(other)
        let beforeSwitch = model.auditState!
        model.requestRoom(other); model.activate(environment: otherManifest)
        let otherState = model.auditState!
        let otherCursor = model.history!.cursor
        model.undo()
        check(model.libraryBusy && model.history!.cursor == otherCursor && model.auditState == otherState, "Cross-room undo waits for assets")
        model.historyRestoreFailed("missing asset")
        check(model.history!.cursor == otherCursor && model.auditState == otherState && !model.libraryBusy, "Failed restore preserves old state")
        model.undo(); model.activate(environment: environment)
        check(model.auditState == beforeSwitch, "Cross-room undo commits after asset readiness")
        model.redo(); model.activate(environment: otherManifest)
        check(model.auditState == otherState, "Cross-room redo")

        let reopened = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        reopened.bootstrapLibrary(defaultRoom: environment)
        check(reopened.roomRequest?.room == other, "Relaunch requests the history room")
        reopened.activate(environment: otherManifest)
        check(reopened.auditState == otherState && reopened.canUndo, "History and active room survive relaunch")
        reopened.restoreHistory(showNode); reopened.activate(environment: environment)
        check(reopened.auditState == show && !reopened.rooms.contains(other), "Jump restores catalog membership and saved setups")
        reopened.blackout = true; reopened.flushHistoryEdits()
        check(reopened.history!.node(otherCursor) != nil && !reopened.canRedo, "Branch keeps abandoned events")
        reopened.restoreHistory(otherCursor); reopened.activate(environment: otherManifest)
        check(reopened.auditState == otherState, "Abandoned branch can be restored")

        let nodeCount = reopened.history!.nodes.count
        await reopened.sync()
        check(reopened.history!.nodes.count == nodeCount, "Sync creates audit entries without reversible nodes")
        check(reopened.history!.entries.filter { $0.kind == .external }.count == 2, "Sync request and receipt logged")
        reopened.undo(); reopened.activate(environment: environment)
        check(reopened.hasUnsyncedChanges, "Restore invalidates sync acknowledgement")
        reopened.setupName = "Pending text"
        reopened.undo()
        check(reopened.setupName != "Pending text", "Undo flushes pending text first")

        // The journal is authoritative over retained save files, including after restart.
        reopened.restoreHistory(reopened.history!.nodes[0].id)
        let blankRestart = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        blankRestart.activate(environment: environment)
        check(blankRestart.savedSetups.isEmpty && blankRestart.fixtures.isEmpty, "Undone saved files do not reappear on restart")
        let historyFile = folder.appendingPathComponent("Library/audit-history.json")
        let broken = Data("damaged audit history".utf8)
        try broken.write(to: historyFile)
        let damaged = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        damaged.activate(environment: environment); damaged.canPlace = true
        damaged.beginPlacement(); damaged.place(at: [2.66,0,-2], surfaceID: "floor")
        let preserved = try Data(contentsOf: historyFile)
        check(preserved == broken && !damaged.canUndo, "Corrupt log is preserved with history disabled")
        print("Audit checks passed: transactions, exact undo/redo, branch retention, presets/aim, saved setups, cross-room failure, relaunch, sync and corrupt-log preservation.")
    }
}
