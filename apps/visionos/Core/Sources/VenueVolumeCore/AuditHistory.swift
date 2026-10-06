import Foundation

/// Append-only state graph: editing after Undo forks without erasing old events.
/// Navigation and external effects are audit entries, not reversible commands.
public struct AuditHistory<State: Codable & Equatable & Sendable>: Codable, Sendable {
    public struct Node: Codable, Identifiable, Sendable {
        public var id: UUID
        public var parent: UUID?
        public var date: Date
        public var title: String
        public var state: State
    }
    public struct Entry: Codable, Identifiable, Sendable {
        public var id: UUID
        public var date: Date
        public var title: String
        public var nodeID: UUID
        public var kind: Kind
        public enum Kind: String, Codable, Sendable { case change, undo, redo, jump, external }
    }
    public private(set) var schemaVersion = 1
    public private(set) var nodes: [Node]
    public private(set) var entries: [Entry]
    public private(set) var cursor: UUID
    public private(set) var redoPath: [UUID] = []

    public init(state: State) {
        let node = Node(id: UUID(), parent: nil, date: Date(), title: "Initial state", state: state)
        nodes = [node]; cursor = node.id
        entries = [Entry(id: UUID(), date: node.date, title: node.title, nodeID: node.id, kind: .change)]
    }
    public var current: Node { nodes.first { $0.id == cursor }! }
    public var undoTarget: UUID? { current.parent }
    public var redoTarget: UUID? { redoPath.last }
    public func node(_ id: UUID) -> Node? { nodes.first { $0.id == id } }

    @discardableResult public mutating func record(_ title: String, state: State) -> Bool {
        guard current.state != state else { return false }
        let node = Node(id: UUID(), parent: cursor, date: Date(), title: title, state: state)
        nodes.append(node); cursor = node.id; redoPath = []
        append(title, kind: .change)
        return true
    }
    public mutating func append(_ title: String, kind: Entry.Kind = .external) {
        entries.append(Entry(id: UUID(), date: Date(), title: title, nodeID: cursor, kind: kind))
    }
    public mutating func move(to id: UUID, kind: Entry.Kind) throws {
        guard let destination = node(id), id != cursor else { return }
        switch kind {
        case .undo:
            guard id == undoTarget else { throw EnvironmentError.invalid("invalid undo destination") }
            redoPath.append(cursor)
        case .redo:
            guard id == redoTarget else { throw EnvironmentError.invalid("invalid redo destination") }
            redoPath.removeLast()
        case .jump: redoPath = []
        default: throw EnvironmentError.invalid("invalid history navigation")
        }
        let title = kind == .undo ? "Undo · \(current.title)" : "\(kind == .redo ? "Redo" : "Restore") · \(destination.title)"
        cursor = id; append(title, kind: kind)
    }
    public func validate() throws {
        guard schemaVersion == 1, !nodes.isEmpty, Set(nodes.map(\.id)).count == nodes.count,
              Set(entries.map(\.id)).count == entries.count, node(cursor) != nil else { throw EnvironmentError.invalid("invalid audit history") }
        var seen: Set<UUID> = []
        for (index, node) in nodes.enumerated() {
            guard index == 0 ? node.parent == nil : node.parent.map({ seen.contains($0) }) == true else {
                throw EnvironmentError.invalid("invalid audit parent")
            }
            seen.insert(node.id)
        }
        guard entries.allSatisfy({ seen.contains($0.nodeID) }) else { throw EnvironmentError.invalid("missing audit state") }
        var previous = cursor
        for id in redoPath.reversed() {
            guard node(id)?.parent == previous else { throw EnvironmentError.invalid("invalid redo path") }
            previous = id
        }
    }
    public func save(to url: URL) throws {
        try validate()
        let directory = url.deletingPathExtension().appendingPathExtension("states")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Write each immutable snapshot once. Only the smaller event index is
        // replaced on subsequent edits; a long history never rewrites every scene.
        for node in nodes {
            let file = directory.appendingPathComponent(node.id.uuidString + ".json")
            if !FileManager.default.fileExists(atPath: file.path) {
                try JSONEncoder().encode(node).write(to: file, options: .atomic)
            }
        }
        let archive = Archive(schemaVersion: schemaVersion, nodes: nodes.map(\.id), entries: entries, cursor: cursor, redoPath: redoPath)
        try JSONEncoder().encode(archive).write(to: url, options: .atomic)
    }
    public static func load(from url: URL) throws -> Self? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let archive = try JSONDecoder().decode(Archive.self, from: data)
        let directory = url.deletingPathExtension().appendingPathExtension("states")
        let nodes = try archive.nodes.map { id in
            let node = try JSONDecoder().decode(Node.self, from: Data(contentsOf: directory.appendingPathComponent(id.uuidString + ".json")))
            guard node.id == id else { throw EnvironmentError.invalid("audit snapshot identity mismatch") }
            return node
        }
        guard let first = nodes.first else { throw EnvironmentError.invalid("empty audit archive") }
        var result = Self(state: first.state)
        result.schemaVersion = archive.schemaVersion; result.nodes = nodes; result.entries = archive.entries
        result.cursor = archive.cursor; result.redoPath = archive.redoPath
        try result.validate()
        return result
    }
    private struct Archive: Codable {
        var schemaVersion: Int
        var nodes: [UUID]
        var entries: [Entry]
        var cursor: UUID
        var redoPath: [UUID]
    }
}

