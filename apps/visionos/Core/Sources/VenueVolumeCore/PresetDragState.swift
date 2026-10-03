import Foundation
import Observation

/// Transient input only; never serialized into a venue or its undo history.
@MainActor @Observable
public final class PresetDragState {
    public struct Sample: Equatable, Sendable {
        /// All points are in SwiftUI's immersive coordinate space. The renderer
        /// converts them together into meters using RealityViewContent.
        public var source: SIMD3<Float>
        public var cursor: SIMD3<Float>
        public var hand: SIMD3<Float>?
        public var rayOrigin: SIMD3<Float>?
        public var rayPoint: SIMD3<Float>?
        public init(source: SIMD3<Float>, cursor: SIMD3<Float>, hand: SIMD3<Float>? = nil,
                    rayOrigin: SIMD3<Float>? = nil, rayPoint: SIMD3<Float>? = nil) {
            self.source = source; self.cursor = cursor; self.hand = hand
            self.rayOrigin = rayOrigin; self.rayPoint = rayPoint
        }
        public var isFinite: Bool {
            [source, cursor, hand, rayOrigin, rayPoint].compactMap { $0 }.allSatisfy { point in
                point.x.isFinite && point.y.isFinite && point.z.isFinite
            }
        }
    }
    public struct Session: Equatable, Sendable {
        public let id: UUID
        public let presetID: UUID
        public var sample: Sample
        public var armed: Bool
        public var released = false
    }
    public struct Feedback: Equatable, Sendable {
        public let id: UUID
        public let fixtureID: UUID
        public let presetID: UUID
        public let succeeded: Bool
        public let date: Date
    }
    public private(set) var sources: [UUID: SIMD3<Float>] = [:]
    public private(set) var session: Session?
    public private(set) var proposedFixtureID: UUID?
    public private(set) var feedback: Feedback?
    public var isActive: Bool { session != nil }
    public init() {}

    @discardableResult public func begin(presetID: UUID, sample: Sample) -> UUID? {
        guard sample.isFinite, session == nil else { return nil }
        let id = UUID()
        session = .init(id: id, presetID: presetID, sample: sample, armed: false)
        proposedFixtureID = nil; feedback = nil
        return id
    }
    public func update(_ id: UUID, sample: Sample, armed: Bool) {
        guard sample.isFinite, session?.id == id, session?.released == false else { return }
        var updated = session!
        updated.sample = sample
        updated.armed = updated.armed || armed
        session = updated
    }
    public func propose(_ fixtureID: UUID?) {
        guard session != nil else { return }
        if proposedFixtureID != fixtureID { proposedFixtureID = fixtureID }
    }
    public func release(_ id: UUID) {
        guard session?.id == id else { return }
        session?.released = true
    }
    /// Taking a release consumes it once, before applying the undoable command.
    public func takeRelease() -> (presetID: UUID, fixtureID: UUID?)? {
        guard let session, session.released else { return nil }
        let target = session.armed ? proposedFixtureID : nil
        cancel()
        return (session.presetID, target)
    }
    public func cancel() { session = nil; proposedFixtureID = nil }
    public func registerSource(presetID: UUID, point: SIMD3<Float>?) { sources[presetID] = point }
    public func showFeedback(presetID: UUID, fixtureID: UUID, succeeded: Bool) {
        feedback = .init(id: UUID(), fixtureID: fixtureID, presetID: presetID, succeeded: succeeded, date: Date())
    }
}

