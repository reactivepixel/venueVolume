import ARKit
import CryptoKit
import Metal
import QuartzCore
import RealityKit
import SwiftUI
import VenueVolumeCore

/// Only these entities can begin a held spatial manipulation.
struct SpatialDragTarget: Component {}

@MainActor
final class VenueScene {
    let root = Entity()
    let overlayRoot = Entity()
    private var frameSubscription: EventSubscription?
    private weak var model: VenueModel?
    private var thermalPoll: Double = 1
    private var lightBudgets: [UUID: Int] = [:]
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private let targetMarker = ModelEntity(mesh: .generateSphere(radius: 0.025), materials: [UnlitMaterial(color: .cyan)])
    private var roomMaterials: [(Entity, ModelComponent)] = []
    private var displayedWhiteRoom: Bool?
    private let roomAmbientLight = RoomAmbientLight()
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
    private var displayedMapRequestID: UUID?
    private var mapWorldPosition = SIMD3<Float>.zero
    private var mapWorldOrientation = simd_quatf(angle: 0,axis: [0,1,0])
    private let palmMap = PalmNavigationVisual()
    private var navigationEnvironment: EnvironmentManifest? {
        manifest.map { PalmMapProjection.includingFixtures(model?.fixtures ?? [], in: $0) }
    }
    private let placementGhost = Entity()
    private struct PlacementTarget {
        let point: SIMD3<Float>
        let surfaceID: String?
        let kind: FixtureKind
        let unitID: UUID?
        let roomToken: UUID
        let sessionID: UUID
    }
    private var placementTarget: PlacementTarget?
    private let groupLinks = Entity()
    private var navigationGestureCancelled = false
    private var blackoutCover: ModelEntity?
    private var navigationTransition: Task<Void, Never>?
    private var blackoutFadeStart: Double?
    private var blackoutFadeDuration: Double = 0.333
    private var groupAnimationTime: Double = 0
    private var reduceNavigationMotion = false
    private var connectorRevision = ""
    private var leftNavigation = LeftHandNavigation()
    private var spawnRootTransform = Transform()
    private var spawnFrameRotation = simd_quatf(angle: 0,axis: [0,1,0])
    private var viewerResetToken: UUID?
    private var latestLeftHand: HandAnchor?
    private var lastHandUpdate: Double = 0
    private var labelLayoutElapsed: Double = 0
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
                source = BundledEnvironmentRepository(directory: resources.appendingPathComponent("Environments"))
            }
            self.model = model
            model.supportsExtendedLights = metalDevice?.supportsFamily(.apple6) == true
            model.environmentStatus = "Loading room…"
            if model.rooms.isEmpty {
                let bundled = try await source.resolve(id: environmentID)
                var additional: [EnvironmentManifest] = []
                if repository == nil {
                    for id in BundledEnvironmentRepository.folders.keys.sorted() where id != environmentID {
                        additional.append(try await source.resolve(id: id).manifest)
                    }
                }
                model.bootstrapLibrary(defaultRoom: bundled.manifest, additionalRooms: additional)
            }
            guard let selected = model.roomRequest?.room ?? model.activeRoom ?? model.rooms.first else { throw EnvironmentError.invalid("room library is empty") }
            let resolved: ResolvedEnvironment
            if selected.origin == .bundled { resolved = try await source.resolve(id: selected.manifest.id) }
            else { resolved = try await DirectoryEnvironmentRepository(directory: model.library.roomDirectory(selected)).resolve(id: selected.manifest.id) }
            try resolved.manifest.validate()
            guard selected.manifest == resolved.manifest else {
                throw EnvironmentError.invalid("this saved room version is unavailable; open the current room as a new setup")
            }
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
            try await roomAmbientLight.prepare()
            // Publish only after all assets and collision shapes are ready.
            // A failed import/open therefore leaves the previous room usable.
            try Task.checkCancellation()
            try model.prepareHistoryRestore()
            root.children.removeAll(); cubes.removeAll(); rigs.removeAll(); labels.removeAll()
            leftNavigation.cancel(at: ProcessInfo.processInfo.systemUptime); model.endViewerNavigation()
            aligned = false; root.transform = Transform(); root.isEnabled = false
            root.addChild(room); proxies.forEach { root.addChild($0) }
            roomMaterials = newMaterials; displayedWhiteRoom = nil
            roomAmbientLight.attach(to: newMaterials.map { $0.0 }, in: root, level: model.houseLight)
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
            model.requestToolbox()
            model.libraryMessage = error.localizedDescription
            model.roomRequest = nil; model.libraryBusy = false
            return false
        }
    }

    func startAnimation(in content: RealityViewContent) {
        frameSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self else { return }
            if let model = self.model { self.applyViewerNavigation(model: model) }
            self.rigs.values.forEach { $0.tick(deltaTime: event.deltaTime) }
            self.tickPhasers()
            self.tickNavigation()
            self.updatePlacementGhost()
            self.groupAnimationTime += event.deltaTime
            self.groupLinks.components.set(OpacityComponent(opacity: self.reduceNavigationMotion ? 1 :
                0.35 + 0.65 * Float((sin(self.groupAnimationTime * 4)+1)/2)))
            self.labelLayoutElapsed += event.deltaTime
            if self.labelLayoutElapsed >= 0.1 {
                self.labelLayoutElapsed = 0
                self.layoutFixtureLabels()
            }
            self.updateThermalBudget(deltaTime: event.deltaTime)
        }
    }

    private func canDragBody(_ fixture: Fixture, model: VenueModel) -> Bool {
        model.gizmoVisible && model.transformMode == .move && model.selectedID == fixture.id && !model.isRetargeting && !model.isPlacing
    }

    private func tickPhasers() {
        guard let model, !model.navigationBlackoutActive else { return }
        let animated = Set(model.sceneFixtures.filter { model.hasAnimatedPalette(for: $0) }.map(\.id))
        guard !animated.isEmpty else { return }
        let channels = Dictionary(uniqueKeysWithValues: model.sceneFixtures.map { ($0.id,model.renderedChannels(for: $0)) })
        let budgets = LightingBudget.allocate(model.sceneFixtures.map { fixture in
            let look = LightingPreview(channels: channels[fixture.id] ?? fixture.channels,blackout: model.isBlackedOut(fixture))
            return .init(id: fixture.id,emitters: fixtureTemplates[fixture.assetID ?? ""] == nil ? 0 : fixture.asset?.emitters.count ?? 0,
                         emitting: look.intensity > 0 && look.rgb.contains { $0 > 0 })
        },selected: model.selectedID,limit: model.effectiveLightLimit)
        for fixture in model.sceneFixtures {
            guard animated.contains(fixture.id) || budgets[fixture.id] != lightBudgets[fixture.id],
                  let rig = rigs[fixture.id] else { continue }
            rig.update(fixture: model.renderedFixture(fixture),channels: channels[fixture.id] ?? fixture.channels,
                       selected: model.selectedFixtureIDs.contains(fixture.id),blackout: model.isBlackedOut(fixture),
                       placing: model.isPickingRoom,interactive: model.isTransformDragging,
                       bodyDraggable: canDragBody(fixture, model: model), lightBudget: budgets[fixture.id] ?? 0)
        }
        lightBudgets = budgets
    }

    private func updateThermalBudget(deltaTime: Double) {
        guard let model else { return }
        thermalPoll += deltaTime
        guard thermalPoll >= 1 else { return }
        thermalPoll = 0
        let thermal: LightingBudget.Thermal
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = .nominal
        case .fair: thermal = .fair
        case .serious: thermal = .serious
        case .critical: thermal = .critical
        @unknown default: thermal = .serious
        }
        if model.lightingThermal != thermal { model.lightingThermal = thermal }
    }

    func handleTap(entity: Entity, position: SIMD3<Float>, model: VenueModel) {
        guard !model.navigationBlackoutActive else { return }
        tickNavigation()
        let point = Position3D(x: position.x, y: position.y, z: position.z)
        if entity.name.hasPrefix("palm-map-") {
            if model.palmMapVisible && model.canPlace, let manifest = navigationEnvironment {
                if let action = palmMap.tap(entity, worldPoint: root.convert(position: position, to: nil), environment: manifest) {
                    transitionNavigation(action, milliseconds: model.navigationFadeMilliseconds)
                }
            }
            return
        }
        guard !model.palmMapVisible else { return }
        if FixtureTransformGizmo.handle(entity) != nil { return }
        if model.isPlacing {
            // Commit the last displayed outline. The system's gaze target only
            // confirms the click; it must never choose a different placement.
            guard model.canPlace, placementGhost.isEnabled, let target = placementTarget,
                  target.kind == model.fixtureKind, target.unitID == model.placementUnitID,
                  target.roomToken == model.roomLoadToken, target.sessionID == model.placementSessionID else {
                model.message = "Move the placement box onto a clear floor or tabletop, then pinch."
                return
            }
            if let surfaceID = target.surfaceID { model.place(at: target.point, surfaceID: surfaceID) }
            else { model.placeOnMesh(at: .init(x: target.point.x, y: target.point.y, z: target.point.z)) }
            placementTarget = nil; placementGhost.isEnabled = false
        } else if let id = UUID(uuidString: entity.name), !model.isRetargeting {
            model.tapFixture(id)
        } else if model.isSurfaceMoveActive, isRoomSurface(entity) {
            guard let hit = surfaceHit(entity: entity, point: position),
                  let fixture = model.selectedID.flatMap({ model.fixture($0) }),
                  supportsSurface(at: hit.point, normal: hit.normal, radius: fixture.footprintRadius) else {
                model.message = "Choose a solid surface with enough room for this fixture."; return
            }
            let surface = model.environment?.surfaces.first { $0.fixturePosition(hit: .init(x: hit.point.x,y: hit.point.y,z: hit.point.z), halfSize: fixture.footprintRadius) != nil && hit.normal.y > 0.98 }
            _ = model.moveToSurface(at: .init(x: hit.point.x,y: hit.point.y,z: hit.point.z),
                                   normal: .init(x: hit.normal.x,y: hit.normal.y,z: hit.normal.z), surfaceID: surface?.id)
        } else if !model.isPickingRoom {
            if isRoomSurface(entity) { model.deselect() }
        } else if entity.name.hasPrefix("aim-surface:"), model.isRetargeting {
            _ = model.acceptTarget(point)
        }
    }

    private func isRoomSurface(_ entity: Entity) -> Bool {
        entity.name.hasPrefix("aim-surface:") || entity.name.hasPrefix("room-collider:")
    }

    private func surfaceHit(entity: Entity, point: SIMD3<Float>) -> (point: SIMD3<Float>, normal: SIMD3<Float>)? {
        guard let scene = root.scene else { return nil }
        let eye = root.convert(position: SIMD3(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z), from: nil)
        let direction = point-eye, distance = simd_length(direction)
        guard distance > 0.001 else { return nil }
        let hits = scene.raycast(origin: eye, direction: direction/distance, length: distance+0.08,
                                 query: .all, mask: .all, relativeTo: root)
        guard let hit = hits.filter({ $0.entity == entity }).min(by: { abs($0.distance-distance) < abs($1.distance-distance) }),
              simd_length(hit.normal) > 0.001 else { return nil }
        let normal = simd_normalize(hit.normal)
        return (hit.position, simd_dot(normal, eye-hit.position) < 0 ? -normal : normal)
    }

    /// Check the rendered room beneath the mount's center and four corners.
    private func supportsSurface(at point: SIMD3<Float>, normal: SIMD3<Float>, radius: Float) -> Bool {
        guard let scene = root.scene else { return false }
        let orientation = FixtureAiming.alignedMount(.init(), normal: normal)
        return [(Float(0),Float(0)),(-radius,-radius),(-radius,radius),(radius,-radius),(radius,radius)].allSatisfy { x,z in
            let sample = point + FixtureAiming.rotate(orientation, [x,0,z])
            return scene.raycast(origin: sample+normal*0.04, direction: -normal, length: 0.08,
                                 query: .all, mask: .all, relativeTo: root).contains {
                $0.entity.name.hasPrefix("aim-surface:") && simd_distance($0.position,sample) < 0.025
                    && abs(simd_dot(simd_normalize($0.normal),normal)) > 0.98
            }
        }
    }

    /// Select the editing overlay even when a closer room/fixture mesh won the
    /// system hit. This uses only the system-provided interaction ray, not eye data.
    func transformHandle(origin: SIMD3<Float>, direction: SIMD3<Float>, model: VenueModel) -> CollisionCastHit? {
        guard model.gizmoVisible, !model.isPickingRoom, !model.palmMapVisible,
              simd_length(direction) > 0.001, let scene = root.scene else { return nil }
        return scene.raycast(origin: origin, direction: simd_normalize(direction), length: 100,
                             query: .all, mask: .all, relativeTo: root).first {
            FixtureTransformGizmo.handle($0.entity)?.1 == model.transformMode
        }
    }

    func handleDrag(entity: Entity, position: SIMD3<Float>, start: SIMD3<Float>, model: VenueModel) -> Bool {
        guard !model.navigationBlackoutActive else { return false }
        tickNavigation()
        if !navigationGestureCancelled, model.palmMapVisible, model.canPlace, let environment = navigationEnvironment,
           palmMap.drag(entity, worldPoint: root.convert(position: position, to: nil),
                        worldStart: root.convert(position: start, to: nil), environment: environment) { return true }
        guard !model.palmMapVisible else { return false }
        if model.isRetargeting && entity.name.hasPrefix("aim-surface:") {
            _ = model.acceptTarget(.init(x: position.x, y: position.y, z: position.z))
            return true
        }
        if let (axis, mode) = FixtureTransformGizmo.handle(entity), model.gizmoVisible, mode == model.transformMode {
            if !model.isTransformDragging { model.beginTransformDrag(axis: axis, mode: mode, at: start) }
            model.updateTransformDrag(to: position)
            return true
        }
        if let id = UUID(uuidString: entity.name), id == model.selectedID, model.gizmoVisible, model.transformMode == .move,
           !model.isRetargeting && !model.isPlacing {
            if !model.isTransformDragging { model.beginSurfaceDrag(id, at: start) }
            if let candidate = model.surfaceDragDestination(to: position),
               supportsSurface(at: FixtureAiming.vector(candidate.point), normal: FixtureAiming.vector(candidate.normal), radius: candidate.radius) {
                _ = model.updateSurfaceDrag(to: position)
            } else { model.message = "Keep the fixture on a solid part of its current plane." }
            return true
        }
        return false
    }

    private func alignToSpawn() {
        guard !aligned, let spawn = manifest?.spawn else { return }
        let heading = atan2(deviceTransform.columns.2.x, deviceTransform.columns.2.z)
        let rotation = simd_quatf(angle: heading-spawn.yaw, axis: [0,1,0])
        root.orientation = rotation
        // Room floor stays at the immersive space floor; tracked eye height is never overridden.
        root.position = SIMD3(deviceTransform.columns.3.x, 0, deviceTransform.columns.3.z)
            - rotation.act(SIMD3(spawn.position[0], spawn.position[1], spawn.position[2]))
        spawnRootTransform = root.transform
        spawnFrameRotation = simd_quatf(angle: heading,axis: [0,1,0])
        root.isEnabled = true
        aligned = true
    }

    private func applyViewerNavigation(model: VenueModel) {
        guard aligned else { return }
        if viewerResetToken != model.viewerResetToken {
            viewerResetToken = model.viewerResetToken
            // An explicit full reset reanchors spawn under the current tracked head.
            if model.viewerPose == ViewerNavigationPose() {
                aligned = false; alignToSpawn()
            }
        }
        let pose = model.viewerPose
        let q = simd_quatf(ix: pose.orientation.x,iy: pose.orientation.y,iz: pose.orientation.z,r: pose.orientation.w)
        let inverseView = (spawnFrameRotation*q*spawnFrameRotation.inverse).inverse
        let eye = SIMD3<Float>(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let offset = spawnFrameRotation.act(FixtureAiming.vector(pose.offset))
        let rotation = inverseView*spawnRootTransform.rotation
        let position = pose.orientation == Quaternion3D() ? spawnRootTransform.translation-offset : eye + inverseView.act(spawnRootTransform.translation-eye-offset)
        if root.orientation.vector != rotation.vector { root.orientation = rotation }
        if root.position != position { root.position = position }
    }

    func updateLeftNavigation(_ sample: NavigationHandSample?, at time: Double, model: VenueModel) {
        guard aligned, model.canPlace, !model.libraryBusy, !model.navigationBlackoutActive, !model.palmMapVisible, !palmMap.dragging else {
            leftNavigation.cancel(at: time); model.endViewerNavigation(); model.navigationInputReserved = false; return
        }
        if time < model.leftUIReservedUntil {
            leftNavigation.cancel(at: time); model.endViewerNavigation(); model.navigationInputReserved = false
            return
        }
        if leftNavigation.activeFinger == nil { leftNavigation.restore(model.viewerPose) }
        let previous = leftNavigation.activeFinger
        let head = spawnFrameRotation.inverse*simd_quatf(deviceTransform)
        leftNavigation.update(sample, headBasis: .init(x: head.imag.x,y: head.imag.y,z: head.imag.z,w: head.real),at: time)
        if previous == nil, let finger = leftNavigation.activeFinger { model.beginViewerNavigation(finger) }
        model.updateViewerNavigation(leftNavigation.pose)
        if let reset = leftNavigation.reset, reset == .spawn { model.viewerResetToken = UUID() }
        if previous != nil && leftNavigation.activeFinger == nil { model.endViewerNavigation() }
        let reserved = leftNavigation.reservesInput(at: time)
        if model.navigationInputReserved != reserved { model.navigationInputReserved = reserved }
        applyViewerNavigation(model: model)
    }

    private func navigationSample(_ hand: HandAnchor) -> NavigationHandSample? {
        guard hand.chirality == .left, hand.isTracked, let skeleton = hand.handSkeleton else { return nil }
        let joints = [HandSkeleton.JointName.thumbTip,.indexFingerTip,.middleFingerTip].map { skeleton.joint($0) }
        guard joints.allSatisfy(\.isTracked) else { return nil }
        let points = joints.map { joint -> SIMD3<Float> in
            let t = hand.originFromAnchorTransform*joint.anchorFromJointTransform
            return spawnFrameRotation.inverse.act([t.columns.3.x,t.columns.3.y,t.columns.3.z])
        }
        return .init(thumb: points[0],index: points[1],middle: points[2])
    }

    func update(model: VenueModel, attachments: RealityViewAttachments) {
        if palmMap.entity.parent == nil { overlayRoot.addChild(palmMap.entity) }
        if placementGhost.parent == nil { root.addChild(placementGhost) }
        if groupLinks.parent == nil { root.addChild(groupLinks) }
        updateGroupLinks(model: model)
        if let controls = attachments.entity(for: "context-bar") {
            if controls.parent != headAnchor { headAnchor.addChild(controls) }
            controls.name = "context-bar"
            controls.position = [0,-0.42,-1.15]
            controls.scale = [1,1,1]
        }
        headAnchor.children.first { $0.name == "context-bar" }?.isEnabled = model.contextBarVisible
        _ = model.fixtureRenderRevision // Rebuild placeholders when an asynchronous catalog asset becomes ready.
        if targetMarker.parent == nil { root.addChild(targetMarker) }
        targetMarker.components.set(DynamicLightShadowComponent(castsShadow: false))
        let marker = model.pendingTarget ?? model.lastTarget
        targetMarker.isEnabled = marker != nil
        if let target = marker { targetMarker.position = FixtureAiming.vector(target) }
        for (entity, _) in roomMaterials {
            entity.components.set(InputTargetComponent(allowedInputTypes: !model.isPickingRoom || model.isRetargeting || model.isSurfaceMoveActive || (model.scannedMesh != nil && model.isPickingRoom) ? [.indirect] : []))
            if model.isRetargeting { entity.components.set(SpatialDragTarget()) }
            else { entity.components.remove(SpatialDragTarget.self) }
        }
        for child in root.children where child.name.hasPrefix("room-collider:") {
            child.components.set(InputTargetComponent(allowedInputTypes: model.isPlacing && model.scannedMesh == nil ? [.indirect] : []))
        }
        if transformGizmo.entity.parent == nil { root.addChild(transformGizmo.entity) }
        transformGizmo.update(fixture: model.transformFixtureContext,
                              visible: model.gizmoVisible && (!model.isPickingRoom || model.isSurfaceMoveActive) && !model.palmMapVisible, mode: model.transformMode, selectedAxis: model.activeTransformAxis)
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
        roomAmbientLight.update(level: model.houseLight)
        let ids = Set(model.sceneFixtures.map(\.id))
        let activeAssets = Set(model.sceneFixtures.compactMap(\.assetID))
        for id in Array(fixtureTemplates.keys) where id != LightingPreview.assetID && !activeAssets.contains(id) {
            fixtureTemplates[id] = nil
        }
        for id in Array(rigs.keys) where !ids.contains(id) {
            rigs.removeValue(forKey: id)?.entity.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
        }
        for id in Array(cubes.keys) where !ids.contains(id) {
            cubes.removeValue(forKey: id)?.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
        }
        // Bound expensive shadow lights; selected fixtures receive preview priority.
        // Geometry and articulation continue for every placed asset.
        let budgets = LightingBudget.allocate(model.sceneFixtures.map { fixture in
            let look = LightingPreview(channels: model.renderedChannels(for: fixture), blackout: model.isBlackedOut(fixture))
            return .init(id: fixture.id, emitters: fixtureTemplates[fixture.assetID ?? ""] == nil ? 0 : fixture.asset?.emitters.count ?? 0,
                         emitting: look.intensity > 0 && look.rgb.contains { $0 > 0 })
        }, selected: model.selectedID, limit: model.effectiveLightLimit)
        lightBudgets = budgets
        for fixture in model.sceneFixtures {
            let displayed = model.renderedFixture(fixture)
            let position = FixtureAiming.vector(displayed.position)
            let selected = model.selectedFixtureIDs.contains(fixture.id)
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
                                         selected: selected, blackout: model.isBlackedOut(fixture), placing: model.isPickingRoom,
                                         interactive: model.isTransformDragging, bodyDraggable: canDragBody(fixture, model: model), lightBudget: budgets[fixture.id] ?? 0)
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
                cube.components.set(InputTargetComponent(allowedInputTypes: model.isPickingRoom && !model.isSurfaceMoveActive ? [] : [.indirect]))
                if canDragBody(fixture, model: model) { cube.components.set(SpatialDragTarget()) }
                else { cube.components.remove(SpatialDragTarget.self) }
            }
            if let cube = cubes[fixture.id] {
                cube.findEntity(named: "SelectionBase")?.isEnabled = selected
            }
            if let label = attachments.entity(for: "label-\(fixture.id)") {
                if label.parent == nil { root.addChild(label) }
                // Pin the lower edge above the cube so Info expands upward.
                let height = label.visualBounds(relativeTo: label).extents.y
                label.position = position + [0, (fixture.assetID == nil ? 0.18 : fixture.visualHeight+0.10) + height * label.scale.x / 2, 0.04]
                label.components.set(BillboardComponent())
                labels[fixture.id] = label
            }

        }
    }

    /// Selected labels retain a readable angular size; nearby names yield when
    /// their projected rectangles overlap. Every object remains in the wrist list.
    private func layoutFixtureLabels() {
        guard let model else { return }
        // The context bar carries the selected name during transformation.
        // Floating fixture controls must not steal gaze/pinch from the gizmo.
        if model.gizmoVisible {
            for label in labels.values { label.isEnabled = false }
            return
        }
        let eye = SIMD3(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
        let view = simd_inverse(deviceTransform)
        var candidates: [SpatialLabelLayout.Candidate] = []
        for fixture in model.sceneFixtures {
            guard let label = labels[fixture.id] else { continue }
            let localSize = label.visualBounds(relativeTo: label, excludeInactive: false).extents
            let base = FixtureAiming.vector(model.renderedFixture(fixture).position)
            let world = root.transformMatrix(relativeTo: nil) * SIMD4<Float>(base, 1)
            let distance = simd_distance(eye, SIMD3(world.x, world.y, world.z))
            let scale = max(1, distance / 2)
            label.scale = SIMD3(repeating: scale)
            label.position = base + [0, (fixture.assetID == nil ? 0.18 : fixture.visualHeight + 0.10) + localSize.y * scale / 2, 0.04]
            let center = view * SIMD4<Float>(label.position(relativeTo: nil), 1)
            guard center.z < -0.05 else { label.isEnabled = false; continue }
            candidates.append(.init(id: fixture.id, center: [center.x / -center.z, center.y / -center.z],
                halfSize: [max(localSize.x, 0.1) * scale / (-2 * center.z), max(localSize.y, 0.06) * scale / (-2 * center.z)],
                distance: distance, selected: model.selectedFixtureIDs.contains(fixture.id)))
        }
        let visible = SpatialLabelLayout.visible(candidates)
        for (id, label) in labels { label.isEnabled = visible.contains(id) }
    }

    func updateAccessibility(reduceMotion: Bool) {
        reduceNavigationMotion = reduceMotion
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
                guard model.sceneFixtures.contains(where: { $0.assetID == descriptor.id }) else { return }
                _ = try FixtureRig(template: template, id: UUID(), descriptor: descriptor)
                self.fixtureTemplates[descriptor.id] = template
                model.fixtureAssetStatus = "\(FixtureCatalog.all.count) catalog assets · loaded \(descriptor.name)"
                model.fixtureRenderRevision += 1
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
            model.updateHandToolboxActivation(attended: false, now: CACurrentMediaTime())
            model.resetToolboxActivation()
            leftNavigation.cancel(at: ProcessInfo.processInfo.systemUptime)
            model.endViewerNavigation(); model.navigationInputReserved = false
        }
        #if targetEnvironment(simulator)
        model.trackingStatus = "Simulator · room-relative placement"
        alignToSpawn()
        model.canPlace = manifest != nil
        // ARKit device tracking is unavailable in Simulator; use its floor origin and forward direction.
        while !Task.isCancelled {
            model.handTrackingStatus = "Left index: move · left middle: rotate · double pinch: reset"
            let reserved = false
            if model.navigationInputReserved != reserved { model.navigationInputReserved = reserved }
            applyViewerNavigation(model: model)
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
        model.handTrackingStatus = handAccess ? "Left index: move · left middle: rotate · double pinch: reset" : "Hand tracking unavailable · use navigation controls"
        do {
            if handAccess { try await session.run([world, hands]) }
            else { try await session.run([world]) }
            // Cache the update stream instead of consuming latestAnchors every frame;
            // briefly missing a provider tick must not restart an active pinch.
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
                var navigation: NavigationHandSample?
                if world.state == .running,
                   let device = world.queryDeviceAnchor(atTimestamp: now), device.isTracked {
                    deviceTransform = device.originFromAnchorTransform
                    alignToSpawn()
                    model.canPlace = manifest != nil
                    model.trackingStatus = "World tracking active"
                    if handAccess, hands.state == .running, now - lastHandUpdate < 0.25, let hand = latestLeftHand {
                        eligible = wristAttended(hand)
                        navigation = navigationSample(hand)
                    }
                } else {
                    model.canPlace = false
                    model.trackingStatus = "Tracking paused · look around to recover"
                }
                if handAccess && hands.state == .stopped {
                    model.needsManualToolbox = true
                    model.handTrackingStatus = "Hand tracking stopped · use navigation controls or re-enter to retry"
                }
                model.updateHandToolboxActivation(attended: eligible, now: now)
                updateLeftNavigation(navigation, at: ProcessInfo.processInfo.systemUptime, model: model)
                try await Task.sleep(for: .milliseconds(33))
            }
        } catch is CancellationError {
        } catch {
            model.trackingStatus = "Tracking unavailable: \(error.localizedDescription)"
            model.updateHandToolboxActivation(attended: false, now: CACurrentMediaTime())
            model.needsManualToolbox = true
            model.handTrackingStatus = "Use navigation controls or re-enter the venue to retry tracking."
            // Keep the explicit fallback responsive even after authorization/session failure.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        #endif
    }

    /// Head direction approximates attention; visionOS does not expose eye gaze.
    /// A wrist remains usable when its fingers are hidden or the palm is edge-on.
    private func wristAttended(_ hand: HandAnchor) -> Bool {
        guard hand.chirality == .left, hand.isTracked,
              let wrist = hand.handSkeleton?.joint(.wrist), wrist.isTracked else { return false }
        let transform = hand.originFromAnchorTransform * wrist.anchorFromJointTransform
        return WristAttention.isAttended(
            wrist: [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z],
            eye: [deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z],
            forward: -SIMD3(deviceTransform.columns.2.x, deviceTransform.columns.2.y, deviceTransform.columns.2.z))
    }


    func endSpatialDrag(model: VenueModel) {
        if model.palmMapVisible, model.canPlace, !navigationGestureCancelled {
            palmMap.finish()
            model.message = palmMap.message
        } else { palmMap.cancel() }
        navigationGestureCancelled = false
        model.endTransformDrag()
    }

    func cancelSpatialDrag(model: VenueModel) {
        palmMap.cancel(); navigationGestureCancelled = false; model.endTransformDrag()
    }

    private func tickNavigation() {
        guard let manifest = navigationEnvironment else { return }
        let eye = SIMD3(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let localEye = root.convert(position: eye, from: nil)
        if displayedMapRequestID != model?.palmMapRequestID {
            if palmMap.dragging { navigationGestureCancelled = true }
            palmMap.cancel()
            palmMap.reset()
            displayedMapRequestID = model?.palmMapRequestID
            // Capture a world pose once per explicit opening. Looking around or
            // moving hands does not shift the map while acquiring its marker.
            mapWorldOrientation = simd_quatf(deviceTransform)
            mapWorldPosition = eye + mapWorldOrientation.act([0,0.06,-0.8])
        }
        let visible = model?.palmMapVisible == true && model?.canPlace == true
        if !visible { palmMap.cancel() }
        palmMap.update(environment: manifest, viewpoint: localEye - SIMD3<Float>(0, max(0.5, deviceTransform.columns.3.y), 0), worldPosition: mapWorldPosition,
                       orientation: mapWorldOrientation, visible: visible)
        if let start = blackoutFadeStart {
            let opacity = max(0,1-Float((CACurrentMediaTime()-start)/blackoutFadeDuration))
            blackoutCover?.components.set(OpacityComponent(opacity: opacity))
            if opacity == 0 {
                blackoutCover?.isEnabled = false; blackoutFadeStart = nil
                model?.navigationBlackoutActive = false
            }
        }
    }

    private func transitionNavigation(_ action: PalmNavigationVisual.Action, milliseconds: Double) {
        guard navigationTransition == nil, blackoutFadeStart == nil else { return }
        if blackoutCover == nil {
            var material = UnlitMaterial(color: .black)
            material.faceCulling = .front
            let cover = ModelEntity(mesh: .generateSphere(radius: 0.12), materials: [material])
            cover.name = "NavigationBlackout"; headAnchor.addChild(cover); blackoutCover = cover
        }
        let requestID = model?.palmMapRequestID
        model?.navigationBlackoutActive = true
        blackoutFadeStart = nil
        blackoutCover?.components.set(OpacityComponent(opacity: 1)); blackoutCover?.isEnabled = true
        navigationTransition = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.navigationTransition = nil }
            // Present a black frame before changing the world under the viewer.
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            guard self.model?.palmMapRequestID == requestID, requestID != nil, self.model?.canPlace == true else {
                self.blackoutCover?.isEnabled = false
                self.model?.navigationBlackoutActive = false
                return
            }
            let eye = SIMD3(self.deviceTransform.columns.3.x,self.deviceTransform.columns.3.y,self.deviceTransform.columns.3.z)
            switch action {
            case .teleport(let destination):
                guard let manifest = self.navigationEnvironment, PalmMapProjection.obstruction(destination, in: manifest) == nil else {
                    self.blackoutCover?.isEnabled = false; self.model?.navigationBlackoutActive = false; return
                }
                let rotation = self.root.orientation
                let localEye = self.root.convert(position: eye, from: nil)
                let eyeHeight = max(0.5, self.deviceTransform.columns.3.y)
                self.root.position += rotation.act(localEye - SIMD3(destination.x,destination.y + eyeHeight,destination.z))
            }
            if let model = self.model {
                let view = (self.root.orientation * self.spawnRootTransform.rotation.inverse).inverse
                let poseRotation = self.spawnFrameRotation.inverse * view * self.spawnFrameRotation
                let worldOffset = self.spawnRootTransform.translation-eye-view.act(self.root.position-eye)
                let offset = self.spawnFrameRotation.inverse.act(worldOffset)
                model.beginViewerNavigation(.index)
                model.updateViewerNavigation(.init(offset: .init(x: offset.x,y: offset.y,z: offset.z),
                    orientation: .init(x: poseRotation.imag.x,y: poseRotation.imag.y,z: poseRotation.imag.z,w: poseRotation.real)))
                model.endViewerNavigation()
                self.leftNavigation.restore(model.viewerPose)
            }
            self.blackoutFadeDuration = max(0.001,min(max(milliseconds,0),2000)/1000)
            self.blackoutFadeStart = CACurrentMediaTime()
        }
    }

    private func updatePlacementGhost() {
        placementTarget = nil
        placementGhost.isEnabled = false
        guard let model, model.isPlacing, model.canPlace, !model.palmMapVisible, !palmMap.dragging else { placementGhost.isEnabled = false; return }
        let eye = SIMD3(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let direction = -SIMD3(deviceTransform.columns.2.x,deviceTransform.columns.2.y,deviceTransform.columns.2.z)
        // Head-forward chooses the displayed outline and the committed position.
        // Cache this hit so a gaze-targeted click cannot move the fixture elsewhere.
        guard let hits = root.scene?.raycast(origin: eye,direction: direction,length: 30,query: .all,mask: .all,relativeTo: nil),
              let hit = hits.sorted(by: { $0.distance < $1.distance }).first(where: {
                  model.scannedMesh != nil ? $0.entity.name.hasPrefix("aim-surface:") : $0.entity.name.hasPrefix("room-collider:")
              }) else { placementGhost.isEnabled = false; return }
        let point = root.convert(position: hit.position, from: nil)
        let radius = model.fixtureKind.radius
        let base: SIMD3<Float>
        if let scan = model.scannedMesh {
            guard scan.supports(.init(x: point.x,y: point.y,z: point.z),radius: radius) else { placementGhost.isEnabled = false; return }
            base = point
        } else {
            let id = String(hit.entity.name.dropFirst("room-collider:".count))
            guard let position = manifest?.surfaces.first(where: { $0.id == id })?.fixturePosition(hit: .init(x: point.x,y: point.y,z: point.z),halfSize: radius) else {
                placementGhost.isEnabled = false; return
            }
            base = [position.x,position.y-radius,position.z]
        }
        if placementGhost.name != model.fixtureKind.name {
            placementGhost.children.removeAll(); placementGhost.name = model.fixtureKind.name
            let asset = model.fixtureKind.asset
            let minimum = asset.map { SIMD3<Float>($0.boundsMin[0],$0.boundsMin[1],$0.boundsMin[2]) } ?? [-radius,0,-radius]
            let maximum = asset.map { SIMD3<Float>($0.boundsMax[0],$0.boundsMax[1],$0.boundsMax[2]) } ?? [radius,2*radius,radius]
            let extent = maximum-minimum, center = (minimum+maximum)/2
            for axis in 0..<3 { for a: Float in [-1,1] { for b: Float in [-1,1] {
                var size = SIMD3<Float>(repeating: 0.002); size[axis] = extent[axis]
                var location = center
                location[(axis+1)%3] += a*extent[(axis+1)%3]/2
                location[(axis+2)%3] += b*extent[(axis+2)%3]/2
                let line = ModelEntity(mesh: .generateBox(size: size),materials: [UnlitMaterial(color: .cyan)])
                line.position = location; placementGhost.addChild(line)
            } } }
            placementGhost.components.set(OpacityComponent(opacity: 0.55))
        }
        placementGhost.position = base; placementGhost.isEnabled = true
        placementTarget = PlacementTarget(point: point,
            surfaceID: model.scannedMesh == nil ? String(hit.entity.name.dropFirst("room-collider:".count)) : nil,
            kind: model.fixtureKind, unitID: model.placementUnitID,
            roomToken: model.roomLoadToken, sessionID: model.placementSessionID)
    }

    private func updateGroupLinks(model: VenueModel) {
        let selected = model.fixtures.filter { model.selectedFixtureIDs.contains($0.id) }
        let key = selected.map { "\($0.id):\($0.position)" }.joined()
        guard key != connectorRevision else { return }
        connectorRevision = key; groupLinks.children.removeAll()
        guard selected.count > 1 else { return }
        for index in 1..<selected.count {
            let first = selected[index-1], second = selected[index]
            let start = FixtureAiming.vector(first.position)+[0,first.assetID == nil ? -0.10 : 0.02,0]
            let end = FixtureAiming.vector(second.position)+[0,second.assetID == nil ? -0.10 : 0.02,0]
            let distance = simd_distance(start,end), count = min(48,max(2,Int(distance/0.045)))
            for dot in 0..<count {
                let point = start+(end-start)*(Float(dot)/Float(count-1))
                let bead = ModelEntity(mesh: .generateSphere(radius: 0.002),materials: [UnlitMaterial(color: .cyan)])
                bead.position = point; groupLinks.addChild(bead)
            }
        }
    }

    func clearAttachments() {
        navigationTransition?.cancel(); navigationTransition = nil; blackoutFadeStart = nil
        model?.navigationBlackoutActive = false
        palmMap.reset()
        displayedMapRequestID = nil
        model?.closePalmMap()
        blackoutCover?.removeFromParent(); blackoutCover = nil
        fixtureLoadGeneration = UUID()
        fixtureLoads.values.forEach { $0.cancel() }; fixtureLoads.removeAll()
        for entity in labels.values { entity.removeFromParent() }
        labels.removeAll()
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
        let base = Entity(); base.name = "SelectionBase"; base.position.y = -side/2-0.002
        // A flat, padded 2D ring at the primitive's base, without a hit target.
        for index in 0..<64 {
            let angle = Float(index)*2 * .pi/64
            let segment = ModelEntity(mesh: .generateBox(size: [0.016,0.001,0.002]),materials: [edgeMaterial])
            segment.position = [cos(angle)*0.17,0,sin(angle)*0.17]
            segment.orientation = simd_quatf(angle: -angle + .pi/2,axis: [0,1,0])
            base.addChild(segment)
        }
        base.isEnabled = false; cube.addChild(base)
        return cube
    }
}
