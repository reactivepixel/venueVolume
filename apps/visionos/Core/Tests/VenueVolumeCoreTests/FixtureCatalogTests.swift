import Foundation
import Testing
@testable import VenueVolumeCore

@Test func catalogControlsAreAddressableAndNeutralAtRest() throws {
    #expect(FixtureCatalog.all.count >= 127)
    #expect(Set(FixtureCatalog.all.map(\.id)).count == FixtureCatalog.all.count)
    for asset in FixtureCatalog.all {
        let kind = try #require(FixtureKind(rawValue: asset.id))
        #expect(FixtureKind(token: kind.dragToken)?.assetID == asset.id)
        #expect(asset.height > 0 && asset.radius > 0)
        var parents = Set<String>()
        for joint in asset.joints {
            #expect(joint.parent == nil || parents.contains(joint.parent!))
            #expect((0..<16).contains(joint.channel))
            #expect(joint.value(channels: asset.neutralChannels) == 0)
            for byte in [0, 64, 128, 192, 255] {
                var channels = asset.neutralChannels; channels[joint.channel] = byte
                #expect(joint.byte(for: joint.value(channels: channels)) == byte)
            }
            parents.insert(joint.id)
        }
    }
    #expect(FixtureKind(token: "venue-volume:fixture-kind:unknown/model") == nil)
}

@Test func everyMovingHeadTargetsUsingItsOwnPivots() throws {
    for asset in FixtureCatalog.all where asset.headAim {
        var fixture = Fixture(name: asset.name, assetID: asset.id, channels: asset.neutralChannels,
                              position: .init(x: 3,y: 1,z: -2), orientation: FixtureAiming.euler(yaw: 27,pitch: -14,roll: 8))
        for (pan, tilt) in [(128,128), (45,73), (209,234), (0,0), (255,255)] {
            fixture.channels[4] = pan; fixture.channels[5] = tilt
            let ray = FixtureAiming.localRay(channels: fixture.channels, asset: asset)
            let target = FixtureAiming.vector(fixture.position) + FixtureAiming.rotate(fixture.orientation, ray.origin+ray.direction*5)
            let result = try FixtureAiming.articulated(fixture, target: .init(x: target.x,y: target.y,z: target.z))
            #expect(result == PanTiltOverride(pan: pan, tilt: tilt), "\(asset.id)")
        }
    }
}

@Test func compoundFixturesKeepIndependentControlsAndEmitters() throws {
    let duo = try #require(FixtureCatalog.asset("chauvet-dj/intimidator-spot-duo"))
    #expect(duo.joints.map(\.id) == ["pan_1", "tilt_1", "pan_2", "tilt_2"])
    #expect(duo.emitters.map(\.parent) == ["tilt_1", "tilt_2"])
    #expect(!duo.headAim)
    #expect(Set(duo.joints.map(\.channel)).count == 4)
    var channels = duo.neutralChannels
    channels[duo.joints[0].channel] = 211
    #expect(duo.joints[0].value(channels: channels) != 0)
    #expect(duo.joints[2].value(channels: channels) == 0)
    let bar = try #require(FixtureCatalog.asset("eurolite/led-kls-120-compact-light-set"))
    #expect(bar.joints.count == 4 && bar.emitters.count == 4)
    #expect(bar.joints.allSatisfy { $0.mode == "manual" })
    #expect(Set(bar.emitters.compactMap(\.parent)).count == 4)
    let fixture = Fixture(name: duo.name, assetID: duo.id, channels: channels)
    #expect(try JSONDecoder().decode(Fixture.self, from: JSONEncoder().encode(fixture)) == fixture)
}

@Test func moduleOverridesSurvivePresetChangesAndOldSaves() throws {
    let asset = try #require(FixtureCatalog.asset("claypaky/volero-wave"))
    let joint = try #require(asset.joints.first)
    var preset = LightingPreview.presets[0]
    var fixture = Fixture(presetID: preset.id, name: asset.name, assetID: asset.id, channels: asset.neutralChannels)
    fixture.jointOverrides = [joint.id: 211]; fixture.preserveAimOverride()
    let other = Fixture(presetID: preset.id, name: "Other", assetID: asset.id, startAddress: 17, channels: asset.neutralChannels)
    preset.channels[joint.channel] = 40
    let saved = try PresetOperations.saving(preset, fixtures: [fixture, other])
    #expect(saved[0].channels[joint.channel] == 211)
    #expect(saved[1].channels[joint.channel] == 40)
    #expect(try JSONDecoder().decode(Fixture.self, from: JSONEncoder().encode(saved[0])) == saved[0])
    var old = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(other)) as? [String: Any])
    old.removeValue(forKey: "jointOverrides")
    #expect(try JSONDecoder().decode(Fixture.self, from: JSONSerialization.data(withJSONObject: old)).jointOverrides == nil)
    preset.channels = [1,2]
    #expect(throws: PresetError.self) { try PresetOperations.saving(preset, fixtures: saved) }
}

@Test func mountAimUsesStaticAndMultiEmitterGeometry() throws {
    for asset in FixtureCatalog.all where !asset.emitters.isEmpty {
        var fixture = Fixture(name: asset.name, assetID: asset.id, channels: asset.neutralChannels, position: .init(x: 2,y: 1,z: -2))
        for joint in asset.joints { fixture.channels[joint.channel] = 192 }
        let target = Position3D(x: 4,y: 3,z: -8)
        let orientation = try FixtureAiming.mounted(fixture, target: target)
        let ray = FixtureAiming.localRay(channels: fixture.channels, asset: asset)
        let origin = FixtureAiming.vector(fixture.position)+FixtureAiming.rotate(orientation, ray.origin)
        let delta = FixtureAiming.vector(target)-origin
        let direction = FixtureAiming.rotate(orientation, ray.direction)
        #expect(FixtureAiming.length(delta/FixtureAiming.length(delta)-direction) < 0.0001, "\(asset.id)")
    }
}
