import Foundation

/// One portable file contains the immutable room and an independent fixture setup.
/// Asset paths are validated by EnvironmentManifest; imported names never become paths.
public struct VenueSave: Codable, Equatable, Sendable {
    public var format = "com.venuevolume.save"
    public var schemaVersion = 1
    public var room: LibraryRoom
    public var setup: VenueSetup
    public var asset: Data
    public static let maximumFileBytes = 350_000_000

    public init(room: LibraryRoom, setup: VenueSetup, asset: Data) {
        self.room = room; self.setup = setup; self.asset = asset
    }

    public func validate(assetChecksum: String) throws {
        guard format == "com.venuevolume.save", schemaVersion == 1 else {
            throw EnvironmentError.invalid("unsupported Venue Volume save file")
        }
        try room.manifest.validate()
        try setup.validate(room: room)
        guard setup.presets.count <= 64, asset.count == room.manifest.asset.bytes,
              assetChecksum == room.manifest.asset.sha256 else {
            throw EnvironmentError.invalid("save file asset is damaged or exceeds its limits")
        }
        if room.manifest.asset.file == "environment.mesh.json" {
            try JSONDecoder().decode(ScannedMesh.self, from: asset).validate()
        }
    }
}

extension RoomLibraryStore {
    /// Importing always creates a new setup identity and cannot overwrite a local save.
    /// Publish model state only after this succeeds; rollback newly installed geometry
    /// when the setup cannot be written.
    public func importSave(_ document: VenueSave, assetChecksum: String) throws -> (room: LibraryRoom, setup: VenueSetup) {
        try document.validate(assetChecksum: assetChecksum)
        var room = document.room
        room.origin = document.room.manifest.asset.file == "environment.mesh.json" ? .scanned : .imported
        var setup = document.setup
        setup.id = UUID(); setup.modified = Date()
        let folder = try roomDirectory(room)
        let existed = FileManager.default.fileExists(atPath: folder.path)
        do {
            try install(room: room, asset: document.asset)
            try save(setup, room: room)
            return (room, setup)
        } catch {
            if !existed { try? FileManager.default.removeItem(at: folder) }
            throw error
        }
    }
}
