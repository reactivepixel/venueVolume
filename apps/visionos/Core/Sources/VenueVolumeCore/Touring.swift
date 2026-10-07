import Foundation

public struct InventoryUnit: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID { fixture.id }
    public var fixture: Fixture
    public var groupID: UUID?
    public var unavailable = false
    public init(fixture: Fixture, groupID: UUID? = nil) { self.fixture = fixture; self.groupID = groupID }
}
public struct EquipmentQuantity: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var quantity: Int
    public init(name: String, quantity: Int) { self.name = name; self.quantity = quantity }
}
public struct FixtureGroup: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var parentID: UUID?
    public init(name: String, parentID: UUID? = nil) { self.name = name; self.parentID = parentID }
}
public struct FocusTarget: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public init(name: String) { self.name = name }
}
public struct TourConfiguration: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var unitIDs: Set<UUID>
    public var layout: [Fixture] = []
    public init(name: String, unitIDs: Set<UUID> = []) { self.name = name; self.unitIDs = unitIDs }
}
/// Each included channel retains the preset identity that owns its value.
public struct TourProgramming: Codable, Equatable, Sendable {
    public var groups: [UUID: [Int: UUID]] = [:]
    public var units: [UUID: [Int: UUID]] = [:]
    /// Venue reset suppresses an inherited show-level individual exception.
    public var releasedUnits: [UUID: Set<Int>] = [:]
    public init() {}
}
public struct TouringShow: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion = 1
    public var id = UUID()
    public var revision = 1
    public var name: String
    public var units: [InventoryUnit] = []
    public var quantities: [EquipmentQuantity] = []
    public var groups: [FixtureGroup] = []
    public var presets: [DMXPreset]
    public var targets: [FocusTarget] = []
    public var configurations = [TourConfiguration(name: "Tour rig")]
    public var programming = TourProgramming()
    public init(name: String, presets: [DMXPreset] = []) { self.name = name; self.presets = presets }
    public func ancestors(of id: UUID?) -> [UUID] {
        var result: [UUID] = []; var next = id
        while let current = next, !result.contains(current) {
            result.append(current); next = groups.first { $0.id == current }?.parentID
        }
        return result
    }
    public func members(of groupID: UUID?) -> Set<UUID> {
        Set(units.filter { groupID == nil || ancestors(of: $0.groupID).contains(groupID!) }.map(\.id))
    }
    public func validate() throws {
        guard schemaVersion == 1, revision > 0, revision < Int.max, Self.validName(name), units.count <= 256,
              presets.count <= 64, groups.count <= 128, targets.count <= 64,
              !configurations.isEmpty, configurations.count <= 32,
              Set(units.map(\.id)).count == units.count, Set(groups.map(\.id)).count == groups.count,
              Set(presets.map(\.id)).count == presets.count, Set(targets.map(\.id)).count == targets.count,
              Set(configurations.map(\.id)).count == configurations.count,
              Set(quantities.map(\.id)).count == quantities.count,
              quantities.count <= 256, quantities.allSatisfy({ Self.validName($0.name) && (1...100_000).contains($0.quantity) }) else {
            throw PresetError("Invalid show identity, name or inventory limits.")
        }
        let ids = Set(units.map(\.id)); let groupIDs = Set(groups.map(\.id))
        for group in groups {
            guard Self.validName(group.name), group.parentID != group.id,
                  group.parentID == nil || groupIDs.contains(group.parentID!),
                  !ancestors(of: group.parentID).contains(group.id) else { throw PresetError("Groups need valid parents and cannot contain cycles.") }
        }
        for unit in units {
            guard unit.groupID == nil || groupIDs.contains(unit.groupID!),
                  unit.fixture.assetID == nil || unit.fixture.asset != nil else { throw PresetError("Inventory references missing groups or fixture models.") }
            // Preferred patches may conflict; only placed, resolved patches must be unique.
            if let issue = unit.fixture.validationIssue(among: [unit.fixture]) { throw PresetError(issue) }
        }
        for config in configurations {
            guard Self.validName(config.name), config.unitIDs.isSubset(of: ids),
                  Set(config.layout.map(\.id)).count == config.layout.count,
                  Set(config.layout.map(\.id)).isSubset(of: config.unitIDs) else { throw PresetError("Configuration references missing or duplicate units.") }
            for fixture in config.layout {
                guard let unit = units.first(where: { $0.id == fixture.id }), unit.fixture.assetID == fixture.assetID, unit.fixture.channels.count == fixture.channels.count else { throw PresetError("Configuration layout changed an equipment model or footprint.") }
                if let issue = fixture.validationIssue(among: config.layout) { throw PresetError(issue) }
            }
        }
        for preset in presets {
            if let issue = preset.validationIssue ?? preset.referenceIssue(in: presets) { throw PresetError(issue) }
            if let id = preset.focusTargetID, !targets.contains(where: { $0.id == id }) { throw PresetError("Preset references a missing focus target.") }
        }
        guard targets.allSatisfy({ Self.validName($0.name) }) else { throw PresetError("Name each focus target.") }
        try Touring.validate(programming, unitIDs: ids, groupIDs: groupIDs, presets: presets)
    }
    public static func validName(_ name: String) -> Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 120 }
}

