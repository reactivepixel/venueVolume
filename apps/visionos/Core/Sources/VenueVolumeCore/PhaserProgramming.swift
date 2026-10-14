import Foundation

public enum DimmerPattern: String, CaseIterable, Sendable {
    case wave = "Wave", breathe = "Breathe", pulse = "Pulse"
    public func make(beatsPerMinute: Double = 120, measure: Double = 4) -> Phaser {
        Phaser(steps: [.init(values: [0: 0], curve: .sine), .init(values: [0: 255], curve: .sine)], beatsPerMinute: beatsPerMinute,
               measure: measure, phaseSpreadDegrees: self == .wave ? 360 : 0, transition: self == .pulse ? 0 : 1)
    }
}

public struct TapTempo: Sendable {
    private var taps: [Double] = []
    public init() {}
    /// Average recent intervals. A pause or non-monotonic time starts a fresh series.
    public mutating func tap(at seconds: Double) -> Double? {
        guard seconds.isFinite else { return nil }
        if let last = taps.last, seconds <= last || seconds - last > 2 { taps = [] }
        taps.append(seconds); taps = Array(taps.suffix(6))
        guard taps.count >= 2, let first = taps.first, let last = taps.last else { return nil }
        return min(600, max(1, 60 * Double(taps.count - 1) / (last - first)))
    }
}

extension Phaser {
    /// Step count and cycle duration are independent. New steps repeat the last source.
    public mutating func resizeSteps(to proposed: Int) {
        let count = min(32, max(2, proposed))
        if count < steps.count { steps = Array(steps.prefix(count)) }
        else { while steps.count < count { steps.append(steps.last ?? .init(values: [:])) } }
    }
}
