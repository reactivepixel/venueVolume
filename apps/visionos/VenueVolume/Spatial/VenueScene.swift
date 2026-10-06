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
    private var fixtureTemplates: [String: Entity] = [:]
    private var fixtureLoads: [String: Task<Void, Never>] = [:]
    private var fixtureFailures: Set<String> = []
    private var fixtureLoadGeneration = UUID()
    private var rigs: [UUID: FixtureRig] = [:]
    private let transformGizmo = FixtureTransformGizmo()
    private let presetDragVisual = PresetDragVisual()
    #if DEBUG
    private var presetInputFromScene: AffineTransform3D?
    #endif
    let headAnchor = AnchorEntity(.head, trackingMode: .continuous)
    private let repository: (any EnvironmentRepository)?
    private let environmentID: String
    private var manifest: EnvironmentManifest?
    private var aligned = false
    private var cubes: [UUID: ModelEntity] = [:]
    private var labels: [UUID: Entity] = [:]
    private var drops: [UUID: Entity] = [:]
    private var palmGate = PalmRevealGate()
    private var mapToggle = PalmMapToggle()
    private let palmMap = PalmNavigationVisual()
    private let placementGhost = Entity()
    private let groupLinks = Entity()
    private var latestRightHand: HandAnchor?
    private var lastRightHandUpdate: Double = 0
    private var hasHandAccess = false
    private var lastRightPinchAt = Double.leastNormalMagnitude
    private var navigationGestureCancelled = false
    private var mapAttended = false
    private var mapHeld = false
    private var palmPosition = SIMD3<Float>.zero
    private var blackoutCover: ModelEntity?
    private var navigationTransition: Task<Void, Never>?
    private var blackoutFadeStart: Double?
    private var blackoutFadeDuration: Double = 0.333
    private var groupAnimationTime: Double = 0
    private var connectorRevision = ""
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
            // Publish only after all assets and collision shapes are ready.
            // A failed import/open therefore leaves the previous room usable.
            try Task.checkCancellation()
            try model.prepareHistoryRestore()
            root.children.removeAll(); cubes.removeAll(); rigs.removeAll(); labels.removeAll(); drops.removeAll()
            aligned = false; root.transform = Transform(); root.isEnabled = false
            root.addChild(room); proxies.forEach { root.addChild($0) }
            roomMaterials = newMaterials; displayedWhiteRoom = nil
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
            self.rigs.values.forEach { $0.tick(deltaTime: event.deltaTime) }
            self.presetDragVisual.tick()
            self.tickPhasers()
            self.tickNavigation()
            self.updatePlacementGhost()
            self.groupAnimationTime += event.deltaTime
            self.groupLinks.children.enumerated().forEach { index, child in
                child.components.set(OpacityComponent(opacity: 0.35 + 0.65 * Float((sin(self.groupAnimationTime * 4 - Double(index)*0.3)+1)/2)))
            }
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
        for fixture in model.fixtures {
            let palette = model.previewDraft && model.selectedFixtureIDs.contains(fixture.id)
                ? model.presetDraft : model.presets.first(where: { $0.id == fixture.presetID })
            guard palette?.phaser != nil, let rig = rigs[fixture.id] else { continue }
            rig.update(fixture: model.renderedFixture(fixture),channels: model.renderedChannels(for: fixture),
                       selected: model.selectedFixtureIDs.contains(fixture.id),blackout: model.isBlackedOut(fixture),
                       placing: model.isPickingRoom,interactive: model.isTransformDragging,
                       lightBudget: benchmarkBudgets[fixture.id] ?? 0)
        }
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
        let point = Position3D(x: position.x, y: position.y, z: position.z)
        if entity.name.hasPrefix("palm-map-") {
            if !hasHandAccess || CACurrentMediaTime()-lastRightPinchAt < 0.2 { _ = palmMap.tap(entity) }
            return
        }
        if !model.isPickingRoom {
            if FixtureTransformGizmo.handle(entity) != nil { return }
            if let id = UUID(uuidString: entity.name) { model.select(id) }
            else if entity.name.hasPrefix("aim-surface:") || entity.name.hasPrefix("room-collider:") {
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
        guard !model.navigationBlackoutActive else { return false }
        if !navigationGestureCancelled, let environment = manifest,
           (!hasHandAccess || palmMap.dragging || rightHandPinching()),
           palmMap.drag(entity, worldPoint: root.convert(position: position, to: nil),
                        worldStart: root.convert(position: start, to: nil), environment: environment) { return true }
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

    #if DEBUG
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
    /// Feeds synthetic pointer samples through the real snap/render/commit path.
    /// The source is a measured preset row, never a fabricated window position.
    /// This intentionally does not claim physical pinch acceptance.
    func runPresetDragSmoke(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--preset-drag-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.toolboxLibraryTab = 1
            model.requestToolbox()
            guard let fixture = model.fixtures.first,
                  let preset = model.presets.first(where: { $0.id != fixture.presetID }) else {
                throw EnvironmentError.invalid("Missing smoke fixture or alternate preset")
            }
            for _ in 0..<100 where model.presetDrag.sources[preset.id] == nil ||
                model.toolboxPresentedID != model.toolboxRequestID || !model.toolboxVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            // Window geometry is available before its presentation fade ends.
            // Wait for the recalled window, then sample the current row origin.
            try await Task.sleep(for: .seconds(3))
            guard let source = model.presetDrag.sources[preset.id], let transform = presetInputFromScene,
                  let inverse = transform.inverse, model.toolboxVisible,
                  model.toolboxPresentedID == model.toolboxRequestID,
                  let entity = rigs[fixture.id]?.entity ?? cubes[fixture.id] else {
                throw EnvironmentError.invalid("Wrist preset source geometry unavailable")
            }
            func input(_ point: SIMD3<Float>) -> SIMD3<Float> {
                let result = Point3D(x: Double(point.x), y: Double(point.y), z: Double(point.z)).applying(transform)
                return [Float(result.x), Float(result.y), Float(result.z)]
            }
            let target = entity.visualBounds(relativeTo: nil, excludeInactive: true).center
            let row = Point3D(x: Double(source.x), y: Double(source.y), z: Double(source.z)).applying(inverse)
            let rowWorld = SIMD3<Float>(Float(row.x), Float(row.y), Float(row.z))
            let right = SIMD3<Float>(deviceTransform.columns.0.x, deviceTransform.columns.0.y, deviceTransform.columns.0.z)
            let up = SIMD3<Float>(deviceTransform.columns.1.x, deviceTransform.columns.1.y, deviceTransform.columns.1.z)
            let towardViewer = SIMD3<Float>(deviceTransform.columns.2.x, deviceTransform.columns.2.y, deviceTransform.columns.2.z)
            // Explicitly synthetic hand data lets the two-segment tether leave
            // the window's silhouette. A straight source-to-fixture segment is
            // normally hidden by the system window, even at correct coordinates.
            let hand = input(rowWorld + right*0.85 + up*0.45 + towardViewer*0.10)
            let initial = PresetDragState.Sample(source: source, cursor: input(target + right + up*0.6), hand: hand)
            guard let id = model.presetDrag.begin(presetID: preset.id, sample: initial) else { throw CancellationError() }
            model.beginPresetDrag(preset.id)
            model.presetDrag.update(id, sample: initial, armed: true)
            try await Task.sleep(for: .seconds(1))
            guard model.presetDrag.proposedFixtureID == nil else { throw EnvironmentError.invalid("Unsnapped presentation unexpectedly selected a fixture") }
            print("PRESET_DRAG_SMOKE_DOTTED settled=true syntheticHand=true")
            try await Task.sleep(for: .seconds(6))
            let snapped = PresetDragState.Sample(source: source, cursor: input(target), hand: hand)
            model.presetDrag.update(id, sample: snapped, armed: true)
            try await Task.sleep(for: .seconds(1))
            guard model.presetDrag.proposedFixtureID == fixture.id else { throw EnvironmentError.invalid("Fixture did not snap") }
            print("PRESET_DRAG_SMOKE_SOLID settled=true syntheticHand=true")
            try await Task.sleep(for: .seconds(6))
            let oldCount = model.history?.entries.count ?? 0
            model.presetDrag.release(id)
            try await Task.sleep(for: .milliseconds(200))
            guard model.fixture(fixture.id)?.presetID == preset.id,
                  model.history?.entries.count == oldCount+1,
                  model.presetDrag.feedback?.succeeded == true,
                  model.fixture(fixture.id).map({ model.renderedChannels(for: $0) == preset.channels }) == true else {
                throw EnvironmentError.invalid("Drop did not apply once with success feedback")
            }
            model.presetDrag.release(id)
            try await Task.sleep(for: .milliseconds(100))
            guard model.history?.entries.count == oldCount+1 else { throw EnvironmentError.invalid("Duplicate release was applied") }
            model.undo()
            guard model.fixture(fixture.id)?.presetID == fixture.presetID else { throw EnvironmentError.invalid("Drop undo failed") }
            model.redo()
            guard model.fixture(fixture.id)?.presetID == preset.id else { throw EnvironmentError.invalid("Drop redo failed") }
            print("PRESET_DRAG_SMOKE_PASS realRowSource=true snap=true applyOnce=true undo=true redo=true syntheticPointer=true")
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
        root.isEnabled = true
        aligned = true
    }

    func update(model: VenueModel, attachments: RealityViewAttachments) {
        if let bar = attachments.entity(for: "venue-context-bar") {
            if bar.parent == nil { headAnchor.addChild(bar) }
            bar.name = "VenueContextBar"; bar.position = [0,-0.36,-0.8]
        }
        if palmMap.entity.parent == nil { overlayRoot.addChild(palmMap.entity) }
        if placementGhost.parent == nil { root.addChild(placementGhost) }
        if groupLinks.parent == nil { root.addChild(groupLinks) }
        updateGroupLinks(model: model)
        _ = model.fixtureRenderRevision // Rebuild placeholders when an asynchronous catalog asset becomes ready.
        if targetMarker.parent == nil { root.addChild(targetMarker) }
        targetMarker.components.set(DynamicLightShadowComponent(castsShadow: false))
        let marker = model.pendingTarget ?? model.lastTarget
        targetMarker.isEnabled = marker != nil
        if let target = marker { targetMarker.position = FixtureAiming.vector(target) }
        for (entity, _) in roomMaterials {
            entity.components.set(InputTargetComponent(allowedInputTypes: !model.isPickingRoom || model.isRetargeting || (model.scannedMesh != nil && model.isPickingRoom) ? [.indirect] : []))
            if model.isRetargeting { entity.components.set(SpatialDragTarget()) }
            else { entity.components.remove(SpatialDragTarget.self) }
        }
        for child in root.children where child.name.hasPrefix("room-collider:") {
            child.components.set(InputTargetComponent(allowedInputTypes: model.isPickingRoom && !model.isRetargeting && model.scannedMesh == nil ? [.indirect] : []))
        }
        if transformGizmo.entity.parent == nil { root.addChild(transformGizmo.entity) }
        transformGizmo.update(fixture: model.selectedID.flatMap { model.fixture($0) },
                              visible: model.gizmoVisible && !model.isPickingRoom, mode: model.transformMode, selectedAxis: model.activeTransformAxis)
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
        let budgets = LightingBudget.allocate(model.fixtures.map { fixture in
            let look = LightingPreview(channels: model.renderedChannels(for: fixture), blackout: model.isBlackedOut(fixture))
            return .init(id: fixture.id, emitters: fixtureTemplates[fixture.assetID ?? ""] == nil ? 0 : fixture.asset?.emitters.count ?? 0,
                         emitting: look.intensity > 0 && look.rgb.contains { $0 > 0 })
        }, selected: model.selectedID, limit: model.effectiveLightLimit)
        benchmarkBudgets = budgets
        for fixture in model.fixtures {
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
                cube.components.set(InputTargetComponent(allowedInputTypes: model.isPickingRoom ? [] : [.indirect]))
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
                drop.position = position + [0, fixture.assetID == nil ? 0 : fixture.visualHeight/2, 0.20]
                drop.components.set(BillboardComponent())
                drop.isEnabled = model.draggingPresetID != nil && !model.presetDrag.isActive && !model.isPickingRoom
                drops[fixture.id] = drop
            }
        }
    }

    /// Selected labels retain a readable angular size; nearby names yield when
    /// their projected rectangles overlap. Every object remains in the wrist list.
    private func layoutFixtureLabels() {
        guard let model else { return }
        let eye = SIMD3(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
        let view = simd_inverse(deviceTransform)
        var candidates: [SpatialLabelLayout.Candidate] = []
        for fixture in model.fixtures {
            guard let label = labels[fixture.id] else { continue }
            let localSize = label.visualBounds(relativeTo: label, excludeInactive: false).extents
            let base = FixtureAiming.vector(fixture.position)
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

    /// SwiftUI window coordinates are converted by the system into this scene;
    /// neither the row origin nor the pinch origin is estimated from head pose.
    func updatePresetDrag(model: VenueModel, content: RealityViewContent, reduceMotion: Bool) {
        if presetDragVisual.root.parent == nil { overlayRoot.addChild(presetDragVisual.root) }
        #if DEBUG
        presetInputFromScene = content.transform(from: .scene, to: .immersiveSpace)
        #endif
        func bounds(_ id: UUID) -> BoundingBox? {
            (rigs[id]?.entity ?? cubes[id]).map { $0.visualBounds(relativeTo: nil, excludeInactive: true) }
        }
        if let feedback = model.presetDrag.feedback, let box = bounds(feedback.fixtureID) {
            presetDragVisual.feedback(id: feedback.id, bounds: box, succeeded: feedback.succeeded, reduceMotion: reduceMotion)
        }
        guard let session = model.presetDrag.session else {
            presetDragVisual.tether(points: [], snapped: false, target: nil)
            return
        }
        guard aligned, model.canPlace, !model.libraryBusy, !model.isPickingRoom, !model.isTransformDragging,
              model.presets.contains(where: { $0.id == session.presetID }) else {
            model.endPresetDrag(); presetDragVisual.clear(); return
        }
        func point(_ input: SIMD3<Float>) -> SIMD3<Float> {
            content.convert(Point3D(x: Double(input.x), y: Double(input.y), z: Double(input.z)), from: .immersiveSpace, to: .scene)
        }
        let sample = session.sample
        let source = point(sample.source), cursor = point(sample.cursor)
        let hand = sample.hand.map(point), rayOrigin = sample.rayOrigin.map(point), rayPoint = sample.rayPoint.map(point)
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
                let origin = rayOrigin ?? hand ?? cursor
                let delta = candidate.point-origin, length = simd_length(delta)
                var blocked = false
                if length > 0.001, let scene = root.scene {
                    let entry = PresetDropSnap.entryDistance(from: origin, through: candidate.point, target: target) ?? length
                    let firstWall = scene.raycast(origin: origin, direction: delta/length, length: entry, query: .all,
                                                 mask: .all, relativeTo: nil).filter {
                        $0.entity.name.hasPrefix("aim-surface:") || $0.entity.name.hasPrefix("room-collider:")
                    }.map(\.distance).min()
                    blocked = firstWall.map { $0 < entry-0.015 } ?? false
                }
                if !blocked { proposed = candidate.id; contactPoint = candidate.point; break }
                targets.removeAll { $0.id == candidate.id }
            }
        }
        model.presetDrag.propose(proposed)
        var points = [source]
        if let hand { points.append(hand) }
        points.append(contactPoint ?? cursor)
        presetDragVisual.tether(points: points, snapped: proposed != nil, target: proposed.flatMap(bounds))
        if let release = model.presetDrag.takeRelease() {
            if let fixtureID = release.fixtureID {
                let success = model.applyPreset(release.presetID, to: fixtureID)
                model.presetDrag.showFeedback(presetID: release.presetID, fixtureID: fixtureID, succeeded: success, message: success ? nil : model.message)
            } else {
                model.endPresetDrag()
                model.message = "Preset drop cancelled. Drag until the line becomes solid, or use the preset's Apply menu."
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
            model.resetToolboxActivation()
            palmGate = PalmRevealGate()
        }
        #if targetEnvironment(simulator)
        model.trackingStatus = "Simulator · room-relative placement"
        alignToSpawn()
        model.canPlace = manifest != nil
        // ARKit device tracking is unavailable in Simulator; use its floor origin and forward direction.
        while !Task.isCancelled {
            model.handTrackingStatus = "Simulator wrist menu"
            model.updateToolboxActivation(raised: model.simulatedPalm)
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
        defer { session.stop(); latestLeftHand = nil; latestRightHand = nil; hasHandAccess = false }
        var handAccess = false
        if HandTrackingProvider.isSupported {
            let status = await session.requestAuthorization(for: [.handTracking])
            handAccess = status[.handTracking] == .allowed
        }
        hasHandAccess = handAccess
        model.needsManualToolbox = !handAccess
        model.handTrackingStatus = handAccess ? "Turn your left hand toward you to open the wrist menu" : "Hand tracking unavailable · use Show toolbox"
        do {
            if handAccess { try await session.run([world, hands]) }
            else { try await session.run([world]) }
            // Cache the update stream instead of consuming latestAnchors every frame;
            // missing a provider tick must not restart the reveal debounce.
            let handTask: Task<Void, Never>? = handAccess ? Task { @MainActor in
                for await update in hands.anchorUpdates {
                    guard !Task.isCancelled else { return }
                    if update.anchor.chirality == .right {
                        self.latestRightHand = update.event == .removed ? nil : update.anchor
                        self.lastRightHandUpdate = CACurrentMediaTime()
                    }
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
                mapAttended = false; mapHeld = false
                if world.state == .running,
                   let device = world.queryDeviceAnchor(atTimestamp: now), device.isTracked {
                    deviceTransform = device.originFromAnchorTransform
                    alignToSpawn()
                    model.canPlace = manifest != nil
                    model.trackingStatus = "World tracking active"
                    if handAccess, hands.state == .running, now - lastHandUpdate < 0.25, let hand = latestLeftHand {
                        let attention = handAttention(hand)
                        eligible = attention.wrist
                        mapAttended = attention.palm
                        mapHeld = attention.facing
                        palmPosition = attention.center
                    }
                } else {
                    model.canPlace = false
                    model.trackingStatus = "Tracking paused · look around to recover"
                }
                if handAccess && hands.state == .stopped {
                    model.needsManualToolbox = true
                    model.handTrackingStatus = "Hand tracking stopped · use Show toolbox or re-enter to retry"
                }
                if rightHandPinching() { lastRightPinchAt = now }
                _ = mapToggle.update(attended: mapAttended, now: now)
                if !mapHeld {
                    if palmMap.dragging { navigationGestureCancelled = true }
                    palmMap.cancel()
                }
                let revealed = palmGate.update(eligible: eligible, now: now)
                model.updateToolboxActivation(raised: revealed)
                try await Task.sleep(for: .milliseconds(33))
            }
        } catch is CancellationError {
        } catch {
            model.trackingStatus = "Tracking unavailable: \(error.localizedDescription)"
            model.needsManualToolbox = true
            model.handTrackingStatus = "Use Show toolbox or re-enter the venue to retry tracking."
            // Keep the explicit fallback responsive even after authorization/session failure.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        #endif
    }

    /// Head-attention is an approximation, not raw eye gaze. System hover handles
    /// precise gaze targeting of the map marker, rotation rings and context bar.
    private func handAttention(_ hand: HandAnchor) -> (wrist: Bool, palm: Bool, facing: Bool, center: SIMD3<Float>) {
        guard hand.chirality == .left, hand.isTracked, let skeleton = hand.handSkeleton else { return (false,false,false,.zero) }
        let joints = [HandSkeleton.JointName.wrist, .indexFingerKnuckle, .littleFingerKnuckle].map { skeleton.joint($0) }
        guard joints.allSatisfy(\.isTracked) else { return (false,false,false,.zero) }
        let points = joints.map { joint -> SIMD3<Float> in
            let t = hand.originFromAnchorTransform * joint.anchorFromJointTransform
            return SIMD3(t.columns.3.x,t.columns.3.y,t.columns.3.z)
        }
        let center = (points[0]+points[1]+points[2])/3
        let normal = simd_cross(points[1]-points[0],points[2]-points[0])
        let eye = SIMD3(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let ray = center-eye, distance = simd_length(ray)
        guard distance > 0.12, distance < 1.2, simd_length(normal) > 0.0001 else { return (false,false,false,center) }
        let forward = -SIMD3(deviceTransform.columns.2.x,deviceTransform.columns.2.y,deviceTransform.columns.2.z)
        let attending = simd_dot(simd_normalize(ray),forward) > 0.88
        let facing = simd_dot(simd_normalize(normal),-simd_normalize(ray)) > 0.35
        // Wrist activation accepts either side: users shouldn't need to find a
        // narrow palm angle merely to recall their toolbox. Map requires palm up.
        let wristRay = points[0]-eye
        let wristAttended = simd_dot(simd_normalize(wristRay),forward) > 0.9
        return (wristAttended,attending && facing,facing,center)
    }

    private func rightHandPinching() -> Bool {
        guard CACurrentMediaTime()-lastRightHandUpdate < 0.25, let hand = latestRightHand, hand.isTracked, let skeleton = hand.handSkeleton else { return false }
        let index = skeleton.joint(.indexFingerTip), thumb = skeleton.joint(.thumbTip)
        guard index.isTracked, thumb.isTracked else { return false }
        let a = index.anchorFromJointTransform.columns.3, b = thumb.anchorFromJointTransform.columns.3
        return simd_length(SIMD3(a.x-b.x,a.y-b.y,a.z-b.z)) < 0.045
    }

    var isNavigationDragging: Bool { palmMap.dragging }

    func endSpatialDrag(model: VenueModel) {
        if let action = palmMap.finish() { transitionNavigation(action, milliseconds: model.navigationFadeMilliseconds) }
        navigationGestureCancelled = false
        model.endTransformDrag()
    }

    func cancelSpatialDrag(model: VenueModel) {
        palmMap.cancel(); navigationGestureCancelled = false; model.endTransformDrag()
    }

    private func tickNavigation() {
        guard let manifest else { return }
        let eye = SIMD3(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let localEye = root.convert(position: eye, from: nil)
        #if targetEnvironment(simulator)
        let visible = model?.simulatedPalm == true
        let position = eye + simd_quatf(deviceTransform).act([0,-0.25,-0.5])
        #else
        let visible = mapToggle.isVisible && mapHeld
        let position = palmPosition + [0,0.07,0]
        #endif
        palmMap.update(environment: manifest, viewpoint: localEye, worldPosition: position,
                       orientation: simd_quatf(deviceTransform), visible: visible)
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
        model?.navigationBlackoutActive = true
        blackoutFadeStart = nil
        blackoutCover?.components.set(OpacityComponent(opacity: 1)); blackoutCover?.isEnabled = true
        navigationTransition = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.navigationTransition = nil }
            // Present a black frame before changing the world under the viewer.
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            let eye = SIMD3(self.deviceTransform.columns.3.x,self.deviceTransform.columns.3.y,self.deviceTransform.columns.3.z)
            switch action {
            case .teleport(let destination):
                let rotation = self.root.orientation
                let localEye = self.root.convert(position: eye, from: nil)
                self.root.position += rotation.act(localEye - SIMD3(destination.x,localEye.y,destination.z))
            case .rotate(let axis,let angle):
                let pivot = self.root.convert(position: eye, from: nil)
                var vector = SIMD3<Float>.zero; vector[axis] = 1
                self.root.orientation = self.root.orientation * simd_quatf(angle: -angle,axis: vector)
                self.root.position = eye-self.root.orientation.act(pivot)
            }
            self.blackoutFadeDuration = max(0.001,min(max(milliseconds,0),2000)/1000)
            self.blackoutFadeStart = CACurrentMediaTime()
        }
    }

    private func updatePlacementGhost() {
        guard let model, model.isPlacing, model.canPlace, !palmMap.dragging else { placementGhost.isEnabled = false; return }
        let eye = SIMD3(deviceTransform.columns.3.x,deviceTransform.columns.3.y,deviceTransform.columns.3.z)
        let direction = -SIMD3(deviceTransform.columns.2.x,deviceTransform.columns.2.y,deviceTransform.columns.2.z)
        // No eye ray is exposed by visionOS. Head-forward surface preview is a
        // deliberately documented approximation; the pinch's system target is authoritative.
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
            let distance = simd_distance(start,end), count = min(240,max(2,Int(distance/0.045)))
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
        palmMap.cancel(); palmMap.entity.isEnabled = false
        mapToggle = PalmMapToggle(); latestRightHand = nil
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