/// Logical application state only. Mesh bytes stay in the immutable asset store.
/// Tracking poses, async requests and transient drag/placement modes are excluded.
public struct VenueAuditState: Codable, Equatable, Sendable {
    public var rooms: [LibraryRoom]
    public var setups: [VenueSetup]
    public var roomID: String
    public var fixtures: [Fixture]
    public var presets: [DMXPreset]
    public var draft: DMXPreset
    public var editingPresetID: UUID?
    public var setupName: String
    public var activeSetupID: UUID?
    public var savedSetup: VenueSetup?
    public var whiteRoom: Bool
    public var houseLight: Float
    public var blackout: Bool
    public var selectedID: UUID?
    public var expandedID: UUID?
    public var previewDraft: Bool
    public var previewBlackout: Bool?

    public init(rooms: [LibraryRoom], setups: [VenueSetup], roomID: String, fixtures: [Fixture], presets: [DMXPreset],
                draft: DMXPreset, editingPresetID: UUID?, setupName: String, activeSetupID: UUID?, savedSetup: VenueSetup?,
                whiteRoom: Bool, houseLight: Float, blackout: Bool, selectedID: UUID?, expandedID: UUID?, previewDraft: Bool, previewBlackout: Bool? = nil) {
        self.rooms = rooms; self.setups = setups; self.roomID = roomID; self.fixtures = fixtures; self.presets = presets
        self.draft = draft; self.editingPresetID = editingPresetID; self.setupName = setupName; self.activeSetupID = activeSetupID
        self.savedSetup = savedSetup; self.whiteRoom = whiteRoom; self.houseLight = houseLight; self.blackout = blackout
        self.selectedID = selectedID; self.expandedID = expandedID; self.previewDraft = previewDraft; self.previewBlackout = previewBlackout
    }
    public func validate() throws {
        guard let room = rooms.first(where: { $0.id == roomID }), Set(rooms.map(\.id)).count == rooms.count,
              Set(setups.map(\.id)).count == setups.count, Set(presets.map(\.id)).count == presets.count,
              presets.allSatisfy({ $0.validationIssue == nil }), houseLight.isFinite, (0...1).contains(houseLight),
              fixtures.allSatisfy({ fixture in fixture.referencedPaletteIDs.isSubset(of: Set(presets.map(\.id))) }),
              editingPresetID == nil || presets.contains(where: { $0.id == editingPresetID }),
              activeSetupID == nil || setups.contains(where: { $0.id == activeSetupID }),
              savedSetup?.id == activeSetupID,
              selectedID == nil || fixtures.contains(where: { $0.id == selectedID }),
              expandedID == nil || fixtures.contains(where: { $0.id == expandedID }),
              (1...16).contains(draft.channels.count), draft.channels.allSatisfy({ (0...255).contains($0) }) else {
            throw EnvironmentError.invalid("invalid audit snapshot")
        }
        for room in rooms { try room.manifest.validate() }
        try RoomPlacements(environment: room.manifest, fixtures: fixtures, revision: 0).validate(environment: room.manifest)
        for setup in setups {
            guard let owner = rooms.first(where: { $0.id == setup.roomID }) else { throw EnvironmentError.invalid("missing setup room") }
            try setup.validate(room: owner)
        }
        if let savedSetup { try savedSetup.validate(room: room) }
    }
}
