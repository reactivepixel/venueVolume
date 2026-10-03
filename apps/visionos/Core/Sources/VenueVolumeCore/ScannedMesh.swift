import Foundation

public struct ScannedMesh: Codable, Equatable, Sendable {
    public struct Chunk: Codable, Equatable, Sendable {
        public var vertices: [Position3D]
        public var triangles: [UInt32]
        public init(vertices: [Position3D], triangles: [UInt32]) { self.vertices = vertices; self.triangles = triangles }
    }
    public var schemaVersion = 1
    public var chunks: [Chunk]
    public init(chunks: [Chunk]) { self.chunks = chunks }
    public var triangleCount: Int { chunks.reduce(0) { $0 + $1.triangles.count/3 } }

    public func validate() throws {
        guard schemaVersion == 1, !chunks.isEmpty, chunks.count <= 2048,
              triangleCount > 0, triangleCount <= 1_000_000 else { throw EnvironmentError.invalid("scan is empty or exceeds one million triangles") }
        for chunk in chunks {
            guard !chunk.vertices.isEmpty, chunk.vertices.count <= 1_000_000,
                  !chunk.triangles.isEmpty, chunk.triangles.count.isMultiple(of: 3),
                  chunk.triangles.allSatisfy({ Int($0) < chunk.vertices.count }),
                  chunk.vertices.allSatisfy({ [$0.x,$0.y,$0.z].allSatisfy { $0.isFinite && abs($0) < 1000 } }) else {
                throw EnvironmentError.invalid("invalid scan geometry")
            }
        }
    }

    /// Require supporting horizontal mesh beneath the center and four corners.
    /// This avoids treating unobserved holes in a scanned floor's bounding box as solid.
    public func supports(_ point: Position3D, radius: Float) -> Bool {
        let samples: [(Float,Float)] = [(0,0),(-radius,-radius),(-radius,radius),(radius,-radius),(radius,radius)]
        return samples.allSatisfy { dx, dz in
            let x = point.x+dx, z = point.z+dz
            return chunks.contains { chunk in
                stride(from: 0, to: chunk.triangles.count, by: 3).contains { i in
                    let a = chunk.vertices[Int(chunk.triangles[i])]
                    let b = chunk.vertices[Int(chunk.triangles[i+1])]
                    let c = chunk.vertices[Int(chunk.triangles[i+2])]
                    let den = (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
                    guard abs(den) > 0.000001 else { return false }
                    let u = ((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/den
                    let v = ((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/den
                    guard u >= -0.001, v >= -0.001, u+v <= 1.001 else { return false }
                    let ab = SIMD3(b.x-a.x,b.y-a.y,b.z-a.z), ac = SIMD3(c.x-a.x,c.y-a.y,c.z-a.z)
                    let n = SIMD3(ab.y*ac.z-ab.z*ac.y, ab.z*ac.x-ab.x*ac.z, ab.x*ac.y-ab.y*ac.x)
                    guard abs(n.y) > FixtureAiming.length(n)*0.98 else { return false }
                    return abs(u*a.y+v*b.y+(1-u-v)*c.y-point.y) < 0.025
                }
            }
        }
    }
}

public struct FixtureKind: RawRepresentable, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public static let movingHead = FixtureKind(unchecked: "movingHead")
    public static let cube = FixtureKind(unchecked: "cube")
    private init(unchecked: String) { rawValue = unchecked }
    public init?(rawValue: String) {
        guard rawValue == "movingHead" || rawValue == "cube" || FixtureCatalog.asset(rawValue) != nil else { return nil }
        self.rawValue = rawValue
    }
    public static var allCases: [FixtureKind] {
        FixtureCatalog.all.map { $0.id == LightingPreview.assetID ? .movingHead : FixtureKind(unchecked: $0.id) } + [.cube]
    }
    public var id: String { rawValue }
    public var asset: FixtureAsset? { FixtureCatalog.asset(assetID) }
    public var name: String { asset?.name ?? "DMX cube" }
    public var radius: Float { asset?.radius ?? 0.12 }
    public var assetID: String? { self == .cube ? nil : self == .movingHead ? LightingPreview.assetID : rawValue }
    public var dragToken: String { "venue-volume:fixture-kind:" + rawValue }
    public init?(token: String) {
        let prefix = "venue-volume:fixture-kind:"
        guard token.hasPrefix(prefix) else { return nil }
        self.init(rawValue: String(token.dropFirst(prefix.count)))
    }
}
