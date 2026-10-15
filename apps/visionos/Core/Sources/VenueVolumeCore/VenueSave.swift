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
