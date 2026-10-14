import Testing
@testable import VenueVolumeCore

@Test func wristAttentionNeedsNoFingerTrackingOrPalmNormal() {
    #expect(WristAttention.isAttended(wrist: [-0.1,-0.05,-0.4], eye: .zero, forward: [0,0,-1]))
    #expect(WristAttention.isAttended(wrist: [1.9,1.45,2.6], eye: [2,1.5,3], forward: [0,0,-1]))
}

@Test func wristAttentionRejectsMissingDistantAndUnattendedWrist() {
    for wrist: SIMD3<Float>? in [nil, [0,0,-0.05], [0,0,-1.3], [0.5,0,-0.1], [0,0,0.5], [.nan,0,-0.5]] {
        #expect(!WristAttention.isAttended(wrist: wrist, eye: .zero, forward: [0,0,-1]))
    }
    #expect(!WristAttention.isAttended(wrist: [0,0,-0.5], eye: .zero, forward: .zero))
}