/// Snap in physical scene meters. The authored world bounds remain intact;
/// only the *additional* input tolerance is bounded. Occluded targets are
/// filtered by the renderer using the actual bounds entry distance.
public enum PresetDropSnap {
    public struct Target: Equatable, Sendable {
        public let id: UUID
        public let minimum: SIMD3<Float>
        public let maximum: SIMD3<Float>
        public var center: SIMD3<Float> { (minimum+maximum)/2 }
        public init(id: UUID, minimum: SIMD3<Float>, maximum: SIMD3<Float>) {
            self.id = id; self.minimum = minimum; self.maximum = maximum
        }
        /// Convenience for small cube-like targets, including legacy tests.
        public init(id: UUID, center: SIMD3<Float>, radius: Float) {
            self.init(id: id, minimum: center-SIMD3(repeating: radius), maximum: center+SIMD3(repeating: radius))
        }
        fileprivate var isValid: Bool {
            finite(minimum) && finite(maximum) && (0..<3).allSatisfy { minimum[$0] <= maximum[$0] }
        }
        fileprivate func closest(to point: SIMD3<Float>) -> SIMD3<Float> {
            SIMD3((0..<3).map { min(maximum[$0], max(minimum[$0], point[$0])) })
        }
    }
    public struct Match: Equatable, Sendable {
        public let id: UUID
        /// Point on/in the actual fixture bounds, not the expanded input halo.
        public let point: SIMD3<Float>
        /// Forward ray entry in meters, or cursor distance for direct input.
        public let distance: Float
        fileprivate let score: Float
    }
    public static func target(cursor: SIMD3<Float>, rayOrigin: SIMD3<Float>?, rayPoint: SIMD3<Float>?,
                              targets: [Target], previous: UUID?) -> UUID? {
        match(cursor: cursor, rayOrigin: rayOrigin, rayPoint: rayPoint, targets: targets, previous: previous)?.id
    }
    public static func match(cursor: SIMD3<Float>, rayOrigin: SIMD3<Float>?, rayPoint: SIMD3<Float>?,
                             targets: [Target], previous: UUID?) -> Match? {
        guard finite(cursor) else { return nil }
        let ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)?
        if let origin = rayOrigin, let point = rayPoint, finite(origin), finite(point), length(point-origin) > 0.0001 {
            ray = (origin, (point-origin)/length(point-origin))
        } else { ray = nil }
        var matches: [Match] = []
        for target in targets where target.isValid {
            let extra: Float = target.id == previous ? 0.12 : 0
            let directPoint = target.closest(to: cursor)
            let directDistance = length(cursor-directPoint)
            var candidate: Match?
            if directDistance <= 0.18+extra {
                candidate = .init(id: target.id, point: directPoint, distance: directDistance, score: directDistance)
            }
            if let ray {
                let distance = max(0, dot(target.center-ray.origin, ray.direction))
                let tolerance = min(distance*0.025, 0.16)+extra
                let inset = SIMD3<Float>(repeating: tolerance)
                // A slab intersection honors long fixtures and scaled models;
                // a center sphere would reject hits at their visible ends.
                if let entry = intersection(origin: ray.origin, direction: ray.direction,
                                            minimum: target.minimum-inset, maximum: target.maximum+inset), entry <= 60 {
                    let contact = target.closest(to: ray.origin+ray.direction*entry)
                    let rayMatch = Match(id: target.id, point: contact, distance: entry, score: 1+entry)
                    if candidate == nil || rayMatch.score < candidate!.score { candidate = rayMatch }
                }
            }
            if let candidate { matches.append(candidate) }
        }
        let best = matches.min { a, b in a.score == b.score ? a.id.uuidString < b.id.uuidString : a.score < b.score }
        if let previous, let retained = matches.first(where: { $0.id == previous }),
           let best, best.score >= retained.score*0.75 { return retained }
        return best
    }

    /// First nonnegative ray distance into the real bounds. A wall before this
    /// point occludes the fixture, regardless of the fixture's width or height.
    public static func entryDistance(from origin: SIMD3<Float>, through point: SIMD3<Float>, target: Target) -> Float? {
        guard target.isValid, finite(origin), finite(point), length(point-origin) > 0.0001 else { return nil }
        return intersection(origin: origin, direction: (point-origin)/length(point-origin),
                            minimum: target.minimum, maximum: target.maximum)
    }

    private static func intersection(origin: SIMD3<Float>, direction: SIMD3<Float>,
                                     minimum: SIMD3<Float>, maximum: SIMD3<Float>) -> Float? {
        var entry: Float = 0, exit = Float.infinity
        for axis in 0..<3 {
            if abs(direction[axis]) < 0.00001 {
                guard origin[axis] >= minimum[axis], origin[axis] <= maximum[axis] else { return nil }
            } else {
                let first = (minimum[axis]-origin[axis])/direction[axis]
                let second = (maximum[axis]-origin[axis])/direction[axis]
                entry = max(entry, min(first, second)); exit = min(exit, max(first, second))
                guard entry <= exit else { return nil }
            }
        }
        return exit >= 0 ? entry : nil
    }
    private static func finite(_ p: SIMD3<Float>) -> Bool { p.x.isFinite && p.y.isFinite && p.z.isFinite }
    private static func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
    private static func length(_ p: SIMD3<Float>) -> Float { sqrt(dot(p,p)) }
}
