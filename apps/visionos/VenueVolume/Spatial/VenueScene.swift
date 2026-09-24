import ARKit
import QuartzCore
import RealityKit
import SwiftUI
import VenueVolumeCore

@MainActor
final class VenueScene {
    let root = Entity()
    let headAnchor = AnchorEntity(.head, trackingMode: .continuous)
    private let placementRig = Entity()
    private let placementSurface: ModelEntity
    private var cubes: [UUID: ModelEntity] = [:]
    private var labels: [UUID: Entity] = [:]
    private var panels: [UUID: Entity] = [:]
    private var deviceTransform = matrix_identity_float4x4

    init() {
        placementSurface = ModelEntity(mesh: .generateBox(width: 6, height: 4, depth: 0.002),
                                       materials: [Self.glass(opacity: 0.045)])
        placementSurface.name = "placement-surface"
        placementSurface.components.set(CollisionComponent(shapes: [.generateBox(size: [6, 4, 0.008])]))
        placementSurface.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
        placementRig.addChild(placementSurface)
        // A subtle grid makes the system's gaze target visible without obscuring the room.
        let gridMaterial = UnlitMaterial(color: UIColor.cyan.withAlphaComponent(0.18))
        for column in -6...6 {
            let line = ModelEntity(mesh: .generateBox(width: 0.0015, height: 4, depth: 0.001), materials: [gridMaterial])
            line.position = [Float(column) * 0.5, 0, 0.005]
            placementSurface.addChild(line)
        }
        for row in -4...4 {
            let line = ModelEntity(mesh: .generateBox(width: 6, height: 0.0015, depth: 0.001), materials: [gridMaterial])
            line.position = [0, Float(row) * 0.5, 0.005]
            placementSurface.addChild(line)
        }
        root.addChild(placementRig)
        placementRig.isEnabled = false
        deviceTransform.columns.3 = [0, 1.5, 0, 1]
    }

    func update(model: VenueModel, attachments: RealityViewAttachments) {
        placementRig.isEnabled = model.isPlacing && model.canPlace
        updatePlacement(distance: model.placementDistance)
        if let debug = attachments.entity(for: "debug"), debug.parent == nil {
            debug.position = [0.52, -0.16, -1.15]
            headAnchor.addChild(debug)
        }

        let ids = Set(model.fixtures.map(\.id))
        for id in Array(cubes.keys) where !ids.contains(id) {
            cubes.removeValue(forKey: id)?.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
            panels.removeValue(forKey: id)?.removeFromParent()
        }
        for fixture in model.fixtures {
            let cube: ModelEntity
            if let existing = cubes[fixture.id] {
                cube = existing
            } else {
                cube = Self.makeCube(id: fixture.id)
                cubes[fixture.id] = cube
                root.addChild(cube)
            }
            let position = SIMD3<Float>(fixture.position.x, fixture.position.y, fixture.position.z)
            cube.position = position
            let selected = model.selectedID == fixture.id
            cube.model?.materials = [Self.glass(opacity: selected ? 0.16 : 0.07)]
            cube.children.forEach { $0.components.set(OpacityComponent(opacity: selected ? 1 : 0.45)) }
            // Only the grid receives spatial placement gestures while placement is armed.
            cube.components.set(InputTargetComponent(allowedInputTypes: model.isPlacing ? [] : [.indirect, .direct]))
            if let label = attachments.entity(for: "label-\(fixture.id)") {
                if label.parent == nil { root.addChild(label) }
                label.position = position + [0, 0.24, 0]
                label.components.set(BillboardComponent())
                labels[fixture.id] = label
            }
            if model.expandedID == fixture.id, let panel = attachments.entity(for: "panel-\(fixture.id)") {
                if panel.parent == nil { root.addChild(panel) }
                panel.position = position + [-0.48, -0.08, 0.1]
                panel.components.set(BillboardComponent())
                panels[fixture.id] = panel
            } else {
                panels.removeValue(forKey: fixture.id)?.removeFromParent()
            }
        }
    }

    func runTracking(model: VenueModel) async {
        #if targetEnvironment(simulator)
        model.trackingStatus = "Simulator · fixed placement grid"
        model.canPlace = true
        // ARKit device tracking is unavailable in Simulator. Keep a world-space test grid.
        while !Task.isCancelled {
            updatePlacement(distance: model.placementDistance)
            try? await Task.sleep(for: .milliseconds(33))
        }
        model.canPlace = false
        #else
        guard WorldTrackingProvider.isSupported else {
            model.trackingStatus = "World tracking is unavailable on this device."
            return
        }
        // A stopped ARKit provider cannot be restarted; each entrance gets a fresh pair.
        let session = ARKitSession()
        let worldTracking = WorldTrackingProvider()
        defer {
            session.stop()
            model.canPlace = false
        }
        do {
            try await session.run([worldTracking])
            while !Task.isCancelled {
                if worldTracking.state == .running,
                   let anchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()), anchor.isTracked {
                    deviceTransform = anchor.originFromAnchorTransform
                    updatePlacement(distance: model.placementDistance)
                    model.canPlace = true
                    model.trackingStatus = "World tracking active"
                } else {
                    model.canPlace = false
                    model.trackingStatus = "Tracking paused · look around to recover"
                }
                try await Task.sleep(for: .milliseconds(33))
            }
        } catch is CancellationError {
            // Immersive space dismissed.
        } catch {
            model.trackingStatus = "Tracking unavailable: \(error.localizedDescription)"
        }
        #endif
    }

    func clearAttachments() {
        for entity in labels.values { entity.removeFromParent() }
        for entity in panels.values { entity.removeFromParent() }
        labels.removeAll()
        panels.removeAll()
        headAnchor.children.removeAll()
    }

    private func updatePlacement(distance: Float) {
        placementRig.transform = Transform(matrix: deviceTransform)
        placementSurface.position = [0, 0, -distance]
    }

    private static func glass(opacity: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .cyan)
        material.roughness = .init(floatLiteral: 0.15)
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        material.faceCulling = .none
        return material
    }

    private static func makeCube(id: UUID) -> ModelEntity {
        let side: Float = 0.24
        let cube = ModelEntity(mesh: .generateBox(size: side, cornerRadius: 0.006), materials: [glass(opacity: 0.07)])
        cube.name = id.uuidString
        cube.components.set(CollisionComponent(shapes: [.generateBox(size: SIMD3(repeating: side))]))
        cube.components.set(InputTargetComponent())
        cube.components.set(HoverEffectComponent())
        let edgeMaterial = UnlitMaterial(color: .cyan)
        for axis in 0..<3 {
            for first: Float in [-1, 1] {
                for second: Float in [-1, 1] {
                    var size = SIMD3<Float>(repeating: 0.002)
                    size[axis] = side
                    var position = SIMD3<Float>.zero
                    position[(axis + 1) % 3] = first * side / 2
                    position[(axis + 2) % 3] = second * side / 2
                    let edge = ModelEntity(mesh: .generateBox(size: size), materials: [edgeMaterial])
                    edge.position = position
                    cube.addChild(edge)
                }
            }
        }
        return cube
    }
}
