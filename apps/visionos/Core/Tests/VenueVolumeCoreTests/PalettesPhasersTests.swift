import XCTest
@testable import VenueVolumeCore

final class PalettesPhasersTests: XCTestCase {
    func testStandardLibraryReplacesLegacyLooksAndIncludesEveryCategory() {
        XCTAssertEqual(PaletteLibrary.baseline.count, 15)
        XCTAssertEqual(Set(PaletteLibrary.baseline.map(\.id)).count, 15)
        XCTAssertEqual(Set(PaletteLibrary.baseline.compactMap(\.category)), Set(PaletteCategory.allCases))
        XCTAssertEqual(LightingPreview.presets, Array(PaletteLibrary.baseline.prefix(3)))
        XCTAssertTrue(PaletteLibrary.baseline.allSatisfy { !$0.id.uuidString.hasPrefix("20000000") })
        XCTAssertEqual(PaletteLibrary.baseline.filter { $0.phaser != nil }.count, 4)
    }

    func testTouringMaskAndPaletteAttributesCompose() throws {
        let palette = DMXPreset(name: "Scoped color", channels: [255,200,100,50],
            attributeIndices: [1,2,3], includedChannels: [1,2])
        XCTAssertEqual(palette.channelMask, [1,2])
        XCTAssertEqual(PresetOperations.mergedChannels(palette, existing: [42,0,0,99]), [42,200,100,99])
        XCTAssertEqual(try JSONDecoder().decode(DMXPreset.self, from: JSONEncoder().encode(palette)), palette)
    }
    func testLegacyDecodeAndNewRoundTrip() throws {
        let id = UUID()
        let data = Data("{\"id\":\"\(id.uuidString)\",\"name\":\"Legacy\",\"channels\":[255,0]}".utf8)
        let legacy = try JSONDecoder().decode(DMXPreset.self, from: data)
        XCTAssertNil(legacy.phaser)
        XCTAssertEqual(legacy.channels, [255, 0])
        for palette in PaletteLibrary.baseline {
            XCTAssertNil(palette.validationIssue)
            XCTAssertEqual(try JSONDecoder().decode(DMXPreset.self, from: JSONEncoder().encode(palette)), palette)
        }
    }
    func testWeightedStepsPhaseAndMeasure() {
        let phaser = Phaser(steps: [.init(values: [0: 255]), .init(values: [0: 0])], phaseSpreadDegrees: 360, transition: 0)
        XCTAssertEqual(phaser.sample(base: [42], seconds: 0), [255])
        XCTAssertEqual(phaser.sample(base: [42], seconds: 0.5), [0])
        XCTAssertEqual(phaser.sample(base: [42], seconds: 1), [255])
        XCTAssertEqual(phaser.sample(base: [42], seconds: 0, fixtureIndex: 1, fixtureCount: 2), [0])
        var smooth = phaser; smooth.transition = 1; smooth.measure = 2
        XCTAssertEqual(smooth.sample(base: [42], seconds: 0.5), [128])
        smooth.steps[0].width = 3
        XCTAssertEqual(smooth.sample(base: [42], seconds: 1), [170])
    }
    func testAttributePalettePreservesOtherChannelsAndDuplicatesIndependently() {
        var original = PaletteLibrary.baseline.first { $0.category == .color }!
        var copy = original.duplicated()
        XCTAssertNotEqual(copy.id, original.id)
        copy.channels[1] = 0
        XCTAssertEqual(original.channels[1], 255)
        let merged = PresetOperations.mergedChannels(original, existing: [17, 0, 0, 0, 80])
        XCTAssertEqual(merged[0], 17)
        XCTAssertEqual(merged[4], 80)
        XCTAssertEqual(Array(merged[1...3]), [255, 255, 255])
        original.phaser = Phaser(steps: [.init(values: [0: 0]), .init(values: [0: 255])], beatsPerMinute: .nan)
        XCTAssertNotNil(original.validationIssue)
        XCTAssertEqual(original.sampledChannels(at: .nan), original.channels)
    }
}

