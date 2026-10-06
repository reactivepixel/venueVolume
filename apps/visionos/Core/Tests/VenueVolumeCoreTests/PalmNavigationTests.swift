import Foundation
import Testing
@testable import VenueVolumeCore

@Test func palmMapRoundTripPreservesMetricScale() {
    let map = PalmMapProjection(minimum: [-10, 0, -5], maximum: [10, 4, 5])
    let point = SIMD2<Float>(3.5, -2)
    let restored = map.room(map.map(point))
    #expect(abs(restored.x-point.x) < 0.0001)
    #expect(abs(restored.y-point.y) < 0.0001)
    #expect(abs(map.metersToMap - 0.014) < 0.0001)
}

@Test func palmMapRevealsAfterDwellAndDismissesWhenHidden() {
    var toggle = PalmMapToggle()
    for (attended, now, expected) in [(true,0.0,false), (true,0.36,true), (true,4.0,true),
                                      (false,4.1,false), (true,4.2,false), (true,4.6,true), (true,5.0,true)] {
        let visible = toggle.update(attended: attended, now: now)
        #expect(visible == expected)
    }
}

@Test func isometricDragInvertsFloorProjectionAndSeparatesElevation() {
    let map = PalmMapProjection(minimum: [-10,0,-10], maximum: [10,4,10])
    let delta = SIMD2<Float>(2,-3)
    let x = cos(PalmMapProjection.yaw) * (delta.x + delta.y) * map.metersToMap
    let y = sin(PalmMapProjection.pitch) * cos(PalmMapProjection.yaw) * (delta.x - delta.y) * map.metersToMap
    let restored = map.floorDelta(screen: [x,y])
    #expect(abs(restored.x-delta.x) < 0.0001)
    #expect(abs(restored.y-delta.y) < 0.0001)
    #expect(abs(map.heightDelta(screenY: 2*cos(PalmMapProjection.pitch)*map.metersToMap)-2) < 0.0001)
}

@Test func raisedDestinationClearsFurnitureButStillRejectsCeilingAndWalls() throws {
    var room = EnvironmentManifest.simple(id: "map", title: "Map", min: [-5,0,-5], max: [5,5,5], spawn: [0,0,3], yaw: 0,
        file: "room.usdz", checksum: String(repeating: "a", count: 64), bytes: 1, scanned: false)
    room.colliders.append(.init(id: "desk", sourceID: "desk", shape: "box", center: [0,0.5,0], size: [2,1,2], rotation: [0,0,0,1]))
    #expect(PalmMapProjection.destination([0,0], in: room) == nil)
    #expect(PalmMapProjection.destination([0,0], in: room, elevation: 1)?.y == 1)
    #expect(PalmMapProjection.destination([3,0], in: room) != nil)
    #expect(PalmMapProjection.destination([0,0], in: room, elevation: 4) == nil)
    #expect(PalmMapProjection.destination([0,0], in: room, elevation: -1) == nil)
    #expect(PalmMapProjection.destination([5,0], in: room, elevation: 1) == nil)
    #expect(PalmMapProjection.destination([0,0], in: room, elevation: .nan) == nil)
    room.colliders.append(.init(id: "wall", sourceID: "wall", shape: "box", center: [3,2.5,0], size: [0.2,5,5], rotation: [0,0,0,1]))
    #expect(PalmMapProjection.destination([3,0], in: room, elevation: 1) == nil)
}

@Test func palmMapRespectsRotatedObstacles() {
    var room = EnvironmentManifest.simple(id: "map", title: "Map", min: [-5,0,-5], max: [5,5,5], spawn: [0,0,3], yaw: 0,
        file: "room.usdz", checksum: String(repeating: "a", count: 64), bytes: 1, scanned: false)
    room.colliders.append(.init(id: "diagonal", sourceID: "diagonal", shape: "box", center: [0,1,0], size: [4,2,0.2],
        rotation: [0,sin(Float.pi/8),0,cos(Float.pi/8)]))
    #expect(PalmMapProjection.destination([1,-1], in: room) == nil)
    #expect(PalmMapProjection.destination([1,1], in: room) != nil)
}

@Test func palmMapRejectsOutsideFloorAndFurniture() throws {
    let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments/Classroom/environment.json").standardizedFileURL
    let room = try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: source))
    let spawn = SIMD2<Float>(room.spawn.position[0], room.spawn.position[2])
    #expect(PalmMapProjection.destination(spawn, in: room) != nil)
    #expect(PalmMapProjection.destination([1000,1000], in: room) == nil)
    let desk = try #require(room.surfaces.first { $0.id == "instructor-desk-top" })
    #expect(PalmMapProjection.destination([desk.center[0],desk.center[2]], in: room) == nil)
    #expect(PalmMapProjection.destination([.nan,0], in: room) == nil)
}

@Test func palmMapEquipmentEnvelopeParticipatesInCollision() {
    let room = EnvironmentManifest.simple(id: "map", title: "Map", min: [-5,0,-5], max: [5,5,5], spawn: [0,0,3], yaw: 0,
        file: "room.usdz", checksum: String(repeating: "a", count: 64), bytes: 1, scanned: false)
    let fixture = Fixture(name: "Cube", position: .init(x: 0,y: 0.12,z: 0))
    let withEquipment = PalmMapProjection.includingFixtures([fixture], in: room)
    #expect(PalmMapProjection.destination([0,0], in: room) != nil)
    #expect(PalmMapProjection.destination([0,0], in: withEquipment) == nil)
    #expect(PalmMapProjection.destination([0,0], in: withEquipment, elevation: 0.3) != nil)
}
