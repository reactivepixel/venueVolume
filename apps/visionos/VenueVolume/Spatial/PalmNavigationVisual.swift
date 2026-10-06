import RealityKit
import SwiftUI
import VenueVolumeCore

/// System gaze targeting + right-hand pinch/drag operate these input targets.
/// We never synthesize an eye ray or bind locomotion to finger-motion updates.
@MainActor
final class PalmNavigationVisual {
    let entity = Entity()
    private let marker = ModelEntity()
    private let rings = Entity()
    private var projection: PalmMapProjection?
    private var roomID: String?
    private var proposed: Position3D?
    private var dragStart: SIMD3<Float>?
    private var dragMarkerStart = SIMD3<Float>.zero
    private var rotationAxis: Int?
    private var rotationStart: Float?
    private var rotationAmount: Float = 0
    private var moved = false
    private(set) var rotating = false
    var dragging: Bool { dragStart != nil }

    init() {
        entity.name = "PalmNavigationMap"
        marker.name = "palm-map-viewpoint"
        marker.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
        marker.components.set(HoverEffectComponent())
        marker.components.set(SpatialDragTarget())
        entity.addChild(marker); entity.addChild(rings)
        entity.isEnabled = false
    }

    func update(environment: EnvironmentManifest, viewpoint: SIMD3<Float>, worldPosition: SIMD3<Float>, orientation: simd_quatf, visible: Bool) {
        if roomID != environment.id + ":" + environment.version {
            roomID = environment.id + ":" + environment.version
            projection = PalmMapProjection(minimum: environment.bounds.min, maximum: environment.bounds.max)
            rebuild(environment)
        }
        entity.isEnabled = visible
        guard visible, let projection, !dragging else { return }
        entity.position = worldPosition
        entity.orientation = orientation
        let point = projection.map([viewpoint.x, viewpoint.z])
        marker.position = [point.x, -point.y, 0.009]
        rings.position = marker.position
        rings.isEnabled = rotating
    }

