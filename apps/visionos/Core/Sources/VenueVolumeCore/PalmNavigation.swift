import Foundation

/// Metric X/Z coordinates, with a fixed isometric view and independent floor-relative height.
public struct PalmMapProjection: Sendable {
    public let center: SIMD2<Float>
    public let metersToMap: Float
    public static let yaw: Float = .pi / 4
    public static let pitch: Float = atan(1 / sqrt(2))
    public init(minimum: [Float], maximum: [Float], width: Float = 0.28) {
        center = [(minimum[0] + maximum[0]) / 2, (minimum[2] + maximum[2]) / 2]
        metersToMap = width / max(maximum[0] - minimum[0], maximum[2] - minimum[2], 0.1)
    }
    public func map(_ room: SIMD2<Float>) -> SIMD2<Float> { (room - center) * metersToMap }
    public func room(_ map: SIMD2<Float>) -> SIMD2<Float> { map / metersToMap + center }
    public func floorDelta(screen: SIMD2<Float>) -> SIMD2<Float> {
        let x = screen.x / cos(Self.yaw)
        let z = screen.y / (sin(Self.pitch) * cos(Self.yaw))
        return SIMD2((x + z) / 2, (x - z) / 2) / metersToMap
    }
    public func heightDelta(screenY: Float) -> Float { screenY / cos(Self.pitch) / metersToMap }
    /// Include placed fixture envelopes so a destination cannot overlap equipment.
    public static func includingFixtures(_ fixtures: [Fixture], in environment: EnvironmentManifest) -> EnvironmentManifest {
        var result = environment
        result.colliders += fixtures.map { fixture in
            let low = fixture.asset?.boundsMin ?? [-0.12,-0.12,-0.12]
            let high = fixture.asset?.boundsMax ?? [0.12,0.12,0.12]
            let center = fixture.visualCenter, q = fixture.orientation
            return .init(id: "fixture-" + fixture.id.uuidString, sourceID: fixture.id.uuidString, shape: "box",
                center: [center.x,center.y,center.z],
                size: [(high[0]-low[0])*fixture.scale.x, (high[1]-low[1])*fixture.scale.y, (high[2]-low[2])*fixture.scale.z],
                rotation: [q.x,q.y,q.z,q.w])
        }
        return result
    }
    public static func floorHeight(_ point: SIMD2<Float>, in environment: EnvironmentManifest) -> Float {
        environment.surfaces.first {
            $0.role == "floor" && abs(point.x - $0.center[0]) <= $0.size[0]/2 && abs(point.y - $0.center[2]) <= $0.size[1]/2
        }?.center[1] ?? environment.bounds.min[1]
    }
    public static func destination(_ point: SIMD2<Float>, in environment: EnvironmentManifest, clearance: Float = 0.25, elevation: Float = 0) -> Position3D? {
        let target = Position3D(x: point.x, y: floorHeight(point, in: environment) + elevation, z: point.y)
        return obstruction(target, in: environment, clearance: clearance) == nil ? target : nil
    }
    public static func obstruction(_ target: Position3D, in environment: EnvironmentManifest, clearance: Float = 0.25) -> String? {
        let height: Float = 1.7
        guard [target.x, target.y, target.z].allSatisfy(\.isFinite) else { return "Choose a finite position." }
        guard target.x >= environment.bounds.min[0] + clearance, target.x <= environment.bounds.max[0] - clearance,
              target.z >= environment.bounds.min[2] + clearance, target.z <= environment.bounds.max[2] - clearance,
              target.y >= floorHeight([target.x, target.z], in: environment), target.y + height <= environment.bounds.max[1] else {
            return "Keep the user cube inside the room, above the floor and below the ceiling."
        }
        let bodyCenter = SIMD3<Float>(target.x, target.y + height/2, target.z)
        let bodyHalf = SIMD3<Float>(clearance, height/2, clearance)
        let axes: [SIMD3<Float>] = [[1,0,0],[0,1,0],[0,0,1]]
        func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float { a.x*b.x + a.y*b.y + a.z*b.z }
        func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> { [a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x] }
        for box in environment.colliders {
            let q = box.rotation, u = SIMD3<Float>(q[0],q[1],q[2])
            let boxAxes = axes.map { $0 + 2 * cross(u, cross(u, $0) + q[3] * $0) }
            let half = SIMD3<Float>(box.size[0]/2, box.size[1]/2, box.size[2]/2)
            let delta = bodyCenter - SIMD3<Float>(box.center[0],box.center[1],box.center[2])
            let candidates = axes + boxAxes + axes.flatMap { a in boxAxes.map { cross(a,$0) } }
            let separated = candidates.contains { axis in
                guard dot(axis,axis) > 0.000001 else { return false }
                var radius: Float = 0
                for i in 0..<3 { radius += abs(dot(axis,axes[i]))*bodyHalf[i] + abs(dot(axis,boxAxes[i]))*half[i] }
                // Touching the floor or the top of an obstacle is allowed.
                return abs(dot(delta,axis)) >= radius - 0.0001
            }
            if !separated { return "Obstructed · raise the cube with the vertical handle or move it to another spot." }
        }
        return nil
    }
}

/// Attend the palm to reveal, hide it to dismiss. A new reveal requires a short dwell.
public struct PalmMapToggle: Sendable {
    public private(set) var isVisible = false
    private var enteredAt: Double?
    public init() {}
    public mutating func update(attended: Bool, now: Double) -> Bool {
        guard attended else { enteredAt = nil; isVisible = false; return false }
        if enteredAt == nil { enteredAt = now }
        if now - (enteredAt ?? now) >= 0.35 { isVisible = true }
        return isVisible
    }
}
