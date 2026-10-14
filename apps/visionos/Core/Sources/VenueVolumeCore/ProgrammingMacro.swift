import Foundation

public enum MacroTarget: Codable, Equatable, Hashable, Sendable {
    case currentSelection
    case group(UUID)
}

public struct MacroLine: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var paletteID: UUID?
    public var enabled: Bool
    public init(id: UUID = UUID(), paletteID: UUID? = nil, enabled: Bool = true) {
        self.id = id; self.paletteID = paletteID; self.enabled = enabled
    }
}

/// A bounded, inspectable sequence of saved-palette recalls, not a console CLI.
public struct ProgrammingMacro: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var target: MacroTarget
    public var lines: [MacroLine]
    public init(id: UUID = UUID(), name: String, target: MacroTarget = .currentSelection, lines: [MacroLine] = [.init()]) {
        self.id = id; self.name = name; self.target = target; self.lines = lines
    }
    public var validationIssue: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Name this macro." }
        if name.count > 120 { return "Use a name with at most 120 characters." }
        if !(1...32).contains(lines.count) { return "A macro needs 1–32 action rows." }
        if Set(lines.map(\.id)).count != lines.count { return "Action row identifiers must be unique." }
        if !lines.contains(where: \.enabled) { return "Enable at least one action." }
        if lines.contains(where: { $0.enabled && $0.paletteID == nil }) { return "Choose a saved palette for every enabled action." }
        return nil
    }
    public func plan(selection: Set<UUID>, groups: [UUID: Set<UUID>], fixtures: [Fixture], palettes: [DMXPreset]) throws -> MacroPlan {
        if let issue = validationIssue { throw PresetError(issue) }
        let targetIDs: Set<UUID>
        switch target {
        case .currentSelection: targetIDs = selection
        case .group(let id):
            guard let members = groups[id] else { throw PresetError("The target group is missing. Choose another group.") }
            targetIDs = members
        }
        guard !targetIDs.isEmpty else { throw PresetError("Select fixtures or choose a group with placed fixtures.") }
        guard targetIDs.isSubset(of: Set(fixtures.map(\.id))) else { throw PresetError("Some target fixtures are no longer in this room.") }
        let resolved = try lines.filter(\.enabled).map { line -> DMXPreset in
            guard let palette = palettes.first(where: { $0.id == line.paletteID }) else { throw PresetError("A palette is missing. Repair the macro before running it.") }
            if let issue = palette.referenceIssue(in: palettes) { throw PresetError(issue) }
            return palette
        }
        // Validate the entire result before publishing any live mutation.
        var next = fixtures
        for palette in resolved {
            for fixture in fixtures where targetIDs.contains(fixture.id) {
                next = try PresetOperations.applying(palette, to: fixture.id, fixtures: next)
            }
        }
        return MacroPlan(targetIDs: targetIDs, palettes: resolved, fixtures: next)
    }
    public static var starters: [ProgrammingMacro] {
        let palettes = PaletteLibrary.baseline
        func id(_ name: String) -> UUID? { palettes.first { $0.name == name }?.id }
        return [
            .init(id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!, name: "Full warm wash", lines: [.init(paletteID: id("Intensity · Full")), .init(paletteID: id("Color · Warm")), .init(paletteID: id("Beam · Wash"))]),
            .init(id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!, name: "Cool breathing wash", lines: [.init(paletteID: id("Color · Blue")), .init(paletteID: id("Phaser · Dimmer breathe"))])
        ]
    }
}

public struct MacroPlan: Sendable {
    public let targetIDs: Set<UUID>
    public let palettes: [DMXPreset]
    public let fixtures: [Fixture]
}
