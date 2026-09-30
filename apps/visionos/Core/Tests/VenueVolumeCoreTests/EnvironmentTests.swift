import Foundation
import Testing
@testable import VenueVolumeCore

private func classroom() throws -> EnvironmentManifest {
    // Test the actual shipped manifest, so exporter/schema drift fails the Swift suite.
    let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments/Classroom/environment.json").standardizedFileURL
    return try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: source))
}

@Test func exportedClassroomContractAndDeskPlacement() throws {
    let room = try classroom()
    try room.validate()
    #expect(room.colliders.count == 96)
    #expect(room.surfaces.count == 11)
    let desk = try #require(room.surfaces.first { $0.id == "instructor-desk-top" })
    let point = Position3D(x: desk.center[0], y: desk.center[1], z: desk.center[2])
    let fixture = try #require(desk.fixturePosition(hit: point))
    #expect(abs(fixture.y-0.86) < 0.001)
    #expect(desk.fixturePosition(hit: .init(x: point.x, y: point.y-0.04, z: point.z)) == nil)
    #expect(desk.fixturePosition(hit: .init(x: point.x+desk.size[0]/2-0.01, y: point.y, z: point.z)) == nil)
}

@Test func incompatibleAndMalformedManifestsFailBeforeLoading() throws {
    let original = try classroom()
    for change in 0..<8 {
        var room = original
        switch change {
        case 0: room.schemaVersion = 99
        case 1: room.asset.file = "../outside.usdz"
        case 2: room.upAxis = "Z"
        case 3: room.spawn.position = [0, .nan, 0]
        case 4: room.colliders[0].rotation = [0,0,0,0]
        case 5: room.surfaces[0].role = "ceiling"
        case 6: room.surfaces[0].id = "missing-proxy"
        default: room.surfaces[0].center[1] += 1
        }
        #expect(throws: EnvironmentError.self) { try room.validate() }
    }
}

@Test func placementsSurviveNewStoreAndAreIsolatedByRoomVersion() throws {
    var room = try classroom()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let fixture = Fixture(name: "Desk test", channels: [0,127,255], position: .init(x: 5.65,y: 0.86,z: -6.55),
                          orientation: .init(y: 0.70710677,w: 0.70710677), surfaceID: "instructor-desk-top")
    let snapshot = RoomPlacements(environment: room, fixtures: [fixture], revision: 5)
    try PlacementStore(directory: directory).save(snapshot, environment: room)
    let restored = try PlacementStore(directory: directory).load(environment: room)
    #expect(restored == snapshot)
    let payload = SyncPayload(fixtures: restored!.fixtures, revision: 5, environment: room)
    #expect(payload.environmentID == room.id)
    #expect(payload.environmentVersion == room.version)
    #expect(payload.coordinateSpace == "environment-local-meters-y-up")
    room.version = String(repeating: "a", count: 64)
    #expect(try PlacementStore(directory: directory).load(environment: room) == nil)
}

@Test func corruptPlacementsRemainUntouched() throws {
    let room = try classroom()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let file = directory.appendingPathComponent(room.id+"-"+room.version+".json")
    let original = Data("unfinished external edit".utf8)
    try original.write(to: file)
    #expect(throws: (any Error).self) { try PlacementStore(directory: directory).load(environment: room) }
    #expect(try Data(contentsOf: file) == original)
}

@Test func localRepositoryResolvesAndRejectsWrongIDAndTruncation() async throws {
    let room = try classroom()
    let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments/Classroom").standardizedFileURL
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.copyItem(at: source, to: directory)
    let repository = DirectoryEnvironmentRepository(directory: directory)
    let resolved = try await repository.resolve(id: room.id)
    #expect(resolved.manifest == room)
    await #expect(throws: EnvironmentError.self) { try await repository.resolve(id: "another-room") }
    try Data([0,1,2]).write(to: resolved.assetURL)
    await #expect(throws: EnvironmentError.self) { try await repository.resolve(id: room.id) }
}
