import RealityKit
import SwiftUI
import VenueVolumeCore

/// An isometric miniature. A blocked proposal stays selected so it can be raised
/// or moved again; only the explicit Teleport target commits a clear destination.
@MainActor
final class PalmNavigationVisual {
    let entity = Entity()
    private let map = Entity()
    private let marker = ModelEntity()
    private let handles = Entity()
    private let feedback = Entity()
    private var projection: PalmMapProjection?
    private var roomID: String?
    private var obstacles: [EnvironmentManifest.Collider] = []
    private var elevation: Float = 0
    private var proposed: Position3D?
    private var dragStart: SIMD3<Float>?
    private var dragProposal = Position3D(x: 0, y: 0, z: 0)
    private var dragAxis: Int?
    private var selected = false
    private var issue: String?
    private var feedbackText = ""
    var dragging: Bool { dragStart != nil }
    var message: String { issue ?? "Drag the cube or its handles, then select Teleport." }

    init() {
        entity.name = "PalmNavigationMap"
        map.orientation = simd_quatf(angle: PalmMapProjection.pitch, axis: [1,0,0]) * simd_quatf(angle: PalmMapProjection.yaw, axis: [0,1,0])
        marker.name = "palm-map-viewpoint"
        Self.input(marker, draggable: true)
        map.addChild(marker); map.addChild(handles)
        entity.addChild(map); entity.addChild(feedback)
        entity.isEnabled = false
    }

    func update(environment: EnvironmentManifest, viewpoint: SIMD3<Float>, worldPosition: SIMD3<Float>, orientation: simd_quatf, visible: Bool) {
        if roomID != environment.id + ":" + environment.version {
            roomID = environment.id + ":" + environment.version
            projection = PalmMapProjection(minimum: environment.bounds.min, maximum: environment.bounds.max)
            proposed = nil
            obstacles = []; rebuild(environment)
        }
        if obstacles != environment.colliders {
            obstacles = environment.colliders; rebuild(environment)
        }
        entity.isEnabled = visible
        guard visible, let projection else { return }
        if !dragging { entity.position = worldPosition; entity.orientation = orientation }
        if proposed == nil {
            // The scene supplies the floor-relative feet position.
            proposed = .init(x: viewpoint.x, y: max(PalmMapProjection.floorHeight([viewpoint.x,viewpoint.z], in: environment), viewpoint.y), z: viewpoint.z)
        }
        if let proposed {
            let p = projection.map([proposed.x,proposed.z])
            marker.position = [p.x, (proposed.y - environment.bounds.min[1] + 0.85)*projection.metersToMap, p.y]
            issue = PalmMapProjection.obstruction(proposed, in: environment)
            elevation = max(0, proposed.y - PalmMapProjection.floorHeight([proposed.x,proposed.z], in: environment))
        }
        marker.model?.materials = [Self.material(issue == nil ? .cyan : .yellow)]
        handles.position = marker.position; handles.isEnabled = selected
        showFeedback()
    }

