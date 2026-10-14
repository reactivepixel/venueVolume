import Testing
import Foundation
@testable import VenueVolumeCore

@Test func cueTrackingIsolationAndPersistence() throws {
    let fixtures = [Fixture(name: "Left"), Fixture(name: "Right")]
    let ids = Set(fixtures.map(\.id))
    var sheet = CueSheet()
    sheet.include(fixtures, palettes: PaletteLibrary.baseline)
    var dimmer = PaletteLibrary.baseline.first { $0.pool == .intensity }!
    dimmer.channels[0] = 150
    try sheet.record(dimmer, for: ids, sources: [])
    dimmer.channels[0] = 20
    try sheet.record(dimmer, for: [fixtures[0].id], at: 2, sources: [])
    #expect(sheet.current == 1)
    #expect(sheet.sample(fixtures[0].id, at: 0, order: fixtures.map(\.id))?[0] == 150)
    sheet.select(2)
    #expect(sheet.sample(fixtures[0].id, at: 0, order: fixtures.map(\.id))?[0] == 20)
    #expect(sheet.sample(fixtures[1].id, at: 0, order: fixtures.map(\.id))?[0] == 150)
    var color = PaletteLibrary.baseline.first { $0.pool == .color }!
    color.channels[1] = 42
    try sheet.record(color, for: ids, sources: [])
    #expect(sheet.sample(fixtures[0].id, at: 0, order: fixtures.map(\.id))?[0] == 20)
    #expect(sheet.sample(fixtures[0].id, at: 0, order: fixtures.map(\.id))?[1] == 42)
    sheet.select(0); #expect(sheet.current == 1)
    sheet.select(256); #expect(sheet.current == 255)
    #expect(throws: PresetError.self) { try sheet.record(color, for: ids, at: 256, sources: []) }
    try sheet.validate()
    #expect(try JSONDecoder().decode(CueSheet.self, from: JSONEncoder().encode(sheet)) == sheet)
}

@Test func cuesPinLinkedPhaserSources() throws {
    let fixture = Fixture(name: "Beam")
    var full = PaletteLibrary.baseline.first { $0.pool == .intensity }!
    full.channels[0] = 255
    var wave = full; wave.id = UUID(); wave.name = "Wave"
    wave.phaser = Phaser(steps: [.init(values: [0: 0]), .init(values: [0: 255], paletteID: full.id)], beatsPerMinute: 60, measure: 2, transition: 0)
    var sheet = CueSheet(); sheet.include([fixture], palettes: [])
    try sheet.record(wave, for: [fixture.id], sources: [full])
    let sample = sheet.sample(fixture.id, at: 1.5, order: [fixture.id])
    full.channels[0] = 10
    try sheet.record(wave, for: [fixture.id], at: 2, sources: [full])
    #expect(sheet.sample(fixture.id, at: 1.5, order: [fixture.id]) == sample)
    #expect(sample?[0] == 255)
    sheet.select(2)
    #expect(sheet.sample(fixture.id, at: 1.5, order: [fixture.id])?[0] == 10)
}

@Test func previewClockFreezesAndResumesWithoutJump() {
    var playback = PalettePlayback(now: 10)
    #expect(playback.seconds(at: 12) == 2)
    playback.setPlaying(false, at: 12)
    #expect(playback.seconds(at: 100) == 2)
    playback.setPlaying(true, at: 100)
    #expect(playback.seconds(at: 100) == 2)
    #expect(playback.seconds(at: 101) == 3)
}
