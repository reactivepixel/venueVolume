import Foundation
import Testing
@testable import VenueVolumeCore

@Test func mountAlignsToFloorWallAndCeilingWithoutInvalidQuaternion() {
    let original = FixtureAiming.euler(yaw: 37,pitch: 16,roll: -9)
    for normal: SIMD3<Float> in [[0,1,0],[1,0,0],[0,0,1],[0,-1,0]] {
        let q = FixtureAiming.alignedMount(original, normal: normal)
        #expect(FixtureAiming.length(FixtureAiming.rotate(q,[0,1,0])-normal) < 0.001)
        #expect(abs(q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w-1) < 0.001)
    }
    let heading = FixtureAiming.euler(yaw: 37,pitch: 0,roll: 0)
    #expect(FixtureAiming.length(FixtureAiming.rotate(FixtureAiming.alignedMount(heading,normal: [0,1,0]),[0,0,-1])-FixtureAiming.rotate(heading,[0,0,-1])) < 0.001)
}

@Test func slidingPlaneRemovesOnlyNormalMotion() {
    let wall = FixtureMountPlane(origin: .init(x: 0,y: 0,z: -3), normal: .init(x: 0,y: 0,z: 1))
    #expect(wall.projected([1,2,8]) == SIMD3<Float>(1,2,0))
    let floor = FixtureMountPlane(origin: .init(x: 0,y: 0,z: 0), normal: .init(x: 0,y: 1,z: 0))
    #expect(floor.projected([1,7,3]) == SIMD3<Float>(1,0,3))
    #expect(!FixtureMountPlane(origin: .init(x: 0,y: 0,z: 0),normal: .init(x: 0,y: 0,z: 0)).isValid)
}

@Test func scanRequiresAllCornersOnCapturedWallPlane() {
    let mesh = ScannedMesh(chunks: [.init(vertices: [.init(x: -1,y: 0,z: -2),.init(x: 1,y: 0,z: -2),.init(x: 1,y: 2,z: -2),.init(x: -1,y: 2,z: -2)], triangles: [0,1,2,0,2,3])])
    #expect(mesh.supports(.init(x: 0,y: 1,z: -2),normal: .init(x: 0,y: 0,z: 1),radius: 0.23))
    #expect(!mesh.supports(.init(x: 0.9,y: 1,z: -2),normal: .init(x: 0,y: 0,z: 1),radius: 0.23))
    #expect(!mesh.supports(.init(x: 0,y: 1,z: -1.8),normal: .init(x: 0,y: 0,z: 1),radius: 0.23))
    #expect(!mesh.supports(.init(x: 0,y: 1,z: -2),normal: .init(x: 0,y: 1,z: 0),radius: 0.23))
}

@Test func planeSurvivesFixtureRoundTripAndLegacyStillDecodes() throws {
    var fixture = Fixture(name: "Spot",assetID: LightingPreview.assetID)
    fixture.mountPlane = .init(origin: .init(x: 0,y: 1,z: -3),normal: .init(x: 0,y: 0,z: 1))
    let data = try JSONEncoder().encode(fixture)
    #expect(try JSONDecoder().decode(Fixture.self,from: data) == fixture)
    var object = try #require(JSONSerialization.jsonObject(with: data) as? [String:Any])
    object.removeValue(forKey: "mountPlane")
    #expect(try JSONDecoder().decode(Fixture.self,from: JSONSerialization.data(withJSONObject: object)).mountPlane == nil)
    fixture.mountPlane?.normal.y = .nan
    #expect(fixture.validationIssue(among: [fixture]) != nil)
}
