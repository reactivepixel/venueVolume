import Foundation
import Testing
@testable import VenueVolumeCore

@Test func selectedLabelWinsOverlapEvenAtADistance() {
    let selected = UUID(), near = UUID(), separate = UUID()
    let items: [SpatialLabelLayout.Candidate] = [
        .init(id: near, center: .zero, halfSize: [0.1,0.1], distance: 1, selected: false),
        .init(id: selected, center: .zero, halfSize: [0.1,0.1], distance: 12, selected: true),
        .init(id: separate, center: [0.5,0], halfSize: [0.1,0.1], distance: 2, selected: false)]
    #expect(SpatialLabelLayout.visible(items) == [selected, separate])
}
@Test func labelsBoundClutterAndRejectInvalidOrDistantCandidates() {
    let valid = (0..<10).map { SpatialLabelLayout.Candidate(id: UUID(), center: [Float($0) * 0.15 - 0.75,0], halfSize: [0.025,0.025], distance: Float($0)/10+1, selected: false) }
    let invalid: [SpatialLabelLayout.Candidate] = [
        .init(id: UUID(), center: [.nan,0], halfSize: [0.1,0.1], distance: 1, selected: true),
        .init(id: UUID(), center: [10,0], halfSize: [0.1,0.1], distance: 5, selected: false)]
    #expect(SpatialLabelLayout.visible(valid+invalid) == Set(valid.prefix(6).map(\.id)))
}

@Test func offscreenNeighborsDoNotHideFrontalLabels() {
    let front = UUID()
    let side = (0..<8).map { SpatialLabelLayout.Candidate(id: UUID(), center: [Float($0) + 4,0], halfSize: [0.1,0.1], distance: 1, selected: false) }
    #expect(SpatialLabelLayout.visible(side + [.init(id: front, center: .zero, halfSize: [0.1,0.1], distance: 2, selected: false)]) == [front])
}