    private func rebuild(_ environment: EnvironmentManifest) {
        guard let projection else { return }
        for child in Array(entity.children) where child != marker && child != rings { child.removeFromParent() }
        for child in Array(rings.children) { child.removeFromParent() }
        let scale = projection.metersToMap
        let width = (environment.bounds.max[0]-environment.bounds.min[0])*scale
        let height = (environment.bounds.max[2]-environment.bounds.min[2])*scale
        let panel = ModelEntity(mesh: .generateBox(size: [width+0.012, height+0.012, 0.003]), materials: [Self.material(.black, alpha: 0.8)])
        panel.position.z = -0.004
        entity.addChild(panel)
        for surface in environment.surfaces where surface.role == "floor" || surface.role == "tabletop" {
            let p = projection.map([surface.center[0], surface.center[2]])
            let w = surface.size[0]*scale, h = surface.size[1]*scale
            for (offset, size) in [(SIMD3<Float>(0,h/2,0), SIMD3<Float>(w,0.001,0.001)),
                                   (SIMD3<Float>(0,-h/2,0), SIMD3<Float>(w,0.001,0.001)),
                                   (SIMD3<Float>(w/2,0,0), SIMD3<Float>(0.001,h,0.001)),
                                   (SIMD3<Float>(-w/2,0,0), SIMD3<Float>(0.001,h,0.001))] {
                let edge = ModelEntity(mesh: .generateBox(size: size), materials: [Self.material(surface.role == "floor" ? .white : .gray)])
                edge.position = SIMD3(p.x,-p.y,0) + offset; entity.addChild(edge)
            }
        }
        // Structural walls and furniture footprints complete the floor plan.
        for box in environment.colliders where box.center[1] + box.size[1]/2 > 0.15 && box.center[1] - box.size[1]/2 < 1.8 {
            let rotation = simd_quatf(ix: box.rotation[0],iy: box.rotation[1],iz: box.rotation[2],r: box.rotation[3])
            let center = SIMD3<Float>(box.center[0],box.center[1],box.center[2])
            let corners = [SIMD3<Float>(-box.size[0]/2,0,-box.size[2]/2),
                           SIMD3<Float>(box.size[0]/2,0,-box.size[2]/2),
                           SIMD3<Float>(box.size[0]/2,0,box.size[2]/2),
                           SIMD3<Float>(-box.size[0]/2,0,box.size[2]/2)].map { offset -> SIMD2<Float> in
                let world = center+rotation.act(offset)
                return projection.map([world.x,world.z])
            }
            for index in 0..<4 {
                let a = corners[index], b = corners[(index+1)%4], delta = b-a
                let length = simd_length(delta)
                guard length > 0.0001 else { continue }
                let edge = ModelEntity(mesh: .generateBox(size: [length,0.0007,0.0007]),materials: [Self.material(.gray,alpha: 0.65)])
                edge.position = [(a.x+b.x)/2,-(a.y+b.y)/2,0.001]
                edge.orientation = simd_quatf(angle: -atan2(delta.y,delta.x),axis: [0,0,1])
                entity.addChild(edge)
            }
        }
        // A half-meter footprint, 1.7m height, in the same venue-to-map scale.
        let size = SIMD3<Float>(0.5*scale, 0.5*scale, 1.7*scale)
        marker.model = ModelComponent(mesh: .generateBox(size: size), materials: [Self.material(.cyan)])
        // Generous target while keeping the visible marker human-scaled.
        marker.components.set(CollisionComponent(shapes: [.generateBox(size: [max(size.x,0.016),max(size.y,0.016),size.z])]))
        for axis in 0..<3 {
            for index in 0..<48 {
                let angle = Float(index)*2*Float.pi/48
                var p = SIMD3<Float>.zero
                p[(axis+1)%3] = cos(angle)*0.032
                p[(axis+2)%3] = sin(angle)*0.032
                let dot = ModelEntity(mesh: .generateSphere(radius: 0.0016), materials: [Self.material([UIColor.red,.green,.blue][axis], alpha: 0.45)])
                dot.name = "palm-map-axis-\(axis)"; dot.position = p
                dot.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.004)]))
                dot.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
                dot.components.set(HoverEffectComponent()); dot.components.set(SpatialDragTarget())
                rings.addChild(dot)
            }
        }
        rings.isEnabled = false
    }

    func tap(_ target: Entity) -> Bool {
        guard target.name == marker.name || target.name.hasPrefix("palm-map-axis-") else { return false }
        rotating.toggle(); rings.isEnabled = rotating
        return true
    }

    func drag(_ target: Entity, worldPoint: SIMD3<Float>, worldStart: SIMD3<Float>, environment: EnvironmentManifest) -> Bool {
        guard target.name == marker.name || target.name.hasPrefix("palm-map-axis-"), let projection, entity.isEnabled else { return false }
        let point = entity.convert(position: worldPoint, from: nil)
        let start = entity.convert(position: worldStart, from: nil)
        if dragStart == nil {
            dragStart = start; dragMarkerStart = marker.position; moved = false
            rotationAxis = target.name.hasPrefix("palm-map-axis-") ? Int(target.name.suffix(1)) : nil
            rotationAmount = 0; rotationStart = nil
        }
        if let axis = rotationAxis {
            let offset = point - dragMarkerStart
            let angle = atan2(offset[(axis+2)%3], offset[(axis+1)%3])
            if let previous = rotationStart {
                var delta = angle-previous
                if delta > .pi { delta -= 2 * .pi }
                if delta < -.pi { delta += 2 * .pi }
                rotationAmount += delta
            }
            rotationStart = angle
            moved = moved || abs(rotationAmount) > 0.02
            for child in rings.children {
                if var material = (child as? ModelEntity)?.model?.materials.first as? UnlitMaterial {
                    material.blending = .transparent(opacity: .init(floatLiteral: child.name == target.name ? 1 : 0.25))
                    (child as? ModelEntity)?.model?.materials = [material]
                }
            }
        } else {
            let delta = point-start
            moved = moved || simd_length(delta) > 0.006
            let proposedMap = SIMD2(dragMarkerStart.x+delta.x, -dragMarkerStart.y-delta.y)
            let room = projection.room(proposedMap)
            proposed = PalmMapProjection.destination(room, in: environment)
            marker.position = [proposedMap.x,-proposedMap.y,dragMarkerStart.z]
            marker.model?.materials = [Self.material(proposed == nil ? .red : .cyan)]
            rings.position = marker.position
        }
        return true
    }

    enum Action { case teleport(Position3D), rotate(Int, Float) }
    func finish() -> Action? {
        defer { dragStart = nil; proposed = nil; rotationAxis = nil; rotationStart = nil; moved = false }
        guard dragging else { return nil }
        if !moved { rotating.toggle(); rings.isEnabled = rotating; return nil }
        if let axis = rotationAxis { return .rotate(axis,rotationAmount) }
        if let proposed { rotating = false; rings.isEnabled = false; return .teleport(proposed) }
        return nil
    }

    func cancel() { dragStart = nil; proposed = nil; rotationAxis = nil; rotationStart = nil; moved = false }

    private static func material(_ color: UIColor, alpha: Float = 1) -> UnlitMaterial {
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        return material
    }
}
