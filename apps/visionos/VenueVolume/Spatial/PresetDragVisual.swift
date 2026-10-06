import RealityKit
import SwiftUI

/// A viewer-to-target cable. Pooled geometry never participates in hit testing.
@MainActor final class PresetDragVisual {
    let root = Entity()
    private let segments: [ModelEntity]
    private let dots: [ModelEntity]
    private let ring: [ModelEntity]
    private let outline: [ModelEntity]
    private let tip = ModelEntity(mesh: .generateSphere(radius: 0.009), materials: [UnlitMaterial(color: .white)])
    private var origin: SIMD3<Float>?
    private var destination = SIMD3<Float>.zero
    private var displayedEnd: SIMD3<Float>?
    private var targetID: UUID?
    private var targetBounds: BoundingBox?
    private var snapStart = Date.distantPast
    private var lastTick = Date()
    private var feedbackID: UUID?
    private var feedbackStart = Date.distantPast
    private var feedbackBounds: BoundingBox?
    private var feedbackSucceeded = true
    private var reduceMotion = false
    private let warm = UIColor(red: 1, green: 0.82, blue: 0.43, alpha: 1)

    #if DEBUG
    var visibleOrigin: SIMD3<Float>? { origin }
    var hasTether: Bool { origin != nil }
    var isSnapped: Bool { targetID != nil }
    #endif

    init() {
        let mesh = MeshResource.generateBox(size: 1)
        let white = UnlitMaterial(color: .white)
        segments = (0..<80).map { _ in ModelEntity(mesh: mesh, materials: [white]) }
        dots = (0..<80).map { _ in ModelEntity(mesh: .generateSphere(radius: 0.0045), materials: [white]) }
        ring = (0..<32).map { _ in ModelEntity(mesh: mesh, materials: [white]) }
        outline = (0..<12).map { _ in ModelEntity(mesh: mesh, materials: [white]) }
        (segments + dots + ring + outline + [tip]).forEach {
            $0.components.set(DynamicLightShadowComponent(castsShadow: false))
            $0.isEnabled = false; root.addChild($0)
        }
    }

    func tether(origin: SIMD3<Float>?, end: SIMD3<Float> = .zero, targetID: UUID? = nil,
                target: BoundingBox? = nil, reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        if self.origin == nil { displayedEnd = end }
        if self.targetID != targetID { snapStart = Date() }
        self.origin = origin; destination = end; self.targetID = targetID; targetBounds = target
        if origin == nil {
            displayedEnd = nil
            (segments + dots + ring + [tip]).forEach { $0.isEnabled = false }
            if feedbackBounds == nil { showOutline(nil, color: .white) }
        }
    }

    func feedback(id: UUID, bounds: BoundingBox, succeeded: Bool, reduceMotion: Bool) {
        guard id != feedbackID else { return }
        feedbackID = id; feedbackStart = Date(); feedbackBounds = bounds
        feedbackSucceeded = succeeded; self.reduceMotion = reduceMotion
    }

    func tick() {
        let now = Date(), dt = min(0.05, max(0, now.timeIntervalSince(lastTick)))
        lastTick = now
        if let origin {
            let end = reduceMotion ? destination : simd_mix(displayedEnd ?? destination, destination, SIMD3(repeating: Float(1-exp(-dt*24))))
            displayedEnd = end
            drawCable(from: origin, to: end, age: now.timeIntervalSince(snapStart))
            showOutline(targetBounds, color: warm)
        }
        if let bounds = feedbackBounds {
            let age = now.timeIntervalSince(feedbackStart)
            if age < 0.65 {
                showOutline(bounds, color: feedbackSucceeded ? .white : .red)
                let opacity: Float = reduceMotion ? 1 : Float(max(0, 1-age/0.65))
                outline.forEach { $0.components.set(OpacityComponent(opacity: opacity)) }
            } else {
                feedbackBounds = nil
                if origin == nil { showOutline(nil, color: .white) }
            }
        }
    }

    private func drawCable(from start: SIMD3<Float>, to end: SIMD3<Float>, age: Double) {
        let delta = end-start, distance = simd_length(delta)
        guard distance > 0.001 else {
            (segments + dots + ring + [tip]).forEach { $0.isEnabled = false }; return
        }
        let snapped = targetID != nil
        let sag = SIMD3<Float>(0, -min(0.16, distance*0.065), 0)
        let p1 = start+delta*0.33+sag, p2 = start+delta*0.78+sag*0.5
        let normal = delta/distance
        let side = simd_normalize(simd_cross(abs(normal.y) < 0.95 ? SIMD3(0,1,0) : SIMD3(1,0,0), normal))
        let up = simd_cross(normal, side)
        func point(_ t: Float) -> SIMD3<Float> {
            let u = 1-t
            let curve = start*(u*u*u)+p1*(3*u*u*t)+p2*(3*u*t*t)+end*(t*t*t)
            // One small settling ripple near the endpoint; no constant oscillation.
            let envelope = snapped && !reduceMotion && age < 0.45 ? Float(exp(-age*12))*0.025 : 0
            let ripple = sin(t * .pi * 10 - Float(age)*26)*sin(t * .pi)*pow(t,4)*envelope
            return curve+up*ripple
        }
        if snapped {
            dots.forEach { $0.isEnabled = false }
            for i in segments.indices {
                Self.line(segments[i], from: point(Float(i)/80), to: point(Float(i+1)/80), thickness: 0.0035)
            }
        } else {
            segments.forEach { $0.isEnabled = false }
            let count = max(2,min(dots.count,Int(ceil(distance/0.045))))
            for i in dots.indices {
                dots[i].isEnabled = i < count
                if i < count { dots[i].position = point(Float(i)/Float(count-1)) }
            }
        }
        tip.position = end; tip.isEnabled = true
        tip.model?.materials = [UnlitMaterial(color: snapped ? warm : .white)]
        let settle = snapped && !reduceMotion && age < 0.4 ? Float(exp(-age*10)*sin(age*24))*0.012 : 0
        let radius: Float = (snapped ? 0.028 : 0.016)+settle
        for i in ring.indices {
            let a = Float(i)/32 * .pi*2, b = Float(i+1)/32 * .pi*2
            Self.line(ring[i], from: end+(side*cos(a)+up*sin(a))*radius,
                      to: end+(side*cos(b)+up*sin(b))*radius, thickness: 0.0025)
            ring[i].model?.materials = [UnlitMaterial(color: snapped ? warm : .white)]
        }
    }

    func clear() {
        origin = nil; displayedEnd = nil; targetID = nil; targetBounds = nil; feedbackBounds = nil
        (segments + dots + ring + outline + [tip]).forEach { $0.isEnabled = false }
    }

    private func showOutline(_ bounds: BoundingBox?, color: UIColor) {
        guard let bounds else { outline.forEach { $0.isEnabled = false }; return }
        let min = bounds.min-SIMD3(repeating: 0.018), max = bounds.max+SIMD3(repeating: 0.018)
        var index = 0
        for axis in 0..<3 {
            for first in 0...1 { for second in 0...1 {
                var start = min, end = min
                let a = (axis+1)%3, b = (axis+2)%3
                start[a] = first == 0 ? min[a] : max[a]; start[b] = second == 0 ? min[b] : max[b]
                end = start; end[axis] = max[axis]
                Self.line(outline[index], from: start, to: end, thickness: 0.003)
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
