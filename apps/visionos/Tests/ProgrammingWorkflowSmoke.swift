import Foundation
import VenueVolumeCore

@MainActor enum ProgrammingWorkflowSmoke {
    static func run(environment: EnvironmentManifest) throws {
        func check(_ value: @autoclosure () -> Bool, _ text: String) { precondition(value(), text) }
        let suite = "programming-workflow-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        model.activate(environment: environment); model.canPlace = true; model.isImmersed = true
        if ProcessInfo.processInfo.arguments.contains("--interaction-regression") {
            var failures: [String] = []
            func expect(_ condition: Bool, _ text: String) { if !condition { failures.append(text) } }
            // Drive the same palm attention samples used by VenueScene, including dwell.
            model.updateHandToolboxActivation(attended: true, palmVisible: true, now: 0)
            model.updateHandToolboxActivation(attended: true, palmVisible: true, now: 1)
            expect(!model.palmMapVisible && model.toolboxRequestID != nil,
                   "Left-hand attention must recall the selection Toolbox, never Palm Map")
            model.reserveLeftHandInput()
            expect(!model.navigationInputReserved, "A UI pinch must not disable its own palette controls")
            _ = model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66, y: 0, z: -2), surfaceID: "floor")
            model.choosePreset(model.presets[0])
            _ = model.applyPaletteToSelection(model.presets[0].id)
            model.presetWindowVisible = true
            model.presetDraft.channels[0] = 42
            expect(model.renderedChannels(for: model.fixtures[0])[0] == 42, "Editing after Apply must preview on the actual selected fixture")
            for failure in failures { FileHandle.standardError.write(Data(("REGRESSION_FAIL: " + failure + "\n").utf8)) }
            check(failures.isEmpty, "Interaction regressions")
            print("Interaction regression checks passed.")
            return
        }
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66, y: 0, z: -2), surfaceID: "floor"), "Place first macro target")
        check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 5, y: 0, z: -2), surfaceID: "floor"), "Place second macro target")
        model.select(model.fixtures[0].id, extendSelection: false)
        let before = model.fixtures
        let macro = ProgrammingMacro.starters[0]
        check(model.canRunMacro(macro), "Macro validates saved references")
        check(model.runMacro(macro), "Macro runs")
        let after = model.fixtures
        check(after[0] != before[0] && after[1] == before[1], "Macro only touches its snapshotted target")
        model.undo(); check(model.fixtures == before, "One undo restores all macro rows")
        model.redo(); check(model.fixtures == after, "Redo restores full macro result")
        check(model.runMacro(macro) && model.fixtures == after, "Repeating a macro is idempotent")
        var broken = macro; broken.lines.append(.init(paletteID: UUID()))
        check(!model.runMacro(broken) && model.fixtures == after, "Broken later action prevents partial application")
        var saved = macro; saved.name = "Stored warm wash"
        check(model.storeMacro(saved), "Store custom macro")
        let restored = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        check(restored.programmingMacros.contains(saved), "Macro references survive relaunch")
        model.deselect()
        check(!model.runMacro(macro) && model.fixtures == after, "Empty selection never falls back to all fixtures")
        check(model.contextBarVisible && !model.contextBarHasSelection, "Deselection keeps only compact context menu")
        model.toolboxTab = 1; model.requestToolbox()
        check(model.toolboxTab == 0, "Wrist recall opens fixture toolbox instead of room panel")
        let touring = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("tour"))
        touring.createTouringShow(name: "Macro tour")
        touring.addInventory(.movingHead, quantity: 2)
        let units = touring.tourUnits.map(\.id)
        touring.activate(environment: environment); touring.canPlace = true
        touring.beginInventoryPlacement(units[0], repeatAll: true)
        for x: Float in [2, 4] { touring.place(at: [x,0,-2], surfaceID: "floor") }
        touring.select(units[0], extendSelection: false)
        let tourBefore = touring.fixtures
        check(touring.runMacro(macro), "Tour macro validates all recalls before one commit")
        let tourAfter = touring.fixtures
        check(tourAfter[1] == tourBefore[1], "Tour macro preserves non-target units")
        touring.undo(); check(touring.fixtures == tourBefore, "Tour macro is one undoable transaction")
        check(!touring.runMacro(broken) && touring.fixtures == tourBefore, "Tour macro failure is atomic")
        print("Programming workflow checks passed: scoped macros, preflight, one Undo, repeatability, persistence, collapsed context and wrist routing.")
    }
}

