import RealityKit
import SwiftUI

/// One lightweight pool renders the tether and target outline. It has no input
/// or collision components, so it cannot intercept fixture or window gestures.
@MainActor final class PresetDragVisual {
    let root = Entity()
    private let segments: [ModelEntity]
    private let outline: [ModelEntity]
    private let tip = ModelEntity(mesh: .generateSphere(radius: 0.012), materials: [UnlitMaterial(color: .cyan)])
    private var feedbackID: UUID?
    private var feedbackStart = Date.distantPast
    private var feedbackBounds: BoundingBox?
    private var feedbackSucceeded = true
    private var reduceMotion = false

    init() {
        let mesh = MeshResource.generateBox(size: 1)
        segments = (0..<80).map { _ in ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .cyan)]) }
        outline = (0..<12).map { _ in ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .white)]) }
        (segments + outline + [tip]).forEach {
            $0.components.set(DynamicLightShadowComponent(castsShadow: false))
            $0.isEnabled = false; root.addChild($0)
        }
    }

    func tether(points: [SIMD3<Float>], snapped: Bool, target: BoundingBox?) {
        segments.forEach { $0.isEnabled = false }
        tip.isEnabled = points.count >= 2
        guard points.count >= 2 else { showOutline(nil, color: .cyan); return }
        tip.position = points.last!
        let material = UnlitMaterial(color: snapped ? .white : .cyan)
        tip.model?.materials = [material]
        var index = 0
        for pair in zip(points, points.dropFirst()) {
            let distance = simd_distance(pair.0, pair.1)
            guard distance > 0.001 else { continue }
            let count = snapped ? 1 : max(1, min(36, Int(ceil(distance/0.045))))
            for step in 0..<count where index < segments.count {
                let start = Float(step)/Float(count)
                let end = snapped ? Float(1) : min(1, start+0.45/Float(count))
                Self.line(segments[index], from: simd_mix(pair.0, pair.1, SIMD3(repeating: start)),
                          to: simd_mix(pair.0, pair.1, SIMD3(repeating: end)), thickness: 0.004)
                segments[index].model?.materials = [material]; index += 1
            }
        }
        showOutline(target, color: .white)
    }

    func feedback(id: UUID, bounds: BoundingBox, succeeded: Bool, reduceMotion: Bool) {
        guard id != feedbackID else { return }
        feedbackID = id; feedbackStart = Date(); feedbackBounds = bounds
        feedbackSucceeded = succeeded; self.reduceMotion = reduceMotion
    }

    func tick() {
        guard let bounds = feedbackBounds else { return }
        let age = Date().timeIntervalSince(feedbackStart)
        guard age < 0.65 else { feedbackBounds = nil; showOutline(nil, color: .white); return }
        showOutline(bounds, color: feedbackSucceeded ? .white : .red)
        // A single brief highlight, never a repeated strobe. Reduce Motion keeps
        // the border steady until it disappears.
        let opacity: Float = reduceMotion ? 1 : Float(max(0, 1-age/0.65))
        outline.forEach { $0.components.set(OpacityComponent(opacity: opacity)) }
    }

    func clear() {
        feedbackBounds = nil
        (segments + outline + [tip]).forEach { $0.isEnabled = false }
    }

    private func showOutline(_ bounds: BoundingBox?, color: UIColor) {
        guard let bounds else {
            if feedbackBounds == nil { outline.forEach { $0.isEnabled = false } }
            return
        }
        let min = bounds.min-SIMD3(repeating: 0.018), max = bounds.max+SIMD3(repeating: 0.018)
        var index = 0
        for axis in 0..<3 {
            for first in 0...1 { for second in 0...1 {
                var start = min, end = min
                let a = (axis+1)%3, b = (axis+2)%3
                start[a] = first == 0 ? min[a] : max[a]; start[b] = second == 0 ? min[b] : max[b]
                end = start; end[axis] = max[axis]
                Self.line(outline[index], from: start, to: end, thickness: 0.007)
                outline[index].model?.materials = [UnlitMaterial(color: color)]
                outline[index].components.set(OpacityComponent(opacity: 1)); index += 1
            } }
        }
    }

    private static func line(_ entity: ModelEntity, from start: SIMD3<Float>, to end: SIMD3<Float>, thickness: Float) {
        let delta = end-start, length = simd_length(delta)
        guard length > 0.0001 else { entity.isEnabled = false; return }
        entity.position = (start+end)/2
        entity.scale = [thickness, thickness, length]
        entity.orientation = simd_quatf(from: [0,0,1], to: delta/length)
        entity.isEnabled = true
    }
}
