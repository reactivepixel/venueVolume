import Foundation

/// Screen-plane rectangles (x/depth, y/depth) let the renderer avoid competing
/// fixture labels without moving the labels away from their objects.
public enum SpatialLabelLayout {
    public struct Candidate: Sendable {
        public let id: UUID
        public let center: SIMD2<Float>
        public let halfSize: SIMD2<Float>
        public let distance: Float
        public let selected: Bool
        public init(id: UUID, center: SIMD2<Float>, halfSize: SIMD2<Float>, distance: Float, selected: Bool) {
            self.id = id; self.center = center; self.halfSize = halfSize; self.distance = distance; self.selected = selected
        }
    }
    public static func visible(_ candidates: [Candidate]) -> Set<UUID> {
        let eligible = candidates.filter {
            $0.distance.isFinite && $0.distance > 0 && ($0.selected || $0.distance <= 4) &&
            $0.center.x.isFinite && $0.center.y.isFinite && $0.halfSize.x.isFinite && $0.halfSize.y.isFinite &&
            $0.halfSize.x > 0 && $0.halfSize.y > 0 &&
            abs($0.center.x) - $0.halfSize.x < 1.4 && abs($0.center.y) - $0.halfSize.y < 1.1
        }.sorted {
            if $0.selected != $1.selected { return $0.selected }
            if $0.distance != $1.distance { return $0.distance < $1.distance }
            return $0.id.uuidString < $1.id.uuidString
        }
        var accepted: [Candidate] = []
        for candidate in eligible {
            guard accepted.count < 6 else { break }
            let overlaps = accepted.contains {
                abs(candidate.center.x - $0.center.x) < candidate.halfSize.x + $0.halfSize.x + 0.015 &&
                abs(candidate.center.y - $0.center.y) < candidate.halfSize.y + $0.halfSize.y + 0.015
            }
            if !overlaps { accepted.append(candidate) }
        }
        return Set(accepted.map(\.id))
    }
}
