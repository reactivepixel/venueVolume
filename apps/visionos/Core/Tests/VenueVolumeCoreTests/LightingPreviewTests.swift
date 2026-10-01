import Foundation
import Testing
@testable import VenueVolumeCore

@Test func previewPersonalityDecodesDmxAndClamps() {
    let look = LightingPreview(channels: [255, 255, 128, 0, 128, 128, 255])
    #expect(look.intensity == 35_000)
    #expect(look.rgb[0] == 1 && look.rgb[2] == 0)
    #expect(abs(look.panDegrees) < 0.001 && abs(look.tiltDegrees) < 0.001)
    #expect(look.outerAngle == 60)
    let invalid = LightingPreview(channels: [-1, 999])
    #expect(invalid.intensity == 0 && invalid.rgb == [1, 0, 0])
    #expect(LightingPreview(channels: [], blackout: false).intensity == 0)
    #expect(LightingPreview(channels: [255], blackout: true).intensity == 0)
}

@Test func panTiltAndBeamRespondIndependently() {
    let neutral = LightingPreview(channels: [128, 0, 0, 255, 128, 128, 0])
    let aimed = LightingPreview(channels: [128, 0, 0, 255, 255, 0, 255])
    #expect(aimed.panDegrees > 130 && aimed.tiltDegrees < -60)
    #expect(aimed.intensity == neutral.intensity && aimed.rgb == neutral.rgb)
    #expect(neutral.outerAngle == 10 && aimed.outerAngle == 60)
}

@Test func fixtureAssetAndTransformRoundTripWithPresets() throws {
    let fixture = Fixture(name: "Rig", assetID: LightingPreview.assetID, position: .init(x: 1, y: 0, z: -3), orientation: .init(y: 1, w: 0))
    let updated = try PresetOperations.applying(LightingPreview.presets[1], to: fixture.id, fixtures: [fixture])[0]
    #expect(updated.position == fixture.position && updated.orientation == fixture.orientation)
    #expect(updated.assetID == LightingPreview.assetID)
    let copy = try JSONDecoder().decode(Fixture.self, from: JSONEncoder().encode(updated))
    #expect(copy == updated)
    var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture)) as? [String: Any])
    legacy.removeValue(forKey: "assetID"); legacy.removeValue(forKey: "presetID")
    let decoded = try JSONDecoder().decode(Fixture.self, from: JSONSerialization.data(withJSONObject: legacy))
    #expect(decoded.assetID == nil && decoded.presetID == nil)
}
