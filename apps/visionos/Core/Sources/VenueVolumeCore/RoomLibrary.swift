import Foundation

public struct LibraryRoom: Codable, Equatable, Identifiable, Sendable {
    public enum Origin: String, Codable, Sendable { case bundled, imported, scanned }
    public var id: String { manifest.id + "-" + manifest.version }
    public var manifest: EnvironmentManifest
    public var origin: Origin
    public init(manifest: EnvironmentManifest, origin: Origin) { self.manifest = manifest; self.origin = origin }
    public var displayName: String {
        switch manifest.id {
        case "img3153-classroom-v1": "Empty classroom"
        case "mappedRoom": "Empty classroom (mapped)"
        case "the-fortress": "The Fortress"
        default: manifest.title
        }
    }
    public var detail: String {
        switch manifest.id {
        case "img3153-classroom-v1": "Neutral room materials · no fixtures"
        case "mappedRoom": "Photo-derived room materials · no fixtures"
        case "the-fortress": "Provisional venue blockout · estimated dimensions"
        default: origin == .scanned ? "Your local room scan" : "Imported venue"
        }
    }
}

/// A named snapshot owns its resolved fixture values and the preset definitions
/// they refer to. Room geometry remains immutable and shared between snapshots.
public struct VenueSetup: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion = 1
    public var id: UUID
    public var name: String
    public var modified: Date
    public var roomID: String
    public var placements: RoomPlacements
    public var presets: [DMXPreset]
    public var whiteRoom: Bool
    public var houseLight: Float
    public init(id: UUID = UUID(), name: String, room: LibraryRoom, fixtures: [Fixture], presets: [DMXPreset], revision: Int,
                whiteRoom: Bool, houseLight: Float) {
        self.id = id; self.name = name; modified = Date(); roomID = room.id
        placements = .init(environment: room.manifest, fixtures: fixtures, revision: revision)
        self.presets = presets.filter { preset in fixtures.contains { $0.referencedPaletteIDs.contains(preset.id) } }
        self.whiteRoom = whiteRoom; self.houseLight = houseLight
    }
    public func validate(room: LibraryRoom) throws {
        guard schemaVersion == 1, roomID == room.id, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name.count <= 120, houseLight.isFinite, (0...1).contains(houseLight),
              presets.allSatisfy({ $0.validationIssue == nil }), Set(presets.map(\.id)).count == presets.count else {
            throw EnvironmentError.invalid("invalid saved setup")
        }
        try placements.validate(environment: room.manifest)
        guard placements.fixtures.allSatisfy({ fixture in fixture.referencedPaletteIDs.isSubset(of: Set(presets.map(\.id))) }) else {
            throw EnvironmentError.invalid("saved setup is missing a preset")
        }
    }
}

/// Files are individually atomic. No global index can erase unrelated rooms or
/// setups if one file is damaged. Directory names never come from display names.
public struct RoomLibraryStore: Sendable {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }
    public func roomDirectory(_ room: LibraryRoom) throws -> URL {
        try room.manifest.validate()
        return directory.appendingPathComponent("Rooms").appendingPathComponent(room.id)
    }
    public func rooms() throws -> [LibraryRoom] {
        let parent = directory.appendingPathComponent("Rooms")
        guard FileManager.default.fileExists(atPath: parent.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .map { url in
                let record = try JSONDecoder().decode(LibraryRoom.self, from: Data(contentsOf: url.appendingPathComponent("room.json")))
                try record.manifest.validate()
                guard url.lastPathComponent == record.id else { throw EnvironmentError.invalid("room directory mismatch") }
                return record
            }.sorted { $0.manifest.title.localizedStandardCompare($1.manifest.title) == .orderedAscending }
    }
    public func install(room: LibraryRoom, asset: Data) throws {
        let destination = try roomDirectory(room)
        guard asset.count == room.manifest.asset.bytes else { throw EnvironmentError.invalid("asset size mismatch") }
        if FileManager.default.fileExists(atPath: destination.path) {
            let old = try Data(contentsOf: destination.appendingPathComponent(room.manifest.asset.file))
            let prior = try JSONDecoder().decode(LibraryRoom.self, from: Data(contentsOf: destination.appendingPathComponent("room.json")))
            guard old == asset, prior.manifest == room.manifest else { throw EnvironmentError.invalid("different room data already uses this room version") }
            return
        }
        let staging = destination.deletingLastPathComponent().appendingPathComponent(".import-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }
        try asset.write(to: staging.appendingPathComponent(room.manifest.asset.file), options: .atomic)
        try JSONEncoder().encode(room.manifest).write(to: staging.appendingPathComponent("environment.json"), options: .atomic)
        try JSONEncoder().encode(room).write(to: staging.appendingPathComponent("room.json"), options: .atomic)
        try FileManager.default.moveItem(at: staging, to: destination)
    }
    public func setups(rooms: [LibraryRoom]) throws -> [VenueSetup] {
        let folder = directory.appendingPathComponent("Setups")
        guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.map { url in
                let saved = try JSONDecoder().decode(VenueSetup.self, from: Data(contentsOf: url))
                guard let room = rooms.first(where: { $0.id == saved.roomID }), url.lastPathComponent == saved.id.uuidString + ".json" else {
                    throw EnvironmentError.invalid("saved setup references a missing room")
                }
                try saved.validate(room: room)
                return saved
            }.sorted { $0.modified > $1.modified }
    }
    public func save(_ setup: VenueSetup, room: LibraryRoom) throws {
        try setup.validate(room: room)
        let folder = directory.appendingPathComponent("Setups")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(setup).write(to: folder.appendingPathComponent(setup.id.uuidString + ".json"), options: .atomic)
    }
}

extension EnvironmentManifest {
    /// For a measured scan or a meter-scale USDZ that lacks the richer room2blender contract.
    public static func simple(id: String, title: String, min: [Float], max: [Float], spawn: [Float], yaw: Float,
                              file: String, checksum: String, bytes: Int, scanned: Bool) -> Self {
        let center: [Float] = [(min[0]+max[0])/2, 0, (min[2]+max[2])/2]
        let size: [Float] = [max[0]-min[0], max[2]-min[2]]
        return .init(schemaVersion: 1, id: id, version: checksum, title: title, units: "meters", upAxis: "Y", forwardAxis: "-Z",
                     scaleStatus: scanned ? "device-scan" : "provided-meters", bounds: .init(min: min, max: max),
                     spawn: .init(position: spawn, yaw: yaw), asset: .init(file: file, sha256: checksum, bytes: bytes),
                     colliders: [.init(id: "floor", sourceID: "floor", shape: "box", center: [center[0], -0.01, center[2]],
                                       size: [size[0], 0.02, size[1]], rotation: [0,0,0,1])],
                     surfaces: [.init(id: "floor", role: "floor", center: center, size: size, normal: [0,1,0],
                                      allowedAssetCategories: ["fixture"], primPaths: ["/Environment/Geometry/scan"])])
    }
}
