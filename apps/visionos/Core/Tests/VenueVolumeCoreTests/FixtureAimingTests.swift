import Foundation
import Testing
@testable import VenueVolumeCore

private func point(_ v: SIMD3<Float>) -> Position3D { .init(x: v.x, y: v.y, z: v.z) }

@Test func pilotHeadSliderAnglesEncodeToPreviewValues() {
    for value in [0, 1, 64, 128, 192, 254, 255] {
        let pan = LightingPreview(channels: [0, 0, 0, 0, value, 128]).panDegrees
        let tilt = LightingPreview(channels: [0, 0, 0, 0, 128, value]).tiltDegrees
        #expect(FixtureAiming.panByte(for: pan) == value)
        #expect(FixtureAiming.tiltByte(for: tilt) == value)
    }
    #expect(FixtureAiming.panByte(for: .infinity) == 128)
    #expect(FixtureAiming.tiltByte(for: .nan) == 128)
}

@Test func headAimSolvesInFixtureCoordinatesWithQuantizedDmx() throws {
    var fixture = Fixture(name: "Aim", channels: LightingPreview.presets[0].channels,
                          position: .init(x: 3, y: 1, z: -2),
                          orientation: FixtureAiming.euler(yaw: 37, pitch: -22, roll: 18),
                          scale: .init(x: 1.1, y: 0.9, z: 1.2))
    for (pan, tilt) in [(128,128), (45,73), (209,234), (0,0), (255,255)] {
        fixture.channels[4] = pan; fixture.channels[5] = tilt
        let ray = FixtureAiming.localRay(channels: fixture.channels)
        let local = (ray.origin + ray.direction * 4) * FixtureAiming.vector(fixture.scale)
        let target = FixtureAiming.vector(fixture.position) + FixtureAiming.rotate(fixture.orientation, local)
        let aim = try FixtureAiming.articulated(fixture, target: point(target))
        #expect(aim == PanTiltOverride(pan: pan, tilt: tilt))
    }
}

@Test func unreachableHeadTargetsFailInsteadOfClamping() {
    let fixture = Fixture(name: "Aim", position: .init(x: 0, y: 0, z: 0))
    for target: SIMD3<Float> in [[0,0.33078,3], [0,4,0], FixtureAiming.headPivot, [.nan,1,-3]] {
        #expect(throws: PresetError.self) { try FixtureAiming.articulated(fixture, target: point(target)) }
    }
}

@Test func mountAimAccountsForEmitterParallaxAndPreservesArticulation() throws {
    var fixture = Fixture(name: "Aim", channels: LightingPreview.presets[0].channels,
                          position: .init(x: 3, y: 1, z: -2),
                          orientation: FixtureAiming.euler(yaw: 37, pitch: -22, roll: 18),
                          scale: .init(x: 1.1, y: 0.9, z: 1.2))
    fixture.channels[4] = 189; fixture.channels[5] = 90
    for target: SIMD3<Float> in [[1,0,-6], [3,5,-2], [3,-2,-2], [5,2,4]] {
        let orientation = try FixtureAiming.mounted(fixture, target: point(target))
        let ray = FixtureAiming.localRay(channels: fixture.channels)
        let origin = FixtureAiming.vector(fixture.position) + FixtureAiming.rotate(orientation, ray.origin * FixtureAiming.vector(fixture.scale))
        let delta = target - origin
        let direction = FixtureAiming.rotate(orientation, ray.direction * FixtureAiming.vector(fixture.scale))
        let error = delta / FixtureAiming.length(delta) - direction / FixtureAiming.length(direction)
        #expect(FixtureAiming.length(error) < 0.00001)
        #expect(abs(orientation.x*orientation.x + orientation.y*orientation.y + orientation.z*orientation.z + orientation.w*orientation.w - 1) < 0.00001)
    }
    #expect(throws: PresetError.self) { try FixtureAiming.mounted(fixture, target: fixture.position) }
    #expect(throws: PresetError.self) { try FixtureAiming.mounted(fixture, target: .init(x: .infinity, y: 1, z: -3)) }
}

@Test func mountAnglesRoundTripIncludingGimbalLock() {
    for (yaw,pitch,roll): (Float,Float,Float) in [(37,-22,18), (179,89,-90), (-180,-89,170), (40,90,30), (40,-90,30)] {
        let original = FixtureAiming.euler(yaw: yaw, pitch: pitch, roll: roll)
        let angles = FixtureAiming.angles(original)
        let restored = FixtureAiming.euler(yaw: angles.yaw, pitch: angles.pitch, roll: angles.roll)
        for basis: SIMD3<Float> in [[1,0,0], [0,1,0], [0,0,1]] {
            #expect(FixtureAiming.length(FixtureAiming.rotate(original, basis) - FixtureAiming.rotate(restored, basis)) < 0.001)
        }
    }
}

@Test func aimOverrideSurvivesPresetOperationsAndPersistence() throws {
    var preset = LightingPreview.presets[0]
    var fixture = Fixture(presetID: preset.id, name: "A", channels: preset.channels)
    let other = Fixture(presetID: preset.id, name: "B", startAddress: 17, channels: preset.channels)
    fixture.aimOverride = .init(pan: 170, tilt: 140)
    fixture.preserveAimOverride()
    preset.channels[0] = 12; preset.channels[4] = 85
    let saved = try PresetOperations.saving(preset, fixtures: [fixture,other])
    #expect(saved[0].channels[0] == 12 && saved[0].channels[4] == 170 && saved[0].channels[5] == 140)
    #expect(saved[1].channels == preset.channels)
    #expect(try PresetOperations.applying(preset, to: fixture.id, fixtures: [fixture])[0] == saved[0])
    let copy = try JSONDecoder().decode(Fixture.self, from: JSONEncoder().encode(saved[0]))
    #expect(copy == saved[0] && copy.validationIssue(among: saved) == nil)
    let cleared = PresetOperations.clearing(preset.id, fixtures: saved)[0]
    #expect(cleared.channels[0] == 0 && cleared.channels[4] == 170 && cleared.presetID == nil)
    preset.channels = [1,2]
    #expect(throws: PresetError.self) { try PresetOperations.saving(preset, fixtures: saved) }
    #expect(throws: PresetError.self) { try PresetOperations.applying(preset, to: fixture.id, fixtures: saved) }
    var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture)) as? [String: Any])
    legacy.removeValue(forKey: "aimOverride")
    let decoded = try JSONDecoder().decode(Fixture.self, from: JSONSerialization.data(withJSONObject: legacy))
    #expect(decoded.aimOverride == nil)
    var invalid = fixture
    invalid.channels[4] = 0
    #expect(invalid.validationIssue(among: []) != nil)
}
