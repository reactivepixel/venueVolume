import CryptoKit
import Foundation
import RealityKit
import VenueVolumeCore

@MainActor enum RoomAssets {
    nonisolated static func checksum(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    static func meshEntity(_ mesh: ScannedMesh) throws -> Entity {
        try mesh.validate()
        let root = Entity()
        for (index, chunk) in mesh.chunks.enumerated() {
            var descriptor = MeshDescriptor(name: "scan-\(index)")
            descriptor.positions = MeshBuffer(chunk.vertices.map { FixtureAiming.vector($0) })
            descriptor.primitives = .triangles(chunk.triangles)
            let resource = try MeshResource.generate(from: [descriptor])
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .init(white: 0.82, alpha: 1))
            material.roughness = .init(floatLiteral: 0.9)
            material.faceCulling = .none
            let entity = ModelEntity(mesh: resource, materials: [material])
            entity.name = "scan-\(index)"; root.addChild(entity)
        }
        return root
    }

    static func importRoom(from url: URL, store: RoomLibraryStore) async throws -> LibraryRoom {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let room: LibraryRoom, data: Data
        if url.pathExtension.lowercased() == "usdz" {
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 256_000_000 else {
                throw EnvironmentError.invalid("room asset exceeds 256 MB")
            }
            data = try Data(contentsOf: url)
            let entity = try await Entity(contentsOf: url)
            let bounds = entity.visualBounds(relativeTo: entity)
            let low = bounds.min, high = bounds.max
            guard high.x-low.x > 1, high.z-low.z > 1, high.y-low.y > 1 else {
                throw EnvironmentError.invalid("provide a meter-scale room at least one meter across")
            }
            var manifest = EnvironmentManifest.simple(id: "import-" + UUID().uuidString.lowercased(), title: url.deletingPathExtension().lastPathComponent,
                min: [low.x,0,low.z], max: [high.x,high.y-low.y,high.z], spawn: [(low.x+high.x)/2,0,high.z-0.5], yaw: 0,
                file: "environment.usdz", checksum: checksum(data), bytes: data.count, scanned: false)
            manifest.assetTranslation = [0,-low.y,0]
            room = .init(manifest: manifest, origin: .imported)
        } else {
            let manifestURL = url.appendingPathComponent("environment.json")
            guard (try manifestURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 8_000_000 else { throw EnvironmentError.invalid("manifest exceeds 8 MB") }
            let manifest = try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: manifestURL))
            let resolved = try await DirectoryEnvironmentRepository(directory: url).resolve(id: manifest.id)
            data = try Data(contentsOf: resolved.assetURL)
            guard checksum(data) == manifest.asset.sha256 else { throw EnvironmentError.invalid("room checksum mismatch") }
            if manifest.asset.file == "environment.mesh.json" {
                try JSONDecoder().decode(ScannedMesh.self, from: data).validate()
            } else { _ = try await Entity(contentsOf: resolved.assetURL) }
            room = .init(manifest: manifest, origin: .imported)
        }
        try store.install(room: room, asset: data)
        return room
    }
}
