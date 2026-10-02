import RealityKit
import SwiftUI
import VenueVolumeCore

/// Room-axis rings and translation handles. Every segment is a distinct hit target.
@MainActor final class FixtureTransformGizmo {
    let entity = Entity()
    private let rotation = Entity()
    private let movement = Entity()

    init() {
        entity.name = "fixture-transform-gizmo"
        entity.addChild(rotation); entity.addChild(movement)
        for axis in FixtureAxis.allCases {
            let color: UIColor = axis == .x ? .systemRed : axis == .y ? .systemGreen : .systemBlue
            let material = UnlitMaterial(color: color)
            let ring = Entity()
            ring.orientation = simd_quatf(from: [0,0,1], to: axis.vector)
            rotation.addChild(ring)
            let radius: Float = 0.42, count = 64
            let length = 2 * Float.pi * radius / Float(count)
            for index in 0..<count {
                let angle = Float(index) * 2 * .pi / Float(count)
                let segment = ModelEntity(mesh: .generateBox(size: [length+0.002, 0.012, 0.012]), materials: [material])
                segment.position = [cos(angle)*radius, sin(angle)*radius, 0]
                segment.orientation = simd_quatf(angle: angle + .pi/2, axis: [0,0,1])
                Self.target(segment, name: "gizmo:rotate:\(axis.rawValue)", size: [length+0.006,0.045,0.045])
                ring.addChild(segment)
            }
            let arrow = ModelEntity(mesh: .generateCylinder(height: 0.6, radius: 0.009), materials: [material])
            arrow.position = axis.vector * 0.3
            arrow.orientation = simd_quatf(from: [0,1,0], to: axis.vector)
            Self.target(arrow, name: "gizmo:move:\(axis.rawValue)", size: [0.055,0.65,0.055])
            movement.addChild(arrow)
            let tip = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [material])
            tip.position = axis.vector * 0.63
            Self.target(tip, name: "gizmo:move:\(axis.rawValue)", size: [0.09,0.09,0.09])
            movement.addChild(tip)
        }
    }

    func update(fixture: Fixture?, visible: Bool, mode: FixtureTransformMode) {
        entity.isEnabled = visible && fixture != nil
        guard let fixture else { return }
        entity.position = FixtureAiming.vector(fixture.position) + [0, fixture.assetID == nil ? 0 : LightingPreview.height/2, 0]
        rotation.isEnabled = mode == .rotate
        movement.isEnabled = mode == .move
    }

    static func handle(_ entity: Entity) -> (FixtureAxis, FixtureTransformMode)? {
        let parts = entity.name.split(separator: ":")
        guard parts.count == 3, parts[0] == "gizmo", let axis = FixtureAxis(rawValue: String(parts[2])) else { return nil }
        return (axis, parts[1] == "rotate" ? .rotate : .move)
    }

    private static func target(_ entity: ModelEntity, name: String, size: SIMD3<Float>) {
        entity.name = name
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
    }
}
