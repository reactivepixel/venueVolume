import ARKit
import CryptoKit
import QuartzCore
import RealityKit
import SwiftUI
import VenueVolumeCore

@MainActor
final class VenueScene {
    let root = Entity()
    let headAnchor = AnchorEntity(.head, trackingMode: .continuous)
    private let repository: (any EnvironmentRepository)?
    private let environmentID: String
    private var manifest: EnvironmentManifest?
    private var aligned = false
    private var cubes: [UUID: ModelEntity] = [:]
    private var labels: [UUID: Entity] = [:]
    private var panels: [UUID: Entity] = [:]
    private var deviceTransform = matrix_identity_float4x4

    init(repository: (any EnvironmentRepository)? = nil, environmentID: String = "img3153-classroom-v1") {
        self.repository = repository
        self.environmentID = environmentID
        root.name = "VenueEnvironmentRoot"
        deviceTransform.columns.3 = [0, 1.5, 0, 1]
    }

    func load(model: VenueModel) async -> Bool {
        do {
            let source: any EnvironmentRepository
            if let repository { source = repository }
            else {
                guard let resources = Bundle.main.resourceURL else {
                    throw EnvironmentError.invalid("application resources are missing")
                }
                source = DirectoryEnvironmentRepository(directory: resources.appendingPathComponent("Environments/Classroom"))
            }
            model.environmentStatus = "Loading classroom…"
            let resolved = try await source.resolve(id: environmentID)
            try resolved.manifest.validate()
            guard resolved.assetURL.isFileURL else { throw EnvironmentError.invalid("asset must be local") }
            let checksum = try await Task.detached {
                let data = try Data(contentsOf: resolved.assetURL, options: .mappedIfSafe)
                guard data.count == resolved.manifest.asset.bytes else { throw EnvironmentError.invalid("USDZ size mismatch") }
                return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            }.value
            guard checksum == resolved.manifest.asset.sha256 else { throw EnvironmentError.invalid("USDZ checksum mismatch") }
            let room = try await Entity(contentsOf: resolved.assetURL)
            try Task.checkCancellation()
            root.children.removeAll()
            cubes.removeAll()
            aligned = false
            root.transform = Transform()
            root.isEnabled = false
            root.addChild(room)
            for proxy in resolved.manifest.colliders {
                let entity = Entity()
                entity.name = "room-collider:" + proxy.sourceID
                entity.position = SIMD3(proxy.center[0], proxy.center[1], proxy.center[2])
                entity.orientation = simd_quatf(ix: proxy.rotation[0], iy: proxy.rotation[1], iz: proxy.rotation[2], r: proxy.rotation[3])
                let shape = ShapeResource.generateBox(size: SIMD3(proxy.size[0], proxy.size[1], proxy.size[2]))
                entity.components.set(CollisionComponent(shapes: [shape]))
                entity.components.set(PhysicsBodyComponent(shapes: [shape], mass: 0, mode: .static))
                // Keep the whole collider active: walls block targeting through the room.
                entity.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
                root.addChild(entity)
            }
            // RealityKit's default immersive IBL lights these portable PBR materials.
            manifest = resolved.manifest
            model.activate(environment: resolved.manifest)
            return true
        } catch is CancellationError {
            return false
        } catch {
            model.environmentStatus = "Room could not load"
            model.message = error.localizedDescription + " Leave and re-enter to retry."
            model.canPlace = false
            return false
        }
    }

    func handleTap(entity: Entity, position: SIMD3<Float>, model: VenueModel) {
        if entity.name.hasPrefix("room-collider:"), model.isPlacing {
            let id = String(entity.name.dropFirst("room-collider:".count))
            model.place(at: position, surfaceID: id)
        } else if let id = UUID(uuidString: entity.name) {
            model.select(id)
        }
    }

    private func alignToSpawn() {
        guard !aligned, let spawn = manifest?.spawn else { return }
        let heading = atan2(deviceTransform.columns.2.x, deviceTransform.columns.2.z)
        let rotation = simd_quatf(angle: heading-spawn.yaw, axis: [0,1,0])
        root.orientation = rotation
        // Room floor stays at the immersive space floor; tracked eye height is never overridden.
        root.position = SIMD3(deviceTransform.columns.3.x, 0, deviceTransform.columns.3.z)
            - rotation.act(SIMD3(spawn.position[0], spawn.position[1], spawn.position[2]))
        root.isEnabled = true
        aligned = true
    }

    func update(model: VenueModel, attachments: RealityViewAttachments) {
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
            cube.orientation = simd_quatf(ix: fixture.orientation.x, iy: fixture.orientation.y, iz: fixture.orientation.z, r: fixture.orientation.w)
            cube.scale = SIMD3(fixture.scale.x, fixture.scale.y, fixture.scale.z)
            let selected = model.selectedID == fixture.id
            cube.model?.materials = [Self.glass(opacity: selected ? 0.16 : 0.07)]
            cube.children.forEach { $0.components.set(OpacityComponent(opacity: selected ? 1 : 0.45)) }
            // Room collision surfaces receive placement gestures while placement is armed.
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
        model.trackingStatus = "Simulator · room-relative placement"
        alignToSpawn()
        model.canPlace = manifest != nil
        // ARKit device tracking is unavailable in Simulator; use its floor origin and forward direction.
        while !Task.isCancelled {
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
                    alignToSpawn()
                    model.canPlace = manifest != nil
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
