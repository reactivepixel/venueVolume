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

/// Snap in physical scene meters, with a wider release boundary to prevent
/// flicker between neighboring targets. Occluded fixtures are filtered by caller.
public enum PresetDropSnap {
    public struct Target: Equatable, Sendable {
        public let id: UUID
        public let center: SIMD3<Float>
        public let radius: Float
        public init(id: UUID, center: SIMD3<Float>, radius: Float) {
            self.id = id; self.center = center; self.radius = radius
        }
    }
    public static func target(cursor: SIMD3<Float>, rayOrigin: SIMD3<Float>?, rayPoint: SIMD3<Float>?,
                              targets: [Target], previous: UUID?) -> UUID? {
        guard finite(cursor) else { return nil }
        let ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)?
        if let origin = rayOrigin, let point = rayPoint, finite(origin), finite(point), length(point-origin) > 0.0001 {
            ray = (origin, (point-origin)/length(point-origin))
        } else { ray = nil }
        var matches: [(id: UUID, score: Float)] = []
        for target in targets where finite(target.center) && target.radius.isFinite {
            let extra: Float = target.id == previous ? 0.12 : 0
            let radius = max(0.08, min(target.radius, 0.6))
            let direct = length(cursor-target.center)
            var score: Float?
            if direct <= radius + 0.18 + extra { score = direct }
            if let ray {
                let delta = target.center-ray.origin
                let distance = dot(delta, ray.direction)
                let miss = length(delta-ray.direction*distance)
                // A small angular allowance allows relaxed indirect input. Do
                // not select behind the ray or beyond the supported room range.
                let tolerance = radius + min(distance*0.025, 0.16) + extra
                if distance >= 0, distance <= 60, miss <= tolerance {
                    let rayScore = 1 + distance + miss
                    score = min(score ?? rayScore, rayScore)
                }
            }
            if let score { matches.append((target.id, score)) }
        }
        let best = matches.min { a, b in a.score == b.score ? a.id.uuidString < b.id.uuidString : a.score < b.score }
        if let previous, let retained = matches.first(where: { $0.id == previous }),
           let best, best.score >= retained.score * 0.75 { return previous }
        return best?.id
    }
    private static func finite(_ p: SIMD3<Float>) -> Bool { p.x.isFinite && p.y.isFinite && p.z.isFinite }
    private static func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
    private static func length(_ p: SIMD3<Float>) -> Float { sqrt(dot(p,p)) }
}
