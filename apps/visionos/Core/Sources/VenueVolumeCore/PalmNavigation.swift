import Foundation

/// Metric room coordinates projected into a compact, upright palm map.
/// The floor surfaces, rather than the room's enclosing bounds, define walkable targets.
public struct PalmMapProjection: Sendable {
    public let center: SIMD2<Float>
    public let metersToMap: Float
    public init(minimum: [Float], maximum: [Float], width: Float = 0.28) {
        center = [(minimum[0] + maximum[0]) / 2, (minimum[2] + maximum[2]) / 2]
        metersToMap = width / max(maximum[0] - minimum[0], maximum[2] - minimum[2], 0.1)
    }
    public func map(_ room: SIMD2<Float>) -> SIMD2<Float> { (room - center) * metersToMap }
    public func room(_ map: SIMD2<Float>) -> SIMD2<Float> { map / metersToMap + center }

    public static func destination(_ point: SIMD2<Float>, in environment: EnvironmentManifest, clearance: Float = 0.25) -> Position3D? {
        guard point.x.isFinite, point.y.isFinite,
              let floor = environment.surfaces.first(where: {
                  $0.role == "floor" && abs(point.x - $0.center[0]) <= $0.size[0]/2 - clearance &&
                  abs(point.y - $0.center[2]) <= $0.size[1]/2 - clearance
              }) else { return nil }
        // Reject furniture and structural boxes that intersect the user's standing volume.
        // Rotate into each collider's local frame so rotated obstacles are respected.
        for box in environment.colliders where box.sourceID != floor.id && box.id != floor.id {
            guard box.center[1] + box.size[1]/2 > floor.center[1] + 0.15,
                  box.center[1] - box.size[1]/2 < floor.center[1] + 1.8 else { continue }
            let q = box.rotation
            let v = SIMD3<Float>(point.x - box.center[0], floor.center[1] + 0.9 - box.center[1], point.y - box.center[2])
            let u = SIMD3<Float>(-q[0], -q[1], -q[2])
            func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
                [a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x]
            }
            let local = v + 2 * cross(u, cross(u, v) + q[3] * v)
            if abs(local.x) < box.size[0]/2 + clearance && abs(local.z) < box.size[2]/2 + clearance &&
                abs(local.y) < box.size[1]/2 + 0.9 { return nil }
        }
        return .init(x: point.x, y: floor.center[1], z: point.y)
    }
}

/// A fresh attention dwell toggles once, then requires looking away before another toggle.
public struct PalmMapToggle: Sendable {
    public private(set) var isVisible = false
    private var enteredAt: Double?
    private var departedAt: Double?
    private var armed = true
    public init() {}
    public mutating func update(attended: Bool, now: Double) -> Bool {
        if attended {
            departedAt = nil
            if enteredAt == nil { enteredAt = now }
            if armed && now - (enteredAt ?? now) >= 0.35 {
                isVisible.toggle(); armed = false
            }
        } else {
            enteredAt = nil
            if departedAt == nil { departedAt = now }
            if now - (departedAt ?? now) >= 0.5 { armed = true }
        }
        return isVisible
    }
}
