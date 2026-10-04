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
        let a = UUID(), b = UUID()
        model.toolboxAppeared(a); model.toolboxAppeared(b); model.toolboxDisappeared(a)
        check(model.toolboxVisible && model.toolboxWindowIDs == [b] && model.toolboxPresentedID == b,
              "A closing old Toolbox cannot hide the replacement window")
        model.toolboxDisappeared(b)
        check(!model.toolboxVisible && model.toolboxWindowIDs.isEmpty,"Closing all instances clears Toolbox visibility")
        let thirdRecall = model.toolboxRequestID
        model.requestToolbox()
        check(model.toolboxRequestID != thirdRecall, "Manual fallback can recall repeatedly without a hand toggle")
        model.resetToolboxActivation()
        check(model.toolboxRequestID == nil, "Venue exit cancels a pending recall instead of reopening its Toolbox")
        model.updateToolboxActivation(raised: true)
        check(model.toolboxRequestID != nil && model.toolboxRequestID != thirdRecall,
              "Re-entering permits a fresh wrist activation after exit")
        model.activate(environment: environment); model.canPlace = true
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
        print("Interaction checks passed: toolbox activation/close/reopen, target preview/save/cancel, held updates, selection, axis gestures, grouped history, scene clearing and persistence.")
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
        print("Catalog session checks passed: module isolation, grouped undo/redo, saved poses, preset preservation and fan controls.")
    }
}


@MainActor enum FixtureMovementSmoke {
    static func run(environment: EnvironmentManifest) throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(),message) }
        let defaults = UserDefaults(suiteName: "fixture-movement-" + UUID().uuidString)!
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = VenueModel(arguments: [],defaults: defaults,placementDirectory: folder)
        model.activate(environment: environment); model.canPlace = true
        check(model.dropFixture([FixtureKind.movingHead.dragToken],at: .init(x: 2.66,y: 0,z: -2),surfaceID: "floor"),"Place pilot")
        let id = model.fixtures[0].id
        model.deselect(); model.tapFixture(id)
        check(model.selectedID == id && !model.gizmoVisible,"First click selects")
        model.tapFixture(id)
        check(model.gizmoVisible && model.transformMode == .move && model.isSurfaceMoveActive,"Second click enables surface movement and rings")
        let original = model.fixtures[0], nodes = model.history!.nodes.count
        let start = FixtureAiming.vector(original.position)
        model.beginSurfaceDrag(id,at: start)
        check(model.updateSurfaceDrag(to: start+[0.12,4,0.1]),"Slide floor")
        check(model.updateSurfaceDrag(to: start+[0.25,-3,0.2]),"Continue same drag")
        model.endTransformDrag()
        let moved = model.fixtures[0]
        check(moved.position.y == original.position.y && abs(moved.position.x-original.position.x-0.25) < 0.001,"Body drag stays on floor and uses the original gesture position")
        check(moved.orientation == original.orientation && moved.channels == original.channels,"Body drag preserves mount and DMX")
        check(model.history!.nodes.count == nodes+1,"Body drag is one Undo step")
        model.undo(); check(model.fixtures[0] == original,"Undo restores body drag")
        model.redo(); check(model.fixtures[0] == moved,"Redo restores plane and position")
        model.beginTransform(id)
        let beforeBad = model.fixtures
        model.beginSurfaceDrag(id,at: FixtureAiming.vector(moved.position))
        check(!model.updateSurfaceDrag(to: [-30,0,-2]),"Reject off-plane support bounds")
        model.endTransformDrag(); check(model.fixtures == beforeBad,"Rejected drag keeps last valid position")
        model.beginTransform(id)
        let max = environment.bounds.max, min = environment.bounds.min
        let wall = Position3D(x: min[0],y: 1.3,z: (min[2]+max[2])/2)
        check(model.moveToSurface(at: wall,normal: .init(x: 1,y: 0,z: 0)),"Move to wall")
        let wallFixture = model.fixtures[0]
        check(FixtureAiming.length(FixtureAiming.rotate(wallFixture.orientation,[0,1,0])-SIMD3<Float>(1,0,0)) < 0.001 && wallFixture.channels == original.channels,"Wall aligns mount while preserving DMX")
        model.beginSurfaceDrag(id,at: [0,1,0])
        check(model.updateSurfaceDrag(to: [5,1.2,0.1]),"Slide wall")
        model.endTransformDrag()
        check(abs(model.fixtures[0].position.x-wall.x) < 0.001 && abs(model.fixtures[0].position.y-wall.y-0.2) < 0.001,"Wall drag ignores normal movement")
        model.beginTransform(id)
        check(model.moveToSurface(at: .init(x: 3,y: max[1],z: -3),normal: .init(x: 0,y: -1,z: 0)),"Move to ceiling")
        let ceiling = model.fixtures[0]
        check(FixtureAiming.length(FixtureAiming.rotate(ceiling.orientation,[0,1,0])-SIMD3<Float>(0,-1,0)) < 0.001,"Ceiling mount faces into room")
        let restored = VenueModel(arguments: [],defaults: defaults,placementDirectory: folder)
        restored.activate(environment: environment)
        check(restored.fixtures[0] == ceiling,"Mount plane survives relaunch")
        model.deselect(); check(!model.isSurfaceMoveActive && !model.gizmoVisible,"Deselect ends movement")
        let kinds = Array(FixtureKind.allCases.filter { $0 != .movingHead }.prefix(7))
        for kind in kinds { model.selectFixtureKind(kind) }
        model.selectFixtureKind(kinds[4])
        check(model.quickFixtureKinds.first == .movingHead && model.quickFixtureKinds.count == 6,"Pinned pilot plus five recent models")
        check(model.quickFixtureKinds[1] == kinds[4] && Set(model.quickFixtureKinds).count == 6,"Recents deduplicate and reorder")
        let relaunched = VenueModel(arguments: [],defaults: defaults,placementDirectory: folder)
        check(relaunched.quickFixtureKinds == model.quickFixtureKinds,"Recent model choices persist independently of venues")
        model.toolboxVisible = false; model.showVenueControls()
        let recall = model.toolboxRequestID
        check(recall != nil && model.venueControlsVisible,"Appearing controls exposes a closed Toolbox")
        model.showVenueControls()
        check(model.toolboxRequestID == recall,"Repeated appearance callbacks do not queue duplicate Toolboxes")
        model.toolboxVisible = true; model.showVenueControls()
        check(model.toolboxRequestID == recall,"An open Toolbox is not recalled or repositioned")
        print("Fixture movement checks passed: second click, floor/wall/ceiling moves, plane dragging, atomic Undo/Redo, persistence, compact recents and dock wrist reveal.")
    }
}

