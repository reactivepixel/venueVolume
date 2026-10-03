import Foundation

/// Policy, not a measured device capacity. Every granted beam keeps real shadows.
public enum LightingBudget {
    public enum Thermal: String, Codable, Sendable { case nominal, fair, serious, critical }
    public static let options = [0, 1, 2, 4, 8, 16, 32, 64]
    public static func effective(requested: Int, extendedHardware: Bool, thermal: Thermal) -> Int {
        let limit = min(max(0, requested), extendedHardware ? 64 : 8)
        switch thermal {
        case .nominal: return limit
        case .fair: return min(limit, 16)
        case .serious: return min(limit, 4)
        case .critical: return 0
        }
    }
    public struct Demand: Sendable {
        public var id: UUID
        public var emitters: Int
        public var emitting: Bool
        public init(id: UUID, emitters: Int, emitting: Bool) {
            self.id = id; self.emitters = emitters; self.emitting = emitting
        }
    }
    public static func allocate(_ demands: [Demand], selected: UUID?, limit: Int) -> [UUID: Int] {
        var remaining = max(0, min(64, limit)), result: [UUID: Int] = [:]
        let ordered = demands.filter { $0.id == selected } + demands.filter { $0.id != selected }
        for demand in ordered where demand.emitting && demand.emitters > 0 && remaining > 0 {
            let count = min(remaining, demand.emitters)
            result[demand.id] = count
            remaining -= count
        }
        return result
    }
}

/// Isolated launch-time test: same 64 single-emitter rigs for every room/light count.
public struct LightingBenchmark: Equatable, Sendable {
    public let roomID: String
    public let lights: Int
    public let seconds: Double
    public let moving: Bool
    public init?(arguments: [String]) {
        func value(_ prefix: String) -> String? { arguments.first { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) } }
        guard let room = value("--lighting-benchmark="), ["baseline", "mappedRoom"].contains(room) else { return nil }
        guard let count = Int(value("--benchmark-lights=") ?? "8"), LightingBudget.options.contains(count),
              let duration = Double(value("--benchmark-seconds=") ?? "30"), duration.isFinite, (5...300).contains(duration) else { return nil }
        roomID = room == "baseline" ? "img3153-classroom-v1" : "mappedRoom"
        lights = count; seconds = duration; moving = arguments.contains("--benchmark-motion")
    }
    public func fixtures() -> [Fixture] {
        (0..<64).map { i in
            let color = [[255,40,25], [25,255,40], [35,65,255]][i % 3]
            // Dense fixed grid deliberately includes furniture overlap as a stress case.
            // Never saved as an authored lighting plan.
            return Fixture(id: UUID(uuidString: String(format: "30000000-0000-0000-0000-%012d", i+1))!,
                           name: "Benchmark \(i+1)", assetID: LightingPreview.assetID,
                           universe: 1+i/32, startAddress: 1+(i%32)*16,
                           channels: [100] + color + [128,158,220] + Array(repeating: 0, count: 9),
                           position: .init(x: 0.7+Float(i%8)*0.82, y: 0, z: -0.7-Float(i/8)*0.9), surfaceID: "floor")
        }
    }
}

/// SceneEvents.Update cadence is a CPU-side diagnostic, NOT displayed FPS or GPU time.
public struct SceneCadence: Sendable {
    private var values: [Double] = []
    public init() { values.reserveCapacity(40_000) }
    public mutating func append(seconds: Double) {
        guard seconds.isFinite, seconds > 0, values.count < 40_000 else { return }
        values.append(seconds * 1_000)
    }
    public struct Summary: Codable, Sendable {
        public let samples: Int
        public let meanMS: Double
        public let p95MS: Double
        public let p99MS: Double
        public let maximumMS: Double
        public let intervalsOver16_67MS: Int
    }
    public var summary: Summary? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        func percentile(_ fraction: Double) -> Double { sorted[max(0, Int(ceil(Double(sorted.count)*fraction))-1)] }
        return .init(samples: values.count, meanMS: values.reduce(0,+)/Double(values.count), p95MS: percentile(0.95),
                     p99MS: percentile(0.99), maximumMS: sorted.last!, intervalsOver16_67MS: values.filter { $0 > 16.67 }.count)
    }
}
