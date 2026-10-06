import Foundation
import VenueVolumeCore

@MainActor enum InteractionSmoke {
    static func run(environment: EnvironmentManifest) throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
        let suite = "interaction-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: folder) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        model.updateToolboxActivation(raised: true)
        let firstRecall = model.toolboxRequestID
        check(firstRecall != nil, "Raising palm requests the toolbox")
        model.toolboxVisible = true
        model.updateToolboxActivation(raised: true)
        check(model.toolboxRequestID == firstRecall, "Held palm does not repeatedly recall the window")
        model.updateToolboxActivation(raised: false)
        check(model.toolboxVisible, "Lowering the palm leaves the normal window open")
        model.updateToolboxActivation(raised: true)
        let secondRecall = model.toolboxRequestID
        check(secondRecall != firstRecall, "A new raise recalls with a fresh window identity")
        model.toolboxVisible = false
        model.updateToolboxActivation(raised: true)
        check(model.toolboxRequestID == secondRecall && !model.toolboxVisible, "Closing while palm is raised stays closed")
        model.updateToolboxActivation(raised: false); model.updateToolboxActivation(raised: true)
        check(model.toolboxRequestID != secondRecall, "Lower then raise reopens a closed toolbox")
        let thirdRecall = model.toolboxRequestID
        model.requestToolbox()
        check(model.toolboxRequestID != thirdRecall, "Manual fallback can recall repeatedly without a hand toggle")
        model.togglePalmMap()
        check(!model.palmMapVisible, "Map cannot open outside a tracked immersed venue")
        model.activate(environment: environment); model.canPlace = true; model.isImmersed = true
        model.needsManualToolbox = true; model.simulatedPalm = false
        model.togglePalmMap()
        let mapRequest = model.palmMapRequestID
        check(mapRequest != nil && model.palmMapVisible, "Toolbar opens map without hand tracking or raised palm")
        model.updateToolboxActivation(raised: false)
        model.updateToolboxActivation(raised: true)
        check(model.palmMapRequestID == mapRequest, "Wrist recall does not toggle or reposition map")
        model.closePalmMap()
        check(!model.palmMapVisible, "Explicit Done closes map")
        model.togglePalmMap()
        check(model.palmMapRequestID != nil && model.palmMapRequestID != mapRequest, "Reopen requests a new stable pose")
        model.canPlace = false
        check(!model.palmMapVisible, "World tracking loss closes map and invalidates its request")
        model.canPlace = true; model.togglePalmMap()
        model.navigationBlackoutActive = true
        model.togglePalmMap()
        check(!model.palmMapVisible, "Close remains available during pending blackout")
        model.togglePalmMap()
        check(!model.palmMapVisible, "Pending blackout blocks new map request")
        model.navigationBlackoutActive = false; model.togglePalmMap()
        model.isImmersed = false
        check(!model.palmMapVisible, "Leaving immersion clears map visibility")
        model.isImmersed = true; model.togglePalmMap(); model.activate(environment: environment)
        check(!model.palmMapVisible, "Room activation invalidates the previous map request")
        model.canPlace = true
        model.beginPlacement(); model.togglePalmMap()
        check(model.palmMapVisible && model.isPlacing, "Opening map preserves placement context for return")
        model.closePalmMap()
        check(model.isPlacing, "Closing map restores the existing placement context")
        model.finishPlacement()
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66,y: 0,z: -2), surfaceID: "floor"), "First pilot")
        let first = model.fixtures[0].id
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 5,y: 0,z: -2), surfaceID: "floor"), "Second pilot")
        let second = model.fixtures[1].id, preset = model.presets[1]
        check(model.applyPreset(preset.id, to: first) && model.applyPreset(preset.id, to: second), "Shared preset")
        model.beginRetarget(first)
        let before = model.auditState!, revision = model.revision, nodeCount = model.history!.nodes.count
        let original = model.fixture(first)!, other = model.fixture(second)!
        for x: Float in [2.5,2.2,2] {
            check(model.acceptTarget(.init(x: x,y: 1.5,z: -7)), "Held target preview follows updated points")
        }
        check(model.canSaveTarget && model.renderedFixture(original).channels != original.channels, "Renderer previews target")
        check(model.auditState == before && model.revision == revision && model.history!.nodes.count == nodeCount,
              "Held preview does not change committed state, revision or journal")
        let relaunched = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        relaunched.activate(environment: environment)
        check(relaunched.fixtures == model.fixtures && relaunched.targetPreview == nil, "Unsaved target never persists")
        model.cancelPicking()
        check(model.fixture(first) == original && model.renderedFixture(original) == original && !model.canSaveTarget, "Cancel restores head preview")
        model.beginRetarget(first)
        check(model.acceptTarget(.init(x: 2,y: 1.5,z: -7)) && model.saveTarget(), "Save target")
        let aimed = model.fixture(first)!
        check(model.history!.nodes.count == nodeCount+1 && model.fixture(second)!.channels == aimed.channels && model.presets.first { $0.id == preset.id }?.channels == aimed.channels,
              "Save creates one step and updates shared preset assignments")
        model.undo(); check(model.fixture(first) == original, "Undo saved target")
        model.redo(); check(model.fixture(first) == aimed, "Redo saved target")
        model.choosePreset(model.presets.first { $0.id == preset.id }!)
        check(model.previewDraft, "Choosing a preset defaults to simulation")
        model.presetDraft.channels[0] = 177
        let draftBeforeTarget = model.presetDraft
        model.beginPresetTarget()
        check(model.acceptTarget(.init(x: 2.2,y: 1.5,z: -7)), "Target from editor uses draft")
        check(model.renderedChannels(for: model.fixture(first)!)[0] == 177, "Target simulates edited non-aim channels")
        model.cancelPicking()
        check(model.presetDraft == draftBeforeTarget && model.fixture(first) == aimed, "Cancel keeps unsaved draft and committed fixture")
        model.beginPresetTarget()
        check(model.acceptTarget(.init(x: 2.2,y: 1.5,z: -7)), "Restart editor target")
        model.presetDraft.channels[0] = 178
        check(model.renderedChannels(for: model.fixture(first)!)[0] == 178, "Staged target keeps live non-aim edits visible")
        check(model.saveTarget(), "Save draft target")
        check(model.fixture(first)!.channels[0] == 178 && model.fixture(second)!.channels[0] == 178 && !model.draftHasChanges,
              "Target save uses latest draft, saves preset and updates assignments")
        let freshAim = model.fixture(first)!
        model.beginRetarget(first)
        check(model.acceptTarget(.init(x: 2.4,y: 1.5,z: -7)), "Second transient DMX preview")
        model.select(second)
        check(model.selectedID == second && model.targetPreview == nil && !model.isPickingRoom && model.fixture(first) == freshAim,
              "Selecting another item switches context and cancels unsaved aim")
        model.deselect()
        check(model.selectedID == nil && model.expandedID == nil && !model.gizmoVisible, "Background deselection returns scene breakdown")
        check(!model.updateFixtureDetails(first, name: "Invalid patch", universe: other.universe, address: other.startAddress), "Reject overlapping patch")
        check(model.fixture(first) == freshAim, "Rejected edit preserves fixture")
        check(model.updateFixtureDetails(first, name: "  Stage left  ", universe: 2, address: 41), "Save item details")
        check(model.fixture(first)!.name == "Stage left" && model.fixture(first)!.universe == 2 && model.fixture(first)!.startAddress == 41,
              "Full editor updates validated name and patch")
        model.undo(); check(model.fixture(first) == freshAim, "Undo item details")
        model.redo()

        model.select(first)
        model.newPreset()
        check(model.presetDraft.name.isEmpty && model.previewDraft, "New preset starts with blank name and simulation enabled")
        model.beginPresetTarget()
        check(!model.isRetargeting, "Unnamed new preset cannot start targeting")
        model.presetDraft.name = "Solo target"
        model.presetDraft.channels = preset.channels
        let secondBefore = model.fixture(second)!, libraryBefore = model.presets
        model.previewBlackout = true; model.flushHistoryEdits()
        check(model.isBlackedOut(model.fixture(first)!) && !model.isBlackedOut(secondBefore) && model.toolboxBlackout,
              "Preset simulation blackout affects only selected fixture and signals Toolbox")
        check(model.fixtures.contains(secondBefore) && model.presets == libraryBefore && model.presetDraft.channels == preset.channels,
              "Blackout preserves saved and draft channel values")
        model.undo(); check(!model.previewBlackout, "Undo simulation blackout")
        model.redo(); check(model.previewBlackout, "Redo simulation blackout")
        model.blackout = true
        check(model.isBlackedOut(secondBefore), "Global blackout still overrides all outputs")
        model.blackout = false; model.previewBlackout = false
        model.beginPresetTarget()
        check(model.acceptTarget(.init(x: 2.2,y: 1.5,z: -7)) && model.saveTarget(), "Named new draft can target, save and assign")
        check(model.fixture(first)!.presetID == model.editingPresetID && model.fixture(second) == secondBefore,
              "New preset target assignment leaves original preset fixtures alone")
        let targetRestored = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        targetRestored.activate(environment: environment)
        check(targetRestored.fixtures == model.fixtures && targetRestored.presets == model.presets,
              "Preset targets and assignments persist together")
        model.beginRetarget(first)
        check(model.acceptTarget(.init(x: 2.5,y: 1.5,z: -7)), "Start before navigation")
        model.choosePreset(preset)
        check(!model.isRetargeting && !model.saveTarget(), "Switching presets cancels stale target context")

        model.beginRetarget(first)
        check(model.acceptTarget(.init(x: 2.5,y: 1.5,z: -7)), "Start before clear assignment")
        model.clearAssignment(first)
        check(!model.isRetargeting && !model.saveTarget(), "Clearing assignment cancels the old preset target")
        model.undo()
        model.beginTransform(first); model.flushHistoryEdits()
        let transformBefore = model.fixture(first)!, transformNodes = model.history!.nodes.count
        let center = FixtureAiming.vector(transformBefore.position) + [0,LightingPreview.height/2,0]
        model.beginTransformDrag(axis: .y, mode: .rotate, at: center+[0,0,0.42])
        model.updateTransformDrag(to: center+[0.3,0,0.3])
        model.updateTransformDrag(to: center+[0.42,0,0])
        model.endTransformDrag()
        let rotated = model.fixture(first)!
        check(rotated.orientation != transformBefore.orientation && rotated.channels == transformBefore.channels && rotated.position == transformBefore.position,
              "Axis ring rotates mount without changing DMX or position")
        check(model.history!.nodes.count == transformNodes+1, "Ring gesture groups into one Undo step")
        model.undo(); check(model.fixture(first) == transformBefore, "Undo ring gesture")
        model.redo(); check(model.fixture(first) == rotated, "Redo ring gesture")
        model.beginTransform(first)
        let start = FixtureAiming.vector(rotated.position)
        model.transformMode = .move
        model.beginTransformDrag(axis: .x, mode: .move, at: start)
        model.updateTransformDrag(to: start+[0.2,2,1])
        model.endTransformDrag()
        let moved = model.fixture(first)!
        check(abs(moved.position.x-rotated.position.x-0.2) < 0.0001 && moved.position.y == rotated.position.y && moved.position.z == rotated.position.z,
              "Translation handle constrains movement to chosen axis")
        check(moved.orientation == rotated.orientation && moved.channels == rotated.channels, "Movement preserves orientation and DMX")
        model.beginTransformDrag(axis: .x, mode: .move, at: start)
        model.updateTransformDrag(to: start+[-30,0,0]); model.endTransformDrag()
        check(model.fixture(first) == moved, "Out-of-room axis moves rejected")
        let fixtures = model.fixtures, presets = model.presets, room = model.activeRoom
        model.clearScene()
        check(model.fixtures.isEmpty && model.selectedID == nil && model.presets == presets && model.activeRoom == room, "Clear all affects scene items only")
        model.undo(); check(model.fixtures == fixtures, "Undo restores all scene items")
        model.redo(); check(model.fixtures.isEmpty, "Redo clears scene items")
        print("Interaction checks passed: toolbar map lifecycle, toolbox activation/close/reopen, target preview/save/cancel, held updates, selection, axis gestures, grouped history, scene clearing and persistence.")
        let waveKind = FixtureKind(rawValue: "claypaky/volero-wave")!
        check(model.dropFixture([waveKind.dragToken], at: .init(x: 2.66,y: 0,z: -2), surfaceID: "floor"), "Place eight-module bar")
        let wave = model.fixtures[0], joint = wave.asset!.joints[0]
        model.beginHistoryAction("Drag module tilt")
        model.setJoint(wave.id, jointID: joint.id, value: 15)
        model.setJoint(wave.id, jointID: joint.id, value: 30)
        model.endHistoryAction()
        let aimedWave = model.fixtures[0]
        check(aimedWave.jointOverrides?[joint.id] != nil && aimedWave.channels[8] == 128, "Only selected module moves")
        model.undo(); check(model.fixtures[0] == wave, "Undo module gesture")
        model.redo(); check(model.fixtures[0] == aimedWave, "Redo module gesture")
        let restored = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        restored.activate(environment: environment)
        check(restored.fixtures[0] == aimedWave, "Module pose persists")
        check(model.applyPreset(preset.id, to: wave.id), "Apply bar preset")
        check(model.fixtures[0].channels[joint.channel] == aimedWave.channels[joint.channel], "Preset preserves module override")
        model.resetAim(wave.id)
        check(model.fixtures[0].jointOverrides == nil, "Reset clears module override")
        let fanKind = FixtureKind(rawValue: "adj/entour-cyclone")!
        check(model.dropFixture([fanKind.dragToken], at: .init(x: 5,y: 0,z: -2), surfaceID: "floor"), "Place fan")
        let fan = model.fixtures[1]
        model.setJoint(fan.id, jointID: "rotor", value: 360)
        check(model.fixture(fan.id)!.channels[7] > 0 && fan.asset!.emitters.isEmpty, "Fan has speed and no light")
        model.beginRetarget(fan.id)
        check(!model.isRetargeting, "Fan cannot enter light targeting")
        model.clearScene()
        let catalogHead = FixtureKind(rawValue: "chauvet-professional/rogue-r3-beam")!
        check(model.dropFixture([catalogHead.dragToken], at: .init(x: 2.66,y: 0,z: -2), surfaceID: "floor"), "Place catalog moving head")
        let catalogID = model.fixtures[0].id
        check(model.applyPreset(preset.id, to: catalogID), "Assign catalog head preset")
        model.setJoint(catalogID, jointID: "pan", value: 20)
        model.setJoint(catalogID, jointID: "tilt", value: 10)
        let catalogBefore = model.fixture(catalogID)!
        model.beginRetarget(catalogID)
        check(model.isRetargeting && model.acceptTarget(.init(x: 2,y: 1.5,z: -7)), "Catalog head supports preset DMX targeting")
        check(model.saveTarget(), "Save catalog head target over legacy joint overrides")
        let catalogAfter = model.fixture(catalogID)!
        check(catalogAfter.aimOverride == nil && catalogAfter.jointOverrides?["pan"] == nil && catalogAfter.jointOverrides?["tilt"] == nil,
              "Preset target clears conflicting legacy pan/tilt overrides")
        check(catalogAfter.channels == model.presets.first { $0.id == preset.id }?.channels, "Catalog head follows saved preset")
        model.undo(); check(model.fixture(catalogID) == catalogBefore, "Undo restores catalog joint overrides and target preset")
        model.redo(); check(model.fixture(catalogID) == catalogAfter, "Redo restores catalog preset target")
        let grouped = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder.appendingPathComponent("groups"))
        grouped.activate(environment: environment); grouped.canPlace = true
        grouped.beginPlacement()
        grouped.place(at: [2.66,0,-2], surfaceID: "floor")
        check(grouped.isPlacing, "Placement continues after first fixture")
        grouped.place(at: [5,0,-2], surfaceID: "floor")
        check(grouped.fixtures.count == 2 && grouped.isPlacing, "Repeated clicks place fixtures until Done")
        grouped.finishPlacement(); check(!grouped.isPlacing, "Done ends placement")
        let a = grouped.fixtures[0].id, b = grouped.fixtures[1].id
        grouped.select(a); grouped.multiSelectionMode = true; grouped.select(b)
        check(grouped.selectedFixtureIDs == [a,b], "Multi-selection keeps both fixtures")
        grouped.select(b)
        check(grouped.selectedFixtureIDs == [a], "Toggle removes only the clicked ungrouped fixture")
        grouped.select(b)
        grouped.groupSelection()
        let group = grouped.fixture(a)!.groupID!
        grouped.deselect(); grouped.select(b)
        check(grouped.selectedFixtureIDs == [a,b], "Selecting a group member selects the whole group")
        grouped.multiSelectionMode = true; grouped.select(a)
        check(grouped.selectedFixtureIDs.isEmpty, "Toggle another member deselects the whole group")
        grouped.select(a); grouped.multiSelectionMode = false
        check(grouped.applyPreset(grouped.presets[0].id, to: a), "Apply palette to group")
        check(grouped.fixtures.allSatisfy { $0.presetID == grouped.presets[0].id }, "Group palette assignment updates all members")
        let beforePatch = grouped.fixtures
        check(!grouped.updateFixtureDetails(a, name: "Group anchor", universe: 1, address: 510), "Group patch rejects overflowing footprint")
        check(grouped.fixtures == beforePatch, "Invalid group patch is atomic")
        check(grouped.updateFixtureDetails(a, name: "Group anchor", universe: 2, address: 33), "Group patch succeeds")
        check(grouped.fixtures[0].startAddress == 33 && grouped.fixtures[1].startAddress == 49, "Group patch allocates successive footprints")
        let beforeMove = grouped.fixtures
        grouped.moveFixture(a, position: .init(x: 3, y: 0, z: -2), yawDegrees: 30)
        check(grouped.fixture(b)!.position.x > beforeMove[1].position.x && grouped.fixture(b)!.orientation != beforeMove[1].orientation, "Group movement and orientation apply to all")
        grouped.undo(); check(grouped.fixtures == beforeMove, "Group transform is one Undo step")
        grouped.redo()
        let restoredGroup = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder.appendingPathComponent("groups"))
        restoredGroup.activate(environment: environment)
        check(restoredGroup.fixtures.allSatisfy { $0.groupID == group }, "Group membership survives relaunch")
        let portable = try grouped.currentSetupSnapshot()
        let decoded = try JSONDecoder().decode(VenueSetup.self, from: JSONEncoder().encode(portable))
        check(decoded.placements.fixtures.allSatisfy { $0.groupID == group }, "Group membership survives portable setup encoding")
        grouped.beginRetarget(a)
        let target = Position3D(x: 2,y: 1.5,z: -7)
        check(grouped.acceptTarget(target) && grouped.saveTarget(), "Group retarget saves")
        check(grouped.fixtures.allSatisfy { $0.aimOverride != nil }, "Group target resolves per fixture")
        check(grouped.fixture(a)!.aimOverride != grouped.fixture(b)!.aimOverride, "Separated fixtures use distinct DMX angles for common target")
        grouped.ungroup(group); check(grouped.fixtures.allSatisfy { $0.groupID == nil }, "Ungroup clears all membership")
        grouped.undo(); check(grouped.fixtures.allSatisfy { $0.groupID == group }, "Undo restores group")
        grouped.remove(b); check(grouped.fixtures.isEmpty && grouped.fixtureGroups.isEmpty, "Delete acts on group without dangling membership")
        grouped.navigationFadeMilliseconds = 500
        check(VenueModel(arguments: [], defaults: defaults, placementDirectory: folder).navigationFadeMilliseconds == 500, "Navigation fade preference persists")
        let layered = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder.appendingPathComponent("layers"))
        layered.activate(environment: environment); layered.canPlace = true; layered.beginPlacement()
        for x: Float in [2.66, 5, 6] { layered.place(at: [x,0,-2], surfaceID: "floor") }
        layered.finishPlacement()
        check(layered.fixtures.count == 3, "Layered test places three fixtures")
        let one = layered.fixtures[0].id, two = layered.fixtures[1].id
        layered.select(one); layered.multiSelectionMode = true; layered.select(two); layered.groupSelection()
        let chase = layered.presets.first { $0.name == "Phaser · Dimmer chase" }!
        let red = layered.presets.first { $0.name == "Color · Red" }!
        let centerPalette = layered.presets.first { $0.name == "Position · Center" }!
        for palette in [chase, red, centerPalette] {
            check(layered.applyPreset(palette.id, to: one), "Apply independent group attribute palette")
        }
        let oneOutput = layered.renderedChannels(for: layered.fixture(one)!, at: 0)
        let twoOutput = layered.renderedChannels(for: layered.fixture(two)!, at: 0)
        check(oneOutput[0] == 255 && twoOutput[0] == 0, "Unassigned fixtures do not affect chase phase distribution")
        check(Array(oneOutput[1...3]) == [255,0,0] && oneOutput[4] == 128, "Static color/position coexist with intensity phaser")
        check(layered.hasAnimatedPalette(for: layered.fixture(one)!), "Latest static palette does not hide animated layers")
        let layeredSave = try layered.currentSetupSnapshot()
        check(Set(layeredSave.presets.map(\.id)).isSuperset(of: [chase.id, red.id, centerPalette.id]), "Portable setup retains all palette dependencies")
        let layeredRestored = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder.appendingPathComponent("layers"))
        layeredRestored.activate(environment: environment)
        check(layeredRestored.renderedChannels(for: layeredRestored.fixture(two)!, at: 0) == twoOutput, "Layered phaser playback survives relaunch")
        layered.deletePreset(red.id)
        check(layered.hasAnimatedPalette(for: layered.fixture(one)!) && layered.renderedChannels(for: layered.fixture(one)!, at: 0)[0] == 255,
              "Deleting color preserves the independent intensity phaser")
        let legacySuite = suite + "-legacy"
        let legacyDefaults = UserDefaults(suiteName: legacySuite)!
        defer { legacyDefaults.removePersistentDomain(forName: legacySuite) }
        legacyDefaults.set(try JSONEncoder().encode(LightingPreview.presets), forKey: "venue.presets.v1")
        let migrated = VenueModel(arguments: [], defaults: legacyDefaults, placementDirectory: folder.appendingPathComponent("legacy"))
        check(migrated.presets.contains { $0.id == chase.id }, "Existing preset libraries receive the palette baseline once")
        migrated.deletePreset(chase.id)
        let migratedAgain = VenueModel(arguments: [], defaults: legacyDefaults, placementDirectory: folder.appendingPathComponent("legacy"))
        check(!migratedAgain.presets.contains { $0.id == chase.id }, "Deleted baseline palettes are not recreated on relaunch")
        print("Layered palette session checks passed: independent attributes, group phase, portable dependencies, relaunch and selective deletion.")
        print("Catalog session checks passed: module isolation, grouped undo/redo, saved poses, preset preservation and fan controls.")
    }
}
