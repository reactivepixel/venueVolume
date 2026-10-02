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
        model.activate(environment: environment); model.canPlace = true
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66,y: 0,z: -2), surfaceID: "floor"), "First pilot")
        let first = model.fixtures[0].id
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 5,y: 0,z: -2), surfaceID: "floor"), "Second pilot")
        let second = model.fixtures[1].id, preset = model.presets[1]
        check(model.applyPreset(preset.id, to: first) && model.applyPreset(preset.id, to: second), "Shared preset")
        model.beginRetarget(first, method: .head)
        let before = model.auditState!, revision = model.revision, nodeCount = model.history!.nodes.count
        let original = model.fixture(first)!, other = model.fixture(second)!
        for x: Float in [2.5,2.2,2] {
            check(model.acceptTarget(.init(x: x,y: 1.5,z: -7)), "Held target preview follows updated points")
        }
        check(model.canSaveTarget && model.renderedFixture(original).aimOverride != nil, "Renderer previews target")
        check(model.auditState == before && model.revision == revision && model.history!.nodes.count == nodeCount,
              "Held preview does not change committed state, revision or journal")
        let relaunched = VenueModel(arguments: [], defaults: defaults, placementDirectory: folder)
        relaunched.activate(environment: environment)
        check(relaunched.fixtures == model.fixtures && relaunched.targetPreview == nil, "Unsaved target never persists")
        model.cancelPicking()
        check(model.fixture(first) == original && model.renderedFixture(original) == original && !model.canSaveTarget, "Cancel restores head preview")
        model.beginRetarget(first, method: .head)
        check(model.acceptTarget(.init(x: 2,y: 1.5,z: -7)) && model.saveTarget(), "Save target")
        let aimed = model.fixture(first)!
        check(model.history!.nodes.count == nodeCount+1 && model.fixture(second) == other && model.presets.contains(preset),
              "Save creates one step and isolates shared preset")
        model.undo(); check(model.fixture(first) == original, "Undo saved target")
        model.redo(); check(model.fixture(first) == aimed, "Redo saved target")
        model.beginRetarget(first, method: .head)
        check(model.acceptTarget(.init(x: 2.2,y: 1.5,z: -7)), "Preview before concurrent preset edit")
        model.choosePreset(preset)
        model.presetDraft.channels[0] = 177
        check(model.savePreset() && model.saveTarget(), "Save preset while target dialogue remains open")
        check(model.fixture(first)!.channels[0] == 177 && model.fixture(second)!.channels[0] == 177,
              "Target save preserves fresh preset channels instead of overwriting them from preview")
        let freshAim = model.fixture(first)!
        model.beginRetarget(first, method: .mount)
        check(model.acceptTarget(.init(x: 4,y: 2,z: -1)), "Mount preview")
        check(model.renderedFixture(freshAim).orientation != freshAim.orientation && model.fixture(first) == freshAim, "Mount preview is transient")
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

        model.beginTransform(first)
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
    }
}
