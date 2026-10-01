import Foundation
import Testing
@testable import VenueVolumeCore

private func makeRoom(_ id: String = "test-room") -> LibraryRoom {
    .init(manifest: .simple(id: id, title: "Test room", min: [-3,0,-4], max: [3,3,4], spawn: [0,0,0], yaw: 0,
                           file: "environment.mesh.json", checksum: String(repeating: "a", count: 64), bytes: 3, scanned: true), origin: .scanned)
}

@Test func roomLibraryKeepsGeometryAndIndependentSetupsAcrossRelaunch() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder), room = makeRoom()
    try store.install(room: room, asset: Data([1,2,3]))
    let preset = LightingPreview.presets[0]
    var fixture = Fixture(presetID: preset.id, name: "Light", assetID: LightingPreview.assetID, channels: preset.channels,
                          position: .init(x: 0, y: 0, z: -2), orientation: FixtureAiming.euler(yaw: 45, pitch: 10, roll: 20))
    fixture.aimOverride = .init(pan: 160, tilt: 80); fixture.preserveAimOverride()
    let first = VenueSetup(name: "Event A", room: room, fixtures: [fixture], presets: [preset], revision: 4, whiteRoom: true, houseLight: 0.25)
    let blank = VenueSetup(name: "Event B", room: room, fixtures: [], presets: [], revision: 0, whiteRoom: false, houseLight: 1)
    try store.save(first, room: room); try store.save(blank, room: room)
    let reopened = RoomLibraryStore(directory: folder)
    let rooms = try reopened.rooms(), setups = try reopened.setups(rooms: rooms)
    #expect(rooms == [room] && setups.count == 2)
    #expect(setups.first { $0.id == first.id } == first)
    #expect(setups.first { $0.id == blank.id }?.placements.fixtures.isEmpty == true)
    #expect(try Data(contentsOf: reopened.roomDirectory(room).appendingPathComponent(room.manifest.asset.file)) == Data([1,2,3]))
    #expect(throws: EnvironmentError.self) { try store.install(room: room, asset: Data([4,5,6])) }
    #expect(throws: EnvironmentError.self) { try store.save(first, room: makeRoom("other-room")) }
}

@Test func setupRejectsInvalidSnapshotsWithoutOverwritingGoodSave() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = RoomLibraryStore(directory: folder), room = makeRoom()
    let saved = VenueSetup(name: "Good", room: room, fixtures: [], presets: [], revision: 0, whiteRoom: true, houseLight: 0)
    try store.save(saved, room: room)
    var bad = saved; bad.name = " "
    #expect(throws: EnvironmentError.self) { try store.save(bad, room: room) }
    #expect(try store.setups(rooms: [room]) == [saved])
    var unsafe = room; unsafe.manifest.id = "../escape"
    #expect(throws: EnvironmentError.self) { try store.roomDirectory(unsafe) }
    var path = room; path.manifest.asset.file = "../mesh.json"
    #expect(throws: EnvironmentError.self) { try path.manifest.validate() }
    let missing = Fixture(presetID: UUID(), name: "Missing preset")
    let invalid = VenueSetup(name: "Bad", room: room, fixtures: [missing], presets: [], revision: 1, whiteRoom: true, houseLight: 0)
    #expect(throws: EnvironmentError.self) { try store.save(invalid, room: room) }
}

@Test func scannedMeshValidatesAndRejectsUnsupportedEdgesAndHoles() throws {
    let mesh = ScannedMesh(chunks: [.init(vertices: [.init(x: -1,y: 0,z: -1),.init(x: 1,y: 0,z: -1),
                                                        .init(x: 1,y: 0,z: 1),.init(x: -1,y: 0,z: 1)], triangles: [0,2,1,0,3,2])])
    try mesh.validate()
    #expect(mesh.supports(.init(x: 0,y: 0,z: 0), radius: 0.23))
    #expect(!mesh.supports(.init(x: 0.9,y: 0,z: 0), radius: 0.23))
    #expect(!mesh.supports(.init(x: 0,y: 1,z: 0), radius: 0.23))
    var bad = mesh; bad.chunks[0].triangles[0] = 999
    #expect(throws: EnvironmentError.self) { try bad.validate() }
    bad = mesh; bad.chunks[0].vertices[0].x = .nan
    #expect(throws: EnvironmentError.self) { try bad.validate() }
    #expect(try JSONDecoder().decode(ScannedMesh.self, from: JSONEncoder().encode(mesh)) == mesh)
    #expect(FixtureKind(token: FixtureKind.cube.dragToken) == .cube)
    #expect(FixtureKind(token: LightingPreview.presets[0].dragToken) == nil)
}
