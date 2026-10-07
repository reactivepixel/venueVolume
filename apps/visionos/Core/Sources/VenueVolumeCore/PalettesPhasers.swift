import Foundation

public enum PaletteCategory: String, Codable, CaseIterable, Sendable {
    case intensity, color, position, beam, all
    public var label: String { self == .intensity ? "Dimmer" : rawValue.capitalized }
    public var channelIndices: [Int] {
        switch self { case .intensity: [0]; case .color: [1,2,3]; case .position: [4,5]; case .beam: [6]; case .all: Array(0..<16) }
    }
}

/// Independent attribute values per step; absent attributes retain the base palette.
public struct PhaserStep: Codable, Equatable, Sendable {
    public var values: [Int: Int]
    public var width: Double
    public var paletteID: UUID?
    public init(values: [Int: Int], width: Double = 1, paletteID: UUID? = nil) { self.values = values; self.width = width; self.paletteID = paletteID }
}

/// Console-inspired cyclic steps, measured in beats, with fixture phase distribution.
public struct Phaser: Codable, Equatable, Sendable {
    public var steps: [PhaserStep]
    public var beatsPerMinute: Double
    public var measure: Double
    public var phaseDegrees: Double
    public var phaseSpreadDegrees: Double
    public var transition: Double
    public init(steps: [PhaserStep], beatsPerMinute: Double = 60, measure: Double = 1,
                phaseDegrees: Double = 0, phaseSpreadDegrees: Double = 0, transition: Double = 1) {
        self.steps = steps; self.beatsPerMinute = beatsPerMinute; self.measure = measure
        self.phaseDegrees = phaseDegrees; self.phaseSpreadDegrees = phaseSpreadDegrees; self.transition = transition
    }
    public var validationIssue: String? {
        guard (2...32).contains(steps.count) else { return "A phaser needs 2–32 steps." }
        guard beatsPerMinute.isFinite, beatsPerMinute > 0, beatsPerMinute <= 600,
              measure.isFinite, measure > 0, measure <= 64,
              phaseDegrees.isFinite, abs(phaseDegrees) <= 360_000, phaseSpreadDegrees.isFinite, abs(phaseSpreadDegrees) <= 360_000,
              transition.isFinite, (0...1).contains(transition) else { return "Check phaser speed, measure, phase and transition." }
        guard steps.allSatisfy({ $0.width.isFinite && $0.width > 0 && $0.width <= 64 && $0.values.allSatisfy { (0..<16).contains($0.key) && (0...255).contains($0.value) } }) else { return "Check phaser step widths and channel values." }
        return nil
    }
    public func sample(base: [Int], seconds: Double, fixtureIndex: Int = 0, fixtureCount: Int = 1) -> [Int] {
        guard validationIssue == nil, seconds.isFinite else { return base }
        let spread = fixtureCount > 1 ? Double(fixtureIndex) / Double(fixtureCount) * phaseSpreadDegrees : 0
        let cycles = seconds * beatsPerMinute / (60 * measure) + (phaseDegrees + spread) / 360
        let unit = cycles - floor(cycles)
        let total = steps.reduce(0) { $0 + $1.width }
        var cursor = unit * total
        var index = 0
        while index < steps.count - 1 && cursor >= steps[index].width { cursor -= steps[index].width; index += 1 }
        let current = steps[index], next = steps[(index + 1) % steps.count]
        let fraction = cursor / current.width
        let blend = transition == 0 ? 0 : max(0, min(1, (fraction - (1 - transition)) / transition))
        return base.enumerated().map { channel, original in
            let from = current.values[channel] ?? original
            let to = next.values[channel] ?? original
            return Int((Double(from) + Double(to - from) * blend).rounded())
        }
    }
}

public enum PaletteLibrary {
    /// Portable setups retain the static sources used by assigned phasers.
    public static func dependencies(for fixtures: [Fixture], in palettes: [DMXPreset]) -> [DMXPreset] {
        var ids = Set(fixtures.flatMap { $0.referencedPaletteIDs })
        for palette in palettes where ids.contains(palette.id) { ids.formUnion(palette.phaser?.steps.compactMap(\.paletteID) ?? []) }
        return palettes.filter { ids.contains($0.id) }
    }

    private static func palette(_ number: Int, _ name: String, _ category: PaletteCategory, _ values: [Int: Int], phaser: Phaser? = nil) -> DMXPreset {
        var channels = [255, 255, 255, 255, 128, 128, 128] + Array(repeating: 0, count: 9)
        for (index, value) in values { channels[index] = value }
        return DMXPreset(id: UUID(uuidString: String(format: "30000000-0000-0000-0000-%012d", number))!, name: name,
                         channels: channels, phaser: phaser, category: category, attributeIndices: category == .all ? Array(0..<16) : values.keys.sorted())
    }
    /// The three complete looks replace the legacy preview presets. Attribute palettes
    /// below layer over these foundations; phasers own only their animated attributes.
    public static let baseline: [DMXPreset] = [
        palette(101, "All · Warm room wash", .all, [0: 210, 1: 255, 2: 170, 3: 95, 4: 128, 5: 145, 6: 200]),
        palette(102, "All · Blue focus", .all, [0: 255, 1: 45, 2: 115, 3: 255, 4: 128, 5: 145, 6: 125]),
        palette(103, "All · White work light", .all, [0: 180, 1: 255, 2: 255, 3: 255, 4: 128, 5: 128, 6: 240]),
        palette(1, "Intensity · Full", .intensity, [0: 255]),
        palette(4, "Color · White", .color, [1: 255, 2: 255, 3: 255]),
        palette(5, "Color · Warm", .color, [1: 255, 2: 170, 3: 95]),
        palette(6, "Color · Red", .color, [1: 255, 2: 0, 3: 0]),
        palette(7, "Color · Blue", .color, [1: 0, 2: 60, 3: 255]),
        palette(8, "Position · Center", .position, [4: 128, 5: 128]),
        palette(9, "Beam · Narrow", .beam, [6: 0]),
        palette(10, "Beam · Wash", .beam, [6: 220]),
        palette(11, "Phaser · Dimmer chase", .intensity, [0: 255], phaser: Phaser(steps: [.init(values: [0: 255]), .init(values: [0: 0])], phaseSpreadDegrees: 360, transition: 0)),
        palette(12, "Phaser · Dimmer breathe", .intensity, [0: 255], phaser: Phaser(steps: [.init(values: [0: 32]), .init(values: [0: 255])], beatsPerMinute: 30)),
        palette(13, "Phaser · Red / blue", .color, [1: 255, 2: 0, 3: 0], phaser: Phaser(steps: [.init(values: [1: 255, 2: 0, 3: 0]), .init(values: [1: 0, 2: 60, 3: 255])], transition: 0)),
        palette(15, "Phaser · Circle", .position, [4: 128, 5: 128], phaser: Phaser(steps: [.init(values: [4: 128, 5: 80]), .init(values: [4: 180, 5: 128]), .init(values: [4: 128, 5: 180]), .init(values: [4: 80, 5: 128])], beatsPerMinute: 20))
    ]
}
