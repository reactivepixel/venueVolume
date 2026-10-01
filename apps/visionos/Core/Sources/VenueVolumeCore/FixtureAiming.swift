import Foundation

public struct PanTiltOverride: Codable, Equatable, Sendable {
    public var pan: Int
    public var tilt: Int
    public init(pan: Int, tilt: Int) { self.pan = pan; self.tilt = tilt }
}

/// Geometry uses the catalog's authored meter-scale pivots and -Z optical axis.
public enum FixtureAiming {
    public static let headPivot = SIMD3<Float>(0, 0.33078, 0.00051424245)
    public static let emitterOffset = SIMD3<Float>(0, 0, -0.10858966)
    public static let panRange: ClosedRange<Float> = (-128 * 270 / 255)...(127 * 270 / 255)
    public static let tiltRange: ClosedRange<Float> = (-128 * 120 / 255)...(127 * 120 / 255)

    public static func articulated(_ fixture: Fixture, target: Position3D) throws -> PanTiltOverride {
        let local = rotate(inverse(fixture.orientation), vector(target) - vector(fixture.position)) / vector(fixture.scale)
        let direction = local - headPivot
        guard finite(direction), length(direction) > 0.15 else { throw PresetError("Choose a target farther from the fixture head.") }
        let horizontal = sqrt(direction.x * direction.x + direction.z * direction.z)
        let pan = horizontal < 0.00001 ? LightingPreview(channels: fixture.channels).panDegrees : atan2(-direction.x, -direction.z) * 180 / .pi
        let tilt = atan2(direction.y, horizontal) * 180 / .pi
        // A transformed endpoint can round a few millionths of a degree beyond
        // the authored limits. Permit only that numerical error, not unreachable targets.
        let epsilon: Float = 0.0001
        guard pan >= panRange.lowerBound-epsilon, pan <= panRange.upperBound+epsilon,
              tilt >= tiltRange.lowerBound-epsilon, tilt <= tiltRange.upperBound+epsilon else {
            throw PresetError("That point is outside the preview head's pan/tilt range. Rotate the mount or choose Aim mount.")
        }
        return .init(pan: panByte(for: pan), tilt: tiltByte(for: tilt))
    }

    /// Encode the pilot's preview angles, not the manufacturer's DMX personality.
    public static func panByte(for degrees: Float) -> Int {
        guard degrees.isFinite else { return 128 }
        let bounded = min(panRange.upperBound, max(panRange.lowerBound, degrees))
        return max(0, min(255, Int((bounded / 270 * 255 + 128).rounded())))
    }

    public static func tiltByte(for degrees: Float) -> Int {
        guard degrees.isFinite else { return 128 }
        let bounded = min(tiltRange.upperBound, max(tiltRange.lowerBound, degrees))
        return max(0, min(255, Int((bounded / 120 * 255 + 128).rounded())))
    }

    /// Rotate the entire mount while preserving the existing head channels.
    /// Solve the ray's intersection with a sphere about the base, accounting for
    /// the emitter offset; aiming from the base alone produces parallax errors.
    public static func mounted(_ fixture: Fixture, target: Position3D) throws -> Quaternion3D {
        let displacement = vector(target) - vector(fixture.position)
        let ray = localRay(channels: fixture.channels)
        let origin = ray.origin * vector(fixture.scale)
        let forward = normalized(ray.direction * vector(fixture.scale))
        let projected = dot(origin, forward)
        let discriminant = projected * projected + dot(displacement, displacement) - dot(origin, origin)
        guard finite(displacement), discriminant > 0 else { throw PresetError("Choose a target farther from the fixture mount.") }
        let distance = -projected + sqrt(discriminant)
        guard distance > 0.15 else { throw PresetError("Choose a target in front of the light emitter.") }
        let current = rotate(fixture.orientation, origin + forward * distance)
        return multiply(between(normalized(current), normalized(displacement)), fixture.orientation)
    }

    public static func localRay(channels: [Int]) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
        let look = LightingPreview(channels: channels)
        let articulation = euler(yaw: look.panDegrees, pitch: look.tiltDegrees, roll: 0)
        return (headPivot + rotate(articulation, emitterOffset), rotate(articulation, [0,0,-1]))
    }

    public static func euler(yaw: Float, pitch: Float, roll: Float) -> Quaternion3D {
        func axis(_ angle: Float, _ xyz: SIMD3<Float>) -> Quaternion3D {
            let half = angle * .pi / 360, v = xyz * sin(half)
            return .init(x: v.x, y: v.y, z: v.z, w: cos(half))
        }
        return multiply(multiply(axis(yaw, [0,1,0]), axis(pitch, [1,0,0])), axis(roll, [0,0,1]))
    }

    /// Y-X-Z decomposition; deterministic roll-zero representation at gimbal lock.
    public static func angles(_ q: Quaternion3D) -> (yaw: Float, pitch: Float, roll: Float) {
        let x = rotate(q, [1,0,0]), y = rotate(q, [0,1,0]), z = rotate(q, [0,0,1])
        let pitch = asin(max(-1, min(1, -z.y)))
        let yaw: Float, roll: Float
        if abs(z.y) > 0.999999 { yaw = atan2(-x.z, x.x); roll = 0 }
        else { yaw = atan2(z.x, z.z); roll = atan2(x.y, y.y) }
        return (yaw * 180 / .pi, pitch * 180 / .pi, roll * 180 / .pi)
    }

    public static func vector(_ p: Position3D) -> SIMD3<Float> { [p.x, p.y, p.z] }
    public static func rotate(_ q: Quaternion3D, _ v: SIMD3<Float>) -> SIMD3<Float> {
        let axis = SIMD3(q.x, q.y, q.z)
        let t = 2 * cross(axis, v)
        return v + q.w * t + cross(axis, t)
    }
    public static func inverse(_ q: Quaternion3D) -> Quaternion3D { .init(x: -q.x, y: -q.y, z: -q.z, w: q.w) }
    public static func length(_ v: SIMD3<Float>) -> Float { sqrt(dot(v,v)) }
    private static func normalized(_ v: SIMD3<Float>) -> SIMD3<Float> { v / max(length(v), 0.000001) }
    private static func finite(_ v: SIMD3<Float>) -> Bool { v.x.isFinite && v.y.isFinite && v.z.isFinite }
    private static func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
    private static func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
        [a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x]
    }
    private static func multiply(_ a: Quaternion3D, _ b: Quaternion3D) -> Quaternion3D {
        let av = SIMD3(a.x,a.y,a.z), bv = SIMD3(b.x,b.y,b.z)
        let v = a.w*bv+b.w*av+cross(av,bv), w = a.w*b.w-dot(av,bv)
        let n = sqrt(dot(v,v)+w*w)
        return .init(x: v.x/n, y: v.y/n, z: v.z/n, w: w/n)
    }
    private static func between(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Quaternion3D {
        let d = dot(a,b)
        if d < -0.99999 {
            let axis = normalized(cross(a, abs(a.x) < 0.8 ? [1,0,0] : [0,1,0]))
            return .init(x: axis.x, y: axis.y, z: axis.z, w: 0)
        }
        let v = cross(a,b), w = 1+d, n = sqrt(dot(v,v)+w*w)
        return .init(x: v.x/n, y: v.y/n, z: v.z/n, w: w/n)
    }
}