extension PalettesPhasersTests {
    func testLayeredAssignmentsKeepPhaserAndClearOnlyOwnedAttributes() throws {
        let intensity = PaletteLibrary.baseline.first { $0.name == "Phaser · Dimmer chase" }!
        let red = PaletteLibrary.baseline.first { $0.name == "Color · Red" }!
        let position = PaletteLibrary.baseline.first { $0.name == "Position · Center" }!
        var fixture = Fixture(name: "Layered", universe: 1, startAddress: 1)
        var fixtures = try PresetOperations.applying(intensity, to: fixture.id, fixtures: [fixture])
        fixtures = try PresetOperations.applying(red, to: fixture.id, fixtures: fixtures)
        fixtures = try PresetOperations.applying(position, to: fixture.id, fixtures: fixtures)
        fixture = fixtures[0]
        XCTAssertEqual(fixture.referencedPaletteIDs, Set([intensity.id, red.id, position.id]))
        let channels = PresetOperations.renderedChannels(for: fixture, palettes: [intensity, red, position], at: 0.5)
        XCTAssertEqual(channels[0], 0)
        XCTAssertEqual(Array(channels[1...3]), [255, 0, 0])
        var revised = red; revised.channels[1] = 64
        fixtures = try PresetOperations.saving(revised, fixtures: fixtures)
        XCTAssertEqual(fixtures[0].channels[1], 64)
        fixtures = PresetOperations.clearing(red.id, fixtures: fixtures)
        XCTAssertEqual(fixtures[0].referencedPaletteIDs, Set([intensity.id, position.id]))
        XCTAssertEqual(fixtures[0].channels[4], 128)
        XCTAssertEqual(fixtures[0].channels[1], 0)
    }
}

extension PalettesPhasersTests {
    func testFullPaletteReplacementRemovesOldChannelOwners() throws {
        let fixture = Fixture(name: "Replace all")
        let chase = PaletteLibrary.baseline.first { $0.name == "Phaser · Dimmer chase" }!
        let layered = try PresetOperations.applying(chase, to: fixture.id, fixtures: [fixture])
        let replacement = DMXPreset(name: "Short legacy look", channels: [64, 128])
        let replaced = try PresetOperations.applying(replacement, to: fixture.id, fixtures: layered)[0]
        XCTAssertEqual(replaced.channels, [64, 128])
        XCTAssertEqual(replaced.referencedPaletteIDs, [replacement.id])
        XCTAssertEqual(Set(replaced.channelPaletteIDs!.keys), [0, 1])
    }
}

extension PalettesPhasersTests {
    func testLinkedStepSourcesUpdateAndRemainPortable() throws {
        var red = PaletteLibrary.baseline.first { $0.name == "Color · Red" }!
        let blue = PaletteLibrary.baseline.first { $0.name == "Color · Blue" }!
        var chase = red.duplicated(name: "Linked colors")
        chase.phaser = Phaser(steps: [.init(values: [:], paletteID: red.id), .init(values: [:], paletteID: blue.id)], transition: 0)
        XCTAssertNil(chase.referenceIssue(in: [red, blue]))
        XCTAssertEqual(chase.sampledChannels(at: 0, palettes: [red, blue])[1], 255)
        red.channels[1] = 40
        XCTAssertEqual(chase.sampledChannels(at: 0, palettes: [red, blue])[1], 40)
        XCTAssertEqual(chase.sampledChannels(at: 0.5, palettes: [red, blue])[3], 255)
    }
    func testSourceValidationAndDependencyClosure() throws {
        let red = PaletteLibrary.baseline.first { $0.name == "Color · Red" }!
        var chase = red.duplicated(name: "Linked colors")
        chase.phaser = Phaser(steps: [.init(values: [:], paletteID: red.id), .init(values: [1:0,2:0,3:255])])
        let fixture = Fixture(name: "Source dependencies")
        let assigned = try PresetOperations.applying(chase, to: fixture.id, fixtures: [fixture])
        let required = PaletteLibrary.dependencies(for: assigned, in: [red, chase] + PaletteLibrary.baseline.filter { $0.id != red.id })
        XCTAssertEqual(Set(required.map(\.id)), Set([red.id, chase.id]))
        XCTAssertNotNil(chase.referenceIssue(in: []))
        var source = red; source.phaser = Phaser(steps: [.init(values: [1:0]), .init(values: [1:255])])
        XCTAssertNotNil(chase.referenceIssue(in: [source]))
        var color = red; color.setPool(.intensity)
        XCTAssertNotNil(chase.referenceIssue(in: [color]))
        XCTAssertThrowsError(try PresetOperations.saving(color, fixtures: try PresetOperations.applying(red, to: fixture.id, fixtures: [fixture])))
        XCTAssertEqual(try JSONDecoder().decode(DMXPreset.self, from: JSONEncoder().encode(chase)), chase)
    }
}