@MainActor enum ViewerNavigationSmoke {
    static func run(environment: EnvironmentManifest) throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(),message) }
        let suite = "viewer-navigation-"+UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder); defaults.removePersistentDomain(forName: suite) }
        let model = VenueModel(arguments: [],defaults: defaults,placementDirectory: folder)
        model.activate(environment: environment); model.canPlace = true; model.isImmersed = true
        _ = model.dropFixture([FixtureKind.movingHead.dragToken],at: .init(x: 2.66,y: 0,z: -2),surfaceID: "floor")
        let fixtures = model.fixtures, presets = model.presets, count = model.history!.nodes.count
        let moved = ViewerNavigationPose(offset: .init(x: -30,y: 20,z: -100),orientation: FixtureAiming.euler(yaw: 25,pitch: 10,roll: 5))
        model.beginTransform(model.fixtures[0].id)
        model.beginViewerNavigation(.index)
        check(model.gizmoVisible,"Viewer movement keeps mount controls available")
        model.updateViewerNavigation(.init(offset: .init(x: 1,y: 2,z: 3)))
        model.updateViewerNavigation(moved); model.endViewerNavigation()
        check(model.history!.nodes.count == count+1,"Navigation drag is one history action")
        check(model.fixtures == fixtures && model.presets == presets,"Navigation never edits fixture mounts or DMX")
        model.undo(); check(model.viewerPose == .init(),"Undo navigation")
        model.redo(); check(model.viewerPose == moved,"Redo navigation")
        let restored = VenueModel(arguments: [],defaults: defaults,placementDirectory: folder)
        restored.activate(environment: environment)
        check(restored.viewerPose == moved,"Virtual navigation resumes from history")
        model.resetViewerToSpawn(); check(model.viewerPose == .init(),"Full reset")
        model.undo(); check(model.viewerPose == moved,"Reset is undoable")
        let encoded = try JSONEncoder().encode(model.auditState!)
        var legacy = try JSONSerialization.jsonObject(with: encoded) as! [String:Any]
        legacy.removeValue(forKey: "viewerPose")
        let old = try JSONDecoder().decode(VenueAuditState.self,from: JSONSerialization.data(withJSONObject: legacy))
        try old.validate(); check(old.viewerPose == nil,"Legacy audit snapshots remain readable")
        model.stepViewer(offset: [0,0,-0.5],yaw: 15)
        check(model.viewerPose != moved && model.viewerPose.isValid,"Simulator/fallback navigation")
        model.undo(); check(model.viewerPose == moved,"Fallback navigation is undoable")
        print("Viewer navigation checks passed: unbounded movement, fixture isolation, atomic Undo/Redo, reset, history resume, legacy audit decoding and fallback controls.")
    }
}
