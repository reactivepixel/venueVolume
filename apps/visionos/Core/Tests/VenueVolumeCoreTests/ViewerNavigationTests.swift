import Foundation
import Testing
@testable import VenueVolumeCore

private func hand(_ finger: NavigationFinger? = nil, at p: SIMD3<Float> = .zero) -> NavigationHandSample {
    .init(thumb: p,index: p+[finger == .index ? 0.01 : 0.1,0,0],middle: p+[0,finger == .middle ? 0.01 : 0.1,0])
}

@Test func navigationMovesAllAxesWithoutBoundsOrAccumulatingDrift() {
    var nav = LeftHandNavigation()
    nav.update(hand(.index),at: 1)
    nav.update(hand(.index,at: [10,-3,-15]),at: 1.1)
    #expect(nav.pose.offset == .init(x: 30,y: -9,z: -45))
    nav.update(hand(.index,at: [1,2,3]),at: 1.2)
    #expect(nav.pose.offset == .init(x: 3,y: 6,z: 9))
    nav.update(hand(),at: 1.3)
    let released = nav.pose
    nav.update(hand(at: [20,20,20]),at: 1.4)
    #expect(nav.pose == released)
    #expect(nav.activeFinger == nil)
}

@Test func rotationKeepsPositionAndTranslationFollowsRotatedAxes() {
    var nav = LeftHandNavigation()
    let start = ViewerNavigationPose(offset: .init(x: 2,y: 3,z: 4),orientation: FixtureAiming.euler(yaw: 90,pitch: 0,roll: 0))
    nav.restore(start)
    nav.update(hand(.index),at: 1)
    nav.update(hand(.index,at: [0,0,-0.1]),at: 1.1)
    #expect(abs(nav.pose.offset.x-1.7) < 0.001)
    nav.update(hand(),at: 1.2); nav.update(hand(),at: 1.3)
    let position = nav.pose.offset
    nav.update(hand(.middle),at: 1.4)
    nav.update(hand(.middle,at: [0.1,0.2,0.1]),at: 1.5)
    #expect(nav.pose.orientation != start.orientation)
    #expect(nav.pose.offset == position)
    #expect(nav.pose.isValid)
}

@Test func doubleMiddleResetsOnlyOrientationAndDoubleIndexResetsBoth() {
    for finger in [NavigationFinger.middle,.index] {
        var nav = LeftHandNavigation()
        let start = ViewerNavigationPose(offset: .init(x: 1,y: 2,z: 3),orientation: FixtureAiming.euler(yaw: 45,pitch: 20,roll: 15))
        nav.restore(start)
        nav.update(hand(finger),at: 1)
        nav.update(hand(),at: 1.1); nav.update(hand(),at: 1.15)
        nav.update(hand(finger),at: 1.2)
        nav.update(hand(),at: 1.3)
        #expect(nav.pose.orientation == .init())
        #expect(nav.pose.offset == (finger == .index ? .init(x: 0,y: 0,z: 0) : start.offset))
        #expect(nav.reset == (finger == .index ? .spawn : .orientation))
    }
}

@Test func dragAndOtherFingerDoNotBecomeDoubleClicks() {
    var nav = LeftHandNavigation()
    nav.update(hand(.index),at: 1); nav.update(hand(),at: 1.1); nav.update(hand(),at: 1.15)
    nav.update(hand(.middle),at: 1.2); nav.update(hand(),at: 1.3)
    #expect(nav.reset == nil)
    nav.update(hand(),at: 1.35); nav.update(hand(.middle),at: 1.4)
    nav.update(hand(.middle,at: [0.1,0,0]),at: 1.5); nav.update(hand(),at: 1.6)
    #expect(nav.reset == nil)
}

@Test func trackingLossRequiresReleaseAndNeverResumesOldDrag() {
    var nav = LeftHandNavigation()
    nav.update(hand(.index),at: 1); nav.update(hand(.index,at: [0.1,0,0]),at: 1.1)
    let pose = nav.pose
    nav.update(nil,at: 1.2)
    nav.update(hand(.index,at: [2,0,0]),at: 1.3)
    #expect(nav.activeFinger == nil && nav.pose == pose)
    nav.update(hand(),at: 1.4); nav.update(hand(.index,at: [2,0,0]),at: 1.5)
    nav.update(hand(.index,at: [2.1,0,0]),at: 1.6)
    #expect(abs(nav.pose.offset.x-0.6) < 0.001)
    nav.update(hand(.index,at: [100,0,0]),at: 2)
    #expect(nav.activeFinger == nil)
}

@Test func ambiguousAndInvalidPinchesDoNotStartNavigation() {
    var nav = LeftHandNavigation()
    nav.update(.init(thumb: .zero,index: [0.01,0,0],middle: [0,0.01,0]),at: 1)
    #expect(nav.activeFinger == nil && !nav.reservesInput(at: 1))
    nav.update(.init(thumb: [.nan,0,0],index: .zero,middle: .zero),at: 1.1)
    #expect(nav.pose == .init() && nav.activeFinger == nil)
    let invalid = ViewerNavigationPose(orientation: .init(x: 0,y: 0,z: 0,w: 0))
    #expect(!invalid.isValid)
}

@Test func navigationPoseRoundTripsAndRejectsInvalidData() throws {
    let pose = ViewerNavigationPose(offset: .init(x: -30,y: 50,z: -100),orientation: FixtureAiming.euler(yaw: 170,pitch: 80,roll: -180))
    #expect(try JSONDecoder().decode(ViewerNavigationPose.self,from: JSONEncoder().encode(pose)) == pose)
    #expect(pose.isValid)
    #expect(!ViewerNavigationPose(offset: .init(x: .infinity,y: 0,z: 0)).isValid)
}
