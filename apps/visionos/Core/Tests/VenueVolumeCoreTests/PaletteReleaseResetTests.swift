import Foundation
import Testing
@testable import VenueVolumeCore

@Test func paletteReleasePurgesOldStateOnceAndKeepsRooms() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let library = root.appendingPathComponent("Library")
    let rooms = library.appendingPathComponent("Rooms")
    let setups = library.appendingPathComponent("Setups")
    let suite = "palette-release-" + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
    for directory in [rooms, setups] { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
    let old = [root.appendingPathComponent("room-version.json"), setups.appendingPathComponent("save.json")] +
        ["audit-history.json", "touring-shows.json", "touring-history.json"].map { library.appendingPathComponent($0) }
    for file in old { try Data("incompatible".utf8).write(to: file) }
    let asset = rooms.appendingPathComponent("scan.usdz")
    try Data("geometry".utf8).write(to: asset)
    defaults.set(Data("old presets".utf8), forKey: "venue.presets.v1")
    try PaletteReleaseReset.run(placements: root, library: library, defaults: defaults)
    #expect(old.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })
    #expect(try String(contentsOf: asset, encoding: .utf8) == "geometry")
    #expect(try JSONDecoder().decode([DMXPreset].self, from: defaults.data(forKey: "venue.presets.v1")!) == PaletteLibrary.baseline)
    let newSave = root.appendingPathComponent("new-palette-save.json")
    try Data("new".utf8).write(to: newSave)
    let custom = [DMXPreset(name: "User palette")]
    defaults.set(try JSONEncoder().encode(custom), forKey: "venue.presets.v1")
    try PaletteReleaseReset.run(placements: root, library: library, defaults: defaults)
    #expect(FileManager.default.fileExists(atPath: newSave.path))
    #expect(try JSONDecoder().decode([DMXPreset].self, from: defaults.data(forKey: "venue.presets.v1")!) == custom)
}
