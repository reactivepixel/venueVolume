import Foundation
import VenueVolumeCore

@MainActor enum TouringSmoke {
    static func run(environment: EnvironmentManifest) throws {
        let suite = "touring-smoke-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        model.createTouringShow(name: "Tour rig")
        check(model.tour != nil && model.canUndo, "Show can be prepared before a venue")
        model.undo(); check(model.tour == nil, "Pre-venue Undo restores inventory")
        model.redo(); check(model.tour?.show.name == "Tour rig", "Pre-venue Redo")
        model.addInventory(.movingHead, quantity: 3)
        let ids = model.tourUnits.map(\.id)
        check(ids.count == 3 && Set(ids).count == 3, "Quantity creates distinct stable units")
        let prepared = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        check(prepared.tourUnits.map(\.id) == ids, "Prepared inventory persists independently")
        model.activate(environment: environment); model.canPlace = true
        model.beginInventoryPlacement(ids[0], repeatAll: true)
        for x: Float in [2,3,4] { model.place(at: [x,0,-2], surfaceID: "floor") }
        check(Set(model.fixtures.map(\.id)) == Set(ids) && !model.isPlacing, "Repeat placement uses available identities and stops")
        model.beginInventoryPlacement(ids[0]); model.place(at: [5,0,-2], surfaceID: "floor")
        check(model.fixtures.count == 3, "No fourth unit is manufactured")
        model.remove(ids[0]); check(model.availableUnits.map(\.id) == [ids[0]], "Returning a fixture frees the same unit")
        model.undo(); check(model.fixtures.count == 3, "Undo returns the placement")
        model.redo(); model.beginInventoryPlacement(ids[0]); model.place(at: [2,0,-2], surfaceID: "floor")
        model.saveGroup(name: "Front", parentID: nil)
        let parent = model.tour!.show.groups[0].id
        model.saveGroup(name: "Left", parentID: parent)
        let child = model.tour!.show.groups[1].id
        model.selectGroup(nil); model.assignSelectionToGroup(parent)
        check(model.tour!.show.units.allSatisfy { $0.groupID == nil }, "Membership preview is transient")
        check(model.commitTourPreview(), "Commit membership")
        model.selectInventory(ids[0]); model.assignSelectionToGroup(child); check(model.commitTourPreview(), "Child membership")
        model.selectGroup(parent); check(model.tourSelection == Set(ids), "Parent selects descendants")
        model.newPreset(); model.presetDraft.name = "Colour"; model.presetDraft.includedChannels = [1,2,3]
        model.presetDraft.channels[1] = 242; model.presetDraft.channels[2] = 67; model.presetDraft.channels[3] = 10
        model.tourEditShow = true; check(model.savePreset(), "Save shared partial preset")
        let colour = model.editingPresetID!
        let old = model.fixtures
        check(model.applyTourPreset(colour, group: parent, preview: true, toShow: true), "Preview shared group default")
        check(model.fixtures == old, "Preview does not mutate committed output")
        model.cancelTourPreview(); check(model.fixtures == old, "Cancel leaves entire group unchanged")
        check(model.applyTourPreset(colour, group: parent, preview: true, toShow: true), "Re-preview group")
        let beforeApply = model.auditState!
        check(model.commitTourPreview(), "Save group assignment")
        let afterApply = model.auditState!
        check(model.fixtures.allSatisfy { $0.channels[1] == 242 }, "Group look resolves across descendants")
        model.undo(); check(model.tour == beforeApply.touring?.active && model.fixtures == old, "Group application is one Undo step")
        model.redo(); check(model.tour == afterApply.touring?.active, "Redo restores exact assignments")
        model.beginSelectionTransform(); model.transformMode = .move
        let pivot = model.transformFixtureContext!.position
        model.beginTransformDrag(axis: .x, mode: .move, at: [pivot.x,pivot.y,pivot.z])
        let beforeMove = model.fixtures
        model.updateTransformDrag(to: [pivot.x+0.2,pivot.y,pivot.z]); model.updateTransformDrag(to: [pivot.x+0.4,pivot.y,pivot.z]); model.endTransformDrag()
        check(zip(beforeMove,model.fixtures).allSatisfy { abs($1.position.x-$0.position.x-0.4)<0.001 && $0.channels == $1.channels }, "Group axis moves all mounts, preserves DMX")
        model.undo(); check(model.fixtures == beforeMove, "Group axis gesture is one Undo")
        model.gizmoVisible = false
        model.selectGroup(parent); model.previewGroupTransform(translation: .init(x: 0.2,y: 0,z: 0), spacing: 0.8, mirror: true)
        check(model.tourPreview != nil, "Numeric arrangement preview")
        model.cancelTourPreview(); check(model.fixtures == beforeMove, "Transform cancel restores all")
        model.selectInventory(ids[0]); model.beginRetarget(ids[0])
        check(model.message?.contains("focus preset") == true, "No misleading retarget when only colour is assigned")
        model.selectGroup(parent); model.newPreset(); model.presetDraft.name = "Vocal focus"; model.presetDraft.includedChannels = [4,5]
        model.beginPresetTarget()
        check(model.isRetargeting, "Touring draft target begins")
        check(model.acceptTarget(.init(x: 3,y: 1.4,z: -6)), "Target preview solves group")
        let targetPreview = model.tourPreview!
        check(Set(targetPreview.map { $0.channels[4] }).count > 1, "Target has per-fixture Pan")
        let beforeTarget = model.fixtures
        check(model.saveTarget(), "Save target")
        check(model.tour!.targetLocations.count == 1 && model.fixtures != beforeTarget, "Target location and resolved channels commit together")
        model.undo(); check(model.fixtures == beforeTarget && model.tour!.targetLocations.isEmpty, "Target Undo restores definitions and output")
        model.redo(); check(model.tour!.targetLocations.count == 1, "Target Redo")
        // Return/re-place keeps group programming, then compare pinned room instances.
        model.saveConfiguration(name: "Layout", selectionOnly: false)
        let layoutID = model.tour!.show.configurations.last!.id
        model.setupName = "First venue"; check(model.saveSetup(asNew: true), "Save touring venue")
        let setup = model.savedSetups.first { $0.name == "First venue" }!
        check(setup.tour?.show.units.count == 3 && setup.presets.count == model.presets.count, "Saved snapshot includes full inventory and unused presets")
        let room = model.activeRoom!
        model.requestRoom(room, blank: true, configurationID: layoutID); model.activate(environment: environment); model.canPlace = true
        check(model.tour?.configurationID == layoutID, "New venue accepts a staged configuration without altering the old save")
        model.previewConfigurationLayout(translation: .init(x: 0.2,y: 0,z: 0), yaw: 0)
        check(model.tourPreview?.count == 3 && model.fixtures.isEmpty, "Adapt layout previews the saved arrangement")
        model.cancelTourPreview()
        check(model.fixtures.isEmpty && model.tourUnits.map(\.id) == ids, "Blank next venue reuses hardware without reservations")
        check(model.tour!.targetLocations.isEmpty && model.tour!.presetOverrides.isEmpty, "Venue overrides and target locations do not leak")
        check(model.tour!.show.programming.groups[parent]?[1] == colour, "Shared group defaults travel")
        model.selectGroup(parent); model.previewGroupPlacement(origin: .init(x: 3,y: 0,z: -2), spacing: 1)
        check(model.tourPreview?.count == 3 && model.fixtures.isEmpty, "Batch row previews without placement mutation")
        model.cancelTourPreview(); check(model.fixtures.isEmpty, "Row cancel")
        model.previewGroupPlacement(origin: .init(x: 3,y: 0,z: -2), spacing: 1)
        check(model.commitTourPreview() && model.fixtures.count == 3, "Commit complete supported row")
        model.undo(); check(model.fixtures.isEmpty, "Row is one undo step")
        model.redo(); check(model.fixtures.count == 3, "Row redo restores IDs")
        model.newPreset(); model.presetDraft.name = "Only in second venue"; model.tourEditShow = false
        check(model.savePreset(), "Save a second-venue-only preset before restoring the first venue")
        model.requestRoom(room, setup: setup); model.activate(environment: environment)
        check(model.editingPresetID == nil || model.presets.contains { $0.id == model.editingPresetID }, "Room restoration keeps a valid editor context")
        check(model.historyMessage?.contains("failed") != true, "Changing scoped preset libraries must not break the audit snapshot")
        check(model.tour == setup.tour && model.fixtures == setup.placements.fixtures, "Reopen pinned original venue")
        let relaunched = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        relaunched.activate(environment: environment)
        check(relaunched.tour == model.tour && relaunched.fixtures == model.fixtures, "Tour state and placements survive relaunch")
        var newShow = model.tour!.show; newShow.revision += 1; newShow.name = "Updated tour"
        let pinned = model.tour!
        model.importTouringShow(try JSONEncoder().encode(newShow))
        check(model.tour == pinned && model.availableShowUpdate?.name == "Updated tour", "Import does not replace pinned venue")
        model.previewShowUpdate(); check(model.tour == pinned, "Review adoption remains transient")
        check(model.commitTourPreview() && model.tour!.show.name == "Updated tour", "Accept revision update")
        model.undo(); check(model.tour == pinned, "Undo adoption")
        model.importTouringShow(Data("{broken".utf8)); check(model.tour == pinned, "Corrupt import preserves current venue")
        model.previewGroupTransform(translation: .init(x: 0.1,y: 0,z: 0))
        if let id = model.fixtures.first?.id { model.remove(id) }
        check(!model.commitTourPreview(), "Stale preview cannot resurrect a returned unit")
        check(model.historyMessage?.contains("failed") != true, "Touring changes all produce valid audit snapshots")
        if model.availableShowUpdate != nil { model.previewShowUpdate(); check(model.commitTourPreview(), "Adopt latest revision before publishing") }
        model.newPreset(); model.presetDraft.name = "Publish without changing values"; model.tourEditShow = false
        check(model.savePreset(), "Save a venue-only preset")
        let publishID = model.editingPresetID!
        model.tourEditShow = true
        check(model.canSavePreset && model.savePreset(), "Publishing a saved venue preset must not require editing a channel")
        check(model.tour!.show.presets.contains { $0.id == publishID } && !model.tour!.presetOverrides.contains { $0.id == publishID }, "Publishing preserves preset identity")
        // Legacy saves remain explicit migrations, never merged by names/models.
        let legacy = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("legacy"))
        legacy.activate(environment: environment); legacy.canPlace = true; legacy.beginPlacement(); legacy.place(at: [2,0,-2], surfaceID: "floor")
        let legacyID = legacy.fixtures[0].id; let legacyPose = legacy.fixtures[0]
        check(legacy.saveSetup(asNew: true), "Save legacy before migration"); let legacySave = legacy.savedSetups[0]
        legacy.createTouringShow(name: "Migrated")
        check(legacy.tourUnits.first?.id == legacyID && legacy.fixtures[0] == legacyPose, "Explicit legacy migration retains identity and transform")
        legacy.undo(); check(legacy.tour == nil && legacy.fixtures[0] == legacyPose, "Undo migration restores legacy mode")
        legacy.redo(); check(legacy.tourUnits.first?.id == legacyID, "Redo migration restores inventory identity")
        let rowBefore = legacy.fixtures
        legacy.selectGroup(nil); legacy.previewGroupTransform(translation: .init(x: 100,y: 0,z: 0))
        check(legacy.tourPreview == nil && legacy.fixtures == rowBefore, "Out-of-bounds batch rejects without changes")
        legacy.saveGroup(name: "Parent", parentID: nil); let legacyParent = legacy.tour!.show.groups[0].id
        legacy.saveGroup(name: "Child", parentID: legacyParent); let legacyChild = legacy.tour!.show.groups[1].id
        legacy.saveGroup(id: legacyParent, name: "Parent", parentID: legacyChild)
        check(legacy.tourPreview == nil && legacy.tour!.show.groups[0].parentID == nil, "Reparent cycle cannot enter a preview")
        legacy.createFocusTarget(name: "Tour-only target"); legacy.newPreset(); legacy.presetDraft.name = "Tour-only focus"
        legacy.presetDraft.focusTargetID = legacy.tour!.show.targets[0].id; legacy.presetDraft.includedChannels = [4,5]; legacy.tourEditShow = true
        check(legacy.savePreset(), "Save a tour-only focus definition")
        legacy.requestRoom(legacy.activeRoom!, setup: legacySave); legacy.activate(environment: environment)
        check(legacy.tour == nil && legacy.presets.allSatisfy { $0.focusTargetID == nil }, "Opening a legacy save does not leak touring presets")
        let corruptFolder = directory.appendingPathComponent("corrupt/Library")
        try FileManager.default.createDirectory(at: corruptFolder, withIntermediateDirectories: true)
        let corruptURL = corruptFolder.appendingPathComponent("touring-shows.json")
        try Data("broken".utf8).write(to: corruptURL)
        let corrupt = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("corrupt"))
        corrupt.createTouringShow(name: "Do not overwrite")
        check(corrupt.touringBlocked && corrupt.tour == nil, "Corrupt inventory is preserved")
        let preserved = try Data(contentsOf: corruptURL)
        check(preserved == Data("broken".utf8), "Corrupt bytes not overwritten")
        print("Touring session checks passed: prepared inventory, quantity limits, groups, atomic presets, shared scope, axes, target solve, previews, room pinning, persistence, import/adoption and Undo/Redo.")
    }
}
