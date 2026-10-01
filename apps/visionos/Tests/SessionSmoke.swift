import Foundation
import VenueVolumeCore

@main
struct SessionSmoke {
    @MainActor static func main() async throws {
        let suite = "venue-volume-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { try? FileManager.default.removeItem(at: directory) }
        let environment = try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: URL(fileURLWithPath: "VenueVolume/Environments/Classroom/environment.json")))
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        model.activate(environment: environment)
        check(model.recent.items.isEmpty, "New session must show the recent guide")
        model.canPlace = true
        model.beginPlacement()
        model.place(at: [2.66, 0, -2], surfaceID: "floor")
        let fixtureID = model.fixtures[0].id
        let presetID = model.presets[0].id
        check(model.applyPreset(presetID, to: fixtureID), "Apply saved preset")
        let pilotPreset = model.presets[0]
        let beforeManualAim = model.fixtures[0]
        model.beginHistoryAction("Aim moving head pilot")
        model.setHeadAim(fixtureID, panDegrees: 35)
        model.setHeadAim(fixtureID, tiltDegrees: -20)
        model.endHistoryAction()
        let manualAim = model.fixtures[0]
        check(manualAim.aimOverride != nil && abs(LightingPreview(channels: manualAim.channels).panDegrees-35) < 1.1,
              "Pilot pan slider stores a per-fixture aim override")
        check(abs(LightingPreview(channels: manualAim.channels).tiltDegrees+20) < 0.5 && model.presets[0] == pilotPreset,
              "Pilot tilt slider moves the head without editing the shared preset")
        model.undo()
        check(model.fixtures[0] == beforeManualAim, "Pilot slider gesture is one undoable aim change")
        model.redo()
        check(model.fixtures[0] == manualAim, "Redo restores the pilot head aim")
        let manualRestored = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        manualRestored.activate(environment: environment)
        check(manualRestored.fixtures[0].aimOverride == manualAim.aimOverride, "Pilot manual aim survives relaunch")
        let isolation = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("pilot-isolation"))
        isolation.activate(environment: environment); isolation.canPlace = true
        check(isolation.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66, y: 0, z: -2), surfaceID: "floor"), "Place first pilot")
        let firstID = isolation.fixtures[0].id
        check(isolation.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 5, y: 0, z: -2), surfaceID: "floor"), "Place second pilot")
        let secondID = isolation.fixtures[1].id
        check(isolation.applyPreset(presetID, to: firstID) && isolation.applyPreset(presetID, to: secondID), "Share one preset across two pilots")
        let secondBeforeAim = isolation.fixture(secondID)!
        isolation.beginHistoryAction("Drag pilot Pan")
        isolation.setHeadAim(firstID, panDegrees: 10)
        isolation.setHeadAim(firstID, panDegrees: 20)
        isolation.setHeadAim(firstID, panDegrees: 35)
        isolation.endHistoryAction()
        let firstAfterAim = isolation.fixture(firstID)!
        check(firstAfterAim.aimOverride != nil && isolation.fixture(secondID) == secondBeforeAim,
              "Continuous aim updates only the selected fixture")
        isolation.undo()
        check(isolation.fixture(firstID)?.aimOverride == nil && isolation.fixture(secondID) == secondBeforeAim,
              "One Undo restores the entire Pan gesture without touching the shared preset")
        isolation.redo()
        check(isolation.fixture(firstID) == firstAfterAim && isolation.fixture(secondID) == secondBeforeAim,
              "Redo restores the Pan gesture and preserves the other fixture")
        model.resetAim(fixtureID)
        check(model.fixtures[0].aimOverride == nil && model.fixtures[0].channels == pilotPreset.channels,
              "Pilot reset restores the preset aim")
        let applied = model.fixtures[0].channels
        model.choosePreset(model.presets[0])
        model.presetDraft.channels[0] = 42
        check(model.fixtures[0].channels == applied, "Drafts must not affect fixtures")
        let revision = model.revision
        check(model.savePreset(), "Save succeeds")
        check(model.fixtures[0].channels[0] == 42 && model.revision == revision + 1, "Saving updates fixtures and sync revision")
        model.presetDraft.channels[0] = 100
        model.presetDraft.name = "Independent copy"
        check(model.savePreset(asNew: true), "Save as succeeds")
        check(model.fixtures[0].presetID == presetID && model.fixtures[0].channels[0] == 42, "Save as must preserve original assignments")
        let restored = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        restored.activate(environment: environment)
        check(restored.presets == model.presets, "Saved presets survive relaunch")
        check(restored.fixtures == model.fixtures, "Fixtures and resolved preset values survive relaunch")
        model.previewDraft = true
        check(model.renderedChannels(for: model.fixtures[0])[0] == 100, "Draft preview drives renderer")
        check(model.fixtures[0].channels[0] == 42, "Preview must not commit values")
        model.previewDraft = false
        check(model.renderedChannels(for: model.fixtures[0])[0] == 42, "Release preview restores saved look")
        model.moveFixture(fixtureID, position: .init(x: 3, y: 0.5, z: -3), yawDegrees: 90)
        check(abs(model.yawDegrees(for: model.fixtures[0])-90) < 0.001, "Base rotation is applied")
        check(model.fixtures[0].position.x == 3 && model.fixtures[0].presetID == presetID, "Position does not detach preset")
        let afterMove = model.fixtures
        model.moveFixture(fixtureID, position: .init(x: -9, y: 0, z: -3), yawDegrees: 0)
        check(model.fixtures == afterMove, "Out-of-room moves are rejected")
        model.activate(environment: environment)
        check(model.fixtures == afterMove, "Re-enter preserves current arrangement")
        model.transformFixture(fixtureID, position: .init(x: 3, y: 0.5, z: -3), yaw: 0, pitch: 12, roll: 8)
        model.moveFixture(fixtureID, position: .init(x: 3, y: 0.5, z: -4), yawDegrees: 0)
        let angles = FixtureAiming.angles(model.fixtures[0].orientation)
        check(abs(angles.pitch-12) < 0.001 && abs(angles.roll-8) < 0.001, "XYZ moves preserve pitch and roll")
        let beforeAim = model.fixtures[0]
        let savedPresets = model.presets
        model.previewDraft = true
        model.beginRetarget(fixtureID, method: .head)
        check(model.isRetargeting && !model.previewDraft, "Retarget uses committed fixture values")
        check(!model.acceptTarget(beforeAim.position), "Unreachable target is rejected")
        check(model.isRetargeting && model.fixtures[0] == beforeAim, "Failed aim preserves object and allows retry")
        let aimPoint = Position3D(x: 2, y: 1.5, z: -7)
        check(model.acceptTarget(aimPoint), "Retarget reachable point")
        check(!model.isPickingRoom && model.lastTarget == aimPoint, "One-shot targeting ends with a marker")
        let aimed = model.fixtures[0]
        check(aimed.aimOverride != nil && aimed.channels[4] != beforeAim.channels[4], "Head aim writes resolved DMX")
        check(aimed.position == beforeAim.position && aimed.orientation == beforeAim.orientation, "Head aim keeps mount transform")
        check(model.presets == savedPresets, "Retarget does not edit shared presets")
        check(model.applyPreset(presetID, to: fixtureID), "Can apply preset after aiming")
        check(model.fixtures[0].aimOverride == aimed.aimOverride && model.fixtures[0].channels[4] == aimed.channels[4], "Preset preserves aim")
        let aimRestored = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        aimRestored.activate(environment: environment)
        check(aimRestored.fixtures == model.fixtures, "Aim override survives relaunch")
        model.beginRetarget(fixtureID, method: .mount)
        check(model.acceptTarget(.init(x: 4, y: 2, z: -2)), "Mount can aim behind the original heading")
        check(model.fixtures[0].orientation != aimed.orientation && model.fixtures[0].channels == aimed.channels, "Mount aim preserves DMX")
        let mount = model.fixtures[0]
        model.beginReposition(fixtureID)
        model.reposition(at: .init(x: -9, y: 0, z: -3), surfaceID: "floor")
        check(model.fixtures[0] == mount && model.isPickingRoom, "Invalid reposition can be retried")
        model.reposition(at: .init(x: 2.66, y: 0, z: -2), surfaceID: "floor")
        check(model.fixtures.count == 1 && model.fixtures[0].id == fixtureID, "Reposition moves existing fixture")
        check(model.fixtures[0].position.y == 0 && !model.isPickingRoom, "Reposition puts base on surface")
        check(model.fixtures[0].orientation == mount.orientation && model.fixtures[0].channels == mount.channels, "Reposition preserves orientation and channels")
        model.beginRetarget(fixtureID, method: .head)
        model.cancelPicking()
        check(!model.isPickingRoom && !model.acceptTarget(aimPoint), "Cancel disarms targeting")
        model.resetAim(fixtureID)
        check(model.fixtures[0].aimOverride == nil && model.fixtures[0].channels == model.presets.first { $0.id == presetID }?.channels, "Reset restores preset values")
        let savedCount = model.presets.count
        model.newPreset()
        model.presetDraft.name = " "
        check(!model.savePreset() && model.presets.count == savedCount, "Invalid preset must not save")
        model.clearAssignment(fixtureID)
        check(model.fixtures[0].presetID == nil && model.fixtures[0].channels.allSatisfy { $0 == 0 }, "Clear assignment zeros channels")
        check(model.applyPreset(presetID, to: fixtureID), "Reassign")
        model.deletePreset(presetID)
        check(model.fixtures[0].presetID == nil && model.fixtures[0].channels.allSatisfy { $0 == 0 }, "Delete clears assigned values")
        check(!model.recent.items.contains(.preset(presetID)), "Delete removes stale recent preset")
        await model.sync()
        check(!model.hasUnsyncedChanges && model.syncStatus.contains("HTTP 200"), "Sync accepts the new snapshot")
        model.beginRetarget(fixtureID, method: .head)
        model.remove(fixtureID)
        check(!model.isPickingRoom, "Deleting target cancels picking")
        check(!model.recent.items.contains(.fixture(fixtureID)), "Delete removes stale recent object")
        check(model.selectedID == nil && model.expandedID == nil, "Delete clears selection")
        print("Session smoke checks passed: drafts, presets, transforms, retarget, reposition, persistence, cancel, delete, recents, mock sync.")
        let roomModel = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("room-tests"))
        roomModel.activate(environment: environment); roomModel.canPlace = true
        let point = Position3D(x: 2.66, y: 0, z: -2)
        check(roomModel.dropFixture([FixtureKind.cube.dragToken], at: point, surfaceID: "floor"), "Drop creates a cube")
        let cubeID = roomModel.fixtures[0].id
        check(roomModel.fixtures[0].assetID == nil && roomModel.fixtures[0].position.y == 0.12, "Cube rests on the floor")
        let roomPreset = roomModel.presets[0]
        check(roomModel.applyPreset(roomPreset.id, to: cubeID), "Assign look before snapshot")
        roomModel.setupName = "Event A"
        check(roomModel.saveSetup() && !roomModel.hasUnsavedSetup, "Save named room instance")
        let eventA = roomModel.savedSetups[0]
        roomModel.choosePreset(roomPreset); roomModel.presetDraft.channels[0] = 19
        check(roomModel.savePreset() && roomModel.hasUnsavedSetup, "Preset edit dirties setup")
        roomModel.setupName = "Event B"
        check(roomModel.saveSetup(asNew: true) && roomModel.savedSetups.count == 2, "Save as leaves Event A intact")
        let room = roomModel.activeRoom!
        roomModel.requestRoom(room); roomModel.activate(environment: environment); roomModel.canPlace = true
        check(roomModel.fixtures.isEmpty && roomModel.activeSetupID == nil && roomModel.savedSetups.count == 2, "Blank setup preserves saved instances")
        roomModel.requestRoom(room, setup: eventA); roomModel.activate(environment: environment); roomModel.canPlace = true
        check(roomModel.fixtures[0].channels == eventA.placements.fixtures[0].channels, "Load restores original resolved DMX")
        check(roomModel.fixtures[0].presetID != roomPreset.id, "Conflicting preset is forked when restoring a snapshot")
        check(roomModel.presets.first { $0.id == roomPreset.id }?.channels[0] == 19, "Other preset definitions survive snapshot restore")
        check(!roomModel.hasUnsavedSetup, "A freshly restored setup is clean")
        let relaunched = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("room-tests"))
        relaunched.activate(environment: environment)
        check(relaunched.savedSetups.count == 2 && relaunched.fixtures == roomModel.fixtures, "Room library and working arrangement survive relaunch")
        let workingFile = directory.appendingPathComponent("room-tests/\(environment.id)-\(environment.version).json")
        let unreadable = Data("unreadable working arrangement".utf8)
        try unreadable.write(to: workingFile)
        relaunched.requestRoom(room, setup: eventA); relaunched.activate(environment: environment)
        let preservedWorkingFile = try Data(contentsOf: workingFile)
        check(preservedWorkingFile == unreadable, "Loading a named setup preserves a damaged working file")
        check(relaunched.saveSetup(asNew: true), "Named setup save remains available when working autosave is blocked")
        print("Room session checks passed: fixture drop, named save/save-as, blank setup, load, preset isolation and relaunch.")
        try await AuditSmoke.run(environment: environment)
    }
}
