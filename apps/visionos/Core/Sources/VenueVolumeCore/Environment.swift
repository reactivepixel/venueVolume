import Foundation

public enum EnvironmentError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? {
        switch self { case .invalid(let reason): "Environment: \(reason)" }
    }
}

/// Version 1 contract shared with room2blender. All positions are meters in room-local Y-up space.
public struct EnvironmentManifest: Codable, Equatable, Sendable {
    public struct Asset: Codable, Equatable, Sendable {
        public var file: String
        public var sha256: String
        public var bytes: Int
    }
    public struct Bounds: Codable, Equatable, Sendable {
        public var min: [Float]
        public var max: [Float]
    }
    public struct Spawn: Codable, Equatable, Sendable {
        public var position: [Float]
        public var yaw: Float
    }
    public struct Collider: Codable, Equatable, Sendable {
        public var id: String
        public var sourceID: String
        public var shape: String
        public var center: [Float]
        public var size: [Float]
        /// Quaternion components in x, y, z, w order. Size is in the box's local axes.
        public var rotation: [Float]

        // Axis-aligned envelope of the oriented box, used to cross-check surface metadata.
        var worldHalfExtents: [Float] {
            let x = rotation[0], y = rotation[1], z = rotation[2], w = rotation[3]
            let rows: [[Float]] = [
                [1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]
            ]
            return rows.map { row in zip(row, size).reduce(Float(0)) { $0+abs($1.0)*$1.1/2 } }
        }
    }
    public struct Surface: Codable, Equatable, Sendable {
        public var id: String
        public var role: String
        public var center: [Float]
        /// Horizontal rectangle dimensions along room X and Z.
        public var size: [Float]
        public var normal: [Float]
        public var allowedAssetCategories: [String]
        public var primPaths: [String]

        /// A 24cm fixture must fit fully on a top; reject side hits and edge overhang.
        public func fixturePosition(hit: Position3D, halfSize: Float = 0.12) -> Position3D? {
            guard (role == "floor" || role == "tabletop"), allowedAssetCategories.contains("fixture"),
                  center.count == 3, size.count == 2,
                  abs(hit.y-center[1]) < 0.025,
                  abs(hit.x-center[0]) <= size[0]/2-halfSize,
                  abs(hit.z-center[2]) <= size[1]/2-halfSize else { return nil }
            return Position3D(x: hit.x, y: center[1]+halfSize, z: hit.z)
        }
    }
    public var schemaVersion: Int
    public var id: String
    public var version: String
    public var title: String
    public var units: String
    public var upAxis: String
    public var forwardAxis: String
    public var scaleStatus: String
    public var bounds: Bounds
    public var spawn: Spawn
    public var asset: Asset
    public var colliders: [Collider]
    public var surfaces: [Surface]
    public var assetTranslation: [Float]? = nil

