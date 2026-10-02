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
    private var frameSubscription: EventSubscription?
    private let targetMarker = ModelEntity(mesh: .generateSphere(radius: 0.025), materials: [UnlitMaterial(color: .cyan)])
    private var roomMaterials: [(Entity, ModelComponent)] = []
    private var displayedWhiteRoom: Bool?
    private var fixtureTemplates: [String: Entity] = [:]
    private var fixtureLoads: [String: Task<Void, Never>] = [:]
    private var fixtureFailures: Set<String> = []
    private var fixtureLoadGeneration = UUID()
    private var rigs: [UUID: FixtureRig] = [:]
    private let transformGizmo = FixtureTransformGizmo()
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
            if model.rooms.isEmpty {
                let bundled = try await source.resolve(id: environmentID)
                model.bootstrapLibrary(defaultRoom: bundled.manifest)
            }
            guard let selected = model.roomRequest?.room ?? model.activeRoom ?? model.rooms.first else { throw EnvironmentError.invalid("room library is empty") }
            let resolved: ResolvedEnvironment
            if selected.origin == .bundled { resolved = try await source.resolve(id: selected.manifest.id) }
            else { resolved = try await DirectoryEnvironmentRepository(directory: model.library.roomDirectory(selected)).resolve(id: selected.manifest.id) }
            try resolved.manifest.validate()
            guard resolved.assetURL.isFileURL else { throw EnvironmentError.invalid("asset must be local") }
            let checksum = try await Task.detached {
                let data = try Data(contentsOf: resolved.assetURL, options: .mappedIfSafe)
                guard data.count == resolved.manifest.asset.bytes else { throw EnvironmentError.invalid("USDZ size mismatch") }
                return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            }.value
            guard checksum == resolved.manifest.asset.sha256 else { throw EnvironmentError.invalid("USDZ checksum mismatch") }
            let room: Entity
            let scan: ScannedMesh?
            if resolved.manifest.asset.file == "environment.mesh.json" {
                scan = try JSONDecoder().decode(ScannedMesh.self, from: Data(contentsOf: resolved.assetURL))
                room = try RoomAssets.meshEntity(scan!)
            } else { scan = nil; room = try await Entity(contentsOf: resolved.assetURL) }
            if let translation = resolved.manifest.assetTranslation { room.position = [translation[0],translation[1],translation[2]] }
            try Task.checkCancellation()
            var newMaterials: [(Entity, ModelComponent)] = []
            func collect(_ entity: Entity) {
                if let component = entity.components[ModelComponent.self] { newMaterials.append((entity, component)) }
                for child in entity.children { collect(child) }
            }
            collect(room)
            model.environmentStatus = "Preparing room targeting…"
            for (entity, component) in newMaterials {
                let shape = try await ShapeResource.generateStaticMesh(from: component.mesh)
                try Task.checkCancellation()
                entity.name = "aim-surface:" + entity.name
                entity.components.set(CollisionComponent(shapes: [shape]))
                entity.components.set(InputTargetComponent(allowedInputTypes: []))
            }
            guard let fixtureURL = Bundle.main.resourceURL?.appendingPathComponent("FixtureAssets/RogueR1X/fixture.usdz") else {
                throw EnvironmentError.invalid("fixture resources are missing")
            }
            let template = try await Entity(contentsOf: fixtureURL)
            try Task.checkCancellation()
            // Fail visibly before accepting placements if the expected rig cannot be built.
            _ = try FixtureRig(template: template, id: UUID())
            model.fixtureAssetStatus = "\(FixtureCatalog.all.count) catalog assets · VV Preview 16"
            var proxies: [Entity] = []
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
                proxies.append(entity)
            }
            // Publish only after all assets and collision shapes are ready.
            // A failed import/open therefore leaves the previous room usable.
            try Task.checkCancellation()
            try model.prepareHistoryRestore()
            root.children.removeAll(); cubes.removeAll(); rigs.removeAll(); labels.removeAll(); drops.removeAll()
            aligned = false; root.transform = Transform(); root.isEnabled = false
            root.addChild(room); proxies.forEach { root.addChild($0) }
            let background = Entity()
            background.name = "scene-background"
            background.position = SIMD3(resolved.manifest.bounds.min[0]+resolved.manifest.bounds.max[0],
                                        resolved.manifest.bounds.min[1]+resolved.manifest.bounds.max[1],
                                        resolved.manifest.bounds.min[2]+resolved.manifest.bounds.max[2]) / 2
            background.components.set(CollisionComponent(shapes: [.generateSphere(radius: 40)]))
            background.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
            root.addChild(background)
            roomMaterials = newMaterials; displayedWhiteRoom = nil
            fixtureLoadGeneration = UUID()
            fixtureLoads.values.forEach { $0.cancel() }; fixtureLoads.removeAll(); fixtureFailures.removeAll()
            fixtureTemplates = [LightingPreview.assetID: template]
            model.scannedMesh = scan
            // Imported opaque PBR meshes receive dynamic light and write depth.
            manifest = resolved.manifest
            model.activate(environment: resolved.manifest)
            return true
        } catch is CancellationError {
            return false
        } catch {
            model.historyRestoreFailed(error.localizedDescription)
            model.auditExternal("Room load failed · \(error.localizedDescription)")
            model.environmentStatus = "Room could not load"
            model.message = error.localizedDescription + " Leave and re-enter to retry."
            model.canPlace = false
            model.needsManualToolbox = true
            model.toolboxVisible = true
            model.libraryMessage = error.localizedDescription
            model.roomRequest = nil; model.libraryBusy = false
            return false
        }
    }

    func startAnimation(in content: RealityViewContent) {
        frameSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.rigs.values.forEach { $0.tick(deltaTime: event.deltaTime) }
        }
    }

    func handleTap(entity: Entity, position: SIMD3<Float>, model: VenueModel) {
        let point = Position3D(x: position.x, y: position.y, z: position.z)
        if !model.isPickingRoom {
            if FixtureTransformGizmo.handle(entity) != nil { return }
            if let id = UUID(uuidString: entity.name) { model.select(id) }
            else if entity.name.hasPrefix("aim-surface:") || entity.name.hasPrefix("room-collider:") || entity.name == "scene-background" {
                model.deselect()
            }
        } else if entity.name.hasPrefix("aim-surface:"), model.isRetargeting {
            _ = model.acceptTarget(point)
        } else if entity.name.hasPrefix("aim-surface:"), model.scannedMesh != nil, model.isPlacing {
            model.placeOnMesh(at: point)
        } else if entity.name.hasPrefix("aim-surface:"), model.scannedMesh != nil, model.scenePick != nil {
            model.repositionOnMesh(at: point)
        } else if entity.name.hasPrefix("room-collider:") {
            let id = String(entity.name.dropFirst("room-collider:".count))
            if model.isPlacing { model.place(at: position, surfaceID: id) }
            else if model.scenePick != nil { model.reposition(at: point, surfaceID: id) }
        }
    }

    func handleDrag(entity: Entity, position: SIMD3<Float>, start: SIMD3<Float>, model: VenueModel) -> Bool {
        if model.isRetargeting && entity.name.hasPrefix("aim-surface:") {
            _ = model.acceptTarget(.init(x: position.x, y: position.y, z: position.z))
            return true
        }
        if let (axis, mode) = FixtureTransformGizmo.handle(entity), model.gizmoVisible {
            if !model.isTransformDragging { model.beginTransformDrag(axis: axis, mode: mode, at: start) }
            model.updateTransformDrag(to: position)
            return true
        }
        return false
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
            #if !targetEnvironment(simulator)
            pane.scale = .init(repeating: 0.6)
            #endif
            toolbox = pane
        }
        toolbox?.isEnabled = model.toolboxVisible
        if let hud = attachments.entity(for: "targeting") {
            if hud.parent == nil { hud.position = [0, -0.42, -1.2]; headAnchor.addChild(hud) }
            hud.isEnabled = model.isPickingRoom || (model.gizmoVisible && model.selectedID != nil)
        }
        if targetMarker.parent == nil { root.addChild(targetMarker) }
        targetMarker.components.set(DynamicLightShadowComponent(castsShadow: false))
        let marker = model.pendingTarget ?? model.lastTarget
        targetMarker.isEnabled = marker != nil
        if let target = marker { targetMarker.position = FixtureAiming.vector(target) }
        for (entity, _) in roomMaterials {
            entity.components.set(InputTargetComponent(allowedInputTypes: !model.isPickingRoom || model.isRetargeting || (model.scannedMesh != nil && model.isPickingRoom) ? [.indirect] : []))
        }
        for child in root.children where child.name.hasPrefix("room-collider:") {
            child.components.set(InputTargetComponent(allowedInputTypes: model.isRetargeting || model.scannedMesh != nil ? [] : [.indirect]))
        }
        root.findEntity(named: "scene-background")?.components.set(InputTargetComponent(allowedInputTypes: model.isPickingRoom ? [] : [.indirect]))
        if transformGizmo.entity.parent == nil { root.addChild(transformGizmo.entity) }
        transformGizmo.update(fixture: model.selectedID.flatMap { model.fixture($0) },
                              visible: model.gizmoVisible && !model.isPickingRoom, mode: model.transformMode)
        for surface in model.environment?.surfaces ?? [] {
            if let zone = attachments.entity(for: "surface-drop-\(surface.id)") {
                if zone.parent == nil { root.addChild(zone) }
                let extents = zone.visualBounds(relativeTo: zone).extents
                if extents.x > 0 && extents.y > 0 { zone.scale = [surface.size[0]/extents.x, surface.size[1]/extents.y, 1] }
                zone.orientation = simd_quatf(angle: -.pi/2, axis: [1,0,0])
                zone.position = [surface.center[0],surface.center[1]+0.01,surface.center[2]]
                zone.isEnabled = model.draggingFixture != nil
            }
        }
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
        let activeAssets = Set(model.fixtures.compactMap(\.assetID))
        for id in Array(fixtureTemplates.keys) where id != LightingPreview.assetID && !activeAssets.contains(id) {
            fixtureTemplates[id] = nil
        }
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
        // Bound expensive shadow lights; selected fixtures receive preview priority.
        // Geometry and articulation continue for every placed asset.
        var budgets: [UUID: Int] = [:], remaining = 8
        let priority = model.fixtures.filter { $0.id == model.selectedID } + model.fixtures.filter { $0.id != model.selectedID }
        for fixture in priority where !model.blackout {
            guard LightingPreview(channels: model.renderedChannels(for: fixture)).intensity > 0 else { continue }
            let count = min(remaining, fixture.asset?.emitters.count ?? 0)
            budgets[fixture.id] = count; remaining -= count
        }
        for fixture in model.fixtures {
            let displayed = model.renderedFixture(fixture)
            let position = FixtureAiming.vector(displayed.position)
            let selected = model.selectedID == fixture.id
            if let descriptor = fixture.asset {
                if let template = fixtureTemplates[descriptor.id] {
                cubes.removeValue(forKey: fixture.id)?.removeFromParent()
                if rigs[fixture.id] == nil {
                    do {
                        let rig = try FixtureRig(template: template, id: fixture.id, descriptor: descriptor)
                        rigs[fixture.id] = rig; root.addChild(rig.entity)
                    } catch { model.message = error.localizedDescription }
                }
                rigs[fixture.id]?.update(fixture: displayed, channels: model.renderedChannels(for: fixture),
                                         selected: selected, blackout: model.blackout, placing: model.isPickingRoom,
                                         interactive: model.isTransformDragging, lightBudget: budgets[fixture.id] ?? 0)
                } else {
                    requestFixture(descriptor, model: model)
                    let placeholder = cubes[fixture.id] ?? Self.makeCube(id: fixture.id)
                    if placeholder.parent == nil { root.addChild(placeholder); cubes[fixture.id] = placeholder }
                    placeholder.position = position + [0,0.12,0]
                }
            } else {
                let cube = cubes[fixture.id] ?? Self.makeCube(id: fixture.id)
                if cube.parent == nil { root.addChild(cube); cubes[fixture.id] = cube }
                cube.position = position
                cube.orientation = simd_quatf(ix: fixture.orientation.x, iy: fixture.orientation.y, iz: fixture.orientation.z, r: fixture.orientation.w)
                cube.scale = FixtureAiming.vector(fixture.scale)
                cube.model?.materials = [Self.glass(opacity: selected ? 0.16 : 0.07)]
                cube.components.set(InputTargetComponent(allowedInputTypes: model.isPickingRoom ? [] : [.indirect, .direct]))
            }
            if let label = attachments.entity(for: "label-\(fixture.id)") {
                if label.parent == nil { root.addChild(label) }
                // Pin the lower edge above the cube so Info expands upward.
                let height = label.visualBounds(relativeTo: label).extents.y
                label.position = position + [0, (fixture.assetID == nil ? 0.18 : fixture.visualHeight+0.10) + height / 2, 0.04]
                label.components.set(BillboardComponent())
                labels[fixture.id] = label
            }
            if let drop = attachments.entity(for: "drop-\(fixture.id)") {
                if drop.parent == nil { root.addChild(drop) }
                drop.position = position + [0, fixture.assetID == nil ? 0 : fixture.visualHeight/2, 0.20]
                drop.components.set(BillboardComponent())
                drop.isEnabled = !model.isPickingRoom
                drops[fixture.id] = drop
            }
        }
    }

    private func requestFixture(_ descriptor: FixtureAsset, model: VenueModel) {
        guard fixtureLoads[descriptor.id] == nil, !fixtureFailures.contains(descriptor.id) else { return }
        let generation = fixtureLoadGeneration
        fixtureLoads[descriptor.id] = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if self.fixtureLoadGeneration == generation { self.fixtureLoads[descriptor.id] = nil } }
            do {
                guard let url = Bundle.main.resourceURL?.appendingPathComponent(descriptor.resource) else {
                    throw EnvironmentError.invalid("Fixture resources are missing")
                }
                let hash = try await Task.detached {
                    SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe)).map { String(format: "%02x", $0) }.joined()
                }.value
                guard hash == descriptor.sha256 else { throw EnvironmentError.invalid("\(descriptor.name) asset checksum mismatch") }
                let template = try await Entity(contentsOf: url)
                try Task.checkCancellation()
                guard self.fixtureLoadGeneration == generation else { return }
                guard model.fixtures.contains(where: { $0.assetID == descriptor.id }) else { return }
                _ = try FixtureRig(template: template, id: UUID(), descriptor: descriptor)
                self.fixtureTemplates[descriptor.id] = template
                model.fixtureAssetStatus = "\(FixtureCatalog.all.count) catalog assets · loaded \(descriptor.name)"
                model.revision += 1
            } catch is CancellationError {
            } catch {
                guard self.fixtureLoadGeneration == generation, !Task.isCancelled else { return }
                self.fixtureFailures.insert(descriptor.id)
                model.message = "Could not load \(descriptor.name): \(error.localizedDescription). Re-enter the room to retry."
                model.fixtureAssetStatus = model.message ?? "Fixture load failed"
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
            setToolboxVisible(model.simulatedPalm || model.draggingPresetID != nil || model.draggingFixture != nil, model: model)
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
                setToolboxVisible(visible || model.draggingPresetID != nil || model.draggingFixture != nil, model: model)
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
            palmPosition = center + [0, 0.16, 0]
        }
        return visible && facing
    }

    private func setToolboxVisible(_ visible: Bool, model: VenueModel) {
        #if !targetEnvironment(simulator)
        if visible && !model.toolboxVisible {
            toolbox?.position = palmPosition
        } else if visible && model.draggingFixture == nil && model.draggingPresetID == nil, let toolbox {
            toolbox.position += (palmPosition-toolbox.position)*0.15
        }
        #endif
        if model.toolboxVisible != visible { model.toolboxVisible = visible }
        toolbox?.isEnabled = visible
    }

    func clearAttachments() {
        fixtureLoadGeneration = UUID()
        fixtureLoads.values.forEach { $0.cancel() }; fixtureLoads.removeAll()
        for entity in labels.values { entity.removeFromParent() }
        for entity in drops.values { entity.removeFromParent() }
        labels.removeAll()
        drops.removeAll()
        toolbox?.removeFromParent()
        toolbox = nil
        headAnchor.children.removeAll()
        frameSubscription?.cancel(); frameSubscription = nil
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
