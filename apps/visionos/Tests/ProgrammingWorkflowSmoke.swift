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
