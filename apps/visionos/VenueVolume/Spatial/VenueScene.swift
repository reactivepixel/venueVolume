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
    private var thermalPoll: Double = 0
    private var benchmarkElapsed: Double = 0
    private var benchmarkCadence = SceneCadence()
    private var benchmarkFinished = false
    private var benchmarkBudgets: [UUID: Int] = [:]
    private var benchmarkThermals: Set<String> = []
    private var benchmarkAllocated: Set<Int> = []
    private var benchmarkInitialThermal = ""
    private var benchmarkFixtures: [Fixture] = []
    private var benchmarkRevision = 0
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
    private let presetDragVisual = PresetDragVisual()
    private var presetReduceMotion = false
    private var latestRightHand: HandAnchor?
    private var lastRightHandUpdate: Double = 0
    let headAnchor = AnchorEntity(.head, trackingMode: .continuous)
    private let repository: (any EnvironmentRepository)?
    private let environmentID: String
    private var manifest: EnvironmentManifest?
    private var aligned = false
    private var cubes: [UUID: ModelEntity] = [:]
    private var labels: [UUID: Entity] = [:]
    private var drops: [UUID: Entity] = [:]
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
                if let benchmark = model.lightingBenchmark,
                   let room = model.rooms.first(where: { $0.manifest.id == benchmark.roomID }) {
                    model.roomRequest = .init(room: room, setup: nil, blank: true)
                }
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
            #if DEBUG
            try validateRoomImport(newMaterials, manifest: resolved.manifest)
            #endif
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
            root.children.removeAll(); cubes.removeAll(); rigs.removeAll(); labels.removeAll(); drops.removeAll()
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
            benchmarkElapsed = 0; benchmarkCadence = SceneCadence(); benchmarkFinished = false
            benchmarkThermals = []; benchmarkAllocated = []; benchmarkInitialThermal = ""
            model.activate(environment: resolved.manifest)
            benchmarkFixtures = model.lightingBenchmark == nil ? [] : model.fixtures
            benchmarkRevision = model.revision
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
            if let model = self.model, model.presetDrag.isActive { self.updatePresetDrag(model: model, reduceMotion: self.presetReduceMotion) }
            self.presetDragVisual.tick()
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
            self.updateLightingDiagnostics(deltaTime: event.deltaTime)
        }
    }

    private func tickPhasers() {
        guard let model, model.lightingBenchmark == nil, !model.navigationBlackoutActive else { return }
        let animated = Set(model.fixtures.filter { model.hasAnimatedPalette(for: $0) }.map(\.id))
        guard !animated.isEmpty else { return }
        let channels = Dictionary(uniqueKeysWithValues: model.fixtures.map { ($0.id,model.renderedChannels(for: $0)) })
        let budgets = LightingBudget.allocate(model.fixtures.map { fixture in
            let look = LightingPreview(channels: channels[fixture.id] ?? fixture.channels,blackout: model.isBlackedOut(fixture))
            return .init(id: fixture.id,emitters: fixtureTemplates[fixture.assetID ?? ""] == nil ? 0 : fixture.asset?.emitters.count ?? 0,
                         emitting: look.intensity > 0 && look.rgb.contains { $0 > 0 })
        },selected: model.selectedID,limit: model.effectiveLightLimit)
        for fixture in model.fixtures {
            guard animated.contains(fixture.id) || budgets[fixture.id] != benchmarkBudgets[fixture.id],
                  let rig = rigs[fixture.id] else { continue }
            rig.update(fixture: model.renderedFixture(fixture),channels: channels[fixture.id] ?? fixture.channels,
                       selected: model.selectedFixtureIDs.contains(fixture.id),blackout: model.isBlackedOut(fixture),
                       placing: model.isPickingRoom,interactive: model.isTransformDragging,
                       lightBudget: budgets[fixture.id] ?? 0)
        }
        benchmarkBudgets = budgets
    }

    private func updateLightingDiagnostics(deltaTime: Double) {
        guard let model else { return }
        thermalPoll += deltaTime
        if thermalPoll >= 1 || benchmarkInitialThermal.isEmpty {
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
            if benchmarkInitialThermal.isEmpty { benchmarkInitialThermal = thermal.rawValue }
        }
        guard let benchmark = model.lightingBenchmark, !benchmarkFinished,
              aligned, root.isEnabled, model.isImmersed, rigs.count == 64 else { return }
        guard manifest?.id == benchmark.roomID, !model.whiteRoom, !model.blackout, model.houseLight == 0.05,
              model.selectedID == nil, !model.previewDraft, model.revision == benchmarkRevision else {
            benchmarkFinished = true
            model.lightingBenchmarkStatus = "Benchmark invalidated by scene edits. Relaunch to repeat the controlled comparison."
            return
        }
        benchmarkElapsed += deltaTime
        if benchmark.moving {
            for (index, fixture) in benchmarkFixtures.enumerated() {
                var channels = fixture.channels
                channels[4] = 128 + Int(sin(benchmarkElapsed * 0.65 + Double(index)*0.3) * 65)
                channels[5] = 158 + Int(sin(benchmarkElapsed * 0.4 + Double(index)*0.2) * 25)
                rigs[fixture.id]?.update(fixture: fixture, channels: channels, selected: false, blackout: false,
                                         placing: false, lightBudget: benchmarkBudgets[fixture.id] ?? 0)
            }
        }
        // Exclude cold imports, pipeline compilation and the first five seconds.
        guard benchmarkElapsed > 5 else { return }
        benchmarkCadence.append(seconds: deltaTime)
        benchmarkThermals.insert(model.lightingThermal.rawValue)
        benchmarkAllocated.insert(benchmarkBudgets.values.reduce(0,+))
        guard benchmarkElapsed >= 5 + benchmark.seconds, let cadence = benchmarkCadence.summary else { return }
        benchmarkFinished = true
        do {
            let data = try JSONEncoder().encode(cadence)
            let summary = try JSONSerialization.jsonObject(with: data)
            #if targetEnvironment(simulator)
            let execution = "simulator"
            #else
            let execution = "device"
            #endif
            let report: [String: Any] = [
                "schemaVersion": 1, "execution": execution, "roomID": manifest?.id ?? "",
                "roomVersion": manifest?.version ?? "", "assetSHA256": manifest?.asset.sha256 ?? "",
                "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                "os": ProcessInfo.processInfo.operatingSystemVersionString, "gpu": metalDevice?.name ?? "unavailable",
                "requestedShadowLights": benchmark.lights, "allocatedShadowLights": benchmarkAllocated.sorted(),
                "fixtureObjects": rigs.count, "moving": benchmark.moving, "whiteRoom": model.whiteRoom,
                "houseLight": model.houseLight, "measurementSeconds": benchmarkElapsed-5,
                "thermalStart": benchmarkInitialThermal, "thermalStates": benchmarkThermals.sorted(),
                "sceneUpdateCadence": summary,
                "lightComponentWritesIncludingWarmup": rigs.values.reduce(0) { $0+$1.lightComponentWrites },
                "jointTransformWritesIncludingWarmup": rigs.values.reduce(0) { $0+$1.jointTransformWrites },
                "displayedFPS": NSNull(), "gpuFrameTimeMS": NSNull(),
                "conclusion": "Cadence diagnostic only. Verify visible light count, shadows, GPU deadlines and thermal stability with RealityKit Trace on device."
            ]
            let output = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            model.lightingBenchmarkJSON = String(decoding: output, as: UTF8.self)
            let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Benchmarks")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("lighting-" + UUID().uuidString + ".json")
            try output.write(to: file, options: .atomic)
            model.lightingBenchmarkStatus = "Recorded cadence · \(benchmark.lights) requested shadow beams. GPU profiling still required."
            print("VV_LIGHTING_BENCHMARK " + model.lightingBenchmarkJSON)
        } catch {
            model.lightingBenchmarkStatus = "Benchmark report could not be saved: " + error.localizedDescription
        }
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

    #if DEBUG
    /// Exercise the actual RealityKit map entities, drag coordinates and commit gate.
    func runPalmMapSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--palm-map-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            var room = EnvironmentManifest.simple(id: "map-test", title: "Map", min: [-5,0,-5], max: [5,5,5], spawn: [0,0,3], yaw: 0,
                file: "room.usdz", checksum: String(repeating: "a", count: 64), bytes: 1, scanned: false)
            var desk = room.colliders[0]
            desk.id = "desk"; desk.sourceID = "desk"; desk.center = [0,0.5,0]; desk.size = [2,1,2]
            room.colliders.append(desk)
            let visual = PalmNavigationVisual()
            overlayRoot.addChild(visual.entity)
            defer { visual.entity.removeFromParent() }
            func update() { visual.update(environment: room, viewpoint: [0,0,3], worldPosition: .zero, orientation: .init(angle: 0,axis: [0,1,0]), visible: true) }
            update()
            guard let floor = visual.entity.findEntity(named: "palm-map-floor"),
                  let marker = visual.entity.findEntity(named: "palm-map-viewpoint"),
                  let vertical = visual.entity.findEntity(named: "palm-map-move-1"), let miniature = floor.parent else {
                throw EnvironmentError.invalid("Map entities missing")
            }
            _ = visual.tap(floor, worldPoint: miniature.convert(position: .zero, to: nil), environment: room)
            update()
            guard visual.message.contains("Obstructed"),
                  visual.entity.findEntity(named: "palm-map-teleport")?.components[InputTargetComponent.self] == nil else {
                throw EnvironmentError.invalid("Blocked proposal allowed teleport")
            }
            let start = vertical.position(relativeTo: nil)
            let scale = PalmMapProjection(minimum: room.bounds.min, maximum: room.bounds.max).metersToMap
            guard visual.drag(vertical, worldPoint: start+[0,1.2*cos(PalmMapProjection.pitch)*scale,0], worldStart: start, environment: room) else {
                throw EnvironmentError.invalid("Vertical handle did not route")
            }
            visual.finish(); update(); update()
            guard let button = visual.entity.findEntity(named: "palm-map-teleport"),
                  button.components[InputTargetComponent.self] != nil,
                  case .teleport(let point) = visual.tap(button, worldPoint: button.position(relativeTo: nil), environment: room), abs(point.y-1.2) < 0.001 else {
                throw EnvironmentError.invalid("Raised proposal did not persist and clear the obstacle")
            }
            let markerStart = marker.position(relativeTo: nil)
            _ = visual.drag(marker, worldPoint: markerStart+[2,0,0], worldStart: markerStart, environment: room)
            visual.finish(); update(); update()
            guard visual.entity.findEntity(named: "palm-map-teleport")?.components[InputTargetComponent.self] == nil else {
                throw EnvironmentError.invalid("Out-of-room proposal accepted")
            }
            model.togglePalmMap(); tickNavigation()
            if let cube = palmMap.entity.findEntity(named: "palm-map-viewpoint"), let environment = navigationEnvironment {
                _ = palmMap.tap(cube, worldPoint: cube.position(relativeTo: nil), environment: environment)
            }
            tickNavigation()
            FileHandle.standardOutput.write(Data("PALM_MAP_SMOKE_PASS isometric=true blockedPersists=true verticalClearance=true explicitTeleport=true bounds=true\n".utf8))
        } catch { FileHandle.standardOutput.write(Data("PALM_MAP_SMOKE_FAIL \(error)\n".utf8)) }
    }

    func runNavigationSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--navigation-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.resetViewerToSpawn(); applyViewerNavigation(model: model)
            let fixtures = model.fixtures, presets = model.presets
            let eye = SIMD3<Float>(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
            let initialEye = root.convert(position: eye,from: nil)
            var time = ProcessInfo.processInfo.systemUptime
            func send(_ finger: NavigationFinger? = nil, point: SIMD3<Float> = .zero) {
                time += 0.04
                updateLeftNavigation(.init(thumb: point,index: point+[finger == .index ? 0.01 : 0.1,0,0],middle: point+[0,finger == .middle ? 0.01 : 0.1,0]),at: time,model: model)
            }
            send(); send(.index); send(.index,point: [10,4,-10]); send(); send()
            try await Task.sleep(for: .milliseconds(100))
            let moved = model.viewerPose, movedEye = root.convert(position: eye,from: nil)
            guard simd_distance(movedEye,initialEye) > 30, model.fixtures == fixtures, model.presets == presets else { throw EnvironmentError.invalid("Travel failed: distance=\(simd_distance(movedEye,initialEye)) offset=\(moved.offset) fixturesEqual=\(model.fixtures == fixtures) presetsEqual=\(model.presets == presets)") }
            model.undo(); applyViewerNavigation(model: model)
            try await Task.sleep(for: .milliseconds(100))
            guard simd_distance(root.convert(position: eye,from: nil),initialEye) < 0.001 else { throw EnvironmentError.invalid("Navigation Undo failed") }
            model.redo(); applyViewerNavigation(model: model)
            guard model.viewerPose == moved else { throw EnvironmentError.invalid("Navigation Redo failed") }
            send(.middle); send(.middle,point: [0.1,0.2,0.1]); send(); send()
            try await Task.sleep(for: .milliseconds(100))
            guard model.viewerPose.orientation != .init(), model.viewerPose.offset == moved.offset,
                  simd_distance(root.convert(position: eye,from: nil),movedEye) < 0.001 else { throw EnvironmentError.invalid("Rotation moved viewer position") }
            send(.middle); send(); send(); send(.middle); send(); send()
            guard model.viewerPose.orientation == .init(), model.viewerPose.offset == moved.offset else { throw EnvironmentError.invalid("Double middle reset failed") }
            send(.index); send(); send(); send(.index); send(); send()
            try await Task.sleep(for: .milliseconds(100))
            guard model.viewerPose == .init(), simd_distance(root.convert(position: eye,from: nil),initialEye) < 0.001 else { throw EnvironmentError.invalid("Double index spawn reset failed") }
            time += 0.5; send()
            guard !model.navigationInputReserved else { throw EnvironmentError.invalid("Navigation release kept editing blocked") }
            model.message = "Left index moves · left middle rotates · double pinch resets."
            print("VIEWER_NAVIGATION_SMOKE_PASS freeTravel=true fixedFixtures=true rotationPivot=true doubleMiddle=true doubleIndex=true undoRedo=true release=true")
        } catch { print("VIEWER_NAVIGATION_SMOKE_FAIL \(error)") }
    }

    /// Exercises real collision normals and body-drag routing, not hand input.
    func runFixtureMovementSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--movement-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.clearScene()
            guard model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66,y: 0,z: -2.3), surfaceID: "floor"),
                  let fixture = model.fixtures.first else { throw EnvironmentError.invalid("Pilot placement failed") }
            try await Task.sleep(for: .milliseconds(700))
            model.deselect()
            guard let fixtureRoot = root.findEntity(named: fixture.id.uuidString),
                  let target = fixtureRoot.children.first(where: { $0.components.has(InputTargetComponent.self) }) else { throw EnvironmentError.invalid("Fixture input target missing") }
            let start = target.position(relativeTo: root)
            handleTap(entity: target,position: start,model: model)
            guard !model.gizmoVisible else { throw EnvironmentError.invalid("First tap did not stay selection-only") }
            handleTap(entity: target,position: start,model: model)
            try await Task.sleep(for: .milliseconds(250))
            guard model.gizmoVisible, target.components.has(SpatialDragTarget.self),
                  handleDrag(entity: target,position: start+[0.1,0.2,0.1],start: start,model: model) else { throw EnvironmentError.invalid("Second click/body drag routing failed") }
            model.endTransformDrag()
            guard let slid = model.fixture(fixture.id), abs(slid.position.x-fixture.position.x-0.1) < 0.001,
                  slid.position.y == fixture.position.y, slid.channels == fixture.channels else { throw EnvironmentError.invalid("Rendered body drag left its plane or failed: \(model.message ?? "unknown")") }
            model.undo(); guard model.fixture(fixture.id) == fixture else { throw EnvironmentError.invalid("Body drag Undo failed") }
            model.redo(); model.beginTransform(fixture.id)
            guard let physics = root.scene else { throw EnvironmentError.invalid("Physics scene missing") }
            let floorPoint = SIMD3<Float>(2.9,0,-2.7)
            guard let floor = physics.raycast(origin: floorPoint+[0,0.1,0],direction: [0,-1,0],length: 0.2,query: .all,mask: .all,relativeTo: root).first(where: { $0.entity.name.hasPrefix("aim-surface:") }) else { throw EnvironmentError.invalid("Rendered floor missing") }
            handleTap(entity: floor.entity,position: floor.position,model: model)
            guard let onFloor = model.fixture(fixture.id), simd_distance(FixtureAiming.vector(onFloor.position),floor.position) < 0.001,
                  onFloor.mountPlane != nil else { throw EnvironmentError.invalid("Surface tap did not move to rendered floor: \(model.message ?? "unknown")") }
            var onWall: Fixture?
            for collider in model.environment?.colliders ?? [] where collider.size[1] > 1 {
                let axis = collider.size[0] < collider.size[2] ? 0 : 2
                guard collider.size[axis] < 0.5 else { continue }
                let rotation = Quaternion3D(x: collider.rotation[0],y: collider.rotation[1],z: collider.rotation[2],w: collider.rotation[3])
                for sign: Float in [-1,1] {
                    var local = SIMD3<Float>.zero; local[axis] = sign
                    let normal = FixtureAiming.rotate(rotation,local)
                    let face = SIMD3<Float>(collider.center[0],collider.center[1],collider.center[2]) + normal*collider.size[axis]/2
                    let hits = physics.raycast(origin: face+normal*0.15,direction: -normal,length: 0.3,query: .all,mask: .all,relativeTo: root)
                    guard let hit = hits.first(where: { $0.entity.name.hasPrefix("aim-surface:") && abs($0.normal.y) < 0.1 }) else { continue }
                    handleTap(entity: hit.entity,position: hit.position,model: model)
                    if let candidate = model.fixture(fixture.id), let plane = candidate.mountPlane, abs(plane.normal.y) < 0.1 {
                        onWall = candidate; break
                    }
                }
                if onWall != nil { break }
            }
            guard let onWall, let plane = onWall.mountPlane,
                  FixtureAiming.length(FixtureAiming.rotate(onWall.orientation,[0,1,0])-FixtureAiming.vector(plane.normal)) < 0.001,
                  onWall.channels == fixture.channels else { throw EnvironmentError.invalid("No rendered wall accepted mount alignment: \(model.message ?? "unknown")") }
            model.undo(); guard model.fixture(fixture.id) == onFloor else { throw EnvironmentError.invalid("Wall move Undo failed") }
            model.redo(); guard model.fixture(fixture.id) == onWall else { throw EnvironmentError.invalid("Wall move Redo failed") }
            model.deselect()
            try await Task.sleep(for: .milliseconds(200))
            guard !target.components.has(SpatialDragTarget.self),
                  let dock = headAnchor.children.first(where: { $0.name == "context-bar" }),
                  !dock.isEnabled else { throw EnvironmentError.invalid("Deselection did not hide the context bar") }
            // Presentation follows the same user commands after assertions.
            model.beginTransform(fixture.id)
            handleTap(entity: floor.entity,position: floor.position,model: model)
            if ProcessInfo.processInfo.arguments.contains("--movement-screenshot") {
                let tablePoint = SIMD3<Float>(1.5,0.74,-3.68)
                if let table = physics.raycast(origin: tablePoint+[0,0.1,0],direction: [0,-1,0],length: 0.2,query: .all,mask: .all,relativeTo: root).first(where: { $0.entity.name.hasPrefix("aim-surface:") }) {
                    handleTap(entity: table.entity,position: table.position,model: model)
                }
            }
            for kind in FixtureKind.allCases.filter({ $0 != .movingHead }).prefix(5) { model.rememberFixtureKind(kind) }
            model.message = "Movement runtime checks passed."
            print("FIXTURE_MOVEMENT_SMOKE_PASS secondClick=true bodySlide=true floorHit=true wallNormal=true undoRedo=true horizontalDock=true")
        } catch { print("FIXTURE_MOVEMENT_SMOKE_FAIL \(error)") }
    }
    #endif

    #if DEBUG
    func runTransformGizmoSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--gizmo-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            guard let fixture = model.fixtures.first else { throw EnvironmentError.invalid("No fixture") }
            model.finishPlacement(); model.beginTransform(fixture.id)
            func enabledHandles(_ entity: Entity) -> [Entity] {
                guard entity.isEnabled else { return [] }
                return (FixtureTransformGizmo.handle(entity) == nil ? [] : [entity]) + entity.children.flatMap { enabledHandles($0) }
            }
            for mode in FixtureTransformMode.allCases {
                model.transformMode = mode
                transformGizmo.update(fixture: fixture, visible: true, mode: mode)
                let handles = enabledHandles(transformGizmo.entity)
                guard !handles.isEmpty, handles.allSatisfy({ FixtureTransformGizmo.handle($0)?.1 == mode }) else {
                    throw EnvironmentError.invalid("\(mode.rawValue) displays handles from the other action")
                }
            }
            model.selectTransformMode(.move)
            transformGizmo.update(fixture: fixture, visible: true, mode: .move)
            let models = enabledHandles(transformGizmo.entity).compactMap { $0 as? ModelEntity }
            guard let x = models.first(where: { FixtureTransformGizmo.handle($0)?.0 == .x }),
                  let y = models.first(where: { FixtureTransformGizmo.handle($0)?.0 == .y }) else { throw EnvironmentError.invalid("Axis handles missing") }
            func brightness(_ entity: ModelEntity) -> CGFloat {
                guard let material = entity.model?.materials.first as? UnlitMaterial else { return -1 }
                var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
                material.color.tint.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                return brightness
            }
            let idleX = brightness(x), idleY = brightness(y)
            transformGizmo.update(fixture: fixture, visible: true, mode: .move, selectedAxis: .x)
            guard brightness(x) > idleX*2, brightness(y) == idleY,
                  models.allSatisfy({ entity in
                      guard let material = entity.model?.materials.first as? UnlitMaterial else { return false }
                      return !material.readsDepth && !material.writesDepth && entity.components.has(HoverEffectComponent.self)
                  }) else { throw EnvironmentError.invalid("Overlay or selected-axis material failed") }
            let blocker = ModelEntity(mesh: .generateBox(size: [1.6,1.6,0.1]), materials: [UnlitMaterial(color: .gray)])
            blocker.name = "aim-surface:gizmo-test-blocker"
            let center = FixtureAiming.vector(fixture.visualCenter)
            blocker.position = center+[0,0,0.2]
            blocker.components.set(CollisionComponent(shapes: [.generateBox(size: [1.6,1.6,0.1])]))
            blocker.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
            root.addChild(blocker)
            defer { blocker.removeFromParent() }
            try await Task.sleep(for: .milliseconds(300))
            let origin = center+[0.63,0,2]
            guard let scene = root.scene,
                  scene.raycast(origin: origin, direction: [0,0,-1], length: 2, query: .all, mask: .all, relativeTo: root).first?.entity === blocker,
                  let hit = transformHandle(origin: origin, direction: [0,0,-1], model: model),
                  FixtureTransformGizmo.handle(hit.entity)?.0 == .x else { throw EnvironmentError.invalid("Obstructed handle could not be picked") }
            guard handleDrag(entity: hit.entity, position: hit.position, start: hit.position, model: model) else { throw EnvironmentError.invalid("Handle did not start dragging") }
            for mode in FixtureTransformMode.allCases {
                if mode == .rotate { model.selectTransformMode(mode) }
                transformGizmo.update(fixture: fixture, visible: true, mode: mode, selectedAxis: model.activeTransformAxis)
                for blocked in [false,true] {
                    blocker.isEnabled = blocked
                    try await Task.sleep(for: .seconds(1))
                    guard model.transformMode == mode,
                          enabledHandles(transformGizmo.entity).allSatisfy({ FixtureTransformGizmo.handle($0)?.1 == mode }) else {
                        throw EnvironmentError.invalid("Selected mode changed after rendering")
                    }
                    let stage = mode.rawValue.uppercased() + (blocked ? "_BLOCKED" : "_CLEAR")
                    FileHandle.standardOutput.write(Data("GIZMO_CAPTURE_\(stage)\n".utf8))
                    try await Task.sleep(for: .seconds(5))
                }
            }
            FileHandle.standardOutput.write(Data("GIZMO_SMOKE_PASS exclusiveModes=true overlay=true obstructedHit=true selectedBrightness=true\n".utf8))
        } catch { FileHandle.standardOutput.write(Data("GIZMO_SMOKE_FAIL \(error)\n".utf8)) }
    }

    func runPaletteTargetSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--palette-target-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            try await Task.sleep(for: .seconds(2))
            guard model.canPlace, let first = model.fixtures.first,
                  model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 4,y: 0,z: -2), surfaceID: "floor"),
                  let second = model.fixtures.last, first.id != second.id else { throw EnvironmentError.invalid("Target fixtures unavailable") }
            model.finishPlacement(); model.select(first.id, extendSelection: false)
            model.multiSelectionMode = true; model.select(second.id)
            try await Task.sleep(for: .seconds(1))
            guard let palette = model.presets.first(where: { $0.pool == .color && $0.phaser != nil }) else { throw EnvironmentError.invalid("Target palette unavailable") }
            model.choosePreset(palette)
            let library = model.presets
            let point = Position3D(x: 3,y: 1.5,z: -7)
            model.beginPaletteTarget()
            guard model.acceptTarget(point) else { throw EnvironmentError.invalid(model.message ?? "Target rejected") }
            try await Task.sleep(for: .seconds(2))
            for fixture in [first,second] {
                let aim = try FixtureAiming.articulated(fixture, target: point)
                guard model.renderedChannels(for: fixture)[4] == aim.pan,
                      model.renderedChannels(for: fixture)[5] == aim.tilt,
                      rigs[fixture.id] != nil else { throw EnvironmentError.invalid("Target preview did not render") }
            }
            guard model.saveTarget(), model.presets == library else { throw EnvironmentError.invalid("Target cue save failed: \(model.message ?? model.presetMessage ?? "no message")") }
            try await Task.sleep(for: .seconds(2))
            guard !model.isRetargeting, model.currentCue == 1 else { throw EnvironmentError.invalid("Target save did not finish") }
            FileHandle.standardOutput.write(Data("PALETTE_TARGET_SMOKE_PASS multiFixture=true livePreview=true cueSave=true libraryUnchanged=true\n".utf8))
        } catch is CancellationError { }
        catch { FileHandle.standardOutput.write(Data("PALETTE_TARGET_SMOKE_FAIL \(error)\n".utf8)) }
    }

    /// Native render capture checks room ambience independently of fixture data.
    func runRoomLightSmoke(model: VenueModel) async {
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.deselect(); model.closePalmMap(); model.setPalettePlaying(false)
            let fixtures = model.fixtures, cues = model.cueSheet, presets = model.presets
            let channels = fixtures.map { model.renderedChannels(for: $0) }
            model.blackout = true
            for (label, level): (String,Float) in [("LOW",0),("HIGH",1)] {
                model.houseLight = level
                try await Task.sleep(for: .seconds(2))
                FileHandle.standardOutput.write(Data("ROOM_LIGHT_CAPTURE_\(label)\n".utf8))
                try await Task.sleep(for: .seconds(8))
            }
            guard model.fixtures == fixtures, model.presets == presets, model.cueSheet == cues,
                  model.fixtures.map({ model.renderedChannels(for: $0) }) == channels else {
                throw EnvironmentError.invalid("Room light changed fixture programming")
            }
            func emitters(_ entity: Entity) -> [Float] {
                var values: [Float] = []
                if let light = entity.components[SpotLightComponent.self] {
                    values = [light.intensity,light.innerAngleInDegrees,light.outerAngleInDegrees,light.attenuationRadius]
                    values += (light.color.cgColor.components ?? []).map(Float.init)
                }
                return values + entity.children.flatMap { emitters($0) }
            }
            model.blackout = false; model.houseLight = 0
            try await Task.sleep(for: .milliseconds(500))
            let darkEmitters = emitters(root)
            model.houseLight = 1
            try await Task.sleep(for: .milliseconds(500))
            guard !darkEmitters.isEmpty, emitters(root) == darkEmitters,
                  roomMaterials.allSatisfy({ $0.0.components[ImageBasedLightReceiverComponent.self]?.imageBasedLight === roomAmbientLight.entity }),
                  rigs.values.allSatisfy({ !$0.entity.components.has(ImageBasedLightReceiverComponent.self) }) else {
                throw EnvironmentError.invalid("Ambient light changed fixture emitters or escaped room geometry")
            }
            model.houseLight = 0.15
            FileHandle.standardOutput.write(Data("ROOM_LIGHT_SMOKE_PASS fixtureProgrammingUnchanged=true fixtureEmittersUnchanged=true roomOnly=true\n".utf8))
        } catch { FileHandle.standardOutput.write(Data("ROOM_LIGHT_SMOKE_FAIL \(error)\n".utf8)) }
    }

    /// Keep the visible placement box and click target deliberately separated.
    func runPlacementWristSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--placement-wrist-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            try await Task.sleep(for: .milliseconds(500))
            model.clearScene(); model.closePalmMap(); model.fixtureKind = .movingHead
            model.beginPlacement()
            guard let physics = root.scene else { throw EnvironmentError.invalid("Missing physics scene") }
            let previewPoint = SIMD3<Float>(2.66,0,-2.3)
            let clickPoint = SIMD3<Float>(4,0,-2.3)
            let eye = root.convert(position: previewPoint+[0,1,0.5], to: nil)
            let target = root.convert(position: previewPoint, to: nil)
            let originalDevice = deviceTransform
            defer { deviceTransform = originalDevice }
            deviceTransform = Transform(rotation: simd_quatf(from: [0,0,-1], to: simd_normalize(target-eye)), translation: eye).matrix
            updatePlacementGhost()
            guard placementGhost.isEnabled else { throw EnvironmentError.invalid("Preview outline was not rendered") }
            let shownBase = placementGhost.position
            guard let click = physics.raycast(origin: clickPoint+[0,0.3,0],direction: [0,-1,0],length: 0.6,
                query: .all,mask: .all,relativeTo: root).first(where: { $0.entity.name == "room-collider:floor" }) else {
                throw EnvironmentError.invalid("Missing floor click target")
            }
            handleTap(entity: click.entity,position: click.position,model: model)
            guard let fixture = model.fixtures.last, simd_distance(FixtureAiming.vector(fixture.position),shownBase) < 0.001 else {
                throw EnvironmentError.invalid("Placed fixture at \(String(describing: model.fixtures.last?.position)); visible box was at \(shownBase)")
            }
            model.undo()
            guard model.fixtures.isEmpty else { throw EnvironmentError.invalid("Placement Undo failed") }
            model.redo()
            guard model.fixtures == [fixture] else { throw EnvironmentError.invalid("Placement Redo failed") }
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 1 else { throw EnvironmentError.invalid("Consumed preview placed twice") }
            model.isPlacing = true
            updatePlacementGhost()
            model.finishPlacement(); model.beginPlacement()
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 1 else { throw EnvironmentError.invalid("Cancelled placement reused stale preview") }
            updatePlacementGhost()
            model.fixtureKind = .cube
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 1 else { throw EnvironmentError.invalid("Changed fixture reused stale preview") }
            updatePlacementGhost()
            let cubeBase = placementGhost.position
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 2, let cube = model.fixtures.last,
                  simd_distance(FixtureAiming.vector(cube.position),cubeBase+[0,model.fixtureKind.radius,0]) < 0.001 else {
                throw EnvironmentError.invalid("Cube outline and placement bounds disagree")
            }
            updatePlacementGhost()
            model.canPlace = false
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 2 else { throw EnvironmentError.invalid("Tracking loss accepted placement") }
            model.canPlace = true
            handleTap(entity: click.entity,position: click.position,model: model)
            guard model.fixtures.count == 2 else { throw EnvironmentError.invalid("Tracking recovery reused stale preview") }
            deviceTransform = Transform(rotation: simd_quatf(from: [0,0,-1],to: [0,1,0]),translation: eye).matrix
            updatePlacementGhost()
            handleTap(entity: click.entity,position: click.position,model: model)
            guard !placementGhost.isEnabled, model.fixtures.count == 2 else {
                throw EnvironmentError.invalid("Hidden preview fell back to gaze placement")
            }
            model.finishPlacement(); model.resetToolboxActivation()
            let attended = WristAttention.isAttended(wrist: [0,0,-0.45],eye: .zero,forward: [0,0,-1])
            model.updateHandToolboxActivation(attended: attended,now: 0)
            model.updateHandToolboxActivation(attended: attended,now: 0.4)
            let firstRequest = model.toolboxRequestID
            model.updateHandToolboxActivation(attended: false,now: 1)
            model.updateHandToolboxActivation(attended: attended,now: 2)
            model.updateHandToolboxActivation(attended: attended,now: 2.4)
            guard firstRequest != nil, model.toolboxRequestID != firstRequest, !model.palmMapVisible else {
                throw EnvironmentError.invalid("Wrist attention did not recall Toolbox again")
            }
            print("PLACEMENT_WRIST_SMOKE_PASS boxPosition=true gazeIndependent=true undoRedo=true stalePreviewRejected=true cubeBounds=true trackingGuard=true noGazeFallback=true wristRecall=true")
        } catch { print("PLACEMENT_WRIST_SMOKE_FAIL \(error)") }
    }

    /// Native renderer routing check, separate from human pinch acceptance.
    func runInputSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--input-smoke") else { return }
        while !model.canPlace {
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
        }
        do {
            try await Task.sleep(for: .seconds(2))
            guard let fixture = model.fixtures.first, let fixtureRoot = root.findEntity(named: fixture.id.uuidString),
                  let target = fixtureRoot.components.has(CollisionComponent.self) ? fixtureRoot : fixtureRoot.children.first(where: { $0.components.has(InputTargetComponent.self) }),
                  let scene = root.scene, let surface = roomMaterials.first?.0 else {
                throw EnvironmentError.invalid("missing rendered input targets")
            }
            let center = target.position(relativeTo: root)
            let origin = center + [0,0,0.8]
            let hits = scene.raycast(origin: origin, direction: [0,0,-1], length: 1,
                                     query: .all, mask: .all, relativeTo: root)
            let nearestInput = hits.sorted { $0.distance < $1.distance }.first {
                $0.entity.components[InputTargetComponent.self]?.allowedInputTypes.contains(.indirect) == true
            }
            guard nearestInput?.entity == target,
                  !target.components.has(SpatialDragTarget.self),
                  !handleDrag(entity: target, position: center, start: center, model: model),
                  drops.values.allSatisfy({ !$0.isEnabled }) else {
                throw EnvironmentError.invalid("fixture collision or tap/drag isolation failed")
            }
            model.deselect()
            model.beginPlacement(); model.togglePalmMap()
            guard model.palmMapVisible else { throw EnvironmentError.invalid("Toolbar map failed to open") }
            let count = model.fixtures.count
            handleTap(entity: target, position: center, model: model)
            handleTap(entity: surface, position: center, model: model)
            guard model.isPlacing, model.selectedID == nil, model.fixtures.count == count,
                  !handleDrag(entity: surface,position: center,start: center,model: model) else {
                throw EnvironmentError.invalid("Open map allowed editing behind navigation")
            }
            model.closePalmMap()
            guard model.isPlacing else { throw EnvironmentError.invalid("Map close lost prior editing context") }
            model.finishPlacement()
            handleTap(entity: target, position: center, model: model)
            guard model.selectedID == fixture.id else { throw EnvironmentError.invalid("fixture tap did not select") }
            handleTap(entity: surface, position: center, model: model)
            guard model.selectedID == nil else { throw EnvironmentError.invalid("room tap did not deselect") }
            model.beginRetarget(fixture.id)
            try await Task.sleep(for: .milliseconds(250))
            guard surface.components.has(SpatialDragTarget.self) else { throw EnvironmentError.invalid("aim surface did not enable held targeting") }
            model.cancelPicking()
            try await Task.sleep(for: .milliseconds(250))
            guard !surface.components.has(SpatialDragTarget.self) else { throw EnvironmentError.invalid("aim drag target survived cancellation") }
            print("SPATIAL_INPUT_SMOKE_PASS")
        } catch { print("SPATIAL_INPUT_SMOKE_FAIL: \(error)") }
    }
    #endif

    #if DEBUG
    /// Synthetic world-space pointer samples exercise the real render/commit path.
    /// They do not establish physical pinch acceptance.
    func runPresetDragSmoke(model: VenueModel, closeToolbox: () -> Void) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--preset-drag-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.requestToolbox()
            guard let fixture = model.fixtures.first,
                  let preset = model.presets.first(where: { $0.id != fixture.presetID }),
                  let entity = rigs[fixture.id]?.entity ?? cubes[fixture.id] else {
                throw EnvironmentError.invalid("Missing smoke fixture or alternate preset")
            }
            model.endPresetDrag(); updatePresetDrag(model: model, reduceMotion: false)
            guard !presetDragVisual.hasTether else { throw EnvironmentError.invalid("Idle tether is visible") }
            model.activatePresetApplication(preset.id)
            guard let id = model.presetDrag.session?.id else { throw EnvironmentError.invalid("Activation failed") }
            let target = entity.visualBounds(relativeTo: nil, excludeInactive: true).center
            let eye = SIMD3<Float>(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
            let right = SIMD3<Float>(deviceTransform.columns.0.x,deviceTransform.columns.0.y,deviceTransform.columns.0.z)
            let up = SIMD3<Float>(deviceTransform.columns.1.x,deviceTransform.columns.1.y,deviceTransform.columns.1.z)
            let forward = -SIMD3<Float>(deviceTransform.columns.2.x,deviceTransform.columns.2.y,deviceTransform.columns.2.z)
            let hand = eye+right*0.42-up*0.28+forward*0.5
            let initial = PresetDragState.Sample(cursor: target+right+up*0.6, hand: hand)
            model.presetDrag.update(id, sample: initial, armed: true)
            try await Task.sleep(for: .seconds(1))
            guard model.presetDrag.proposedFixtureID == nil,
                  presetDragVisual.visibleOrigin == hand else { throw EnvironmentError.invalid("Dotted tether did not start at the user") }
            print("PRESET_DRAG_SMOKE_DOTTED viewerOrigin=true rowIndependent=true")
            try await Task.sleep(for: .seconds(6))
            closeToolbox()
            try await Task.sleep(for: .milliseconds(500))
            guard model.presetDrag.session?.id == id, !model.toolboxVisible else { throw EnvironmentError.invalid("Toolbox dismissal ended Apply or did not close") }
            model.presetDrag.release(id)
            try await Task.sleep(for: .milliseconds(200))
            guard model.presetDrag.session?.id == id else { throw EnvironmentError.invalid("Missed release ended Apply") }
            let snapped = PresetDragState.Sample(cursor: target, hand: hand)
            model.presetDrag.update(id, sample: snapped, armed: true)
            try await Task.sleep(for: .seconds(1))
            guard model.presetDrag.proposedFixtureID == fixture.id, presetDragVisual.isSnapped else { throw EnvironmentError.invalid("Fixture did not snap") }
            print("PRESET_DRAG_SMOKE_SOLID curved=true targetRing=true")
            try await Task.sleep(for: .seconds(6))
            let oldCount = model.history?.entries.count ?? 0
            model.presetDrag.release(id)
            try await Task.sleep(for: .milliseconds(200))
            guard model.fixture(fixture.id)?.presetID == preset.id,
                  model.history?.entries.count == oldCount+1,
                  model.presetDrag.feedback?.succeeded == true,
                  !presetDragVisual.hasTether,
                  model.fixture(fixture.id).map({ model.renderedChannels(for: $0) == preset.channels }) == true else {
                throw EnvironmentError.invalid("Apply did not commit once and clear the tether")
            }
            model.presetDrag.release(id)
            try await Task.sleep(for: .milliseconds(100))
            guard model.history?.entries.count == oldCount+1 else { throw EnvironmentError.invalid("Duplicate release was applied") }
            model.undo()
            guard model.fixture(fixture.id)?.presetID == fixture.presetID else { throw EnvironmentError.invalid("Apply undo failed") }
            model.redo()
            guard model.fixture(fixture.id)?.presetID == preset.id else { throw EnvironmentError.invalid("Apply redo failed") }
            model.activatePresetApplication(preset.id); model.endPresetDrag()
            updatePresetDrag(model: model, reduceMotion: true)
            guard !presetDragVisual.hasTether, model.presetDrag.session == nil else { throw EnvironmentError.invalid("Cancel left a tether") }
            print("PRESET_DRAG_SMOKE_PASS viewerOrigin=true noRowGeometry=true toolboxClose=true missedReleaseStaysActive=true applyOnce=true cancel=true undo=true redo=true syntheticPointer=true")
        } catch {
            model.endPresetDrag()
            print("PRESET_DRAG_SMOKE_FAIL: \(error)")
        }
    }
    #endif

    #if DEBUG
    /// Checks the material bindings produced by RealityKit, not just USDZ bytes.
    private func validateRoomImport(_ imported: [(Entity, ModelComponent)], manifest: EnvironmentManifest) throws {
        guard ProcessInfo.processInfo.arguments.contains("--room-import-smoke"),
              ["img3153-classroom-v1", "mappedRoom", "the-fortress"].contains(manifest.id) else { return }
        do {
            var textures: [MaterialParameters.Texture] = []
            var bindings: [[String: Any]] = []
            for (entity, component) in imported {
                for material in component.materials {
                    guard let pbr = material as? PhysicallyBasedMaterial else {
                        throw EnvironmentError.invalid("Room material did not import as PBR: \(entity.name)")
                    }
                    guard case .opaque = pbr.blending else {
                        throw EnvironmentError.invalid("Room material is not opaque: \(entity.name)")
                    }
                    if let texture = pbr.baseColor.texture {
                        if !textures.contains(texture) { textures.append(texture) }
                        let index = textures.firstIndex(of: texture)!
                        bindings.append(["entity": entity.name, "textureIndex": index])
                    }
                }
            }
            let sizes = textures.map { ["width": $0.resource.width, "height": $0.resource.height,
                                        "mipLevels": $0.resource.mipmapLevelCount] }
            let expectedMeshes = manifest.id == "the-fortress" ? 135 : 68
            guard imported.count == expectedMeshes else { throw EnvironmentError.invalid("Expected \(expectedMeshes) imported room meshes, got \(imported.count)") }
            if manifest.id == "mappedRoom" {
                guard textures.count == 6,
                      sizes.filter({ $0["width"] == 512 && $0["height"] == 512 }).count == 2,
                      sizes.filter({ $0["width"] == 256 && $0["height"] == 256 }).count == 4 else {
                    throw EnvironmentError.invalid("Expected six native base-color textures: two 512² and four 256²; imported \(sizes)")
                }
            } else if !textures.isEmpty { throw EnvironmentError.invalid("Baseline unexpectedly has base-color textures") }
            let report: [String: Any] = ["roomID": manifest.id, "assetSHA256": manifest.asset.sha256,
                "modelCount": imported.count, "textureCount": textures.count,
                "textures": sizes, "bindings": bindings, "opaquePBR": true]
            let json = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
            print("ROOM_IMPORT_SMOKE_PASS " + String(decoding: json, as: UTF8.self))
        } catch {
            print("ROOM_IMPORT_SMOKE_FAIL \(manifest.id): \(error)")
            throw error
        }
    }
    #endif

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
            drops.removeValue(forKey: id)?.removeFromParent()
        }
        for id in Array(cubes.keys) where !ids.contains(id) {
            cubes.removeValue(forKey: id)?.removeFromParent()
            labels.removeValue(forKey: id)?.removeFromParent()
            drops.removeValue(forKey: id)?.removeFromParent()
        }
        // Bound expensive shadow lights; selected fixtures receive preview priority.
        // Geometry and articulation continue for every placed asset.
        let budgets = LightingBudget.allocate(model.sceneFixtures.map { fixture in
            let look = LightingPreview(channels: model.renderedChannels(for: fixture), blackout: model.isBlackedOut(fixture))
            return .init(id: fixture.id, emitters: fixtureTemplates[fixture.assetID ?? ""] == nil ? 0 : fixture.asset?.emitters.count ?? 0,
                         emitting: look.intensity > 0 && look.rgb.contains { $0 > 0 })
        }, selected: model.selectedID, limit: model.effectiveLightLimit)
        benchmarkBudgets = budgets
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
                                         interactive: model.isTransformDragging, bodyDraggable: model.gizmoVisible && model.transformMode == .move && model.selectedID == fixture.id && !model.isRetargeting && !model.isPlacing, lightBudget: budgets[fixture.id] ?? 0)
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
                if model.gizmoVisible && model.transformMode == .move && model.selectedID == fixture.id && !model.isRetargeting && !model.isPlacing { cube.components.set(SpatialDragTarget()) }
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
            if let drop = attachments.entity(for: "drop-\(fixture.id)") {
                if drop.parent == nil { root.addChild(drop) }
                drop.position = FixtureAiming.vector(fixture.visualCenter) + [0,0,0.20]
                drop.components.set(BillboardComponent())
                drop.isEnabled = model.draggingPresetID != nil && !model.presetDrag.isActive && !model.isPickingRoom && !model.palmMapVisible
                drops[fixture.id] = drop
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

    /// Input is already in world meters. No preset row geometry enters this path.
    func updatePresetDrag(model: VenueModel, reduceMotion: Bool) {
        presetReduceMotion = reduceMotion
        reduceNavigationMotion = reduceMotion
        if presetDragVisual.root.parent == nil { overlayRoot.addChild(presetDragVisual.root) }
        func bounds(_ id: UUID) -> BoundingBox? {
            (rigs[id]?.entity ?? cubes[id]).map { $0.visualBounds(relativeTo: nil, excludeInactive: true) }
        }
        if let feedback = model.presetDrag.feedback, let box = bounds(feedback.fixtureID) {
            presetDragVisual.feedback(id: feedback.id, bounds: box, succeeded: feedback.succeeded, reduceMotion: reduceMotion)
        }
        guard let session = model.presetDrag.session else {
            presetDragVisual.tether(origin: nil, reduceMotion: reduceMotion)
            return
        }
        guard aligned, model.canPlace, !model.libraryBusy, !model.isPickingRoom, !model.palmMapVisible, !model.isTransformDragging,
              model.presets.contains(where: { $0.id == session.presetID }) else {
            model.endPresetDrag(); presetDragVisual.clear(); return
        }
        let eye = SIMD3<Float>(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let forward = -SIMD3<Float>(deviceTransform.columns.2.x,deviceTransform.columns.2.y,deviceTransform.columns.2.z)
        let up = SIMD3<Float>(deviceTransform.columns.1.x,deviceTransform.columns.1.y,deviceTransform.columns.1.z)
        let right = SIMD3<Float>(deviceTransform.columns.0.x,deviceTransform.columns.0.y,deviceTransform.columns.0.z)
        let sample = session.sample
        let cursor = sample?.cursor ?? eye+forward*3
        let hand = sample?.hand ?? rightPinchPosition()
        let rayOrigin = sample?.rayOrigin ?? eye, rayPoint = sample?.rayPoint ?? cursor
        // A tracked hand is preferred. Simulator/permission fallback begins below
        // and to the right of the viewer, never at a preset row or window.
        let origin = hand ?? eye-up*0.22+right*0.18+forward*0.25
        var targets = model.fixtures.compactMap { fixture -> PresetDropSnap.Target? in
            guard let box = bounds(fixture.id) else { return nil }
            return .init(id: fixture.id, minimum: box.min, maximum: box.max)
        }
        var proposed: UUID?
        var contactPoint: SIMD3<Float>?
        if session.armed {
            // Only raycast candidates that can actually snap, rather than one
            // expensive scene query per fixture for every pointer update.
            while let candidate = PresetDropSnap.match(cursor: cursor, rayOrigin: rayOrigin, rayPoint: rayPoint,
                                                       targets: targets, previous: model.presetDrag.proposedFixtureID),
                  let target = targets.first(where: { $0.id == candidate.id }) {
                let visibilityOrigin = rayOrigin
                let delta = candidate.point-visibilityOrigin, length = simd_length(delta)
                var blocked = false
                if length > 0.001, let scene = root.scene {
                    let entry = PresetDropSnap.entryDistance(from: visibilityOrigin, through: candidate.point, target: target) ?? length
                    let firstWall = scene.raycast(origin: visibilityOrigin, direction: delta/length, length: entry, query: .all,
                                                 mask: .all, relativeTo: nil).filter {
                        $0.entity.name.hasPrefix("aim-surface:") || $0.entity.name.hasPrefix("room-collider:")
                    }.map(\.distance).min()
                    blocked = firstWall.map { $0 < entry-0.015 } ?? false
                }
                if !blocked {
                    proposed = candidate.id
                    let cable = candidate.point-origin
                    if simd_length(cable) > 0.001,
                       let entry = PresetDropSnap.entryDistance(from: origin, through: candidate.point, target: target) {
                        // Keep the endpoint ring just outside the nearest bounds
                        // surface instead of burying it inside the fixture body.
                        contactPoint = origin+simd_normalize(cable)*max(0,entry-0.012)
                    } else { contactPoint = candidate.point }
                    break
                }
                targets.removeAll { $0.id == candidate.id }
            }
        }
        model.presetDrag.propose(proposed)
        presetDragVisual.tether(origin: origin, end: contactPoint ?? cursor, targetID: proposed,
                                 target: proposed.flatMap(bounds), reduceMotion: reduceMotion)
        if let release = model.presetDrag.takeRelease(), let fixtureID = release.fixtureID {
            model.finishPresetApplication(presetID: release.presetID, fixtureID: fixtureID)
            presetDragVisual.tether(origin: nil, reduceMotion: reduceMotion)
        }
    }

    private func rightPinchPosition() -> SIMD3<Float>? {
        guard CACurrentMediaTime()-lastRightHandUpdate < 0.25,
              let hand = latestRightHand, hand.isTracked, let skeleton = hand.handSkeleton else { return nil }
        let joints = [HandSkeleton.JointName.thumbTip,.indexFingerTip].map { skeleton.joint($0) }
        guard joints.allSatisfy(\.isTracked) else { return nil }
        let points = joints.map { joint -> SIMD3<Float> in
            let t = hand.originFromAnchorTransform*joint.anchorFromJointTransform
            return [t.columns.3.x,t.columns.3.y,t.columns.3.z]
        }
        return (points[0]+points[1])/2
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
                    } else {
                        self.latestRightHand = update.event == .removed ? nil : update.anchor
                        self.lastRightHandUpdate = CACurrentMediaTime()
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

    var isNavigationDragging: Bool { palmMap.dragging }

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
        presetDragVisual.clear()
        fixtureLoadGeneration = UUID()
        fixtureLoads.values.forEach { $0.cancel() }; fixtureLoads.removeAll()
        for entity in labels.values { entity.removeFromParent() }
        for entity in drops.values { entity.removeFromParent() }
        labels.removeAll()
        drops.removeAll()
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
