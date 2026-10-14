import Foundation

/// Uses only the tracked wrist: finger occlusion and palm orientation must not
/// prevent the selection Toolbox from opening. Coordinates share a world frame.
public enum WristAttention {
    public static func isAttended(wrist: SIMD3<Float>?, eye: SIMD3<Float>, forward: SIMD3<Float>) -> Bool {
        guard let wrist else { return false }
        let ray = wrist-eye
        func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
        let distance = sqrt(dot(ray,ray)), forwardLength = sqrt(dot(forward,forward))
        guard distance > 0.12, distance < 1.2, forwardLength > 0.001 else { return false }
        return dot(ray/distance,forward/forwardLength) > 0.9
    }
}
