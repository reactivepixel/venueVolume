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
