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

@Test func palmMapDwellTogglesOnceAndRequiresFreshAttention() {
    var toggle = PalmMapToggle()
    let result1 = toggle.update(attended: true, now: 0)
    #expect(!result1)
    let result2 = toggle.update(attended: true, now: 0.36)
    #expect(result2)
    let result3 = toggle.update(attended: true, now: 4)
    #expect(result3)
    let result4 = toggle.update(attended: false, now: 4.1)
    #expect(result4)
    let result5 = toggle.update(attended: true, now: 4.2)
    #expect(result5)
    let result6 = toggle.update(attended: true, now: 5)
    #expect(result6)
    _ = toggle.update(attended: false, now: 5.1)
    _ = toggle.update(attended: false, now: 5.7)
    let result7 = toggle.update(attended: true, now: 6)
    #expect(result7)
    let result8 = toggle.update(attended: true, now: 6.4)
    #expect(!result8)
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