/// A pinned copy makes saved venues independent of later show-library edits.
public struct TourSession: Codable, Equatable, Sendable {
    public var show: TouringShow
    public var configurationID: UUID
    public var localUnits: [InventoryUnit] = []
    public var excluded: Set<UUID> = []
    public var programming = TourProgramming()
    public var presetOverrides: [DMXPreset] = []
    public var targetLocations: [UUID: Position3D] = [:]
    public init(show: TouringShow, configurationID: UUID? = nil) {
        self.show = show; self.configurationID = configurationID ?? show.configurations[0].id
    }
    public var configuration: TourConfiguration? { show.configurations.first { $0.id == configurationID } }
    public var allUnits: [InventoryUnit] { show.units + localUnits }
    public var activeUnits: [InventoryUnit] { allUnits.filter { eligibleIDs.contains($0.id) } }
    public var presets: [DMXPreset] { show.presets.map { p in presetOverrides.first { $0.id == p.id } ?? p } + presetOverrides.filter { p in !show.presets.contains { $0.id == p.id } } }
    public var eligibleIDs: Set<UUID> { (configuration?.unitIDs ?? []).union(localUnits.map(\.id)).subtracting(excluded) }
    public func members(of groupID: UUID?) -> Set<UUID> {
        Set(allUnits.filter { groupID == nil || show.ancestors(of: $0.groupID).contains(groupID!) }.map(\.id)).intersection(eligibleIDs)
    }
    public func binding(for unit: InventoryUnit, channel: Int) -> UUID? {
        if let id = programming.units[unit.id]?[channel] { return id }
        if programming.releasedUnits[unit.id]?.contains(channel) != true, let id = show.programming.units[unit.id]?[channel] { return id }
        for group in show.ancestors(of: unit.groupID) {
            if let id = programming.groups[group]?[channel] ?? show.programming.groups[group]?[channel] { return id }
        }
        return nil
    }
    public func validate(fixtures: [Fixture] = []) throws {
        try show.validate()
        let unitIDs = Set(allUnits.map(\.id)); let groups = Set(show.groups.map(\.id))
        guard configuration != nil, allUnits.count <= 256, unitIDs.count == allUnits.count,
              excluded.isSubset(of: unitIDs), Set(fixtures.map(\.id)).isSubset(of: eligibleIDs), fixtures.count <= 64,
              Set(fixtures.map(\.id)).count == fixtures.count,
              Set(presetOverrides.map(\.id)).count == presetOverrides.count,
              presets.count <= 64 else { throw PresetError("Venue inventory or configuration is invalid.") }
        for unit in localUnits {
            guard unit.groupID == nil || groups.contains(unit.groupID!), unit.fixture.assetID == nil || unit.fixture.asset != nil else { throw PresetError("Invalid venue equipment.") }
            if let issue = unit.fixture.validationIssue(among: [unit.fixture]) { throw PresetError(issue) }
        }
        for preset in presetOverrides {
            if let issue = preset.validationIssue ?? preset.referenceIssue(in: presets) { throw PresetError(issue) }
            if let id = preset.focusTargetID, !show.targets.contains(where: { $0.id == id }) { throw PresetError("Missing show focus target.") }
        }
        for (id, point) in targetLocations {
            guard show.targets.contains(where: { $0.id == id }), [point.x, point.y, point.z].allSatisfy(\.isFinite) else { throw PresetError("Invalid focus location.") }
        }
        try Touring.validate(programming, unitIDs: unitIDs, groupIDs: groups, presets: presets)
        for unit in activeUnits {
            let pan = binding(for: unit, channel: 4), tilt = binding(for: unit, channel: 5)
            if presets.contains(where: { ($0.id == pan || $0.id == tilt) && $0.focusTargetID != nil }), pan != tilt {
                throw PresetError("\(unit.fixture.name): named focus requires matching Pan and Tilt assignments.")
            }
            for channel in unit.fixture.channels.indices {
                if let id = binding(for: unit, channel: channel) {
                    guard let preset = presets.first(where: { $0.id == id }), Touring.compatible(preset, with: unit.fixture) else {
                        throw PresetError("\(unit.fixture.name) is incompatible with inherited programming.")
                    }
                }
            }
        }
        for fixture in fixtures {
            guard let unit = allUnits.first(where: { $0.id == fixture.id }), !unit.unavailable, unit.fixture.assetID == fixture.assetID,
                  unit.fixture.channels.count == fixture.channels.count else { throw PresetError("Placement changed the inventory model or footprint.") }
            if let issue = fixture.validationIssue(among: fixtures) { throw PresetError(issue) }
        }
    }
}