    private func rebuild(_ environment: EnvironmentManifest) {
        guard let projection else { return }
        for child in Array(map.children) where child != marker && child != handles { child.removeFromParent() }
        for child in Array(handles.children) { child.removeFromParent() }
        let scale = projection.metersToMap
        let width = (environment.bounds.max[0]-environment.bounds.min[0])*scale
        let depth = (environment.bounds.max[2]-environment.bounds.min[2])*scale
        let panel = ModelEntity(mesh: .generateBox(size: [width,0.002,depth]), materials: [Self.material(.darkGray, alpha: 0.85)])
        panel.name = "palm-map-floor"
        panel.position.y = -0.002
        panel.components.set(CollisionComponent(shapes: [.generateBox(size: [width,0.004,depth])]))
        Self.input(panel)
        map.addChild(panel)
        let floorIDs = Set(environment.surfaces.filter { $0.role == "floor" }.map(\.id))
        for box in environment.colliders {
            let rotation = simd_quatf(ix: box.rotation[0],iy: box.rotation[1],iz: box.rotation[2],r: box.rotation[3])
            let half = SIMD3<Float>(box.size[0],box.size[1],box.size[2])/2
            func magnitude(_ v: SIMD3<Float>) -> SIMD3<Float> { [abs(v.x),abs(v.y),abs(v.z)] }
            let envelope = magnitude(rotation.act([half.x,0,0])) + magnitude(rotation.act([0,half.y,0])) + magnitude(rotation.act([0,0,half.z]))
            // A roofless miniature with wireframe walls keeps interior objects and
            // the selected cube visible. All colliders still participate in validation.
            guard !floorIDs.contains(box.sourceID), box.center[1]-envelope.y < environment.bounds.max[1]-0.2,
                  !box.id.localizedCaseInsensitiveContains("ceiling") else { continue }
            let p = projection.map([box.center[0],box.center[2]])
            let size = half*2*scale
            let shape = Entity()
            shape.position = [p.x,(box.center[1]-environment.bounds.min[1])*scale,p.y]
            shape.orientation = rotation
            if envelope.y > 0.7 && min(envelope.x,envelope.z) < 0.35 {
                for axis in 0..<3 {
                    let a = (axis+1)%3, b = (axis+2)%3
                    for signA: Float in [-1,1] { for signB: Float in [-1,1] {
                        var edgeSize = SIMD3<Float>(repeating: 0.0007); edgeSize[axis] = size[axis]
                        let edge = ModelEntity(mesh: .generateBox(size: edgeSize), materials: [Self.material(.lightGray,alpha: 0.45)])
                        edge.position[a] = signA*size[a]/2; edge.position[b] = signB*size[b]/2
                        shape.addChild(edge)
                    } }
                }
            } else {
                shape.addChild(ModelEntity(mesh: .generateBox(size: size), materials: [Self.material(.lightGray, alpha: 0.6)]))
            }
            map.addChild(shape)
        }
        let size = SIMD3<Float>(0.5,1.7,0.5)*scale
        marker.model = ModelComponent(mesh: .generateBox(size: size), materials: [Self.material(.cyan)])
        marker.components.set(CollisionComponent(shapes: [.generateBox(size: [max(size.x,0.016),max(size.y,0.024),max(size.z,0.016)])]))
        for axis in 0..<3 {
            var size = SIMD3<Float>(repeating: 0.0015); size[axis] = 0.038
            let color: UIColor = axis == 1 ? .white : .cyan
            let shaft = ModelEntity(mesh: .generateBox(size: size), materials: [Self.material(color)])
            shaft.position[axis] = 0.019
            handles.addChild(shaft)
            let tip = ModelEntity(mesh: .generateSphere(radius: 0.005), materials: [Self.material(color)])
            tip.name = "palm-map-move-\(axis)"; tip.position[axis] = 0.043
            tip.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.01)]))
            Self.input(tip, draggable: true); handles.addChild(tip)
        }
        feedbackText = ""
    }

    func tap(_ target: Entity, worldPoint: SIMD3<Float>, environment: EnvironmentManifest) -> Action? {
        guard entity.isEnabled, let projection else { return nil }
        if target.name == "palm-map-teleport", let proposed {
            guard PalmMapProjection.obstruction(proposed, in: environment) == nil else { return nil }
            return .teleport(proposed)
        }
        if target.name == "palm-map-floor" {
            let local = map.convert(position: worldPoint, from: nil)
            let room = projection.room([local.x,local.z])
            proposed = .init(x: room.x, y: PalmMapProjection.floorHeight(room, in: environment), z: room.y)
            selected = true
        } else if target.name == marker.name || target.name.hasPrefix("palm-map-move-") { selected = true }
        return nil
    }

    func drag(_ target: Entity, worldPoint: SIMD3<Float>, worldStart: SIMD3<Float>, environment: EnvironmentManifest) -> Bool {
        guard target.name == marker.name || target.name.hasPrefix("palm-map-move-"), let projection, let proposed, entity.isEnabled else { return false }
        let point = entity.convert(position: worldPoint, from: nil)
        let start = entity.convert(position: worldStart, from: nil)
        if dragStart == nil {
            dragStart = start; dragProposal = proposed
            dragAxis = target.name.hasPrefix("palm-map-move-") ? Int(target.name.suffix(1)) : nil
            selected = true
        }
        let delta = point - (dragStart ?? start)
        var next = dragProposal
        if dragAxis == 1 {
            next.y += projection.heightDelta(screenY: delta.y)
            next.y = max(PalmMapProjection.floorHeight([next.x,next.z], in: environment), next.y)
        } else {
            let floor = projection.floorDelta(screen: [delta.x,delta.y])
            if dragAxis != 2 { next.x += floor.x }
            if dragAxis != 0 { next.z += floor.y }
            let elevation = max(0, dragProposal.y - PalmMapProjection.floorHeight([dragProposal.x,dragProposal.z], in: environment))
            next.y = PalmMapProjection.floorHeight([next.x,next.z], in: environment) + elevation
        }
        self.proposed = next
        issue = PalmMapProjection.obstruction(next, in: environment)
        return true
    }

    enum Action { case teleport(Position3D) }
    func finish() { dragStart = nil; dragAxis = nil }
    func cancel() { if dragging { proposed = dragProposal }; finish() }
    func reset() { cancel(); proposed = nil; selected = false; handles.isEnabled = false; entity.isEnabled = false }

    private func showFeedback() {
        let text = selected ? (String(format: "%.1f m above floor · ", elevation) + (issue ?? "Clear · select Teleport")) : "Select the user cube to move"
        guard feedbackText != text else { return }
        feedbackText = text
        for child in Array(feedback.children) { child.removeFromParent() }
        let label = ModelEntity(mesh: .generateText(text, extrusionDepth: 0.0001, font: .systemFont(ofSize: 0.008),
            containerFrame: CGRect(x: 0,y: 0,width: 0.34,height: 0.045), alignment: .center), materials: [Self.material(issue == nil ? .white : .yellow)])
        label.position = [-0.17,-0.175,0.10]; feedback.addChild(label)
        if selected {
            let button = ModelEntity(mesh: .generateBox(size: [0.09,0.024,0.004]), materials: [Self.material(issue == nil ? .systemTeal : .darkGray)])
            button.name = "palm-map-teleport"; button.position = [0,-0.19,0.06]
            if issue == nil {
                button.components.set(CollisionComponent(shapes: [.generateBox(size: [0.10,0.03,0.01])]))
                Self.input(button)
            }
            let title = ModelEntity(mesh: .generateText("Teleport", extrusionDepth: 0.0001, font: .systemFont(ofSize: 0.009)), materials: [Self.material(.white)])
            title.position = [-0.019,-0.005,0.003]; button.addChild(title); feedback.addChild(button)
        }
    }
    private static func input(_ target: Entity, draggable: Bool = false) {
        target.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
        target.components.set(HoverEffectComponent())
        if draggable { target.components.set(SpatialDragTarget()) }
    }
    private static func material(_ color: UIColor, alpha: Float = 1) -> UnlitMaterial {
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        return material
    }
}
