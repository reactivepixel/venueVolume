import RealityKit
import SwiftUI
import VenueVolumeCore

/// Room-axis rings and translation handles. Every segment is a distinct hit target.
@MainActor final class FixtureTransformGizmo {
    let entity = Entity()
    private let rotation = Entity()
    private let movement = Entity()
    private var displayedAxis: FixtureAxis?

    init() {
        entity.name = "fixture-transform-gizmo"
        entity.addChild(rotation); entity.addChild(movement)
        for axis in FixtureAxis.allCases {
            let material = Self.material(axis, selected: false)
            var style = HoverEffectComponent.HighlightHoverEffectStyle.default
            style.strength = 1; style.opacityFunction = .full
            var hover = HoverEffectComponent.HoverEffect.highlight(style)
            if #available(visionOS 26.0, *) { hover = .highlight(style, groupID: .init()) }
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
                Self.target(segment, name: "gizmo:rotate:\(axis.rawValue)", size: [length+0.006,0.045,0.045], hover: hover)
                ring.addChild(segment)
            }
            let arrow = ModelEntity(mesh: .generateCylinder(height: 0.6, radius: 0.009), materials: [material])
            arrow.position = axis.vector * 0.3
            arrow.orientation = simd_quatf(from: [0,1,0], to: axis.vector)
            Self.target(arrow, name: "gizmo:move:\(axis.rawValue)", size: [0.055,0.65,0.055], hover: hover)
            movement.addChild(arrow)
            let tip = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [material])
            tip.position = axis.vector * 0.63
            Self.target(tip, name: "gizmo:move:\(axis.rawValue)", size: [0.09,0.09,0.09], hover: hover)
            movement.addChild(tip)
        }
    }

    func update(fixture: Fixture?, visible: Bool, mode: FixtureTransformMode, selectedAxis: FixtureAxis? = nil) {
        entity.isEnabled = visible && fixture != nil
        guard let fixture else { return }
        entity.position = FixtureAiming.vector(fixture.visualCenter)
        rotation.isEnabled = mode == .rotate
        movement.isEnabled = mode == .move
        guard displayedAxis != selectedAxis else { return }
        displayedAxis = selectedAxis
        for parent in [rotation, movement] {
            for child in parent.children {
                let models: [ModelEntity] = (child as? ModelEntity).map { [$0] } ?? child.children.compactMap { $0 as? ModelEntity }
                for model in models {
                    guard let (axis, _) = Self.handle(model) else { continue }
                    model.model?.materials = [Self.material(axis, selected: axis == selectedAxis)]
                }
            }
        }
    }

    static func handle(_ entity: Entity) -> (FixtureAxis, FixtureTransformMode)? {
        let parts = entity.name.split(separator: ":")
        guard parts.count == 3, parts[0] == "gizmo", let axis = FixtureAxis(rawValue: String(parts[2])) else { return nil }
        return (axis, parts[1] == "rotate" ? .rotate : .move)
    }

    private static func material(_ axis: FixtureAxis, selected: Bool) -> UnlitMaterial {
        let color: UIColor = axis == .x ? .systemRed : axis == .y ? .systemGreen : .systemBlue
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        var material = UnlitMaterial(color: UIColor(hue: hue, saturation: saturation,
            brightness: brightness * (selected ? 1 : 0.4), alpha: 1))
        // Gizmos are editing overlays, including where a fixture intersects a mesh.
        material.readsDepth = false; material.writesDepth = false
        // Depth bypass alone is insufficient in the opaque pass: a later room
        // draw can cover a handle. Render after opaque meshes at full opacity.
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        return material
    }

    private static func target(_ entity: ModelEntity, name: String, size: SIMD3<Float>, hover: HoverEffectComponent.HoverEffect) {
        entity.name = name
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
        entity.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
        entity.components.set(SpatialDragTarget())
        entity.components.set(HoverEffectComponent(hover))
        entity.components.set(ModelSortGroupComponent(group: .planarUIAlwaysInFront, order: 100))
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
    }
}