public enum Touring {
    public static func validate(_ programming: TourProgramming, unitIDs: Set<UUID>, groupIDs: Set<UUID>, presets: [DMXPreset]) throws {
        guard Set(programming.units.keys).isSubset(of: unitIDs), Set(programming.groups.keys).isSubset(of: groupIDs),
              Set(programming.releasedUnits.keys).isSubset(of: unitIDs),
              programming.releasedUnits.values.allSatisfy({ $0.allSatisfy { (0..<16).contains($0) } }) else { throw PresetError("Programming references missing equipment or groups.") }
        for bindings in Array(programming.units.values) + Array(programming.groups.values) {
            for (channel, id) in bindings {
                guard let preset = presets.first(where: { $0.id == id }), preset.channelMask.contains(channel) else { throw PresetError("A preset assignment references an excluded or missing parameter.") }
            }
        }
    }
    public static func compatible(_ preset: DMXPreset, with fixture: Fixture) -> Bool {
        guard preset.channelMask.allSatisfy({ fixture.channels.indices.contains($0) }) else { return false }
        guard preset.includedChannels != nil || preset.focusTargetID != nil else { return true } // Preserve legacy full-frame looks.
        for channel in preset.channelMask {
            if channel == 4 || channel == 5 {
                guard fixture.asset?.joints.contains(where: { $0.channel == channel }) == true else { return false }
            } else if [0,1,2,3,6].contains(channel), let asset = fixture.asset, asset.emitters.isEmpty { return false }
        }
        return preset.focusTargetID == nil || fixture.asset?.headAim == true
    }
    public static func resolved(_ original: Fixture, in session: TourSession, solveFocus: Bool = false) throws -> Fixture {
        guard let unit = session.allUnits.first(where: { $0.id == original.id }) else { throw PresetError("Fixture is not in this inventory.") }
        var result = original
        result.channels = unit.fixture.channels
        result.presetID = nil
        var focusID: UUID?
        for channel in result.channels.indices {
            guard let id = session.binding(for: unit, channel: channel) else { continue }
            guard let preset = session.presets.first(where: { $0.id == id }), compatible(preset, with: original) else { throw PresetError("\(unit.fixture.name) is incompatible with its preset.") }
            result.channels[channel] = preset.channels[channel]
            result.presetID = id
            if channel == 4 || channel == 5 { focusID = preset.focusTargetID }
        }
        if focusID != nil, !solveFocus {
            result.channels[4] = original.channels[4]; result.channels[5] = original.channels[5]
        }
        result.preserveAimOverride()
        if solveFocus, let focusID {
            guard let target = session.targetLocations[focusID] else { throw PresetError("Locate the focus target in this venue first.") }
            let aim = try FixtureAiming.articulated(result, target: target)
            result.aimOverride = nil; result.jointOverrides?.removeValue(forKey: "pan"); result.jointOverrides?.removeValue(forKey: "tilt")
            result.channels[4] = aim.pan; result.channels[5] = aim.tilt
        }
        return result
    }
    /// No caller-visible mutation until every target and resulting assignment validates.
    public static func applying(_ presetID: UUID, to ids: Set<UUID>, group: UUID? = nil,
                                replaceDescendants: Bool = false, in session: TourSession, fixtures: [Fixture]) throws -> (TourSession, [Fixture]) {
        guard !ids.isEmpty, ids.isSubset(of: session.eligibleIDs), let preset = session.presets.first(where: { $0.id == presetID }) else { throw PresetError("Choose a preset and at least one inventory unit.") }
        if let group { guard session.show.groups.contains(where: { $0.id == group }), ids == session.members(of: group) else { throw PresetError("The group membership changed; select it again.") } }
        let incompatible = session.allUnits.filter { ids.contains($0.id) && !compatible(preset, with: $0.fixture) }.map { $0.fixture.name }
        guard incompatible.isEmpty else { throw PresetError("Incompatible fixtures: " + incompatible.joined(separator: ", ")) }
        var result = session
        if let group {
            for channel in preset.channelMask { result.programming.groups[group, default: [:]][channel] = presetID }
            if replaceDescendants {
                // Replace child defaults and release individual exceptions only
                // for included parameters. Future members inherit this default too.
                for child in result.show.groups where result.show.ancestors(of: child.id).contains(group) {
                    for channel in preset.channelMask { result.programming.groups[child.id, default: [:]][channel] = presetID }
                }
                for id in ids {
                    for channel in preset.channelMask {
                        result.programming.units[id]?.removeValue(forKey: channel)
                        result.programming.releasedUnits[id, default: []].insert(channel)
                    }
                }
            }
        } else {
            for id in ids { for channel in preset.channelMask { result.programming.units[id, default: [:]][channel] = presetID } }
        }
        var updated = fixtures
        for index in updated.indices where ids.contains(updated[index].id) {
            if preset.channelMask.contains(4), let unit = result.allUnits.first(where: { $0.id == updated[index].id }), result.binding(for: unit, channel: 4) == preset.id {
                updated[index].aimOverride = nil; updated[index].jointOverrides?["pan"] = nil; updated[index].jointOverrides?["tilt"] = nil
            }
            updated[index] = try resolved(updated[index], in: result, solveFocus: preset.focusTargetID != nil)
        }
        try result.validate(fixtures: updated)
        return (result, updated)
    }
    public static func transformed(_ fixtures: [Fixture], ids: Set<UUID>, translation: Position3D,
                                   yaw: Float = 0, spacing: Float? = nil, mirror: Bool = false, align: FixtureAxis? = nil) throws -> [Fixture] {
        guard [translation.x, translation.y, translation.z, yaw].allSatisfy(\.isFinite),
              spacing == nil || (spacing!.isFinite && spacing! > 0), !ids.isEmpty else { throw PresetError("Enter finite coordinates and positive spacing.") }
        if align == .x && spacing != nil { throw PresetError("Choose X alignment or X spacing, not both.") }
        let chosen = fixtures.filter { ids.contains($0.id) }.sorted { $0.position.x == $1.position.x ? $0.id.uuidString < $1.id.uuidString : $0.position.x < $1.position.x }
        guard chosen.count == ids.count else { throw PresetError("Place all selected units before transforming.") }
        let pivot = chosen.reduce(SIMD3<Float>.zero) { $0 + FixtureAiming.vector($1.position) } / Float(chosen.count)
        let q = FixtureAiming.euler(yaw: yaw, pitch: 0, roll: 0)
        var updates: [UUID: Fixture] = [:]
        for (index, var fixture) in chosen.enumerated() {
            var offset = FixtureAiming.vector(fixture.position) - pivot
            if let align { offset[align.index] = 0 }
            if let spacing { offset.x = (Float(index) - Float(chosen.count-1)/2) * spacing }
            if mirror { offset.x *= -1 }
            let position = pivot + FixtureAiming.rotate(q, offset) + FixtureAiming.vector(translation)
            fixture.position = .init(x: position.x, y: position.y, z: position.z)
            fixture.orientation = FixtureAiming.rotatedMount(fixture.orientation, around: .y, radians: yaw * .pi / 180)
            fixture.surfaceID = nil; updates[fixture.id] = fixture
        }
        return fixtures.map { updates[$0.id] ?? $0 }
    }
}

public struct TouringArchive: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var shows: [TouringShow] = []
    public var active: TourSession?
    public init() {}
    public func validate() throws {
        guard schemaVersion == 1, shows.count <= 64, Set(shows.map(\.id)).count == shows.count else { throw PresetError("Invalid show library.") }
        for show in shows { try show.validate() }
        if let active { try active.validate() }
    }
    public func save(to url: URL) throws {
        try validate()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }
    public static func load(from url: URL) throws -> Self {
        guard FileManager.default.fileExists(atPath: url.path) else { return .init() }
        let data = try Data(contentsOf: url)
        guard data.count < 20_000_000 else { throw PresetError("Show library is too large.") }
        let archive = try JSONDecoder().decode(Self.self, from: data); try archive.validate(); return archive
    }
}
