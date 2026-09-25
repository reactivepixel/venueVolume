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
    private var drops: [UUID: Entity] = [:]
    private var toolbox: Entity?
    private var palmGate = PalmRevealGate()
    private var latestLeftHand: HandAnchor?
    private var lastHandUpdate: Double = 0
    private var palmPosition = SIMD3<Float>(-0.5, 1.3, -1.2)
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
        if let pane = attachments.entity(for: "toolbox"), pane.parent == nil {
            root.addChild(pane)
            pane.position = [-0.68, 1.35, -1.45]
            pane.components.set(BillboardComponent())
            toolbox = pane
        }
        toolbox?.isEnabled = model.toolboxVisible
        if let preview = attachments.entity(for: "palm-preview"), preview.parent == nil {
            preview.position = [0.57, -0.30, -1.3]
            headAnchor.addChild(preview)
        }

        let ids = Set(model.fixtures.map(\.id))
        for id in Array(cubes.keys) where !ids.contains(id) {
            cubes.removeValue(forKey: id)?.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
            drops.removeValue(forKey: id)?.removeFromParent()
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
                // Pin the lower edge above the cube so Info expands upward.
                let height = label.visualBounds(relativeTo: label).extents.y
                label.position = position + [0, 0.18 + height / 2, 0.04]
                label.components.set(BillboardComponent())
                labels[fixture.id] = label
            }
            if let drop = attachments.entity(for: "drop-\(fixture.id)") {
                if drop.parent == nil { root.addChild(drop) }
                drop.position = position + [0, 0, 0.135]
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
        model.trackingStatus = "Simulator · fixed placement grid"
        model.handTrackingStatus = "Simulator palm preview · hand tracking requires Vision Pro"
        model.canPlace = true
        while !Task.isCancelled {
            updatePlacement(distance: model.placementDistance)
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
                    updatePlacement(distance: model.placementDistance)
                    model.canPlace = true
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
