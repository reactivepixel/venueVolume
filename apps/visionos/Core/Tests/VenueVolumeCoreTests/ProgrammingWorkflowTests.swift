import XCTest
@testable import VenueVolumeCore

final class ProgrammingWorkflowTests: XCTestCase {
    func testTransitionReachesTargetBeforeHoldAndPerStepOverride() {
        let p = Phaser(steps: [.init(values: [0: 255], transition: 0.5), .init(values: [0: 0], transition: 0)], beatsPerMinute: 60, measure: 2)
        XCTAssertEqual(p.sample(base: [42], seconds: 0), [0])
        XCTAssertEqual(p.sample(base: [42], seconds: 0.25), [128])
        XCTAssertEqual(p.sample(base: [42], seconds: 0.5), [255])
        XCTAssertEqual(p.sample(base: [42], seconds: 0.9), [255])
        XCTAssertEqual(p.sample(base: [42], seconds: 1), [0])
        var invalid = p; invalid.steps[1].transition = .nan
        XCTAssertNotNil(invalid.validationIssue)
    }
    func testTapTempoAndResizeKeepCycleAndReferencesIndependent() {
        var tap = TapTempo()
        XCTAssertNil(tap.tap(at: 10)); XCTAssertEqual(tap.tap(at: 10.5), 120)
        XCTAssertEqual(tap.tap(at: 11), 120); XCTAssertNil(tap.tap(at: 15))
        XCTAssertNil(tap.tap(at: .nan))
        let source = UUID()
        var p = Phaser(steps: [.init(values: [:], paletteID: source), .init(values: [0: 255])], beatsPerMinute: 120, measure: 8)
        p.resizeSteps(to: 8)
        XCTAssertEqual(p.steps[0].paletteID, source); XCTAssertEqual(p.steps.count, 8)
        XCTAssertEqual(p.measure, 8); XCTAssertEqual(p.beatsPerMinute, 120)
        p.resizeSteps(to: 1); XCTAssertEqual(p.steps.count, 2)
    }
    func testMacroScopesReferencesAndRepeatability() throws {
        let a = Fixture(name: "A"), b = Fixture(name: "B", startAddress: 17)
        let palette = PaletteLibrary.baseline.first { $0.name == "Color · Red" }!
        let macro = ProgrammingMacro(name: "Red", lines: [.init(paletteID: palette.id), .init(paletteID: UUID(), enabled: false)])
        let plan = try macro.plan(selection: [a.id], groups: [:], fixtures: [a,b], palettes: [palette])
        XCTAssertEqual(plan.targetIDs, [a.id]); XCTAssertEqual(plan.fixtures[1], b)
        XCTAssertEqual(plan.fixtures[0].channels[0], a.channels[0])
        let again = try macro.plan(selection: [a.id], groups: [:], fixtures: plan.fixtures, palettes: [palette])
        XCTAssertEqual(again.fixtures, plan.fixtures)
        XCTAssertThrowsError(try macro.plan(selection: [], groups: [:], fixtures: [a,b], palettes: [palette]))
        var broken = macro; broken.lines[1].enabled = true
        XCTAssertThrowsError(try broken.plan(selection: [a.id], groups: [:], fixtures: [a,b], palettes: [palette]))
        let group = UUID(); var grouped = macro; grouped.target = .group(group)
        let resolved = try grouped.plan(selection: [a.id], groups: [group: [b.id]], fixtures: [a,b], palettes: [palette])
        XCTAssertEqual(resolved.targetIDs, [b.id]); XCTAssertEqual(resolved.fixtures[0], a)
        XCTAssertThrowsError(try grouped.plan(selection: [a.id], groups: [:], fixtures: [a,b], palettes: [palette]))
        XCTAssertEqual(try JSONDecoder().decode(ProgrammingMacro.self, from: JSONEncoder().encode(macro)), macro)
    }
}
