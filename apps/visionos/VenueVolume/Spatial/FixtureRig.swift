import RealityKit
import SwiftUI
import VenueVolumeCore

/// Adds articulation and a real shadow-casting light to the catalog's editable USDZ.
@MainActor final class FixtureRig {
    let entity = Entity()
    private let yoke: Entity
    private let head: Entity
    private let emitter: Entity
    private let selection: ModelEntity

    init(template: Entity, id: UUID) throws {
        let asset = template.clone(recursive: true)
        guard let yoke = asset.findEntity(named: "Yoke"),
              let head = asset.findEntity(named: "Head"),
              let emitter = asset.findEntity(named: "Emitter") else {
            throw EnvironmentError.invalid("fixture asset is missing Yoke, Head or Emitter pivots")
        }
        self.yoke = yoke; self.head = head; self.emitter = emitter
        entity.name = id.uuidString
        entity.addChild(asset)
        // The catalog exports Yoke and Head as siblings with room-local pivots.
        // Preserve the authored rest pose while making tilt inherit pan.
        head.setParent(yoke, preservingWorldTransform: true)
        var light = SpotLightComponent()
        light.intensity = 0
        light.attenuationRadius = 12
        emitter.components.set(light)
        emitter.components.set(SpotLightComponent.Shadow())
        // Prevent the tiny lens/trim meshes intersecting the emitter from blocking its beam.
        Self.disableSelfShadows(asset)
        let target = Entity()
        target.name = id.uuidString
        target.position.y = LightingPreview.height/2
        target.components.set(CollisionComponent(shapes: [.generateBox(size: [0.4, 0.48, 0.34])]))
        target.components.set(InputTargetComponent())
        target.components.set(HoverEffectComponent())
        entity.addChild(target)
        selection = ModelEntity(mesh: .generateBox(width: 0.42, height: 0.004, depth: 0.34),
                                materials: [UnlitMaterial(color: UIColor.cyan.withAlphaComponent(0.35))])
        selection.position.y = 0.003
        selection.components.set(DynamicLightShadowComponent(castsShadow: false))
        entity.addChild(selection)
    }

    func update(fixture: Fixture, channels: [Int], selected: Bool, blackout: Bool, placing: Bool) {
        entity.position = [fixture.position.x, fixture.position.y, fixture.position.z]
        entity.orientation = simd_quatf(ix: fixture.orientation.x, iy: fixture.orientation.y, iz: fixture.orientation.z, r: fixture.orientation.w)
        entity.scale = [fixture.scale.x, fixture.scale.y, fixture.scale.z]
        let look = LightingPreview(channels: channels, blackout: blackout)
        yoke.orientation = simd_quatf(angle: look.panDegrees * .pi/180, axis: [0,1,0])
        head.orientation = simd_quatf(angle: look.tiltDegrees * .pi/180, axis: [1,0,0])
        var light = SpotLightComponent()
        light.intensity = look.intensity
        light.color = UIColor(red: CGFloat(look.rgb[0]), green: CGFloat(look.rgb[1]), blue: CGFloat(look.rgb[2]), alpha: 1)
        light.attenuationRadius = 12
        light.innerAngleInDegrees = look.outerAngle * 0.7
        light.outerAngleInDegrees = look.outerAngle
        emitter.components.set(light)
        selection.isEnabled = selected && !placing
        for child in entity.children where child.components.has(InputTargetComponent.self) {
            child.components.set(InputTargetComponent(allowedInputTypes: placing ? [] : [.indirect, .direct]))
        }
    }

    private static func disableSelfShadows(_ entity: Entity) {
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        for child in entity.children { disableSelfShadows(child) }
    }
}
