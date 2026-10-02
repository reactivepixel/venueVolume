import RealityKit
import SwiftUI
import VenueVolumeCore

/// Wrapper joints preserve the authored rest pose and animate rigid components.
@MainActor final class FixtureRig {
    let entity = Entity()
    let assetID: String
    private let descriptor: FixtureAsset
    private var joints: [String: Entity] = [:]
    private var lights: [Entity] = []
    private var requested: [String: Float] = [:]
    private var current: [String: Float] = [:]
    private var starts: [String: Float] = [:]
    private var elapsed: [String: Double] = [:]
    private var lastBase: Transform?
    private let duration: Double = 0.6
    private let selection: ModelEntity

    init(template: Entity, id: UUID, descriptor: FixtureAsset = FixtureCatalog.asset(LightingPreview.assetID)!) throws {
        self.descriptor = descriptor; assetID = descriptor.id
        let asset = template.clone(recursive: true)
        entity.name = id.uuidString
        entity.addChild(asset)
        if !descriptor.emitters.isEmpty { Self.disableSelfShadows(asset) }
        let sourceRoot = asset.findEntity(named: "Fixture") ?? asset
        func resolve(_ path: String) -> Entity? {
            let components = path.split(separator: "/").map(String.init)
            return components.dropFirst().reduce(Optional(sourceRoot)) { parent, name in
                parent?.children.first(where: { $0.name == name })
            }
        }
        var members: [String: [Entity]] = [:]
        for definition in descriptor.joints {
            members[definition.id] = try definition.members.map { path in
                guard let part = resolve(path) else { throw EnvironmentError.invalid("\(descriptor.name): missing rig part \(path)") }
                return part
            }
        }
        for definition in descriptor.joints {
            let joint = Entity()
            joint.name = "vv-joint:" + definition.id
            entity.addChild(joint)
            joint.position = Self.vector(definition.pivot)
            if let parent = definition.parent {
                guard let parentJoint = joints[parent] else { throw EnvironmentError.invalid("Invalid joint parent: \(parent)") }
                joint.setParent(parentJoint, preservingWorldTransform: true)
            }
            for part in members[definition.id] ?? [] { part.setParent(joint, preservingWorldTransform: true) }
            joints[definition.id] = joint
        }
        for (index, definition) in descriptor.emitters.enumerated() {
            let emitter = Entity()
            emitter.name = "vv-light:\(index)"
            entity.addChild(emitter)
            emitter.position = Self.vector(definition.position)
            emitter.orientation = simd_quatf(from: [0,0,-1], to: Self.vector(definition.axis))
            if let parent = definition.parent, let joint = joints[parent] { emitter.setParent(joint, preservingWorldTransform: true) }
            lights.append(emitter)
        }
        let low = Self.vector(descriptor.boundsMin), high = Self.vector(descriptor.boundsMax)
        let size = simd_max(high-low, SIMD3<Float>(repeating: 0.04))
        let target = Entity()
        target.name = id.uuidString
        target.position = (low+high)/2
        target.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
        target.components.set(InputTargetComponent())
        target.components.set(HoverEffectComponent())
        entity.addChild(target)
        selection = ModelEntity(mesh: .generateBox(width: size.x+0.04, height: 0.004, depth: size.z+0.04),
                                materials: [UnlitMaterial(color: UIColor.cyan.withAlphaComponent(0.35))])
        selection.position = [(low.x+high.x)/2, low.y+0.003, (low.z+high.z)/2]
        selection.components.set(DynamicLightShadowComponent(castsShadow: false))
        entity.addChild(selection)
    }

    func update(fixture: Fixture, channels: [Int], selected: Bool, blackout: Bool, placing: Bool,
                interactive: Bool = false, lightBudget: Int = 4) {
        let base = Transform(scale: FixtureAiming.vector(fixture.scale),
                             rotation: simd_quatf(ix: fixture.orientation.x, iy: fixture.orientation.y, iz: fixture.orientation.z, r: fixture.orientation.w),
                             translation: FixtureAiming.vector(fixture.position))
        if lastBase != base {
            if lastBase == nil || interactive { entity.transform = base }
            else { entity.move(to: base, relativeTo: entity.parent, duration: duration, timingFunction: .easeInOut) }
            lastBase = base
        }
        for definition in descriptor.joints {
            let id = definition.id, value = definition.value(channels: channels)
            if requested[id] != value {
                if current[id] == nil { current[id] = definition.continuous ? 0 : value }
                starts[id] = current[id]; requested[id] = value; elapsed[id] = 0
            }
        }
        tick(deltaTime: 0)
        let look = LightingPreview(channels: channels, blackout: blackout)
        for (index, emitter) in lights.enumerated() {
            if index >= lightBudget || look.intensity == 0 {
                emitter.components.remove(SpotLightComponent.self)
                emitter.components.remove(SpotLightComponent.Shadow.self)
                continue
            }
            var light = SpotLightComponent()
            light.intensity = look.intensity / Float(max(1, lights.count))
            light.color = UIColor(red: CGFloat(look.rgb[0]), green: CGFloat(look.rgb[1]), blue: CGFloat(look.rgb[2]), alpha: 1)
            light.attenuationRadius = 12
            light.innerAngleInDegrees = look.outerAngle * 0.7
            light.outerAngleInDegrees = look.outerAngle
            emitter.components.set(light)
            emitter.components.set(SpotLightComponent.Shadow())
        }
        selection.isEnabled = selected && !placing
        for child in entity.children where child.components.has(InputTargetComponent.self) {
            child.components.set(InputTargetComponent(allowedInputTypes: placing ? [] : [.indirect, .direct]))
        }
    }

    func tick(deltaTime: Double) {
        for definition in descriptor.joints {
            let id = definition.id
            guard let value = requested[id], let joint = joints[id] else { continue }
            if definition.continuous {
                current[id] = ((current[id] ?? 0) + value * Float(max(0, min(deltaTime, 0.1)))).truncatingRemainder(dividingBy: 360)
            } else {
                let time = min(duration, (elapsed[id] ?? 0) + max(0, deltaTime))
                elapsed[id] = time
                let t = Float(time/duration), eased = t*t*(3-2*t), start = starts[id] ?? value
                current[id] = start + (value-start)*eased
            }
            joint.orientation = simd_quatf(angle: (current[id] ?? 0) * .pi/180, axis: Self.vector(definition.axis))
        }
    }

    private static func vector(_ values: [Float]) -> SIMD3<Float> { [values[0],values[1],values[2]] }
    #if DEBUG
    func checkEmitterPose(channels: [Int]) throws {
        guard let emitter = lights.first else { return }
        let expected = FixtureAiming.localRay(channels: channels, asset: descriptor)
        let transform = emitter.transformMatrix(relativeTo: entity)
        let origin = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let forward = -SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        guard simd_distance(origin, expected.origin) < 0.0002, simd_distance(forward, expected.direction) < 0.0002 else {
            throw EnvironmentError.invalid("\(descriptor.id): RealityKit emitter pose differs from targeting geometry")
        }
    }
    #endif
    private static func disableSelfShadows(_ entity: Entity) {
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        for child in entity.children { disableSelfShadows(child) }
    }
}