    public func validate() throws {
        func require(_ value: Bool, _ reason: String) throws {
            if !value { throw EnvironmentError.invalid(reason) }
        }
        func vector(_ v: [Float], count: Int = 3) -> Bool { v.count == count && v.allSatisfy(\.isFinite) }
        func hash(_ s: String) -> Bool { s.count == 64 && s.allSatisfy { "0123456789abcdef".contains($0) } }
        try require(schemaVersion == 1, "unsupported schema version")
        try require(!id.isEmpty && id.utf8.count <= 80 && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-_".contains($0)) }, "invalid room ID")
        try require(hash(version) && hash(asset.sha256), "invalid content version or checksum")
        try require(units == "meters" && upAxis == "Y" && forwardAxis == "-Z", "expected meters, Y-up, -Z forward")
        try require(["environment.usdz", "environment.mesh.json"].contains(asset.file) && asset.bytes > 0 && asset.bytes <= 256_000_000, "invalid asset path or size")
        try require(vector(bounds.min) && vector(bounds.max), "invalid bounds")
        if let assetTranslation { try require(vector(assetTranslation), "invalid asset translation") }
        try require(zip(bounds.min, bounds.max).allSatisfy { $0 < $1 }, "empty bounds")
        try require(vector(spawn.position) && spawn.yaw.isFinite, "invalid spawn")
        try require(abs(spawn.position[1]) < 0.001 && (0..<3).allSatisfy {
            spawn.position[$0] >= bounds.min[$0] && spawn.position[$0] <= bounds.max[$0]
        }, "spawn must lie on the room floor within bounds")
        try require(!colliders.isEmpty && colliders.count <= 10_000 && surfaces.count <= 10_000, "invalid interaction geometry count")
        try require(Set(colliders.map(\.id)).count == colliders.count && Set(surfaces.map(\.id)).count == surfaces.count, "duplicate interaction IDs")
        for c in colliders {
            try require(c.shape == "box" && vector(c.center) && vector(c.size) && c.size.allSatisfy { $0 > 0 }, "invalid collider \(c.id)")
            try require(vector(c.rotation, count: 4) && abs(c.rotation.reduce(0) { $0+$1*$1 }-1) < 0.001, "invalid collider rotation")
        }
        for s in surfaces {
            try require(["floor", "tabletop"].contains(s.role), "unsupported placement role \(s.role)")
            try require(vector(s.center) && vector(s.size, count: 2) && s.size.allSatisfy { $0 > 0 } && s.normal == [0,1,0], "invalid surface \(s.id)")
            guard let collider = colliders.first(where: { $0.sourceID == s.id }) else {
                throw EnvironmentError.invalid("surface \(s.id) has no collider")
            }
            let extent = collider.worldHalfExtents
            try require(abs(collider.center[1]+extent[1]-s.center[1]) < 0.002 &&
                        abs(collider.center[0]-s.center[0])+s.size[0]/2 <= extent[0]+0.002 &&
                        abs(collider.center[2]-s.center[2])+s.size[1]/2 <= extent[2]+0.002,
                        "surface \(s.id) does not match its collider")
            try require(!s.primPaths.isEmpty && s.primPaths.allSatisfy { $0.hasPrefix("/Environment/Geometry/") && !$0.contains("..") }, "invalid surface geometry paths")
        }
        try require(surfaces.contains { $0.role == "floor" }, "missing floor placement surface")
    }
}

public struct ResolvedEnvironment: Sendable {
    public let manifest: EnvironmentManifest
    public let assetURL: URL
    public init(manifest: EnvironmentManifest, assetURL: URL) {
        self.manifest = manifest
        self.assetURL = assetURL
    }
}

/// Future catalogs/downloaders resolve an ID to a local, complete bundle before invoking RealityKit.
/// No networking, credentials, or remote URLs belong in the scene renderer.
public protocol EnvironmentRepository: Sendable {
    func resolve(id: String) async throws -> ResolvedEnvironment
}

public struct DirectoryEnvironmentRepository: EnvironmentRepository {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }

    public func resolve(id: String) async throws -> ResolvedEnvironment {
        guard directory.isFileURL else { throw EnvironmentError.invalid("bundle must be local") }
        let base = directory.resolvingSymlinksInPath().standardizedFileURL
        let manifestURL = base.appendingPathComponent("environment.json").resolvingSymlinksInPath()
        guard manifestURL.deletingLastPathComponent().path == base.path else { throw EnvironmentError.invalid("manifest escapes bundle") }
        let manifestSize = try manifestURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard manifestSize > 0 && manifestSize <= 8_000_000 else { throw EnvironmentError.invalid("manifest is empty or too large") }
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(EnvironmentManifest.self, from: data)
        try manifest.validate()
        guard manifest.id == id else { throw EnvironmentError.invalid("requested room does not match manifest") }
        let asset = base.appendingPathComponent(manifest.asset.file).resolvingSymlinksInPath()
        guard asset.deletingLastPathComponent().path == base.path else { throw EnvironmentError.invalid("asset escapes bundle") }
        let size = try asset.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard size == manifest.asset.bytes else { throw EnvironmentError.invalid("asset size mismatch") }
        // SHA-256 is verified by the app before any RealityKit parsing (CryptoKit on Apple platforms).
        return ResolvedEnvironment(manifest: manifest, assetURL: asset)
    }
}
