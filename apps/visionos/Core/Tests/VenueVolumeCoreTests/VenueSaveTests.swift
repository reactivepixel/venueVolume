import Foundation
import Testing
@testable import VenueVolumeCore

private func portableSave() throws -> VenueSave {
    let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments/Classroom").standardizedFileURL
    let manifest = try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: folder.appendingPathComponent("environment.json")))
    let room = LibraryRoom(manifest: manifest, origin: .bundled)
    let preset = LightingPreview.presets[0]
    let fixture = Fixture(presetID: preset.id, name: "Portable light", channels: preset.channels,
                          position: .init(x: 2.66, y: 0, z: -2), surfaceID: "floor")
    let setup = VenueSetup(name: "Evening event", room: room, fixtures: [fixture], presets: [preset], revision: 9, whiteRoom: false, houseLight: 0.2)
    return VenueSave(room: room, setup: setup, asset: try Data(contentsOf: folder.appendingPathComponent("environment.usdz")))
}

@Test func portableSaveRoundTripsGeometryPresetsAndMaterialSettings() throws {
    let source = try portableSave()
    let decoded = try JSONDecoder().decode(VenueSave.self, from: JSONEncoder().encode(source))
    try decoded.validate(assetChecksum: source.room.manifest.asset.sha256)
    #expect(decoded == source)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    let first = try store.importSave(decoded, assetChecksum: source.room.manifest.asset.sha256)
    let second = try store.importSave(decoded, assetChecksum: source.room.manifest.asset.sha256)
    #expect(first.setup.id != source.setup.id && first.setup.id != second.setup.id)
    #expect(first.setup.presets == source.setup.presets)
    #expect(first.setup.placements.fixtures == source.setup.placements.fixtures)
    #expect(first.setup.whiteRoom == false && first.setup.houseLight == 0.2)
    #expect(try store.setups(rooms: [first.room]).count == 2)
    #expect(try Data(contentsOf: store.roomDirectory(first.room).appendingPathComponent("environment.usdz")) == source.asset)
}

@Test func portableSaveRejectsDamagedAssetsPathsAndUnknownVersionsBeforeWriting() throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    #expect(throws: EnvironmentError.self) { try store.importSave(source, assetChecksum: String(repeating: "0", count: 64)) }
    var bad = source; bad.asset.removeLast()
    #expect(throws: EnvironmentError.self) { try store.importSave(bad, assetChecksum: source.room.manifest.asset.sha256) }
    bad = source; bad.room.manifest.asset.file = "../escape.usdz"
    #expect(throws: EnvironmentError.self) { try store.importSave(bad, assetChecksum: source.room.manifest.asset.sha256) }
    bad = source; bad.schemaVersion = 2
    #expect(throws: EnvironmentError.self) { try store.importSave(bad, assetChecksum: source.room.manifest.asset.sha256) }
    #expect(!FileManager.default.fileExists(atPath: folder.path))
}

@Test func portableSaveRollsBackNewGeometryWhenSetupCannotBeWritten() throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try Data("preserve".utf8).write(to: folder.appendingPathComponent("Setups"))
    let store = RoomLibraryStore(directory: folder)
    #expect(throws: (any Error).self) { try store.importSave(source, assetChecksum: source.room.manifest.asset.sha256) }
    #expect(!FileManager.default.fileExists(atPath: try store.roomDirectory(source.room).path))
    #expect(try Data(contentsOf: folder.appendingPathComponent("Setups")) == Data("preserve".utf8))
}

@Test func bundledVenueChoicesIncludeReviewedFortress() async throws {
    let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments").standardizedFileURL
    let repository = BundledEnvironmentRepository(directory: folder)
    let fortress = try await repository.resolve(id: "the-fortress")
    #expect(fortress.manifest.asset.bytes == 390_565)
    #expect(fortress.manifest.asset.sha256 == "4950fed10bd99647588e538fdcfa50c21db8c57b2550e14900ef01d0d7c7fff5")
    #expect(LibraryRoom(manifest: fortress.manifest, origin: .bundled).displayName == "The Fortress")
}
