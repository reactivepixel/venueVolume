import Foundation
import Testing
@testable import VenueVolumeCore

@Test @MainActor func presetDragRequiresMovementAndConsumesReleaseOnce() {
    let state = PresetDragState(), preset = UUID(), fixture = UUID()
    let sample = PresetDragState.Sample(source: .zero, cursor: [0,0,-1])
    let id = state.begin(presetID: preset, sample: sample)!
    state.propose(fixture)
    state.release(id)
    #expect(state.takeRelease()?.fixtureID == nil)
    #expect(state.takeRelease() == nil)
    let next = state.begin(presetID: preset, sample: sample)!
    state.update(next, sample: sample, armed: true)
    state.propose(fixture)
    state.release(next)
    #expect(state.takeRelease()?.fixtureID == fixture)
    #expect(state.takeRelease() == nil)
}

@Test @MainActor func cancelledAndSupersededDragCannotApply() {
    let state = PresetDragState(), sample = PresetDragState.Sample(source: .zero, cursor: .zero)
    let old = state.begin(presetID: UUID(), sample: sample)!
    #expect(state.begin(presetID: UUID(), sample: sample) == nil)
    state.update(old, sample: sample, armed: true)
    state.propose(UUID()); state.cancel(); state.release(old)
    #expect(state.takeRelease() == nil)
    let fresh = state.begin(presetID: UUID(), sample: sample)!
    state.update(old, sample: .init(source: .zero, cursor: [5,0,0]), armed: true)
    #expect(state.session?.id == fresh)
    #expect(state.session?.sample == sample)
    #expect(state.session?.armed == false)
}

@Test @MainActor func presetDragRejectsInvalidSamplesAndNoTarget() {
    let state = PresetDragState()
    #expect(state.begin(presetID: UUID(), sample: .init(source: .zero, cursor: [.nan,0,0])) == nil)
    let sample = PresetDragState.Sample(source: [1,2,3], cursor: [3,4,5])
    let id = state.begin(presetID: UUID(), sample: sample)!
    state.update(id, sample: .init(source: .zero, cursor: [.infinity,0,0]), armed: true)
    #expect(state.session?.sample == sample)
    state.release(id)
    #expect(state.takeRelease()?.fixtureID == nil)
}

@Test func presetSnapSupportsIndirectInputAndRejectsBehindOrFarTargets() {
    let near = UUID(), far = UUID(), behind = UUID(), distant = UUID()
    let targets: [PresetDropSnap.Target] = [
        .init(id: far, center: [0,0,-6], radius: 0.2), .init(id: near, center: [0.1,0,-3], radius: 0.2),
        .init(id: behind, center: [0,0,2], radius: 0.2), .init(id: distant, center: [0,0,-80], radius: 0.2)]
    #expect(PresetDropSnap.target(cursor: [0,0,-1], rayOrigin: .zero, rayPoint: [0,0,-1], targets: targets, previous: nil) == near)
    #expect(PresetDropSnap.target(cursor: [5,0,-1], rayOrigin: .zero, rayPoint: [5,0,-1], targets: targets, previous: nil) == nil)
    #expect(PresetDropSnap.target(cursor: [.nan,0,0], rayOrigin: .zero, rayPoint: [0,0,-1], targets: targets, previous: near) == nil)
}

@Test func presetSnapRetainsNearBoundaryAndUsesOnlyAvailableTargets() {
    let id = UUID(), target = PresetDropSnap.Target(id: id, center: .zero, radius: 0.2)
    #expect(PresetDropSnap.target(cursor: [0.42,0,0], rayOrigin: nil, rayPoint: nil, targets: [target], previous: nil) == nil)
    #expect(PresetDropSnap.target(cursor: [0.42,0,0], rayOrigin: nil, rayPoint: nil, targets: [target], previous: id) == id)
    #expect(PresetDropSnap.target(cursor: [0.55,0,0], rayOrigin: nil, rayPoint: nil, targets: [target], previous: id) == nil)
    #expect(PresetDropSnap.target(cursor: .zero, rayOrigin: nil, rayPoint: nil, targets: [], previous: id) == nil)
}

@Test func presetSnapReachesLargeVenueFromOnePosition() {
    let id = UUID()
    #expect(PresetDropSnap.target(cursor: [0,0,-1], rayOrigin: .zero, rayPoint: [0,0,-1],
        targets: [.init(id: id, center: [0,0,-30], radius: 0.2)], previous: nil) == id)
}
