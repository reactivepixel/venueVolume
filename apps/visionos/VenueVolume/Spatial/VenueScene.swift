import ARKit
import CryptoKit
import QuartzCore
import RealityKit
import SwiftUI
import VenueVolumeCore

@MainActor
final class VenueScene {
    let root = Entity()
    let overlayRoot = Entity()
    private var roomMaterials: [(Entity, ModelComponent)] = []
    private var displayedWhiteRoom: Bool?
    private var fixtureTemplate: Entity?
    private var rigs: [UUID: FixtureRig] = [:]
    let headAnchor = AnchorEntity(.head, trackingMode: .continuous)
    private let repository: (any EnvironmentRepository)?
    private let environmentID: String
    private var manifest: EnvironmentManifest?
    private var aligned = false
    private var cubes: [UUID: ModelEntity] = [:]
    private var labels: [UUID: Entity] = [:]
    private var drops: [UUID: Entity] = [:]
    private var toolbox: Entity?
    private var palmGate = PalmRevealGate()
    private var latestLeftHand: HandAnchor?
    private var lastHandUpdate: Double = 0
    private var palmPosition = SIMD3<Float>(-0.5, 1.3, -1.2)
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
            roomMaterials.removeAll()
            rememberMaterials(room)
            displayedWhiteRoom = nil
            guard let fixtureURL = Bundle.main.resourceURL?.appendingPathComponent("FixtureAssets/RogueR1X/fixture.usdz") else {
                throw EnvironmentError.invalid("fixture resources are missing")
            }
            let template = try await Entity(contentsOf: fixtureURL)
            try Task.checkCancellation()
            fixtureTemplate = template
            // Fail visibly before accepting placements if the expected rig cannot be built.
            _ = try FixtureRig(template: template, id: UUID())
            model.fixtureAssetStatus = "Rogue R1X Spot · catalog visualization proxy"
            rigs.removeAll()
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
            // Imported opaque PBR meshes receive dynamic light and write depth.
            manifest = resolved.manifest
            model.activate(environment: resolved.manifest)
            return true
        } catch is CancellationError {
            return false
        } catch {
            model.environmentStatus = "Room could not load"
            model.message = error.localizedDescription + " Leave and re-enter to retry."
            model.canPlace = false
            model.needsManualToolbox = true
            model.toolboxVisible = true
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

    private func rememberMaterials(_ entity: Entity) {
        if let model = entity.components[ModelComponent.self] { roomMaterials.append((entity, model)) }
        for child in entity.children { rememberMaterials(child) }
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
        if let pane = attachments.entity(for: "toolbox"), pane.parent == nil {
            overlayRoot.addChild(pane)
            pane.position = [-0.68, 1.35, -1.45]
            pane.components.set(BillboardComponent())
            toolbox = pane
        }
        toolbox?.isEnabled = model.toolboxVisible
        if let preview = attachments.entity(for: "palm-preview"), preview.parent == nil {
            preview.position = [0.57, -0.30, -1.3]
            headAnchor.addChild(preview)
        }

        if displayedWhiteRoom != model.whiteRoom {
            var white = PhysicallyBasedMaterial()
            white.baseColor = .init(tint: UIColor(white: 0.82, alpha: 1))
            white.roughness = .init(floatLiteral: 0.85)
            for (entity, original) in roomMaterials {
                var component = original
                if model.whiteRoom { component.materials = original.materials.map { _ in white } }
                entity.components.set(component)
            }
            displayedWhiteRoom = model.whiteRoom
        }
        root.components.set(EnvironmentLightingConfigurationComponent(environmentLightingWeight: model.houseLight))
        let ids = Set(model.fixtures.map(\.id))
        for id in Array(rigs.keys) where !ids.contains(id) {
            rigs.removeValue(forKey: id)?.entity.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
            drops.removeValue(forKey: id)?.removeFromParent()
        }
        for id in Array(cubes.keys) where !ids.contains(id) {
            cubes.removeValue(forKey: id)?.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
            drops.removeValue(forKey: id)?.removeFromParent()
        }
        for fixture in model.fixtures {
            let position = SIMD3<Float>(fixture.position.x, fixture.position.y, fixture.position.z)
            let selected = model.selectedID == fixture.id
            if fixture.assetID == LightingPreview.assetID, let template = fixtureTemplate {
                if rigs[fixture.id] == nil {
                    do {
                        let rig = try FixtureRig(template: template, id: fixture.id)
                        rigs[fixture.id] = rig; root.addChild(rig.entity)
                    } catch { model.message = error.localizedDescription }
                }
                rigs[fixture.id]?.update(fixture: fixture, channels: model.renderedChannels(for: fixture),
                                         selected: selected, blackout: model.blackout, placing: model.isPlacing)
            } else {
                let cube = cubes[fixture.id] ?? Self.makeCube(id: fixture.id)
                if cube.parent == nil { root.addChild(cube); cubes[fixture.id] = cube }
                cube.position = position
                cube.model?.materials = [Self.glass(opacity: selected ? 0.16 : 0.07)]
                cube.components.set(InputTargetComponent(allowedInputTypes: model.isPlacing ? [] : [.indirect, .direct]))
            }
            if let label = attachments.entity(for: "label-\(fixture.id)") {
                if label.parent == nil { root.addChild(label) }
                // Pin the lower edge above the cube so Info expands upward.
                let height = label.visualBounds(relativeTo: label).extents.y
                label.position = position + [0, (fixture.assetID == nil ? 0.18 : 0.55) + height / 2, 0.04]
                label.components.set(BillboardComponent())
                labels[fixture.id] = label
            }
            if let drop = attachments.entity(for: "drop-\(fixture.id)") {
                if drop.parent == nil { root.addChild(drop) }
                drop.position = position + [0, fixture.assetID == nil ? 0 : 0.22, 0.20]
                drop.components.set(BillboardComponent())
                drop.isEnabled = !model.isPlacing
                drops[fixture.id] = drop
            }
        }
    }

    func runTracking(model: VenueModel) async {
        defer {
            model.canPlace = false
            model.toolboxVisible = false
            palmGate = PalmRevealGate()
        }
        #if targetEnvironment(simulator)
        model.trackingStatus = "Simulator · room-relative placement"
        alignToSpawn()
        model.canPlace = manifest != nil
        // ARKit device tracking is unavailable in Simulator; use its floor origin and forward direction.
        while !Task.isCancelled {
            model.handTrackingStatus = "Simulator palm preview"
            setToolboxVisible(model.simulatedPalm || model.draggingPresetID != nil, model: model)
            try? await Task.sleep(for: .milliseconds(33))
        }
        #else
        guard WorldTrackingProvider.isSupported else {
            model.trackingStatus = "World tracking is unavailable."
            return
        }
        let session = ARKitSession()
        let world = WorldTrackingProvider()
        let hands = HandTrackingProvider()
        defer { session.stop(); latestLeftHand = nil }
        var handAccess = false
        if HandTrackingProvider.isSupported {
            let status = await session.requestAuthorization(for: [.handTracking])
            handAccess = status[.handTracking] == .allowed
        }
        model.needsManualToolbox = !handAccess
        model.handTrackingStatus = handAccess ? "Raise your left palm toward you" : "Hand tracking unavailable · use Show toolbox"
        do {
            if handAccess { try await session.run([world, hands]) }
            else { try await session.run([world]) }
            // Cache the update stream instead of consuming latestAnchors every frame;
            // missing a provider tick must not restart the reveal debounce.
            let handTask: Task<Void, Never>? = handAccess ? Task { @MainActor in
                for await update in hands.anchorUpdates {
                    guard !Task.isCancelled else { return }
                    if update.anchor.chirality == .left {
                        self.latestLeftHand = update.event == .removed ? nil : update.anchor
                        self.lastHandUpdate = CACurrentMediaTime()
                    }
                }
            } : nil
            defer { handTask?.cancel() }
            while !Task.isCancelled {
                let now = CACurrentMediaTime()
                var eligible = false
                if world.state == .running,
                   let device = world.queryDeviceAnchor(atTimestamp: now), device.isTracked {
                    deviceTransform = device.originFromAnchorTransform
                    alignToSpawn()
                    model.canPlace = manifest != nil
                    model.trackingStatus = "World tracking active"
                    if handAccess, hands.state == .running, now - lastHandUpdate < 0.25, let hand = latestLeftHand {
                        eligible = palmFacesViewer(hand)
                    }
                } else {
                    model.canPlace = false
                    model.trackingStatus = "Tracking paused · look around to recover"
                }
                if handAccess && hands.state == .stopped {
                    model.needsManualToolbox = true
                    model.handTrackingStatus = "Hand tracking stopped · use Show toolbox or re-enter to retry"
                }
                let revealed = palmGate.update(eligible: eligible, now: now)
                let visible = model.needsManualToolbox ? model.simulatedPalm : revealed
                setToolboxVisible(visible || model.draggingPresetID != nil, model: model)
                try await Task.sleep(for: .milliseconds(33))
            }
        } catch is CancellationError {
        } catch {
            model.trackingStatus = "Tracking unavailable: \(error.localizedDescription)"
            model.needsManualToolbox = true
            model.handTrackingStatus = "Use Show toolbox or re-enter the venue to retry tracking."
            // Keep the explicit fallback responsive even after authorization/session failure.
            while !Task.isCancelled {
                setToolboxVisible(model.simulatedPalm, model: model)
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        #endif
    }

    private func palmFacesViewer(_ hand: HandAnchor) -> Bool {
        guard hand.chirality == .left, hand.isTracked, let skeleton = hand.handSkeleton else { return false }
        let names: [HandSkeleton.JointName] = [.wrist, .indexFingerKnuckle, .littleFingerKnuckle]
        let joints = names.map { skeleton.joint($0) }
        guard joints.allSatisfy(\.isTracked) else { return false }
        let points = joints.map { joint -> SIMD3<Float> in
            let t = hand.originFromAnchorTransform * joint.anchorFromJointTransform
            return SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
        }
        let wrist = points[0], index = points[1], little = points[2]
        let normal = simd_cross(index - wrist, little - wrist)
        guard simd_length(normal) > 0.0001 else { return false }
        let center = (wrist + index + little) / 3
        let head = SIMD3(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
        let towardPalm = center - head
        let distance = simd_length(towardPalm)
        guard distance > 0.15, distance < 1.0 else { return false }
        let forward = -SIMD3(deviceTransform.columns.2.x, deviceTransform.columns.2.y, deviceTransform.columns.2.z)
        let visible = simd_dot(simd_normalize(towardPalm), forward) > 0.72
        let facing = simd_dot(simd_normalize(normal), -simd_normalize(towardPalm)) > 0.55
        // Use head orientation as a viewing-area approximation; no eye gaze is read.
        if visible && facing {
            palmPosition = head + simd_normalize(towardPalm) * max(distance, 0.95) + [0, 0.18, 0]
        }
        return visible && facing
    }

    private func setToolboxVisible(_ visible: Bool, model: VenueModel) {
        #if !targetEnvironment(simulator)
        if visible && !model.toolboxVisible {
            toolbox?.position = palmPosition
        }
        #endif
        if model.toolboxVisible != visible { model.toolboxVisible = visible }
        toolbox?.isEnabled = visible
    }

    func clearAttachments() {
        for entity in labels.values { entity.removeFromParent() }
        for entity in drops.values { entity.removeFromParent() }
        labels.removeAll()
        drops.removeAll()
        toolbox?.removeFromParent()
        toolbox = nil
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
