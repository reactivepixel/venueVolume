import Foundation

public struct DMXPreset: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var channels: [Int]

    public init(id: UUID = UUID(), name: String, channels: [Int] = Array(repeating: 0, count: 16)) {
        self.id = id
        self.name = name
        self.channels = channels
    }

    public var validationIssue: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Give this preset a name." }
        if !(1...16).contains(channels.count) { return "A preset needs 1–16 channels." }
        if channels.contains(where: { !(0...255).contains($0) }) { return "Channel values must be 0–255." }
        return nil
    }

    public var dragToken: String { "venue-volume:preset:\(id.uuidString)" }
    public static func id(from token: String) -> UUID? {
        let prefix = "venue-volume:preset:"
        guard token.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(token.dropFirst(prefix.count)))
    }

    public static let examples = [
        DMXPreset(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Warm Wash",
                  channels: [255, 212, 180, 255, 36, 0, 118, 0, 64, 32, 0, 0, 0, 0, 0, 0]),
        DMXPreset(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, name: "Cool Beam",
                  channels: [196, 24, 232, 0, 145, 12, 90, 255, 0, 0, 0, 0, 0, 0, 0, 0]),
        DMXPreset(id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!, name: "Blackout")
    ]
}

public enum ToolboxItem: Hashable, Codable, Sendable {
    case addFixture, presets, sync
    case fixture(UUID), preset(UUID)
}

public struct RecentItems: Codable, Equatable, Sendable {
    public private(set) var items: [ToolboxItem] = []
    public init() {}
    public mutating func use(_ item: ToolboxItem) {
        items.removeAll { $0 == item }
        items.insert(item, at: 0)
        items = Array(items.prefix(10))
    }
    public mutating func remove(_ item: ToolboxItem) { items.removeAll { $0 == item } }
}

public struct PresetError: LocalizedError, Equatable, Sendable {
    public let message: String
    public var errorDescription: String? { message }
    public init(_ message: String) { self.message = message }
}

/// Builds a complete candidate snapshot before accepting any assignment or save.
/// Patch identity stays with each fixture; presets own channel count and values.
public enum PresetOperations {
    public static func applying(_ preset: DMXPreset, to id: UUID, fixtures: [Fixture]) throws -> [Fixture] {
        guard let index = fixtures.firstIndex(where: { $0.id == id }) else { throw PresetError("The object no longer exists.") }
        if let issue = preset.validationIssue { throw PresetError(issue) }
        var result = fixtures
        result[index].presetID = preset.id
        result[index].channels = preset.channels
        result[index].preserveAimOverride()
        try validate(result)
        return result
    }

    public static func saving(_ preset: DMXPreset, fixtures: [Fixture]) throws -> [Fixture] {
        if let issue = preset.validationIssue { throw PresetError(issue) }
        var result = fixtures
        for index in result.indices where result[index].presetID == preset.id {
            result[index].channels = preset.channels
            result[index].preserveAimOverride()
        }
        try validate(result)
        return result
    }

    public static func clearing(_ presetID: UUID, fixtures: [Fixture]) -> [Fixture] {
        fixtures.map { original in
            var fixture = original
            if fixture.presetID == presetID {
                fixture.presetID = nil
                fixture.channels = Array(repeating: 0, count: fixture.channels.count)
                fixture.preserveAimOverride()
            }
            return fixture
        }
    }

    private static func validate(_ fixtures: [Fixture]) throws {
        for fixture in fixtures {
            if let issue = fixture.validationIssue(among: fixtures) { throw PresetError(issue) }
        }
    }
}

/// Debounces the physical palm pose. A brief tracking gap doesn't flash the pane.
public struct PalmRevealGate: Sendable {
    public private(set) var isVisible = false
    private var eligibleSince: Double?
    private var lastEligible: Double?
    public init() {}
    public mutating func update(eligible: Bool, now: Double) -> Bool {
        if eligible {
            if eligibleSince == nil { eligibleSince = now }
            lastEligible = now
            if now - (eligibleSince ?? now) >= 0.25 { isVisible = true }
        } else {
            eligibleSince = nil
            if now - (lastEligible ?? -10) >= 0.8 { isVisible = false }
        }
        return isVisible
    }
}