@MainActor enum CueProgrammingSmoke {
    static func run(environment: EnvironmentManifest) throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
        let suite = "cue-programming-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let model = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        model.activate(environment: environment); model.canPlace = true; model.isImmersed = true
        for x: Float in [2, 4] { check(model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: x, y: 0, z: -2), surfaceID: "floor"), "Place cue fixtures") }
        let first = model.fixtures[0], second = model.fixtures[1]
        model.select(first.id, extendSelection: false)
        model.presetWindowVisible = true
        let source = model.presets.first { $0.pool == .intensity && $0.phaser == nil }!
        let poolBefore = model.presets
        model.choosePreset(source); model.presetDraft.channels[0] = 90
        check(model.renderedChannels(for: first)[0] == 90, "First edit previews on selected fixture")
        let secondBefore = model.renderedChannels(for: second)
        check(model.saveCue(), "Save current cue")
        check(model.currentCue == 1 && model.renderedChannels(for: first)[0] == 90 && model.presets == poolBefore, "Cue save preserves reusable library")
        model.selectCue(2)
        check(model.renderedChannels(for: first)[0] == 90, "Unchanged values track to next cue")
        model.presetDraft.channels[0] = 20
        check(model.saveCue(number: 3), "Save explicit cue")
        check(model.currentCue == 2 && model.renderedChannels(for: first)[0] == 90, "Explicit save does not change current output")
        model.selectCue(3)
        check(model.renderedChannels(for: first)[0] == 20 && model.renderedChannels(for: second) == secondBefore, "Cue recall changes only programmed fixtures")
        model.undo(); check(model.currentCue == 2 && model.renderedChannels(for: first)[0] == 90, "Cue navigation undoes with output")
        model.redo(); check(model.currentCue == 3 && model.renderedChannels(for: first)[0] == 20, "Cue navigation redoes with output")
        model.selectCue(1); model.presetDraft.channels[0] = 160
        model.select(second.id, extendSelection: false)
        check(model.renderedChannels(for: first)[0] == 160, "Selection change records edits on original cue and selection")
        check(!model.previewDraft && model.renderedChannels(for: second) == secondBefore, "Selection change never projects previous fixture draft")
        model.select(first.id, extendSelection: false)
        check(model.presetDraft.channels[0] == 160, "Editor follows recorded selection")
        for _ in 0..<10 {
            model.setPhaserMode(true); check(model.presetDraft.phaser != nil, "Dynamic switch works repeatedly")
            model.setPhaserMode(false); check(model.presetDraft.phaser == nil, "Static switch works repeatedly")
        }
        model.presetDraft.phaser = DimmerPattern.wave.make()
        check(model.saveCue(), "Record dynamic cue")
        model.setPalettePlaying(false)
        let paused = model.renderedChannels(for: first)
        Thread.sleep(forTimeInterval: 0.06)
        check(model.renderedChannels(for: first) == paused, "Actual fixture output freezes with diagram playback")
        model.setPalettePlaying(true)
        model.flushHistoryEdits()
        let restored = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory)
        restored.activate(environment: environment)
        check(restored.cueSheet == model.cueSheet && restored.currentCue == 1, "Cue values and current number persist through relaunch")
        model.selectCue(255); model.stepCue(1); check(model.currentCue == 255, "Next cue clamps at 255")
        model.selectCue(1); model.stepCue(-1); check(model.currentCue == 1, "Previous cue clamps at 01")
        let beforeBadSave = model.cueSheet
        check(!model.saveCue(number: 256) && model.cueSheet == beforeBadSave, "Invalid cue save is atomic")
        model.setupName = "Cue show"
        let savedCues = model.cueSheet
        check(model.saveSetup(asNew: true), "Save portable setup with cues")
        let setup = model.savedSetups.first { $0.name == "Cue show" }!
        check(setup.cues == savedCues && !model.hasUnsavedSetup, "Named setup pins cue programming")
        model.selectCue(12)
        check(model.hasUnsavedSetup, "Changing cue dirties the named setup")
        model.requestRoom(model.activeRoom!, setup: setup); model.activate(environment: environment); model.canPlace = true
        check(model.cueSheet == savedCues, "Reopening setup restores its cue sheet")
        model.select(first.id, extendSelection: false)
        model.newPreset(pool: .intensity); model.presetDraft.name = "Linked cue only"
        model.presetDraft.phaser = Phaser(steps: [.init(values: [0: 0]), .init(values: [0: 255], paletteID: source.id)], beatsPerMinute: 120, measure: 4)
        check(model.saveCue(), "Cue-only linked phaser records")
        let protectedCues = model.cueSheet, protectedLibrary = model.presets
        model.choosePreset(source); model.setPhaserMode(true)
        check(!model.savePreset() && model.cueSheet == protectedCues && model.presets == protectedLibrary, "Library edit cannot invalidate a cue-only step reference")
        model.choosePreset(source)
        model.deselect()
        check(model.selectedFixtureIDs.isEmpty && !model.previewDraft && !model.saveCue(), "Background selection clears programmer target")
        let touring = VenueModel(arguments: [], defaults: defaults, placementDirectory: directory.appendingPathComponent("tour-cues"))
        touring.createTouringShow(name: "Cue touring show"); touring.addInventory(.movingHead, quantity: 1)
        touring.activate(environment: environment); touring.canPlace = true
        touring.beginInventoryPlacement(touring.tourUnits[0].id)
        touring.place(at: [2,0,-2], surfaceID: "floor")
        let tourFixture = touring.fixtures[0]
        touring.select(tourFixture.id, extendSelection: false); touring.presetWindowVisible = true
        touring.choosePreset(touring.presets.first { $0.pool == .intensity && $0.phaser == nil }!)
        touring.presetDraft.channels[0] = 51
        check(touring.saveCue(), "Record touring cue")
        touring.selectCue(2); touring.presetDraft.channels[0] = 201
        check(touring.saveCue() && touring.renderedChannels(for: tourFixture)[0] == 201, "Touring cue drives fixture")
        touring.selectCue(1)
        check(touring.renderedChannels(for: tourFixture)[0] == 51, "Touring cue recall isolates later edits")
        print("Cue programming checks passed: selection preview, scoped saves, tracking, explicit destination, Undo/Redo, repeated mode changes, shared pause, persistence, portable setups, touring, bounds and deselection.")
    }
}
