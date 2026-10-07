import Foundation

public struct DMXPreset: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var channels: [Int]
    public var phaser: Phaser?
    public var category: PaletteCategory?
    public var attributeIndices: [Int]?
    public var includedChannels: [Int]?
    public var focusTargetID: UUID?
    public var channelMask: Set<Int> { Set(includedChannels ?? Array(channels.indices)).intersection(Set(attributeIndices ?? Array(channels.indices))) }

    public init(id: UUID = UUID(), name: String, channels: [Int] = Array(repeating: 0, count: 16), phaser: Phaser? = nil, category: PaletteCategory? = nil, attributeIndices: [Int]? = nil, includedChannels: [Int]? = nil, focusTargetID: UUID? = nil) {
        self.id = id
        self.name = name
        self.channels = channels
        self.phaser = phaser
        self.category = category
        self.attributeIndices = attributeIndices
        self.includedChannels = includedChannels
        self.focusTargetID = focusTargetID
    }

    public var validationIssue: String? {
        if let includedChannels, includedChannels.contains(4) != includedChannels.contains(5) { return "Include Pan and Tilt together for Focus." }
        if let includedChannels, includedChannels.isEmpty || Set(includedChannels).count != includedChannels.count || !includedChannels.allSatisfy({ channels.indices.contains($0) }) { return "Choose valid included parameters." }
        if focusTargetID != nil && !Set([4, 5]).isSubset(of: channelMask) { return "Focus includes Pan and Tilt." }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Give this palette a name." }
        if !(1...16).contains(channels.count) { return "A palette needs 1–16 channels." }
        if channels.contains(where: { !(0...255).contains($0) }) { return "Channel values must be 0–255." }
        if let issue = phaser?.validationIssue { return issue }
        if let indices = attributeIndices, indices.isEmpty || indices.contains(where: { !channels.indices.contains($0) }) { return "Palette attributes must reference existing channels." }
        return nil
    }

    public var pool: PaletteCategory {
        category ?? PaletteCategory.allCases.first(where: { $0 != .all && channelMask.isSubset(of: Set($0.channelIndices)) }) ?? .all
    }
    public mutating func setPool(_ pool: PaletteCategory) {
        category = pool
        attributeIndices = pool.channelIndices.filter { channels.indices.contains($0) }
        includedChannels = nil
        if pool != .position && pool != .all { focusTargetID = nil }
        if var phaser {
            for index in phaser.steps.indices {
                phaser.steps[index].values = phaser.steps[index].values.filter { channelMask.contains($0.key) }
                phaser.steps[index].paletteID = nil
            }
            self.phaser = phaser
        }
    }
    public func referenceIssue(in palettes: [DMXPreset]) -> String? {
        for id in phaser?.steps.compactMap(\.paletteID) ?? [] {
            guard id != self.id, let source = palettes.first(where: { $0.id == id }), source.phaser == nil else { return "Each linked step needs an existing static palette." }
            guard channelMask.isSubset(of: source.channelMask) else { return "Step palettes must contain all of this phaser’s attributes." }
        }
        return nil
    }
    public func sampledChannels(at seconds: Double, fixtureIndex: Int = 0, fixtureCount: Int = 1, palettes: [DMXPreset] = []) -> [Int] {
        guard var phaser else { return channels }
        for index in phaser.steps.indices {
            guard let id = phaser.steps[index].paletteID,
                  let source = palettes.first(where: { $0.id == id && $0.phaser == nil }) else { continue }
            for channel in channelMask.intersection(source.channelMask) {
                phaser.steps[index].values[channel] = source.channels[channel]
            }
        }
        return phaser.sample(base: channels, seconds: seconds, fixtureIndex: fixtureIndex, fixtureCount: fixtureCount)
    }

    public func duplicated(name: String? = nil) -> DMXPreset {
        var copy = self
        copy.id = UUID()
        copy.name = name ?? "\(self.name) copy"
        return copy
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
        var references = result[index].channelPaletteIDs ?? Dictionary(uniqueKeysWithValues: result[index].channels.indices.compactMap { channel in
            result[index].presetID.map { (channel, $0) }
        })
        if preset.attributeIndices == nil && preset.includedChannels == nil { references.removeAll() }
        for channel in preset.channelMask { references[channel] = preset.id }
        result[index].channelPaletteIDs = references
        result[index].presetID = preset.id
        result[index].channels = mergedChannels(preset, existing: result[index].channels)
        result[index].preserveAimOverride()
        try validate(result)
        return result
    }

    public static func saving(_ preset: DMXPreset, fixtures: [Fixture]) throws -> [Fixture] {
        if let issue = preset.validationIssue { throw PresetError(issue) }
        var result = fixtures
        for index in result.indices where result[index].referencedPaletteIDs.contains(preset.id) {
            if let references = result[index].channelPaletteIDs {
                let sampled = preset.sampledChannels(at: 0)
                guard !references.contains(where: { $0.value == preset.id && (!sampled.indices.contains($0.key) || !preset.channelMask.contains($0.key)) }) else {
                    throw PresetError("This palette still owns excluded attributes. Save as new or reassign the fixtures before changing its pool.")
                }
                for (channel, owner) in references where owner == preset.id && result[index].channels.indices.contains(channel) && sampled.indices.contains(channel) {
                    result[index].channels[channel] = sampled[channel]
                }
            } else {
                result[index].channels = mergedChannels(preset, existing: result[index].channels)
                result[index].channelPaletteIDs = Dictionary(uniqueKeysWithValues: result[index].channels.indices.map { ($0, preset.id) })
            }
            result[index].preserveAimOverride()
        }
        try validate(result)
        return result
    }

    public static func clearing(_ presetID: UUID, fixtures: [Fixture]) -> [Fixture] {
        fixtures.map { original in
            var fixture = original
            if let references = fixture.channelPaletteIDs {
                for (channel, owner) in references where owner == presetID && fixture.channels.indices.contains(channel) { fixture.channels[channel] = 0 }
                fixture.channelPaletteIDs = references.filter { $0.value != presetID }
                if fixture.presetID == presetID { fixture.presetID = fixture.channelPaletteIDs?.sorted { $0.key < $1.key }.first?.value }
                fixture.preserveAimOverride()
            } else if fixture.presetID == presetID {
                fixture.presetID = nil
                fixture.channels = Array(repeating: 0, count: fixture.channels.count)
                fixture.preserveAimOverride()
            }
            return fixture
        }
    }

    public static func mergedChannels(_ palette: DMXPreset, existing: [Int], at seconds: Double = 0, fixtureIndex: Int = 0, fixtureCount: Int = 1, palettes: [DMXPreset] = []) -> [Int] {
        let output = palette.sampledChannels(at: seconds, fixtureIndex: fixtureIndex, fixtureCount: fixtureCount, palettes: palettes)
        guard palette.attributeIndices != nil || palette.includedChannels != nil else { return output }
        let attributes = palette.channelMask
        var result = Array((existing + Array(repeating: 0, count: output.count)).prefix(max(existing.count, output.count)))
        for index in attributes where output.indices.contains(index) { result[index] = output[index] }
        return result
    }

    /// Resolves simultaneous attribute palettes without erasing unrelated channels.
    public static func renderedChannels(for fixture: Fixture, palettes: [DMXPreset], at seconds: Double, fixtureIndex: Int = 0, fixtureCount: Int = 1) -> [Int] {
        guard let references = fixture.channelPaletteIDs else {
            guard let palette = palettes.first(where: { $0.id == fixture.presetID }) else { return fixture.channels }
            return mergedChannels(palette, existing: fixture.channels, at: seconds, fixtureIndex: fixtureIndex, fixtureCount: fixtureCount, palettes: palettes)
        }
        var channels = fixture.channels
        for paletteID in Set(references.values) {
            guard let palette = palettes.first(where: { $0.id == paletteID }) else { continue }
            let sample = palette.sampledChannels(at: seconds, fixtureIndex: fixtureIndex, fixtureCount: fixtureCount, palettes: palettes)
            for (channel, owner) in references where owner == paletteID && channels.indices.contains(channel) && sample.indices.contains(channel) { channels[channel] = sample[channel] }
        }
        return channels
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
