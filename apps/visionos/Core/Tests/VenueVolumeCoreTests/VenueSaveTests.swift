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

@Test @MainActor func portableSaveWorkerDoesHeavyWorkAwayFromMainActor() async throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appendingPathComponent("test.venuevolume")
    try JSONEncoder().encode(source).write(to: file)
    let worker = VenueSaveWorker()
    let read = try await worker.read(file) { _ in
        #expect(!Thread.isMainThread, "Reading, hashing and validation must not block the UI actor")
        return source.room.manifest.asset.sha256
    }
    #expect(read.save == source)
    let resources = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments").standardizedFileURL
    let encoded = try await worker.encode(room: source.room, setup: source.setup,
                                         repository: BundledEnvironmentRepository(directory: resources)) { _ in
        #expect(!Thread.isMainThread, "Export hashing and encoding must not block the UI actor")
        return source.room.manifest.asset.sha256
    }
    #expect(try JSONDecoder().decode(VenueSave.self, from: encoded) == source)
    await #expect(throws: EnvironmentError.self) {
        try await worker.read(file) { _ in "wrong checksum" }
    }
}

@Test func portableImportPreparationDoesNotPublishUntilCommit() async throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    let worker = VenueSaveWorker()
    let first = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    #expect(try store.rooms().isEmpty)
    #expect(try store.setups(rooms: []).isEmpty)
    first.discard()
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    let prepared = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    try prepared.commit()
    #expect(try store.setups(rooms: [prepared.room]).map(\.id) == [prepared.setup.id])
    let repeated = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    try repeated.commit()
    #expect(try store.setups(rooms: [prepared.room]).count == 2)
}

@Test func portableImportRejectsExistingGeometryChangedAfterPreparation() async throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    let worker = VenueSaveWorker()
    let initial = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    try initial.commit()
    let prepared = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    let asset = try store.roomDirectory(initial.room).appendingPathComponent(initial.room.manifest.asset.file)
    try Data(repeating: 0, count: source.asset.count).write(to: asset, options: .atomic)
    #expect(throws: EnvironmentError.self) { try prepared.commit() }
    #expect(try store.setups(rooms: [initial.room]).count == 1)
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).allSatisfy { !$0.hasPrefix(".save-") })
}

@Test func portableSaveCancellationDoesNotPublishStagedFiles() async throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    let worker = VenueSaveWorker()
    let cancelledRead = Task {
        withUnsafeCurrentTask { $0?.cancel() }
        return try await worker.read(folder.appendingPathComponent("missing")) { _ in "unused" }
    }
    await #expect(throws: CancellationError.self) { try await cancelledRead.value }
    let encodedFile = folder.appendingPathExtension("venuevolume")
    defer { try? FileManager.default.removeItem(at: encodedFile) }
    try JSONEncoder().encode(source).write(to: encodedFile)
    let cancelledDuringWork = Task {
        try await worker.read(encodedFile) { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return source.room.manifest.asset.sha256
        }
    }
    await #expect(throws: CancellationError.self) { try await cancelledDuringWork.value }
    let prepared = try await worker.prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    let cancelledCommit = Task {
        withUnsafeCurrentTask { $0?.cancel() }
        try prepared.commit()
    }
    await #expect(throws: CancellationError.self) { try await cancelledCommit.value }
    #expect(try store.rooms().isEmpty)
    #expect(try store.setups(rooms: []).isEmpty)
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
}

@Test func stagedPortableImportPreservesLibraryWhenPublicationFails() async throws {
    let source = try portableSave()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder)
    let prepared = try await VenueSaveWorker().prepareImport(source, assetChecksum: source.room.manifest.asset.sha256, store: store)
    try Data("preserve".utf8).write(to: folder.appendingPathComponent("Setups"))
    #expect(throws: (any Error).self) { try prepared.commit() }
    #expect(try store.rooms().isEmpty)
    #expect(try Data(contentsOf: folder.appendingPathComponent("Setups")) == Data("preserve".utf8))
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).allSatisfy { !$0.hasPrefix(".save-") })
}
