import Foundation

/// A cue stores changes to fixture attributes. Unchanged attributes track from
/// earlier cues. Palette definitions and step sources are pinned at record time,
/// so editing a different cue cannot rewrite an already recorded look.
public struct CueLayer: Codable, Equatable, Sendable {
    public var palette: DMXPreset
    public var sources: [DMXPreset]
    public var channels: Set<Int>
    public var followsLibrary: Bool
    public init(palette: DMXPreset, sources: [DMXPreset], followsLibrary: Bool = false) {
        self.followsLibrary = followsLibrary
        self.palette = palette
        let ids = Set(palette.phaser?.steps.compactMap(\.paletteID) ?? [])
        self.sources = sources.filter { ids.contains($0.id) }
        channels = palette.channelMask
    }
}

public struct CueLook: Codable, Equatable, Sendable {
    public var base: [Int]
    public var layers: [CueLayer]
    public init(base: [Int], layers: [CueLayer] = []) { self.base = base; self.layers = layers }
    mutating func apply(_ layer: CueLayer) {
        for index in layers.indices { layers[index].channels.subtract(layer.channels) }
        layers.removeAll { $0.channels.isEmpty }
        layers.append(layer)
    }
}

public struct CueSheet: Codable, Equatable, Sendable {
    public static let numbers = 1...255
    public private(set) var current = 1
    public private(set) var baseline: [UUID: CueLook] = [:]
    public private(set) var changes: [Int: [UUID: [CueLayer]]] = [:]
    public init() {}
    public static func label(_ number: Int) -> String { String(format: "%02d", number) }
    public mutating func select(_ number: Int) { current = min(255, max(1, number)) }
    public func hasChanges(at number: Int) -> Bool { changes[number]?.isEmpty == false }

    /// Capture new fixtures once, before recording any attributes for them.
    public mutating func include(_ fixtures: [Fixture], palettes: [DMXPreset]) {
        for fixture in fixtures where baseline[fixture.id] == nil {
            var look = CueLook(base: fixture.channels)
            for palette in palettes where fixture.referencedPaletteIDs.contains(palette.id) {
                var layer = CueLayer(palette: palette, sources: palettes, followsLibrary: true)
                if let owners = fixture.channelPaletteIDs { layer.channels = Set(owners.filter { $0.value == palette.id }.keys) }
                if fixture.aimOverride != nil { layer.channels.subtract([4, 5]) }
                for joint in fixture.asset?.joints ?? [] where fixture.jointOverrides?[joint.id] != nil { layer.channels.remove(joint.channel) }
                if !layer.channels.isEmpty { look.apply(layer) }
            }
            baseline[fixture.id] = look
        }
    }
    public mutating func record(_ palette: DMXPreset, for ids: Set<UUID>, at number: Int? = nil, sources: [DMXPreset], linked: Bool = false) throws {
        let number = number ?? current
        guard Self.numbers.contains(number), !ids.isEmpty, ids.allSatisfy({ baseline[$0] != nil }) else { throw PresetError("Choose fixtures and a cue from 01–255.") }
        if let issue = palette.validationIssue ?? palette.referenceIssue(in: sources) { throw PresetError(issue) }
        let layer = CueLayer(palette: palette, sources: sources, followsLibrary: linked)
        for id in ids {
            var look = CueLook(base: [], layers: changes[number]?[id] ?? [])
            look.apply(layer)
            changes[number, default: [:]][id] = look.layers
        }
    }
    /// Only an explicit library update propagates through linked recalls and
    /// step sources. Cue-local edits never call this operation.
    public mutating func updateLibrary(_ palette: DMXPreset) {
        func refresh(_ layers: [CueLayer]) -> [CueLayer] {
            layers.compactMap { original in
                var layer = original
                if layer.followsLibrary && layer.palette.id == palette.id { layer.palette = palette; layer.channels.formIntersection(palette.channelMask) }
                layer.sources = layer.sources.map { $0.id == palette.id ? palette : $0 }
                return layer.channels.isEmpty ? nil : layer
            }
        }
        baseline = baseline.mapValues { original in var look = original; look.layers = refresh(look.layers); return look }
        changes = changes.mapValues { $0.mapValues(refresh) }
    }
    public func look(for id: UUID, at number: Int? = nil) -> CueLook? {
        guard var look = baseline[id] else { return nil }
        for cue in changes.keys.sorted() where cue <= (number ?? current) {
            for layer in changes[cue]?[id] ?? [] { look.apply(layer) }
        }
        return look
    }
    public func sample(_ id: UUID, at seconds: Double, order: [UUID]) -> [Int]? {
        guard let look = look(for: id) else { return nil }
        var channels = look.base
        for layer in look.layers {
            // The same recorded palette shares fixture distribution even when
            // another attribute layer has been edited on one of its fixtures.
            let members = order.filter { member in
                self.look(for: member)?.layers.contains { $0.palette == layer.palette && $0.sources == layer.sources && !$0.channels.isDisjoint(with: layer.channels) } == true
            }
            let sample = layer.palette.sampledChannels(at: seconds, fixtureIndex: members.firstIndex(of: id) ?? 0, fixtureCount: max(1, members.count), palettes: layer.sources)
            for channel in layer.channels where channels.indices.contains(channel) && sample.indices.contains(channel) { channels[channel] = sample[channel] }
        }
        return channels
    }
    public func validate() throws {
        guard Self.numbers.contains(current), changes.keys.allSatisfy(Self.numbers.contains), changes.values.allSatisfy({ Set($0.keys).isSubset(of: Set(baseline.keys)) }) else { throw PresetError("Invalid cue sheet.") }
        for look in baseline.values {
            guard (1...16).contains(look.base.count), look.base.allSatisfy({ (0...255).contains($0) }) else { throw PresetError("Invalid cue fixture values.") }
        }
        let layers = baseline.values.flatMap(\.layers) + changes.values.flatMap { $0.values.flatMap { $0 } }
        for layer in layers {
            for source in layer.sources {
                if let issue = source.validationIssue { throw PresetError(issue) }
            }
            if let issue = layer.palette.validationIssue ?? layer.palette.referenceIssue(in: layer.sources) { throw PresetError(issue) }
            guard !layer.channels.isEmpty, layer.channels.isSubset(of: layer.palette.channelMask) else { throw PresetError("Invalid cue attributes.") }
        }
    }
}

/// One monotonic clock feeds both the flat diagram and actual fixture output.
public struct PalettePlayback: Equatable, Sendable {
    public private(set) var isPlaying = true
    private var origin: Double
    private var held = 0.0
    public init(now: Double) { origin = now }
    public func seconds(at now: Double) -> Double { isPlaying ? max(0, now - origin) : held }
    public mutating func setPlaying(_ playing: Bool, at now: Double) {
        guard playing != isPlaying else { return }
        if playing { origin = now - held } else { held = seconds(at: now) }
        isPlaying = playing
    }
}
