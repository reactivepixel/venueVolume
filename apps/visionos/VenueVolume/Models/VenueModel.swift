import Foundation
import Observation
import VenueVolumeCore

enum ScenePick: Equatable { case move(UUID), aim(UUID) }
private enum TargetPresetSource { case saved(UUID), draft(UUID) }
enum FixtureTransformMode: String, CaseIterable, Identifiable { case move = "Move", rotate = "Rotate"; var id: String { rawValue } }
private struct FixtureTransformDrag {
    var fixture: Fixture
    var axis: FixtureAxis
    var mode: FixtureTransformMode
    var start: SIMD3<Float>
    var lastAngle: Float?
    var totalAngle: Float = 0
    var members: [Fixture] = []
    var pivot: Position3D?
}
private struct FixtureSurfaceDrag {
    var fixture: Fixture
    var plane: FixtureMountPlane
    var start: SIMD3<Float>
}
struct RoomRequest { var room: LibraryRoom; var setup: VenueSetup?; var blank: Bool; var configurationID: UUID? = nil }

@MainActor @Observable
final class VenueModel {
    private(set) var history: AuditHistory<VenueAuditState>?
    var historyMessage: String?
    private var historyBlocked = false
    private var restoringHistory = false
    private var actionDepth = 0
    private var actionTitle = "Edit"
    private var pendingEdit: (title: String, state: VenueAuditState)?
    private var editTask: Task<Void, Never>?
    private var historyDestination: (id: UUID, kind: AuditHistory<VenueAuditState>.Entry.Kind?)?
    private var preparedHistory: AuditHistory<VenueAuditState>?
    var canUndo: Bool { if history == nil { return !libraryBusy && !touringBlocked && tourHistory?.undoTarget != nil }; return !libraryBusy && !historyBlocked && (pendingEdit != nil || history?.undoTarget != nil || (actionDepth > 0 && auditState != history?.current.state)) }
    var canRedo: Bool { if history == nil { return !libraryBusy && !touringBlocked && tourHistory?.redoTarget != nil }; return !libraryBusy && !historyBlocked && pendingEdit == nil && history?.redoTarget != nil }
    private var historyURL: URL { library.directory.appendingPathComponent("audit-history.json") }
    let library: RoomLibraryStore
    private(set) var rooms: [LibraryRoom] = []
    private(set) var savedSetups: [VenueSetup] = []
    var roomRequest: RoomRequest?
    var roomLoadToken = UUID()
    private(set) var venueIntentID = UUID()
    var libraryMessage: String?
    var libraryBusy = false
    var newVenuePresented = false
    let presetEditor = PresetEditorPresentation()
    let presetDrag = PresetDragState()
    var toolboxTab = 0
    var touring = TouringArchive()
    var touringBlocked = false
    var tourHistory: AuditHistory<TouringArchive>?
    var selectedUnitIDs: Set<UUID> = []
    var selectedGroupID: UUID?
    var multiSelection = false
    var repeatPlacement = false
    var placementUnitID: UUID?
    var placementQueue: [UUID] = []
    var tourEditShow = false
    var tourAssignmentToShow = false
    var tourPreview: [Fixture]?
    var tourPreviewSession: TourSession?
    var tourPreviewTitle = ""
    var focusPickID: UUID?
    var touringPanelPresented = false
    private var tourPreviewPublishes = false
    private var tourPreviewRevision = 0
    private var tourPreviewSource: TouringArchive?
    private var focusBaseSession: TourSession?
    private var focusDraftPresetID: UUID?
    var toolboxLibraryTab = 0
    var venueControlsVisible = false
    var setupName = "Untitled setup" { didSet { queueHistoryEdit("Rename setup") } }
    private(set) var activeSetupID: UUID?
    private var savedSetup: VenueSetup?
    var scannedMesh: ScannedMesh?
    var fixtureKind = FixtureKind.movingHead
    private(set) var recentFixtureKinds: [FixtureKind] = []
    var quickFixtureKinds: [FixtureKind] { [.movingHead] + recentFixtureKinds.filter { $0 != .movingHead }.prefix(5) }
    func rememberFixtureKind(_ proposed: FixtureKind) {
        let kind: FixtureKind = proposed.assetID == LightingPreview.assetID ? .movingHead : proposed
        recentFixtureKinds.removeAll { $0 == kind }
        recentFixtureKinds.insert(kind, at: 0)
        recentFixtureKinds = Array(recentFixtureKinds.prefix(6))
        if !isDemoMode { defaults.set(recentFixtureKinds.map(\.rawValue), forKey: "venue.fixture-recents.v1") }
    }
    func selectFixtureKind(_ kind: FixtureKind) { fixtureKind = kind; rememberFixtureKind(kind) }
    func showVenueControls() {
        let appearing = !venueControlsVisible
        venueControlsVisible = true
        if appearing && !toolboxVisible { requestToolbox() }
    }
    var draggingFixture: FixtureKind?
    var activeRoom: LibraryRoom? { rooms.first { $0.manifest.id == environment?.id && $0.manifest.version == environment?.version } }
    var hasUnsavedSetup: Bool {
        if let savedSetup, savedSetup.tour != touring.active { return true }
        guard let savedSetup else {
            if let tour, tour != TourSession(show: tour.show, configurationID: tour.configurationID) { return true }
            guard let activeRoom else { return !fixtures.isEmpty }
            return !fixtures.isEmpty || setupName != "Untitled setup" || houseLight != 0.15 || whiteRoom != (activeRoom.manifest.id != "mappedRoom" && activeRoom.manifest.id != "the-fortress")
        }
        let assignedPresets = touring.active == nil ? presets.filter { preset in fixtures.contains { $0.presetID == preset.id } } : presets
        return fixtures != savedSetup.placements.fixtures || assignedPresets != savedSetup.presets || setupName != savedSetup.name || whiteRoom != savedSetup.whiteRoom || houseLight != savedSetup.houseLight
    }
    private(set) var fixtures: [Fixture] = []
    var selectedID: UUID?
    var expandedID: UUID?
    private(set) var presets: [DMXPreset] = LightingPreview.presets
    private(set) var recent = RecentItems()
    var presetDraft = DMXPreset(name: "New preset") { didSet { queueHistoryEdit("Edit preset draft") } }
    var editingPresetID: UUID?
    var presetMessage: String?
    var toolboxVisible = false
    var toolboxPresentedID: UUID?
    private(set) var toolboxWindowIDs = Set<UUID>()
    private(set) var unvaluedToolboxVisible = false
    func toolboxAppeared(_ id: UUID?) {
        if let id { toolboxWindowIDs.insert(id) } else { unvaluedToolboxVisible = true }
        toolboxVisible = true; toolboxPresentedID = id
    }
    func toolboxDisappeared(_ id: UUID?) {
        if let id { toolboxWindowIDs.remove(id) } else { unvaluedToolboxVisible = false }
        toolboxVisible = !toolboxWindowIDs.isEmpty || unvaluedToolboxVisible
        if toolboxPresentedID == id { toolboxPresentedID = toolboxWindowIDs.first }
    }
    private(set) var toolboxRequestID: UUID?
    private var palmActivationHeld = false

    /// A raised palm requests a window once; lowering the hand never closes it.
    func updateToolboxActivation(raised: Bool) {
        if raised && !palmActivationHeld { requestToolbox() }
        palmActivationHeld = raised
    }

    func requestToolbox() { toolboxRequestID = UUID() }
    func resetToolboxActivation() {
        palmActivationHeld = false
        toolboxRequestID = nil
    }
    var simulatedPalm = true
    var needsManualToolbox = false
    var handTrackingStatus = "Left index: move · left middle: rotate · double pinch: reset"
    var viewerPose = ViewerNavigationPose()
    var navigationInputReserved = false
    @ObservationIgnored var leftUIReservedUntil: Double = 0
    func reserveLeftHandInput() {
        leftUIReservedUntil = ProcessInfo.processInfo.systemUptime+0.35; navigationInputReserved = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(360))
            if let self, !self.viewerNavigationActive, ProcessInfo.processInfo.systemUptime >= self.leftUIReservedUntil { self.navigationInputReserved = false }
        }
    }
    private(set) var viewerNavigationActive = false
    var viewerResetToken = UUID()
    func beginViewerNavigation(_ finger: NavigationFinger) {
        guard !viewerNavigationActive, !libraryBusy else { return }
        finishHistoryGesture(); endPresetDrag()
        beginHistoryAction(finger == .index ? "Move viewer" : "Rotate viewer")
        viewerNavigationActive = true
    }
    func updateViewerNavigation(_ pose: ViewerNavigationPose) { if pose != viewerPose && pose.isValid { viewerPose = pose } }
    func endViewerNavigation() {
        guard viewerNavigationActive else { return }
        viewerNavigationActive = false; endHistoryAction()
    }
    func stepViewer(offset: SIMD3<Float> = .zero, yaw: Float = 0,pitch: Float = 0,roll: Float = 0) {
        guard isImmersed, !libraryBusy else { return }
        endViewerNavigation(); beginHistoryAction("Navigate viewer"); defer { endHistoryAction() }
        let p = FixtureAiming.vector(viewerPose.offset)+FixtureAiming.rotate(viewerPose.orientation,offset)
        viewerPose = .init(offset: .init(x: p.x,y: p.y,z: p.z),orientation: ViewerNavigationPose.compose(viewerPose.orientation,FixtureAiming.euler(yaw: yaw,pitch: pitch,roll: roll)))
    }
    func resetViewerToSpawn() {
        endViewerNavigation(); beginHistoryAction("Return viewer to spawn"); defer { endHistoryAction() }
        viewerPose = .init(); viewerResetToken = UUID()
    }
    private(set) var draggingPresetID: UUID?
    private var fixtureDragLease: Task<Void, Never>?
    private let defaults: UserDefaults
    private let arguments: [String]
    var previewDraft = false { didSet { queueHistoryEdit("Change draft preview") } }
    var previewBlackout = false { didSet { queueHistoryEdit("Change preset simulation blackout") } }
    var toolboxBlackout: Bool { blackout || (previewDraft && previewBlackout && selectedID != nil) }
    private var targetPresetSource: TargetPresetSource?
    var blackout = false { didSet { queueHistoryEdit("Change blackout") } }
    var houseLight: Float = 0.15 { didSet { queueHistoryEdit("Adjust room light") } }
    var whiteRoom = true { didSet { queueHistoryEdit("Change room materials") } }
    let lightingBenchmark: LightingBenchmark?
    var requestedLightLimit = 8
    var supportsExtendedLights = false
    var lightingThermal = LightingBudget.Thermal.nominal
    var lightingBenchmarkJSON = ""
    var lightingBenchmarkStatus = ""
    var effectiveLightLimit: Int {
        LightingBudget.effective(requested: requestedLightLimit, extendedHardware: supportsExtendedLights, thermal: lightingThermal)
    }
    private var bundledRooms: [LibraryRoom] = []
    var scenePick: ScenePick?
    var lastTarget: Position3D?
    private(set) var pendingTarget: Position3D?
    private(set) var targetPreview: Fixture?
    var canSaveTarget: Bool { focusPickID != nil ? tourPreviewSession != nil : isRetargeting && targetPreview != nil && pendingTarget != nil }
    var gizmoVisible = false
    var transformMode = FixtureTransformMode.rotate
    private var transformDrag: FixtureTransformDrag?
    private var surfaceDrag: FixtureSurfaceDrag?
    var isTransformDragging: Bool { transformDrag != nil || surfaceDrag != nil }
    var isSurfaceMoveActive: Bool {
        if case .move = scenePick { return true }
        return gizmoVisible && transformMode == .move && selectedID != nil && !isRetargeting
    }
    var isRetargeting: Bool { if case .aim = scenePick { true } else { focusPickID != nil } }
    var isPickingRoom: Bool { isPlacing || scenePick != nil || focusPickID != nil }
    var pickingInstruction: String {
        switch scenePick {
        case .move: "Click a surface to move and align the fixture, or drag its body along its current plane."
        case .aim: "Look and click to preview DMX aim. Hold and move your hand to adjust. Save updates this preset and its assigned fixtures; Cancel restores."
        case nil: "Look at a clear floor or tabletop, then pinch to place."
        }
    }
    var controlsTab = 0
    var presetWindowVisible = false
    var fixtureRenderRevision = 0
    var fixtureAssetStatus = "Loading fixture asset…"

    var draftHasChanges: Bool {
        guard let saved = presets.first(where: { $0.id == editingPresetID }) else { return true }
        return presetDraft != saved
    }

    var canSavePreset: Bool {
        if draftHasChanges { return true }
        guard tourEditShow, let tour else { return false }
        return tour.show.presets.first(where: { $0.id == presetDraft.id }) != presetDraft || tour.presetOverrides.contains { $0.id == presetDraft.id }
    }

    var canSimulatePalm: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
    var isImmersed = false
    var isTransitioning = false
    var isPlacing = false
    var trackingStatus = "Starting spatial tracking…"
    var canPlace = false
    private(set) var environment: EnvironmentManifest?
    var environmentStatus = "Loading classroom…"
    private(set) var persistenceStatus = "Placements save on this device"
    private var persistenceBlocked = false
    private let placements: PlacementStore
    var message: String?
    private(set) var revision = 0
    private(set) var syncedRevision: Int?
    private(set) var isSyncing = false
    private(set) var syncStatus = "No configuration sent"
    private(set) var lastRequestJSON = ""
    private(set) var syncFailed = false
    var simulateSyncFailure = false
    let isDemoMode: Bool
    private let client = MockSyncClient()
    private var nextFixtureNumber = 1
    private var didRequestDemoSpace = false

    init(arguments: [String] = ProcessInfo.processInfo.arguments, defaults: UserDefaults = .standard, placementDirectory: URL? = nil) {
        self.defaults = defaults
        self.arguments = arguments
        lightingBenchmark = LightingBenchmark(arguments: arguments)
        requestedLightLimit = lightingBenchmark?.lights ?? 8
        placements = PlacementStore(directory: placementDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VenueVolume/Placements"))
        library = RoomLibraryStore(directory: placements.directory.appendingPathComponent(isDemoModeDirectory(arguments) ? "DemoLibrary" : "Library"))
        isDemoMode = isDemoModeDirectory(arguments)
        var seenKinds = Set<FixtureKind>()
        recentFixtureKinds = Array((defaults.stringArray(forKey: "venue.fixture-recents.v1") ?? []).compactMap(FixtureKind.init(rawValue:)).filter { seenKinds.insert($0).inserted }.prefix(6))
        if !isDemoMode, let data = defaults.data(forKey: "venue.presets.v1"),
           let saved = try? JSONDecoder().decode([DMXPreset].self, from: data),
           saved.allSatisfy({ $0.validationIssue == nil }), Set(saved.map(\.id)).count == saved.count {
            presets = saved
        }
        loadTouring()
        if let first = presets.first { presetDraft = first; editingPresetID = first.id }
        guard isDemoMode else { return }
        simulatedPalm = !arguments.contains("--palm-hidden")

    }

    func activate(environment: EnvironmentManifest) {
        if rooms.isEmpty { bootstrapLibrary(defaultRoom: environment) }
        if let destination = historyDestination, let state = history?.node(destination.id)?.state {
            guard state.rooms.first(where: { $0.id == state.roomID })?.manifest == environment else { return }
            do { try prepareHistoryRestore() }
            catch { historyRestoreFailed(error.localizedDescription); return }
            if let preparedHistory { history = preparedHistory }
            self.preparedHistory = nil; historyDestination = nil; roomRequest = nil; libraryBusy = false
            applyHistoryState(state)
            return
        }
        if let benchmark = lightingBenchmark {
            self.environment = environment
            fixtures = benchmark.fixtures(); selectedID = nil; expandedID = nil
            whiteRoom = false; houseLight = 0.05; blackout = false
            environmentStatus = environment.title
            roomRequest = nil; libraryBusy = false
            persistenceStatus = "Lighting benchmark · temporary placements"
            return
        }
        beginHistoryAction(roomRequest?.setup.map { "Load setup · \($0.name)" } ?? "Open blank room · \(environment.title)")
        defer { endHistoryAction(); startHistoryIfNeeded() }
        if let request = roomRequest {
            guard request.room.manifest == environment else { return }
            viewerPose = .init()
            let preserveDirtyDraft = draftHasChanges
            self.environment = environment
            fixtures = request.setup?.placements.fixtures ?? []
            if let setup = request.setup, let tour = setup.tour {
                touring.active = tour; presets = tour.presets
                if !touring.shows.contains(where: { $0.id == tour.show.id }) { touring.shows.append(tour.show) }
            } else if request.setup != nil { touring.active = nil; refreshTourPresets() }
            else if let tour = touring.active { touring.active = TourSession(show: tour.show, configurationID: request.configurationID ?? tour.configurationID); presets = touring.active!.presets }
            if let setup = request.setup {
                // Fork conflicting preset definitions instead of altering other setups.
                for original in setup.presets {
                    if let existing = presets.first(where: { $0.id == original.id }), existing != original {
                        var copy = original
                        if let equivalent = presets.first(where: { $0.name == original.name && $0.channels == original.channels }) { copy = equivalent }
                        else { copy.id = UUID(); presets.append(copy) }
                        for i in fixtures.indices where fixtures[i].presetID == original.id { fixtures[i].presetID = copy.id }
                    } else if !presets.contains(where: { $0.id == original.id }) { presets.append(original) }
                }
                if !isDemoMode, tour == nil, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
                whiteRoom = setup.whiteRoom; houseLight = setup.houseLight
            } else {
                whiteRoom = environment.id != "mappedRoom" && environment.id != "the-fortress"
                houseLight = 0.15
            }
            if !preserveDirtyDraft {
                if let preset = presets.first(where: { $0.id == editingPresetID }) ?? presets.first(where: { $0.id == fixtures.first?.presetID }) ?? presets.first {
                    presetDraft = preset; editingPresetID = preset.id
                } else { presetDraft = DMXPreset(name: ""); editingPresetID = nil }
            } else if !presets.contains(where: { $0.id == editingPresetID }) {
                editingPresetID = nil
                presetMessage = "Your unsaved draft is preserved. Choose a preset from this venue to change editing context."
            }
            persistenceBlocked = false
            if !isDemoMode {
                do {
                    let working = try placements.load(environment: environment)
                    if !request.blank && request.setup == nil, let working { fixtures = working.fixtures }
                } catch {
                    persistenceBlocked = true
                    persistenceStatus = "Autosave disabled to preserve an unreadable working file. Named setups can still be saved."
                }
            }
            revision += 1; syncedRevision = nil; activeSetupID = request.setup?.id
            setupName = request.setup?.name ?? "Untitled setup"
            savedSetup = request.setup.map { setup in
                var copy = setup; copy.placements = .init(environment: environment, fixtures: fixtures, revision: revision)
                copy.presets = touring.active == nil ? presets.filter { preset in fixtures.contains { $0.presetID == preset.id } } : presets; return copy
            }
            roomRequest = nil; libraryBusy = false
            selectedGroupID = nil; selectedUnitIDs = []; tourPreview = nil
            cancelPicking(); selectedID = fixtures.first?.id; selectedUnitIDs = tour == nil ? [] : Set(selectedID.map { [$0] } ?? []); expandedID = nil; lastTarget = nil
            previewDraft = false; blackout = false; recent = RecentItems(); endPresetDrag(); draggingFixture = nil
            nextFixtureNumber = fixtures.count+1
            environmentStatus = environment.title; libraryMessage = "Opened \(setupName) in \(environment.title)."
            persist()
            return
        }
        // Preserve the active arrangement across a leave/re-enter transition.
        environmentStatus = environment.title
        if self.environment?.id == environment.id && self.environment?.version == environment.version { return }
        self.environment = environment
        whiteRoom = environment.id != "mappedRoom" && environment.id != "the-fortress"
        environmentStatus = environment.title
        isPlacing = false
        selectedID = nil
        expandedID = nil
        syncedRevision = nil
        fixtures = []
        revision = 0
        persistenceBlocked = false
        if isDemoMode {
            let look = arguments.contains("--blue") ? presets[1] : presets[0]
            fixtures = [Fixture(presetID: look.id, name: "Rogue R1X 01", assetID: LightingPreview.assetID,
                                channels: look.channels, position: .init(x: 4.04, y: 0.74, z: -3.68), surfaceID: "table-r2-c2-top")]
            selectedID = fixtures[0].id
            expandedID = arguments.contains("--show-info") ? fixtures[0].id : nil
            presetDraft = look; editingPresetID = look.id
            blackout = arguments.contains("--blackout")
            if arguments.contains("--aim-left") { fixtures[0].channels[4] = 155 }
            if arguments.contains("--fixture-near") { fixtures[0].position = .init(x: 2.66, y: 0, z: -2.3); fixtures[0].surfaceID = "floor" }
            if arguments.contains("--position-tab") { controlsTab = 1 }
            if arguments.contains("--rooms-tab") { toolboxTab = 1 }
            if arguments.contains("--scene-overview") { selectedID = nil; expandedID = nil }
            if arguments.contains("--show-recents") {
                record(.fixture(fixtures[0].id)); record(.preset(look.id))
            }
            revision = 1
            persistenceStatus = "Demo placements are temporary"
        } else {
            do {
                if touring.active != nil { persistenceStatus = "Tour inventory ready · blank layout" }
                else if let saved = try placements.load(environment: environment) {
                    fixtures = saved.fixtures
                    revision = saved.revision
                    persistenceStatus = "Restored \(fixtures.count) room placements"
                } else {
                    persistenceStatus = "New room version · no saved placements"
                }
            } catch {
                // Preserve an unreadable save; never replace it with an empty scene.
                persistenceBlocked = true
                message = "Placements could not be restored: \(error.localizedDescription)"
                persistenceStatus = "Save disabled to preserve the existing file"
            }
        }
        nextFixtureNumber = fixtures.count+1
    }

    private func persist() {
        persistTouring()
        guard !isDemoMode, !persistenceBlocked, let environment else { return }
        do {
            try placements.save(RoomPlacements(environment: environment, fixtures: fixtures, revision: revision), environment: environment)
            persistenceStatus = "Saved \(fixtures.count) placements on this device"
        } catch {
            persistenceStatus = "Save failed: \(error.localizedDescription)"
        }
    }

    var totalChannels: Int { fixtures.reduce(0) { $0 + $1.channels.count } }
    var hasUnsyncedChanges: Bool { syncedRevision != revision }

    func consumeDemoAutoEntry() -> Bool {
        guard isDemoMode, !didRequestDemoSpace else { return false }
        didRequestDemoSpace = true
        return true
    }

    func fixture(_ id: UUID) -> Fixture? { fixtures.first { $0.id == id } }

    func place(at position: SIMD3<Float>, surfaceID: String) {
        guard canPlace, isPlacing else { return }
        guard let surface = environment?.surfaces.first(where: { $0.id == surfaceID }),
              let center = surface.fixturePosition(hit: .init(x: position.x, y: position.y, z: position.z), halfSize: fixtureKind.radius) else {
            message = "Choose the top of a floor or table with space for the fixture."
            return
        }
        let base = Position3D(x: center.x, y: center.y-fixtureKind.radius, z: center.z)
        if let scannedMesh, !scannedMesh.supports(base, radius: fixtureKind.radius) { message = "Scan more of this surface before placing here."; return }
        insertFixture(at: base, surfaceID: surfaceID)
    }

    func placeOnMesh(at point: Position3D) {
        guard canPlace, isPlacing, let scannedMesh, scannedMesh.supports(point, radius: fixtureKind.radius) else {
            message = "Choose a scanned horizontal surface with room for the fixture."; return
        }
        insertFixture(at: point, surfaceID: nil)
    }

    private func insertFixture(at base: Position3D, surfaceID: String?) {
        guard !libraryBusy else { return }
        if touring.active != nil { insertInventoryFixture(at: base, surfaceID: surfaceID); return }
        beginHistoryAction("Place \(fixtureKind.name)"); defer { endHistoryAction() }
        guard fixtures.count < 64 else { message = "This setup supports up to 64 objects."; return }
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 16) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: fixtureKind.name + String(format: " %02d", nextFixtureNumber), assetID: fixtureKind.assetID,
                              universe: patch.universe, startAddress: patch.address, channels: fixtureKind.asset?.neutralChannels ?? Array(repeating: 0, count: 16),
                              position: .init(x: base.x, y: base.y+(fixtureKind == .cube ? fixtureKind.radius : 0), z: base.z), surfaceID: surfaceID)
        if let environment, let issue = fixture.placementIssue(in: environment) { message = issue; return }
        message = nil
        fixtures.append(fixture)
        recent.use(.addFixture)
        nextFixtureNumber += 1
        selectedID = fixture.id
        isPlacing = false
        draggingFixture = nil
        revision += 1
        persist()
    }

    func select(_ id: UUID, expand: Bool = false, extendSelection: Bool = true) {
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction(expand ? "Toggle fixture info" : "Select fixture"); defer { endHistoryAction() }
        guard fixture(id) != nil else { return }
        if extendSelection, multiSelection, touring.active != nil { toggleUnitSelection(id); return }
        cancelTourPreview(); selectedUnitIDs = [id]; selectedGroupID = nil
        if selectedID != id { expandedID = nil; lastTarget = nil; gizmoVisible = false }
        cancelPicking()
        selectedID = id
        toolboxTab = 0
        recent.use(.fixture(id))
        if let fixture = fixture(id) { rememberFixtureKind(fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube) }
        isPlacing = false
        if expand { expandedID = expandedID == id ? nil : id }
    }

    func deselect() {
        cancelTourPreview(); selectedUnitIDs = []; selectedGroupID = nil
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction("Deselect fixture"); defer { endHistoryAction() }
        cancelPicking(); selectedID = nil; expandedID = nil; lastTarget = nil
        gizmoVisible = false; previewDraft = false
    }

    func beginPlacement() {
        rememberFixtureKind(fixtureKind)
        endTransformDrag(); gizmoVisible = false
        targetPreview = nil; pendingTarget = nil
        scenePick = nil
        isPlacing.toggle()
        expandedID = nil
        message = nil
        recent.use(.addFixture)
    }

    func beginFixtureDrag(_ kind: FixtureKind) {
        endTransformDrag(); gizmoVisible = false; cancelPicking()
        selectFixtureKind(kind); draggingFixture = kind; isPlacing = true; scenePick = nil
        fixtureDragLease?.cancel()
        fixtureDragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            self?.draggingFixture = nil; self?.isPlacing = false
        }
    }

    func dropFixture(_ tokens: [String], at point: Position3D, surfaceID: String) -> Bool {
        guard let token = tokens.first, let kind = FixtureKind(token: token), canPlace else { return false }
        selectFixtureKind(kind); isPlacing = true
        let count = fixtures.count
        place(at: FixtureAiming.vector(point), surfaceID: surfaceID)
        draggingFixture = nil; fixtureDragLease?.cancel()
        if fixtures.count == count { isPlacing = false }
        return fixtures.count > count
    }

    func openPreset(_ id: UUID?) {
        // The editor manages dirty-navigation confirmation; external open requests
        // keep the current draft intact while bringing its window forward.
        if draftHasChanges {
            presetMessage = "Your unsaved draft is still open. Use the preset list to save or discard it before switching."
            return
        }
        if let saved = presets.first(where: { $0.id == id }) {
            choosePreset(saved)
        }
    }

    func choosePreset(_ preset: DMXPreset) {
        guard !libraryBusy else { return }
        beginHistoryAction("Open preset · \(preset.name)"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking()
        previewDraft = true; previewBlackout = false
        presetDraft = preset
        editingPresetID = preset.id
        presetMessage = nil
        recent.use(.preset(preset.id))
    }

    func newPreset() {
        guard !libraryBusy else { return }
        beginHistoryAction("New preset draft"); defer { endHistoryAction() }
        editingPresetID = nil
        cancelTourPreview(); cancelPicking()
        previewDraft = true; previewBlackout = false
        presetDraft = DMXPreset(name: "")
        if tour != nil { presetDraft.includedChannels = [0,1,2,3,6] }
        presetMessage = nil
    }

    @discardableResult func savePreset(asNew: Bool = false) -> Bool {
        if touring.active != nil { return saveTourPreset(asNew: asNew) }
        guard !libraryBusy else { return false }
        beginHistoryAction(asNew ? "Save preset as new" : "Save preset"); defer { endHistoryAction() }
        var candidate = presetDraft
        candidate.name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if asNew { candidate.id = UUID() }
        do {
            let updated = try PresetOperations.saving(candidate, fixtures: fixtures)
            var library = presets
            if let index = library.firstIndex(where: { $0.id == candidate.id }) { library[index] = candidate }
            else { library.append(candidate) }
            // Persist the validated library before publishing the new live snapshot.
            if !isDemoMode { defaults.set(try JSONEncoder().encode(library), forKey: "venue.presets.v1") }
            presets = library
            if fixtures != updated { fixtures = updated; revision += 1; persist() }
            choosePreset(candidate)
            presetMessage = asNew ? "Saved as a new preset. Existing assignments are unchanged." : "Saved. Assigned fixtures are updated."
            return true
        } catch {
            presetMessage = error.localizedDescription
            return false
        }
    }

    func deletePreset(_ id: UUID) {
        if touring.active != nil { deleteTourPreset(id); return }
        guard !libraryBusy else { return }
        beginHistoryAction("Delete preset"); defer { endHistoryAction() }
        guard presets.contains(where: { $0.id == id }) else { return }
        let updated = PresetOperations.clearing(id, fixtures: fixtures)
        if fixtures != updated { fixtures = updated; revision += 1; persist() }
        presets.removeAll { $0.id == id }
        recent.remove(.preset(id))
        if !isDemoMode, tour == nil, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        if let first = presets.first { choosePreset(first) } else { newPreset() }
        presetMessage = "Preset deleted. Assigned fixtures are dark and unassigned; aim overrides are preserved."
    }

    @discardableResult func applyPreset(_ presetID: UUID, to fixtureID: UUID) -> Bool {
        if touring.active != nil { return applyTourPreset(presetID, ids: [fixtureID]) }
        guard !libraryBusy else { return false }
        beginHistoryAction("Apply preset"); defer { endHistoryAction() }
        defer { endPresetDrag() }
        guard let preset = presets.first(where: { $0.id == presetID }) else {
            message = "That preset no longer exists."
            return false
        }
        do {
            let updated = try PresetOperations.applying(preset, to: fixtureID, fixtures: fixtures)
            if updated != fixtures { fixtures = updated; revision += 1; persist() }
            previewDraft = false
            select(fixtureID)
            recent.use(.preset(presetID))
            message = "Applied \(preset.name) to \(fixture(fixtureID)?.name ?? "fixture")."
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func clearAssignment(_ id: UUID) {
        if touring.active != nil { resetTourAssignment([id]); return }
        guard !libraryBusy else { return }
        beginHistoryAction("Clear fixture preset"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }), fixtures[index].presetID != nil else { return }
        if case .aim(let targetID) = scenePick, targetID == id { cancelPicking() }
        fixtures[index].presetID = nil
        fixtures[index].channels = Array(repeating: 0, count: fixtures[index].channels.count)
        fixtures[index].preserveAimOverride()
        revision += 1
        persist()
        presetMessage = "Assignment cleared. Output is zero; any aim override is preserved."
    }

    func renderedChannels(for fixture: Fixture) -> [Int] {
        if let preview = tourPreview?.first(where: { $0.id == fixture.id }) { return preview.channels }
        if touring.active != nil, previewDraft, selectedUnitIDs.contains(fixture.id), Touring.compatible(presetDraft, with: fixture) {
            if presetDraft.focusTargetID != nil, var session = tour {
                session.presetOverrides.removeAll { $0.id == presetDraft.id }; session.presetOverrides.append(presetDraft)
                for channel in presetDraft.channelMask { session.programming.units[fixture.id, default: [:]][channel] = presetDraft.id }
                return (try? Touring.resolved(fixture, in: session, solveFocus: true).channels) ?? fixture.channels
            }
            var values = fixture.channels
            for i in presetDraft.channelMask { values[i] = presetDraft.channels[i] }
            return values
        }
        if touring.active != nil { return fixture.channels }
        if targetPreview?.id == fixture.id { return renderedFixture(fixture).channels }
        return previewDraft && selectedID == fixture.id ? presetDraft.channels : fixture.channels
    }

    func renderedFixture(_ fixture: Fixture) -> Fixture {
        if let preview = tourPreview?.first(where: { $0.id == fixture.id }) { return preview }
        guard let preview = targetPreview, preview.id == fixture.id, isRetargeting else { return fixture }
        var current = fixture
        current.channels = targetingPreset?.channels ?? preview.channels
        if current.channels.count >= 6 {
            current.channels[4] = preview.channels[4]; current.channels[5] = preview.channels[5]
        }
        current.aimOverride = nil
        return current
    }

    func isBlackedOut(_ fixture: Fixture) -> Bool {
        blackout || (previewDraft && previewBlackout && (selectedID == fixture.id || selectedUnitIDs.contains(fixture.id)))
    }

    /// Direct preview articulation belongs to this placed fixture, not its shared preset.
    func setHeadAim(_ id: UUID, panDegrees: Float? = nil, tiltDegrees: Float? = nil) {
        guard !libraryBusy else { return }
        beginHistoryAction("Adjust fixture motion"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }),
              let asset = fixtures[index].asset,
              asset.pan != nil || asset.tilt != nil,
              fixtures[index].channels.count >= 6,
              [panDegrees, tiltDegrees].compactMap({ $0 }).allSatisfy(\.isFinite) else { return }
        var candidate = fixtures[index]
        let pan = panDegrees.flatMap { asset.pan?.byte(for: $0) } ?? candidate.channels[4]
        let tilt = tiltDegrees.flatMap { asset.tilt?.byte(for: $0) } ?? candidate.channels[5]
        candidate.aimOverride = .init(pan: pan, tilt: tilt)
        candidate.preserveAimOverride()
        guard candidate != fixtures[index], candidate.validationIssue(among: fixtures) == nil else { return }
        cancelPicking()
        fixtures[index] = candidate
        previewDraft = false
        lastTarget = nil
        revision += 1
        persist()
    }

    func setJoint(_ id: UUID, jointID: String, value: Float) {
        guard !libraryBusy, value.isFinite, let index = fixtures.firstIndex(where: { $0.id == id }),
              let joint = fixtures[index].asset?.joints.first(where: { $0.id == jointID }),
              fixtures[index].channels.indices.contains(joint.channel) else { return }
        if jointID == "pan" { setHeadAim(id, panDegrees: value); return }
        if jointID == "tilt" { setHeadAim(id, tiltDegrees: value); return }
        beginHistoryAction("Adjust \(joint.label)"); defer { endHistoryAction() }
        var candidate = fixtures[index]
        if candidate.jointOverrides == nil { candidate.jointOverrides = [:] }
        candidate.jointOverrides?[jointID] = joint.byte(for: value)
        candidate.preserveAimOverride()
        guard candidate != fixtures[index], candidate.validationIssue(among: fixtures) == nil else { return }
        cancelPicking(); fixtures[index] = candidate; previewDraft = false; lastTarget = nil
        revision += 1; persist()
    }

    func moveFixture(_ id: UUID, position: Position3D, yawDegrees: Float) {
        guard let fixture = fixture(id) else { return }
        let angles = FixtureAiming.angles(fixture.orientation)
        transformFixture(id, position: position, yaw: yawDegrees, pitch: angles.pitch, roll: angles.roll)
    }

    func transformFixture(_ id: UUID, position: Position3D, yaw: Float, pitch: Float, roll: Float) {
        guard !libraryBusy else { return }
        beginHistoryAction("Transform fixture"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }), let environment else { return }
        guard [yaw,pitch,roll].allSatisfy(\.isFinite) else { return }
        var candidate = fixtures[index]
        candidate.position = position
        candidate.orientation = FixtureAiming.euler(yaw: yaw, pitch: pitch, roll: roll)
        if let issue = candidate.placementIssue(in: environment) { message = issue; return }
        candidate.surfaceID = nil
        guard candidate != fixtures[index] else { return }
        cancelPicking()
        fixtures[index] = candidate
        lastTarget = nil
        revision += 1; persist(); message = nil
    }

    func yawDegrees(for fixture: Fixture) -> Float { FixtureAiming.angles(fixture.orientation).yaw }

    /// Scene retarget always starts from the fixture's assigned, saved preset.
    func beginRetarget(_ id: UUID) {
        if let tour {
            guard let unit = tour.allUnits.first(where: { $0.id == id }), let binding = tour.binding(for: unit, channel: 4), let preset = presets.first(where: { $0.id == binding }) else { message = "Apply a focus preset first."; return }
            select(id, extendSelection: false); beginTourTarget(preset, fromDraft: false); return
        }
        guard canPlace, let fixture = fixture(id), fixture.asset?.headAim == true else { return }
        guard let presetID = fixture.presetID, presets.contains(where: { $0.id == presetID }) else {
            message = "Apply a preset before retargeting, or create one in the preset editor."
            return
        }
        select(id, extendSelection: false)
        gizmoVisible = false; previewDraft = false
        targetPresetSource = .saved(presetID)
        scenePick = .aim(id); lastTarget = nil; message = nil
    }

    /// Editor targeting uses all current draft values and saves/assigns that preset.
    func beginPresetTarget() {
        if tour != nil { beginTourTarget(presetDraft, fromDraft: true); return }
        guard canPlace, let id = selectedID, fixture(id)?.asset?.headAim == true else { return }
        guard presetDraft.validationIssue == nil, presetDraft.channels.count >= 6 else {
            presetMessage = presetDraft.validationIssue ?? "Target requires at least six channels."
            return
        }
        cancelPicking(); gizmoVisible = false; previewDraft = true
        targetPresetSource = .draft(presetDraft.id)
        scenePick = .aim(id); lastTarget = nil; message = nil
    }

    private var targetingPreset: DMXPreset? {
        switch targetPresetSource {
        case .saved(let id): return presets.first { $0.id == id }
        case .draft(let id): return presetDraft.id == id ? presetDraft : nil
        case nil: return nil
        }
    }

    func beginReposition(_ id: UUID) { beginTransform(id) }

    func cancelPicking() {
        fixtureDragLease?.cancel(); fixtureDragLease = nil
        if focusPickID != nil { cancelTourPreview() }
        focusPickID = nil; placementUnitID = nil; repeatPlacement = false; placementQueue = []
        scenePick = nil; targetPreview = nil; pendingTarget = nil; targetPresetSource = nil
        isPlacing = false; draggingFixture = nil; message = nil
    }

    @discardableResult func acceptTarget(_ target: Position3D) -> Bool {
        if let focusPickID { return previewFocusLocation(focusPickID, at: target) }
        guard !libraryBusy, canPlace, case .aim(let id) = scenePick,
              var candidate = fixture(id), let preset = targetingPreset else { return false }
        do {
            guard preset.channels.count >= 6 else { throw PresetError("Target requires a preset with at least six channels.") }
            candidate.channels = preset.channels
            candidate.presetID = preset.id
            candidate.aimOverride = nil
            candidate.jointOverrides?.removeValue(forKey: "pan")
            candidate.jointOverrides?.removeValue(forKey: "tilt")
            candidate.preserveAimOverride()
            let aim = try FixtureAiming.articulated(candidate, target: target)
            candidate.channels[4] = aim.pan; candidate.channels[5] = aim.tilt
            if let issue = candidate.validationIssue(among: fixtures) { throw PresetError(issue) }
            targetPreview = candidate; pendingTarget = target
            message = "Previewing \(preset.name) · Save updates preset Pan/Tilt and assigned fixtures. Cancel restores."
            return true
        } catch {
            targetPreview = nil; pendingTarget = nil
            message = error.localizedDescription; return false
        }
    }

    @discardableResult func saveTarget() -> Bool {
        if focusPickID != nil { return commitTourPreview() }
        guard !libraryBusy, canPlace, case .aim(let id) = scenePick, let target = pendingTarget,
              var preset = targetingPreset, acceptTarget(target), let candidate = targetPreview else { return false }
        // Re-solve using the latest preset/draft, then validate the entire assignment
        // before changing either the library or fixtures. One Save is one Undo step.
        preset.channels = candidate.channels
        preset.name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            var assigned = fixtures
            for index in assigned.indices where assigned[index].presetID == preset.id || assigned[index].id == id {
                assigned[index].presetID = preset.id
                assigned[index].aimOverride = nil
                assigned[index].jointOverrides?.removeValue(forKey: "pan")
                assigned[index].jointOverrides?.removeValue(forKey: "tilt")
            }
            let updated = try PresetOperations.saving(preset, fixtures: assigned)
            var library = presets
            if let index = library.firstIndex(where: { $0.id == preset.id }) { library[index] = preset }
            else { library.append(preset) }
            let encoded = try JSONEncoder().encode(library)
            let refreshEditor = editingPresetID == preset.id && !draftHasChanges
            beginHistoryAction("Retarget preset · \(preset.name)"); defer { endHistoryAction() }
            if !isDemoMode { defaults.set(encoded, forKey: "venue.presets.v1") }
            presets = library; fixtures = updated
            // Preserve an unrelated unsaved editor draft when targeting from the scene.
            if case .draft = targetPresetSource { presetDraft = preset; editingPresetID = preset.id }
            else if refreshEditor { presetDraft = preset }
            cancelPicking(); lastTarget = target; revision += 1; persist()
            message = "Saved \(preset.name) target · preset Pan/Tilt updated."
            presetMessage = message
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func beginTransform(_ id: UUID) {
        guard canPlace, fixture(id) != nil else { return }
        select(id, extendSelection: false); gizmoVisible = true; transformMode = .move; previewDraft = false
    }

    func tapFixture(_ id: UUID) {
        if selectedID == id && !multiSelection { beginTransform(id) }
        else { select(id) }
    }

    @discardableResult func updateFixtureDetails(_ id: UUID, name: String, universe: Int, address: Int) -> Bool {
        guard !libraryBusy, let i = fixtures.firstIndex(where: { $0.id == id }) else { return false }
        var candidate = fixtures[i]
        candidate.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.universe = universe; candidate.startAddress = address
        if let issue = candidate.validationIssue(among: fixtures) { message = issue; return false }
        if var session = tour {
            let shared = session.show.units.contains { $0.id == id }
            if let i = session.show.units.firstIndex(where: { $0.id == id }), session.show.units[i].fixture.name != candidate.name {
                session.show.units[i].fixture.name = candidate.name; session.show.revision += 1
            }
            if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].fixture.name = candidate.name }
            var updated = fixtures; updated[i] = candidate
            return commitTour(session, fixtures: updated, title: "Edit inventory name and venue patch", publish: shared && session.show != tour?.show)
        }
        endTransformDrag()
        beginHistoryAction("Edit fixture details"); defer { endHistoryAction() }
        cancelPicking(); fixtures[i] = candidate; revision += 1; persist()
        message = "Saved item details."
        return true
    }

    var transformFixtureContext: Fixture? {
        guard var selected = selectedID.flatMap({ fixture($0) }) else { return nil }
        let members = fixtures.filter { tourSelection.contains($0.id) }
        if tour != nil, members.count > 1 {
            let center = members.reduce(SIMD3<Float>.zero) { $0 + FixtureAiming.vector($1.position) } / Float(members.count)
            selected.position = .init(x: center.x, y: center.y, z: center.z)
        }
        return selected
    }
    func beginSelectionTransform() {
        guard canPlace, selectedID != nil, tourSelection.isSubset(of: Set(fixtures.map(\.id))) else { message = "Place every selected unit before transforming."; return }
        cancelTourPreview(); cancelPicking(); gizmoVisible = true; previewDraft = false
    }
    func returnSelection() {
        let ids = tourSelection
        endTransformDrag(); beginHistoryAction("Return \(ids.count) units to inventory"); defer { endHistoryAction() }
        for id in ids { remove(id) }
        selectedUnitIDs = []; selectedGroupID = nil
    }
    func programmingSummary(_ unit: InventoryUnit) -> String {
        guard let tour else { return "" }
        let individual = tour.programming.units[unit.id]?.isEmpty == false || (tour.show.programming.units[unit.id]?.keys.contains { tour.programming.releasedUnits[unit.id]?.contains($0) != true } == true)
        let ids = Set(unit.fixture.channels.indices.compactMap { tour.binding(for: unit, channel: $0) })
        let names = tour.presets.filter { ids.contains($0.id) }.map(\.name).joined(separator: ", ")
        return (individual ? "Individual assignment · " : "Group / baseline · ") + (names.isEmpty ? "Inventory defaults" : names)
    }

    func beginTransformDrag(axis: FixtureAxis, mode: FixtureTransformMode, at point: SIMD3<Float>) {
        guard canPlace, gizmoVisible, !isTransformDragging, let id = selectedID, let fixture = fixture(id) else { return }
        let pivot = transformFixtureContext?.position ?? fixture.position
        var context = fixture; context.position = pivot
        let center = FixtureAiming.vector(context.visualCenter)
        let angle = axis.angle(at: point, about: center)
        guard mode == .move || angle != nil else { return }
        cancelPicking(); previewDraft = false
        beginHistoryAction("\(mode.rawValue) fixture · \(axis.rawValue.uppercased()) axis")
        transformDrag = .init(fixture: fixture, axis: axis, mode: mode, start: point, lastAngle: angle, members: tour == nil ? [fixture] : fixtures.filter { tourSelection.contains($0.id) }, pivot: pivot)
    }

    func updateTransformDrag(to point: SIMD3<Float>) {
        guard var drag = transformDrag, point.x.isFinite, point.y.isFinite, point.z.isFinite,
              selectedID == drag.fixture.id, let i = fixtures.firstIndex(where: { $0.id == drag.fixture.id }), let environment else { return }
        var candidate = drag.fixture
        if drag.mode == .move {
            var position = FixtureAiming.vector(candidate.position)
            position[drag.axis.index] += point[drag.axis.index]-drag.start[drag.axis.index]
            candidate.position = .init(x: position.x, y: position.y, z: position.z)
            if let issue = candidate.placementIssue(in: environment) { message = issue; return }
        } else {
            var context = drag.fixture; context.position = drag.pivot ?? candidate.position
            let center = FixtureAiming.vector(context.visualCenter)
            guard let next = drag.axis.angle(at: point, about: center), let previous = drag.lastAngle else { return }
            drag.totalAngle += FixtureAiming.angleDelta(from: previous, to: next); drag.lastAngle = next
            candidate.orientation = FixtureAiming.rotatedMount(candidate.orientation, around: drag.axis, radians: drag.totalAngle)
        }
        transformDrag = drag; candidate.surfaceID = nil
        if drag.mode == .move { candidate.mountPlane = nil }
        else { candidate.mountPlane = candidate.mountPlane ?? supportingPlane(for: drag.fixture) }
        guard candidate != fixtures[i], candidate.validationIssue(among: fixtures) == nil else { return }
        if drag.members.count > 1 {
            let pivot = FixtureAiming.vector(drag.pivot ?? drag.fixture.position)
            let q = FixtureAiming.rotatedMount(.init(), around: drag.axis, radians: drag.totalAngle)
            let delta = FixtureAiming.vector(candidate.position) - FixtureAiming.vector(drag.fixture.position)
            var updates = fixtures
            for original in drag.members {
                guard let index = updates.firstIndex(where: { $0.id == original.id }) else { return }
                var member = original
                if drag.mode == .move {
                    let point = FixtureAiming.vector(original.position) + delta
                    member.position = .init(x: point.x, y: point.y, z: point.z)
                } else {
                    let point = pivot + FixtureAiming.rotate(q, FixtureAiming.vector(original.position)-pivot)
                    member.position = .init(x: point.x, y: point.y, z: point.z)
                    member.orientation = FixtureAiming.rotatedMount(original.orientation, around: drag.axis, radians: drag.totalAngle)
                }
                member.surfaceID = nil
                if drag.mode == .move { member.mountPlane = nil }
                else { member.mountPlane = member.mountPlane ?? supportingPlane(for: original) }
                if let issue = member.placementIssue(in: environment) { message = issue; return }
                updates[index] = member
            }
            if let tour { do { try tour.validate(fixtures: updates) } catch { message = error.localizedDescription; return } }
            fixtures = updates
        } else { fixtures[i] = candidate }
        lastTarget = nil; revision += 1; persist(); message = nil
    }

    func endTransformDrag() {
        guard isTransformDragging else { return }
        transformDrag = nil; surfaceDrag = nil; endHistoryAction()
    }

    func supportingPlane(for fixture: Fixture) -> FixtureMountPlane {
        if let plane = fixture.mountPlane { return plane }
        let offset: Float = fixture.assetID == nil ? fixture.footprintRadius : 0
        return .init(origin: .init(x: fixture.position.x, y: fixture.position.y-offset, z: fixture.position.z), normal: .init(x: 0,y: 1,z: 0))
    }

    func beginSurfaceDrag(_ id: UUID, at point: SIMD3<Float>) {
        guard canPlace, !libraryBusy, gizmoVisible, selectedID == id, !isTransformDragging,
              !isRetargeting, !isPlacing, let fixture = fixture(id) else { return }
        cancelPicking(); previewDraft = false; transformMode = .move
        beginHistoryAction("Slide fixture on its surface")
        surfaceDrag = .init(fixture: fixture, plane: supportingPlane(for: fixture), start: point)
    }

    func surfaceDragDestination(to point: SIMD3<Float>) -> (point: Position3D, normal: Position3D, radius: Float)? {
        guard let drag = surfaceDrag else { return nil }
        var fixture = drag.fixture
        let moved = FixtureAiming.vector(fixture.position) + drag.plane.projected(point-drag.start)
        fixture.position = .init(x: moved.x,y: moved.y,z: moved.z)
        return (mountingPoint(for: fixture), drag.plane.normal, fixture.footprintRadius)
    }

    @discardableResult func updateSurfaceDrag(to point: SIMD3<Float>) -> Bool {
        guard let drag = surfaceDrag, selectedID == drag.fixture.id, let environment,
              let i = fixtures.firstIndex(where: { $0.id == drag.fixture.id }),
              [point.x,point.y,point.z].allSatisfy(\.isFinite) else { return false }
        let delta = drag.plane.projected(point-drag.start)
        if FixtureAiming.length(delta) < 0.0001 { return true }
        var candidate = drag.fixture
        let moved = FixtureAiming.vector(candidate.position) + delta
        candidate.position = .init(x: moved.x,y: moved.y,z: moved.z); candidate.mountPlane = drag.plane
        let base = mountingPoint(for: candidate)
        if let surfaceID = candidate.surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }),
           surface.fixturePosition(hit: base, halfSize: candidate.footprintRadius) == nil {
            message = "Keep the fixture on its current surface, or click a different surface."; return false
        }
        if let scannedMesh, !scannedMesh.supports(base, normal: drag.plane.normal, radius: candidate.footprintRadius) {
            message = "The scan has no support here. Choose a captured surface."; return false
        }
        if let issue = candidate.placementIssue(in: environment) ?? candidate.validationIssue(among: fixtures) { message = issue; return false }
        guard candidate != fixtures[i] else { return true }
        fixtures[i] = candidate; revision += 1; persist(); message = nil
        return true
    }

    func mountingPoint(for fixture: Fixture) -> Position3D {
        let p = FixtureAiming.vector(fixture.position)
            - (fixture.assetID == nil ? FixtureAiming.rotate(fixture.orientation, [0,fixture.footprintRadius,0]) : .zero)
        return .init(x: p.x,y: p.y,z: p.z)
    }

    @discardableResult func moveToSurface(at point: Position3D, normal: Position3D, surfaceID: String? = nil) -> Bool {
        guard canPlace, !libraryBusy, isSurfaceMoveActive, let id = selectedID,
              let i = fixtures.firstIndex(where: { $0.id == id }), let environment else { return false }
        let plane = FixtureMountPlane(origin: point, normal: normal)
        guard plane.isValid else { message = "Choose a valid surface."; return false }
        var candidate = fixtures[i]
        if let surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }),
           surface.fixturePosition(hit: point, halfSize: candidate.footprintRadius) == nil {
            message = "Choose a surface with enough space for the fixture."; return false
        }
        if let scannedMesh, !scannedMesh.supports(point, normal: normal, radius: candidate.footprintRadius) {
            message = "Choose a captured surface with enough space."; return false
        }
        candidate.orientation = FixtureAiming.alignedMount(candidate.orientation, normal: FixtureAiming.vector(normal))
        let position = FixtureAiming.vector(point) + (candidate.assetID == nil ? FixtureAiming.vector(normal)*candidate.footprintRadius : .zero)
        candidate.position = .init(x: position.x,y: position.y,z: position.z)
        candidate.surfaceID = surfaceID; candidate.mountPlane = plane
        if let issue = candidate.placementIssue(in: environment) ?? candidate.validationIssue(among: fixtures) { message = issue; return false }
        endTransformDrag(); beginHistoryAction("Move fixture to surface"); defer { endHistoryAction() }
        fixtures[i] = candidate; scenePick = nil; gizmoVisible = true; transformMode = .move; lastTarget = nil
        revision += 1; persist(); message = "Fixture moved and aligned to the surface."
        return true
    }

    func reposition(at hit: Position3D, surfaceID: String) {
        guard let surface = environment?.surfaces.first(where: { $0.id == surfaceID }) else { return }
        _ = moveToSurface(at: hit, normal: .init(x: surface.normal[0],y: surface.normal[1],z: surface.normal[2]), surfaceID: surfaceID)
    }

    func repositionOnMesh(at point: Position3D) {
        _ = moveToSurface(at: point, normal: .init(x: 0,y: 1,z: 0))
    }

    func resetAim(_ id: UUID) {
        guard !libraryBusy else { return }
        beginHistoryAction("Reset fixture aim"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }),
              fixtures[index].aimOverride != nil || fixtures[index].jointOverrides != nil else { return }
        cancelPicking()
        let saved = presets.first(where: { $0.id == fixtures[index].presetID })
        fixtures[index].aimOverride = nil
        fixtures[index].jointOverrides = nil
        for joint in fixtures[index].asset?.joints ?? [] where fixtures[index].channels.indices.contains(joint.channel) {
            fixtures[index].channels[joint.channel] = saved.flatMap { $0.channels.indices.contains(joint.channel) ? $0.channels[joint.channel] : nil } ?? (joint.continuous ? 0 : 128)
        }
        previewDraft = false; lastTarget = nil
        revision += 1; persist(); message = saved == nil ? "Returned moving parts to rest." : "Restored the preset's motion values."
    }

    func activatePresetApplication(_ id: UUID) {
        guard isImmersed, canPlace, !libraryBusy, !isPickingRoom, !isTransformDragging,
              tourPreview == nil, presets.contains(where: { $0.id == id }) else { return }
        endPresetDrag()
        presetDrag.activate(presetID: id)
        beginPresetDrag(id)
    }

    @discardableResult func applyProposedPreset() -> Bool {
        guard let session = presetDrag.session, let fixtureID = presetDrag.proposedFixtureID else { return false }
        return finishPresetApplication(presetID: session.presetID, fixtureID: fixtureID)
    }

    @discardableResult func finishPresetApplication(presetID: UUID, fixtureID: UUID) -> Bool {
        let success = applyPreset(presetID, to: fixtureID)
        endPresetDrag()
        presetDrag.showFeedback(presetID: presetID, fixtureID: fixtureID, succeeded: success, message: success ? nil : message)
        return success
    }

    func beginPresetDrag(_ id: UUID) {
        draggingPresetID = id
    }

    func endPresetDrag() {
        draggingPresetID = nil
        presetDrag.cancel()
    }

    func record(_ item: ToolboxItem) { recent.use(item) }

    func remove(_ id: UUID) {
        selectedUnitIDs.remove(id)
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction(touring.active == nil ? "Delete fixture" : "Return fixture to inventory"); defer { endHistoryAction() }
        guard fixtures.contains(where: { $0.id == id }) else { return }
        fixtures.removeAll { $0.id == id }
        cancelPicking(); lastTarget = nil
        recent.remove(.fixture(id))
        if selectedID == id { selectedID = nil; gizmoVisible = false }
        if expandedID == id { expandedID = nil }
        revision += 1
        persist()
    }

    func clearScene() {
        guard !libraryBusy, !fixtures.isEmpty else { return }
        endTransformDrag()
        beginHistoryAction("Clear scene fixtures"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); fixtures = []; selectedID = nil; expandedID = nil; selectedUnitIDs = []; selectedGroupID = nil
        gizmoVisible = false; lastTarget = nil; previewDraft = false; recent = RecentItems()
        revision += 1; persist()
    }

    func sync() async {
        guard !isSyncing else { return }
        recent.use(.sync)
        isSyncing = true
        syncFailed = false
        defer { isSyncing = false }
        // Capture before suspension: edits made during the request stay marked as unsynced.
        let payload = SyncPayload(fixtures: fixtures, revision: revision, environment: environment)
        auditExternal("Mock sync requested · revision \(payload.revision) · \(payload.totalFixtures) fixtures")
        do {
            lastRequestJSON = String(decoding: try payload.jsonData(), as: UTF8.self)
            syncStatus = "Sending \(payload.totalFixtures) fixtures…"
            let receipt = try await client.send(payload, simulateFailure: simulateSyncFailure)
            if environment?.id == payload.environmentID && environment?.version == payload.environmentVersion {
                syncedRevision = receipt.revision
            }
            syncStatus = "HTTP 200 · \(receipt.acceptedFixtures) fixtures · \(receipt.acceptedChannels) channels"
            auditExternal("Mock sync succeeded · revision \(payload.revision) · HTTP 200")
        } catch {
            syncFailed = true
            syncStatus = error.localizedDescription
            auditExternal("Mock sync failed · revision \(payload.revision) · \(error.localizedDescription)")
        }
    }

    func bootstrapLibrary(defaultRoom: EnvironmentManifest, additionalRooms: [EnvironmentManifest] = []) {
        guard rooms.isEmpty else { return }
        bundledRooms = ([defaultRoom] + additionalRooms).map { LibraryRoom(manifest: $0, origin: .bundled) }
        rooms = bundledRooms
        refreshLibrary()
        guard !isDemoMode else { return }
        do {
            if let saved = try AuditHistory<VenueAuditState>.load(from: historyURL) {
                for node in saved.nodes { try node.state.validate() }
                history = saved
                let state = saved.current.state
                rooms = state.rooms; mergeBundledRooms(); savedSetups = state.setups
                if let room = rooms.first(where: { $0.id == state.roomID }) {
                    historyDestination = (saved.cursor, nil)
                    roomRequest = .init(room: room, setup: nil, blank: true)
                }
            }
        } catch {
            historyBlocked = true
            historyMessage = "History could not be read. Existing log preserved; history recording is disabled: \(error.localizedDescription)"
        }
    }

    /// The launch window needs the room/save library before an immersive scene exists.
    func prepareLibrary(repository providedRepository: (any EnvironmentRepository)? = nil) async {
        guard rooms.isEmpty else { return }
        do {
            let repository: any EnvironmentRepository
            if let providedRepository { repository = providedRepository }
            else {
                guard let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("application resources are missing") }
                repository = BundledEnvironmentRepository(directory: resources.appendingPathComponent("Environments"))
            }
            let defaultRoom = try await repository.resolve(id: "img3153-classroom-v1").manifest
            var additional: [EnvironmentManifest] = []
            for id in ["mappedRoom", "the-fortress"] { additional.append(try await repository.resolve(id: id).manifest) }
            bootstrapLibrary(defaultRoom: defaultRoom, additionalRooms: additional)
            // Present the remembered working setup in the launch UI so replacing
            // unsaved work requires the same confirmation as an in-venue switch.
            if let destination = historyDestination, let state = history?.node(destination.id)?.state {
                applyHistoryState(state)
                historyDestination = nil; roomRequest = nil
            }
            if let benchmark = lightingBenchmark, let room = rooms.first(where: { $0.manifest.id == benchmark.roomID }) {
                roomRequest = .init(room: room, setup: nil, blank: true)
            }
        } catch { libraryMessage = "The venue library could not open: \(error.localizedDescription)" }
    }

    var canResumeVenue: Bool { activeRoom != nil || historyDestination != nil }
    func requestNewVenue() {
        guard !libraryBusy else { return }
        venueIntentID = UUID()
        newVenuePresented = true
    }

    /// Async file parsing belongs to the initiating window and selection intent.
    /// Newer choices or a closed source window invalidate it before any writes.
    func beginVenueImport() -> UUID? {
        guard !libraryBusy, !isTransitioning else { return nil }
        venueIntentID = UUID()
        return venueIntentID
    }

    func cancelVenueImport(_ id: UUID) {
        if venueIntentID == id { venueIntentID = UUID() }
    }

    func cancelRequestedRoom(_ id: UUID) {
        guard roomLoadToken == id, roomRequest != nil else { return }
        roomRequest = nil; libraryBusy = false
        canPlace = isImmersed && environment != nil
        roomLoadToken = UUID()
    }

    /// Returns true only after full validation and durable import. The active scene
    /// is unchanged until the caller requests this setup and RealityKit loads it.
    func importVenueSave(_ document: VenueSave, assetChecksum: String, intentID: UUID? = nil) async throws -> (LibraryRoom, VenueSetup) {
        if let intentID, intentID != venueIntentID { throw CancellationError() }
        guard !libraryBusy else { throw EnvironmentError.invalid("wait for the current room to finish loading") }
        if let existing = rooms.first(where: { $0.id == document.room.id }), existing.manifest != document.room.manifest {
            throw EnvironmentError.invalid("different room metadata already uses this room version")
        }
        let prepared = try await VenueSaveWorker.shared.prepareImport(document, assetChecksum: assetChecksum, store: library)
        defer { prepared.discard() }
        try Task.checkCancellation()
        if let intentID, intentID != venueIntentID { throw CancellationError() }
        guard !libraryBusy else { throw EnvironmentError.invalid("wait for the current room to finish loading") }
        if let existing = rooms.first(where: { $0.id == document.room.id }), existing.manifest != document.room.manifest {
            throw EnvironmentError.invalid("different room metadata already uses this room version")
        }
        try prepared.commit()
        let imported = (room: prepared.room, setup: prepared.setup)
        let room = rooms.first(where: { $0.manifest == imported.room.manifest }) ?? imported.room
        beginHistoryAction("Import save · \(imported.setup.name)"); defer { endHistoryAction() }
        if !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
        savedSetups.insert(imported.setup, at: 0)
        libraryMessage = "Imported \(imported.setup.name)."
        return (room, imported.setup)
    }

    func currentSetupSnapshot() throws -> VenueSetup {
        guard let room = activeRoom, !libraryBusy else { throw EnvironmentError.invalid("open a venue before exporting") }
        let snapshot = VenueSetup(id: activeSetupID ?? UUID(), name: setupName.trimmingCharacters(in: .whitespacesAndNewlines), room: room,
                                  fixtures: fixtures, presets: presets, revision: revision, whiteRoom: whiteRoom, houseLight: houseLight, tour: touring.active)
        try snapshot.validate(room: room)
        return snapshot
    }

    private func mergeBundledRooms() {
        for room in bundledRooms where !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
    }

    func refreshLibrary() {
        guard history == nil else { return }
        do {
            let imported = try library.rooms()
            let bundled = rooms.filter { $0.origin == .bundled }
            rooms = bundled + imported.filter { room in !bundled.contains { $0.id == room.id } }
            savedSetups = try library.setups(rooms: rooms)
        } catch { libraryMessage = "Library could not be read: \(error.localizedDescription). Existing files are preserved." }
    }

    func requestRoom(_ room: LibraryRoom, setup: VenueSetup? = nil, blank: Bool = true, configurationID: UUID? = nil) {
        endTransformDrag(); gizmoVisible = false
        guard !libraryBusy else { return }
        flushHistoryEdits()
        do {
            if let setup { try setup.validate(room: room) }
            else if let configurationID, tour?.show.configurations.contains(where: { $0.id == configurationID }) != true { throw PresetError("Choose an available show configuration.") }
        }
        catch { libraryMessage = error.localizedDescription; return }
        // An explicit launch choice supersedes the remembered audit cursor.
        venueIntentID = UUID()
        historyDestination = nil; preparedHistory = nil
        fixtureDragLease?.cancel(); draggingFixture = nil
        endPresetDrag()
        libraryBusy = true; canPlace = false; previewDraft = false; cancelPicking()
        cancelTourPreview()
        roomRequest = .init(room: room, setup: setup, blank: blank, configurationID: configurationID)
        roomLoadToken = UUID()
    }

    @discardableResult func saveSetup(asNew: Bool = false) -> Bool {
        guard let room = activeRoom, !libraryBusy else { return false }
        beginHistoryAction(asNew ? "Save setup as new" : "Save setup"); defer { endHistoryAction() }
        let name = setupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = VenueSetup(id: asNew ? UUID() : (activeSetupID ?? UUID()), name: name, room: room,
                                  fixtures: fixtures, presets: presets, revision: revision, whiteRoom: whiteRoom, houseLight: houseLight, tour: touring.active)
        do {
            try library.save(snapshot, room: room)
            activeSetupID = snapshot.id; savedSetup = snapshot; setupName = name
            savedSetups.removeAll { $0.id == snapshot.id }; savedSetups.insert(snapshot, at: 0)
            libraryMessage = "Saved \(name) · \(fixtures.count) fixtures."
            return true
        } catch { libraryMessage = error.localizedDescription; return false }
    }
}

extension VenueModel {
    var auditState: VenueAuditState? {
        guard let room = activeRoom else { return nil }
        return .init(rooms: rooms, setups: savedSetups, roomID: room.id, fixtures: fixtures, presets: presets,
                     draft: presetDraft, editingPresetID: editingPresetID, setupName: setupName, activeSetupID: activeSetupID,
                     savedSetup: savedSetup, whiteRoom: whiteRoom, houseLight: houseLight, blackout: blackout,
                     selectedID: selectedID, expandedID: expandedID, previewDraft: previewDraft, previewBlackout: previewBlackout, touring: touring, selectedUnitIDs: tour == nil ? nil : selectedUnitIDs, selectedGroupID: selectedGroupID, viewerPose: viewerPose == .init() ? nil : viewerPose)
    }

    private func startHistoryIfNeeded() {
        guard history == nil, !historyBlocked, let state = auditState else { return }
        let initial = AuditHistory(state: state)
        do { try state.validate(); try initial.save(to: historyURL); history = initial }
        catch { historyMessage = "History could not start: \(error.localizedDescription)" }
    }

    /// Nestable transactions keep multi-object operations and slider gestures atomic.
    func beginHistoryAction(_ title: String) {
        if actionDepth == 0 { flushHistoryEdits(); actionTitle = title }
        actionDepth += 1
    }
    func endHistoryAction() {
        guard actionDepth > 0 else { return }
        actionDepth -= 1
        if actionDepth == 0, let state = auditState { recordHistory(actionTitle, state: state) }
    }
    private func queueHistoryEdit(_ title: String) {
        guard history != nil, !historyBlocked, !restoringHistory, actionDepth == 0, !libraryBusy, let state = auditState else { return }
        if let pendingEdit, pendingEdit.title != title { flushHistoryEdits() }
        pendingEdit = (title, state)
        editTask?.cancel()
        editTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            self?.flushHistoryEdits()
        }
    }
    func flushHistoryEdits() {
        editTask?.cancel(); editTask = nil
        guard let edit = pendingEdit else { return }
        pendingEdit = nil
        recordHistory(edit.title, state: edit.state)
    }
    private func recordHistory(_ title: String, state: VenueAuditState) {
        guard !restoringHistory, !historyBlocked, var next = history else { return }
        do {
            try state.validate()
            guard next.record(title, state: state) else { return }
            try next.save(to: historyURL); history = next; historyMessage = nil
            if historyDestination != nil { historyDestination = (next.cursor, nil) }
        } catch { historyMessage = "History save failed: \(error.localizedDescription)" }
    }
    func auditExternal(_ title: String) {
        flushHistoryEdits()
        if history == nil, !touringBlocked, var journal = tourHistory {
            journal.append(title)
            do { if !isDemoMode { try journal.save(to: touringHistoryURL) }; tourHistory = journal }
            catch { message = error.localizedDescription }
            return
        }
        guard !historyBlocked, var next = history else { return }
        next.append(title)
        do { try next.save(to: historyURL); history = next }
        catch { historyMessage = "Audit save failed: \(error.localizedDescription)" }
    }
    func registerRoom(_ room: LibraryRoom) {
        beginHistoryAction("\(room.origin == .scanned ? "Scan" : "Import") room · \(room.manifest.title)")
        defer { endHistoryAction() }
        if !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
    }

    func undo() {
        if history == nil { undoTouring(redo: false); return }
        finishHistoryGesture()
        flushHistoryEdits()
        if let id = history?.undoTarget { restoreHistory(id, kind: .undo) }
    }
    func redo() {
        if history == nil { undoTouring(redo: true); return }
        finishHistoryGesture()
        flushHistoryEdits()
        if let id = history?.redoTarget { restoreHistory(id, kind: .redo) }
    }
    func restoreHistory(_ id: UUID, kind: AuditHistory<VenueAuditState>.Entry.Kind = .jump) {
        guard !libraryBusy, !historyBlocked else { return }
        // Undo/Redo always includes an in-progress edit before choosing its destination.
        finishHistoryGesture()
        flushHistoryEdits()
        guard let state = history?.node(id)?.state, history?.cursor != id,
              let room = state.rooms.first(where: { $0.id == state.roomID }) else { return }
        do {
            try state.validate()
            historyDestination = (id, kind)
            if room.id == activeRoom?.id {
                try prepareHistoryRestore()
                if let preparedHistory { history = preparedHistory }
                self.preparedHistory = nil; historyDestination = nil
                applyHistoryState(state)
            } else {
                libraryBusy = true; canPlace = false
                roomRequest = .init(room: room, setup: nil, blank: true)
                roomLoadToken = UUID()
            }
        } catch { historyRestoreFailed(error.localizedDescription) }
    }

    func finishHistoryGesture() {
        endViewerNavigation()
        endTransformDrag()
        if actionDepth > 0 { actionDepth = 1; endHistoryAction() }
    }

    /// Called after async asset validation but before publishing a replacement scene.
    /// Failure leaves the old renderer and history cursor untouched.
    func prepareHistoryRestore() throws {
        guard preparedHistory == nil, let destination = historyDestination, var next = history else { return }
        if let kind = destination.kind { try next.move(to: destination.id, kind: kind); try next.save(to: historyURL) }
        preparedHistory = next
    }
    func historyRestoreFailed(_ reason: String) {
        if historyDestination != nil { historyMessage = "Could not restore history: \(reason)" }
        historyDestination = nil; preparedHistory = nil; roomRequest = nil; libraryBusy = false
    }
    private func applyHistoryState(_ state: VenueAuditState) {
        touring = state.touring ?? TouringArchive(); selectedUnitIDs = state.selectedUnitIDs ?? []; selectedGroupID = state.selectedGroupID; tourPreview = nil; tourPreviewSession = nil
        restoringHistory = true; message = nil
        defer { restoringHistory = false }
        cancelPicking(); endPresetDrag(); gizmoVisible = false; lastTarget = nil; recent = RecentItems()
        rooms = state.rooms; mergeBundledRooms(); savedSetups = state.setups
        environment = state.rooms.first { $0.id == state.roomID }!.manifest
        fixtures = state.fixtures; presets = state.presets; presetDraft = state.draft; editingPresetID = state.editingPresetID
        setupName = state.setupName; activeSetupID = state.activeSetupID; savedSetup = state.savedSetup
        viewerPose = state.viewerPose ?? .init()
        whiteRoom = state.whiteRoom; houseLight = state.houseLight; blackout = state.blackout
        selectedID = state.selectedID; expandedID = state.expandedID; previewDraft = state.previewDraft; previewBlackout = state.previewBlackout ?? false
        revision += 1; syncedRevision = nil; nextFixtureNumber = fixtures.count+1
        if !isDemoMode, tour == nil, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        persistenceBlocked = false
        if let environment { do { _ = try placements.load(environment: environment) } catch { persistenceBlocked = true } }
        persist()
        environmentStatus = environment!.title
        historyMessage = "Restored · \(history?.current.title ?? "state")"
    }
}

private func isDemoModeDirectory(_ arguments: [String]) -> Bool {
    arguments.contains("--demo") || LightingBenchmark(arguments: arguments) != nil
}

// Touring operations validate a complete candidate before publishing one history state.
extension VenueModel {
    var tour: TourSession? { touring.active }
    var tourUnits: [InventoryUnit] { tour?.activeUnits ?? [] }
    var tourSelection: Set<UUID> { selectedUnitIDs.intersection(tour?.eligibleIDs ?? []) }
    var tourSelectionName: String {
        if let group = tour?.show.groups.first(where: { $0.id == selectedGroupID }) { return group.name }
        if tourSelection.count == 1, let unit = tourUnits.first(where: { tourSelection.contains($0.id) }) { return unit.fixture.name }
        return "\(tourSelection.count) fixtures"
    }
    var availableUnits: [InventoryUnit] {
        let placed = Set(fixtures.map(\.id))
        return tourUnits.filter { !placed.contains($0.id) && !$0.unavailable }
    }
    var sceneFixtures: [Fixture] { tourPreview ?? fixtures }
    private var touringURL: URL { library.directory.appendingPathComponent("touring-shows.json") }
    private var touringHistoryURL: URL { library.directory.appendingPathComponent("touring-history.json") }

    private func loadTouring() {
        guard !isDemoMode else { return }
        do {
            touring = try TouringArchive.load(from: touringURL)
            tourHistory = try AuditHistory<TouringArchive>.load(from: touringHistoryURL)
            // Once venue history exists it restores the authoritative complete state.
            if !FileManager.default.fileExists(atPath: historyURL.path), let tourHistory {
                try tourHistory.current.state.validate(); touring = tourHistory.current.state
            }
            refreshTourPresets()
        } catch { touringBlocked = true; message = "Show library is unreadable and has been preserved: \(error.localizedDescription)" }
    }
    private func persistTouring() {
        guard !isDemoMode, !touringBlocked else { return }
        do { try touring.save(to: touringURL) }
        catch { message = "Show save failed: \(error.localizedDescription)" }
    }
    private func undoTouring(redo: Bool) {
        guard !libraryBusy, !touringBlocked, var journal = tourHistory,
              let target = redo ? journal.redoTarget : journal.undoTarget else { return }
        do {
            try journal.move(to: target, kind: redo ? .redo : .undo)
            try journal.current.state.validate()
            if !isDemoMode { try journal.save(to: touringHistoryURL) }
            tourHistory = journal; touring = journal.current.state; refreshTourPresets(); persistTouring()
            selectedUnitIDs = []; selectedGroupID = nil; cancelTourPreview()
        } catch { message = error.localizedDescription }
    }
    func restoreTouringEvent(_ id: UUID) {
        guard history == nil, !touringBlocked, !libraryBusy, var journal = tourHistory else { return }
        do {
            try journal.move(to: id, kind: .jump); try journal.current.state.validate()
            if !isDemoMode { try journal.save(to: touringHistoryURL) }
            tourHistory = journal; touring = journal.current.state; refreshTourPresets(); persistTouring()
            selectedUnitIDs = []; selectedGroupID = nil; cancelTourPreview()
        } catch { message = error.localizedDescription }
    }
    private func refreshTourPresets() {
        if let tour { presets = tour.presets }
        else if let data = defaults.data(forKey: "venue.presets.v1"), let legacy = try? JSONDecoder().decode([DMXPreset].self, from: data), legacy.allSatisfy({ $0.validationIssue == nil && $0.focusTargetID == nil }) {
            presets = legacy
        } else { presets = LightingPreview.presets }
        if !presets.contains(where: { $0.id == editingPresetID }) { editingPresetID = nil }
    }
    @discardableResult private func commitTour(_ session: TourSession, fixtures updated: [Fixture], title: String, publish: Bool = false) -> Bool {
        guard !libraryBusy, !touringBlocked, !historyBlocked else { message = "Show changes are unavailable while loading or while the saved history is unreadable."; return false }
        do {
            try session.validate(fixtures: updated)
            if let environment { for fixture in updated { if let issue = fixture.placementIssue(in: environment) { throw PresetError(issue) } } }
            var archive = touring; archive.active = session
            if publish, let latest = archive.shows.first(where: { $0.id == session.show.id }), latest.revision >= session.show.revision, latest != session.show {
                throw PresetError("A newer shared revision already exists. Review changes before editing the show.")
            }
            if publish || !archive.shows.contains(where: { $0.id == session.show.id }) {
                archive.shows.removeAll { $0.id == session.show.id }; archive.shows.append(session.show)
            }
            try archive.validate()
            var journal = tourHistory ?? AuditHistory(state: touring)
            if history == nil {
                journal.record(title, state: archive)
                if !isDemoMode { try journal.save(to: touringHistoryURL) }
            }
            beginHistoryAction(title); defer { endHistoryAction() }
            touring = archive; fixtures = updated; tourHistory = journal; refreshTourPresets()
            selectedUnitIDs.formIntersection(session.eligibleIDs)
            if let selectedID, !updated.contains(where: { $0.id == selectedID }) { self.selectedID = nil; expandedID = nil }
            if let selectedGroupID, !session.show.groups.contains(where: { $0.id == selectedGroupID }) { self.selectedGroupID = nil }
            previewDraft = false; revision += 1; message = title; persist()
            return true
        } catch { message = error.localizedDescription; presetMessage = message; return false }
    }
    func createTouringShow(name: String) {
        guard tour == nil || fixtures.isEmpty else { message = "Save and return this show’s placements before creating another show."; return }
        var show = TouringShow(name: name.trimmingCharacters(in: .whitespacesAndNewlines), presets: tour == nil ? presets : LightingPreview.presets)
        show.units = fixtures.map { InventoryUnit(fixture: $0) }
        show.configurations[0].unitIDs = Set(fixtures.map(\.id))
        for fixture in fixtures {
            if let id = fixture.presetID, let preset = presets.first(where: { $0.id == id }) {
                for channel in preset.channelMask { show.programming.units[fixture.id, default: [:]][channel] = id }
            }
        }
        if commitTour(TourSession(show: show), fixtures: fixtures, title: "Create show · \(name)", publish: true) {
            selectedUnitIDs = Set(selectedID.map { [$0] } ?? [])
        }
    }
    func selectTouringShow(_ id: UUID, configuration: UUID? = nil) {
        guard fixtures.isEmpty else { message = "Save this venue and return its fixtures to inventory before switching shows or configurations."; return }
        guard let show = (tour?.show.id == id ? tour?.show : nil) ?? touring.shows.first(where: { $0.id == id }) else { return }
        _ = commitTour(TourSession(show: show, configurationID: configuration), fixtures: [], title: "Choose show · \(show.name)")
    }
    private func editTourShow(_ title: String, change: (inout TourSession) throws -> Void) {
        guard var session = tour else { return }
        do {
            try change(&session); session.show.revision += 1; try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            _ = commitTour(session, fixtures: updated, title: title, publish: true)
        } catch { message = error.localizedDescription }
    }
    func addInventory(_ kind: FixtureKind, quantity: Int, venueOnly: Bool = false, groupID: UUID? = nil) {
        guard var session = tour, (1...64).contains(quantity), session.allUnits.count + quantity <= 256 else { message = "Choose 1–64 units, up to 256 per show."; return }
        for _ in 0..<quantity {
            let count = session.allUnits.filter { $0.fixture.assetID == kind.assetID }.count + 1
            let patch = Fixture.nextAvailablePatch(in: session.allUnits.map(\.fixture), footprint: 16)
            let fixture = Fixture(name: kind.name + String(format: " %02d", count), assetID: kind.assetID,
                                  universe: patch?.universe ?? 1, startAddress: patch?.address ?? 1,
                                  channels: kind.asset?.neutralChannels ?? Array(repeating: 0, count: 16))
            let unit = InventoryUnit(fixture: fixture, groupID: groupID)
            if venueOnly { session.localUnits.append(unit) }
            else {
                session.show.units.append(unit)
                if let i = session.show.configurations.firstIndex(where: { $0.id == session.configurationID }) { session.show.configurations[i].unitIDs.insert(unit.id) }
            }
        }
        if !venueOnly { session.show.revision += 1 }
        if commitTour(session, fixtures: fixtures, title: "Add \(quantity) × \(kind.name) · \(venueOnly ? "venue" : "show")", publish: !venueOnly) { rememberFixtureKind(kind) }
    }
    func addQuantity(name: String, quantity: Int) {
        editTourShow("Add quantity equipment · \(name)") { $0.show.quantities.append(EquipmentQuantity(name: name, quantity: quantity)) }
    }
    func removeQuantity(_ id: UUID) { editTourShow("Remove quantity equipment") { $0.show.quantities.removeAll { $0.id == id } } }
    func renameInventory(_ id: UUID, name: String) {
        guard var session = tour else { return }
        if let i = session.show.units.firstIndex(where: { $0.id == id }) { session.show.units[i].fixture.name = name; session.show.revision += 1 }
        if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].fixture.name = name }
        var updated = fixtures
        if let i = updated.firstIndex(where: { $0.id == id }) { updated[i].name = name }
        _ = commitTour(session, fixtures: updated, title: "Rename equipment", publish: session.show.units.contains { $0.id == id })
    }
    func setUnitUnavailable(_ id: UUID, _ unavailable: Bool) {
        guard fixture(id) == nil else { message = "Return this fixture to inventory first."; return }
        editTourShow("Change equipment availability") { session in
            if let i = session.show.units.firstIndex(where: { $0.id == id }) { session.show.units[i].unavailable = unavailable }
            if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].unavailable = unavailable }
        }
    }
    func excludeInventory(_ id: UUID) {
        guard var session = tour, fixture(id) == nil else { message = "Return the fixture to inventory before excluding it."; return }
        if session.excluded.contains(id) { session.excluded.remove(id) } else { session.excluded.insert(id) }
        _ = commitTour(session, fixtures: fixtures, title: "Change venue equipment inclusion")
    }
    func removeInventory(_ id: UUID) {
        guard var session = tour, let unit = session.allUnits.first(where: { $0.id == id }) else { return }
        let references = fixture(id) != nil || unit.groupID != nil || session.programming.units[id]?.isEmpty == false || session.show.programming.units[id]?.isEmpty == false || session.show.configurations.contains { $0.layout.contains { $0.id == id } }
        guard !references else { message = "Return this unit, ungroup it, and remove its programming/layout dependencies before removing equipment."; return }
        // Saved venues retain their own pinned copy; their historical identities remain intact.
        session.show.units.removeAll { $0.id == id }; session.localUnits.removeAll { $0.id == id }
        for i in session.show.configurations.indices { session.show.configurations[i].unitIDs.remove(id) }
        session.excluded.remove(id); session.programming.units[id] = nil; session.programming.releasedUnits[id] = nil
        session.show.programming.units[id] = nil; session.show.programming.releasedUnits[id] = nil; session.show.revision += 1
        _ = commitTour(session, fixtures: fixtures, title: "Remove equipment · \(unit.fixture.name)", publish: true)
    }
    func saveGroup(id: UUID? = nil, name: String, parentID: UUID?) {
        if let id, var session = tour, let i = session.show.groups.firstIndex(where: { $0.id == id }) {
            session.show.groups[i].name = name; session.show.groups[i].parentID = parentID; session.show.revision += 1
            previewMembership(session, title: "Edit group · \(name)")
        } else {
            editTourShow("Create group · \(name)") { $0.show.groups.append(FixtureGroup(name: name, parentID: parentID)) }
        }
    }
    func previewRemoveGroup(_ id: UUID) {
        guard var session = tour, let group = session.show.groups.first(where: { $0.id == id }) else { return }
        session.show.groups.removeAll { $0.id == id }
        for i in session.show.groups.indices where session.show.groups[i].parentID == id { session.show.groups[i].parentID = group.parentID }
        for i in session.show.units.indices where session.show.units[i].groupID == id { session.show.units[i].groupID = group.parentID }
        for i in session.localUnits.indices where session.localUnits[i].groupID == id { session.localUnits[i].groupID = group.parentID }
        session.programming.groups[id] = nil; session.show.programming.groups[id] = nil; session.show.revision += 1
        previewMembership(session, title: "Remove group · \(group.name); keep equipment")
    }
    func previewMembership(_ session: TourSession, title: String) {
        do {
            try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) }
            try session.validate(fixtures: updated)
            setTourPreview(session, fixtures: updated, title: title, publish: true)
        } catch { message = error.localizedDescription }
    }
    func assignSelectionToGroup(_ group: UUID?) {
        guard var session = tour, !tourSelection.isEmpty else { return }
        for i in session.show.units.indices where tourSelection.contains(session.show.units[i].id) { session.show.units[i].groupID = group }
        for i in session.localUnits.indices where tourSelection.contains(session.localUnits[i].id) { session.localUnits[i].groupID = group }
        session.show.revision += 1
        previewMembership(session, title: "Move \(tourSelection.count) units into \(session.show.groups.first { $0.id == group }?.name ?? "Ungrouped")")
    }
    func selectGroup(_ id: UUID?) {
        guard !libraryBusy, let tour else { return }
        endTransformDrag(); beginHistoryAction("Select fixture group"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); previewDraft = false; gizmoVisible = false
        selectedGroupID = id; selectedUnitIDs = tour.members(of: id)
        selectedID = fixtures.first { selectedUnitIDs.contains($0.id) }?.id; expandedID = nil
    }
    func toggleUnitSelection(_ id: UUID) {
        guard !libraryBusy, tour?.eligibleIDs.contains(id) == true else { return }
        endTransformDrag(); beginHistoryAction("Change inventory selection"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); previewDraft = false; selectedGroupID = nil
        if selectedUnitIDs.contains(id) { selectedUnitIDs.remove(id) } else { selectedUnitIDs.insert(id) }
        selectedID = fixtures.first { selectedUnitIDs.contains($0.id) }?.id; expandedID = nil
    }
    func selectInventory(_ id: UUID) {
        if let unit = tour?.allUnits.first(where: { $0.id == id }) {
            rememberFixtureKind(unit.fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube)
        }
        if multiSelection { toggleUnitSelection(id); return }
        beginHistoryAction("Select inventory unit"); defer { endHistoryAction() }
        deselect(); selectedUnitIDs = [id]; selectedID = fixture(id)?.id
    }
    func beginInventoryPlacement(_ id: UUID, repeatAll: Bool = false) {
        guard canPlace, let unit = availableUnits.first(where: { $0.id == id }) else { message = "This unit is already placed or unavailable."; return }
        cancelTourPreview(); cancelPicking(); gizmoVisible = false
        selectFixtureKind(unit.fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube)
        placementUnitID = id; repeatPlacement = repeatAll
        placementQueue = [id] + (repeatAll ? availableUnits.filter { $0.id != id && $0.fixture.assetID == unit.fixture.assetID }.map(\.id) : [])
        isPlacing = true; message = "Place \(unit.fixture.name) · \(placementQueue.count) remaining"
    }
    func beginInventoryDrag(_ id: UUID) {
        beginInventoryPlacement(id)
        guard placementUnitID == id, isPlacing else { return }
        draggingFixture = fixtureKind
        fixtureDragLease?.cancel()
        fixtureDragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            self?.cancelPicking()
        }
    }
    private func insertInventoryFixture(at base: Position3D, surfaceID: String?) {
        guard let session = tour, fixtures.count < 64,
              let unit = availableUnits.first(where: { placementUnitID == nil ? $0.fixture.assetID == fixtureKind.assetID : $0.id == placementUnitID }) else { message = "No available unit. Add equipment to the show first."; isPlacing = false; return }
        do {
            var fixture = unit.fixture
            fixture.position = .init(x: base.x, y: base.y + (fixture.assetID == nil ? fixtureKind.radius : 0), z: base.z); fixture.surfaceID = surfaceID; fixture.mountPlane = nil
            if fixture.validationIssue(among: fixtures + [fixture]) != nil {
                guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: fixture.channels.count) else { throw PresetError("No free patch is available.") }
                fixture.universe = patch.universe; fixture.startAddress = patch.address
            }
            fixture = try Touring.resolved(fixture, in: session, solveFocus: true)
            guard commitTour(session, fixtures: fixtures + [fixture], title: "Place \(fixture.name)") else { return }
            selectedID = fixture.id; selectedUnitIDs = [fixture.id]; selectedGroupID = nil
            placementQueue.removeAll { $0 == fixture.id }; draggingFixture = nil
            if repeatPlacement, let next = placementQueue.first { placementUnitID = next; message = "Next: \(session.allUnits.first { $0.id == next }?.fixture.name ?? "fixture") · \(placementQueue.count) remaining" }
            else { cancelPicking(); message = "Placed \(fixture.name)" }
        } catch { message = error.localizedDescription }
    }
    @discardableResult func applyTourPreset(_ id: UUID, ids: Set<UUID>? = nil, group: UUID? = nil, allDescendants: Bool = false, preview: Bool = false, toShow: Bool = false) -> Bool {
        guard let session = tour else { return false }
        let chosen = ids ?? tourSelection
        do {
            var (next, updated) = try Touring.applying(id, to: chosen, group: group, replaceDescendants: allDescendants, in: session, fixtures: fixtures)
            if toShow {
                guard let preset = session.show.presets.first(where: { $0.id == id }), session.presetOverrides.first(where: { $0.id == id }) == nil,
                      chosen.isSubset(of: Set(session.show.units.map(\.id))) else { throw PresetError("Shared assignments require a shared preset and show equipment. Save the preset in Shared show scope first.") }
                if let group {
                    let groups = allDescendants ? session.show.groups.filter { session.show.ancestors(of: $0.id).contains(group) }.map(\.id) : [group]
                    for groupID in groups { for channel in preset.channelMask {
                        next.show.programming.groups[groupID, default: [:]][channel] = id
                        next.programming.groups[groupID]?[channel] = nil
                    } }
                    if allDescendants { for unit in chosen { for channel in preset.channelMask {
                        next.show.programming.units[unit]?[channel] = nil; next.programming.units[unit]?[channel] = nil
                        next.programming.releasedUnits[unit]?.remove(channel)
                    } } }
                } else { for unit in chosen { for channel in preset.channelMask {
                    next.show.programming.units[unit, default: [:]][channel] = id; next.programming.units[unit]?[channel] = nil
                    next.programming.releasedUnits[unit]?.remove(channel)
                } } }
                next.show.revision += 1; try next.validate(fixtures: updated)
            }
            let scope = toShow ? "show" : "venue"
            let title = "Apply \(session.presets.first { $0.id == id }?.name ?? "preset") to \(chosen.count) units · \(scope)\(group != nil && !allDescendants ? " · preserve exceptions" : "")"
            if preview { setTourPreview(next, fixtures: updated, title: title, publish: toShow); return true }
            let result = commitTour(next, fixtures: updated, title: title, publish: toShow); endPresetDrag(); return result
        } catch { message = error.localizedDescription; presetMessage = message; return false }
    }
    private func setTourPreview(_ session: TourSession, fixtures: [Fixture], title: String, publish: Bool = false) {
        guard !libraryBusy else { return }
        endTransformDrag(); gizmoVisible = false
        tourPreviewRevision = revision; tourPreviewSource = touring
        tourPreviewSession = session; tourPreview = fixtures; tourPreviewTitle = title; tourPreviewPublishes = publish; previewDraft = false; message = "Preview · \(title)"
    }
    @discardableResult func commitTourPreview() -> Bool {
        guard let session = tourPreviewSession, let updated = tourPreview else { return false }
        guard tourPreviewRevision == revision, tourPreviewSource == touring else { cancelTourPreview(); message = "The scene changed after this preview. Preview again before saving."; return false }
        beginHistoryAction(tourPreviewTitle); defer { endHistoryAction() }
        let savedFocus = focusDraftPresetID
        guard commitTour(session, fixtures: updated, title: tourPreviewTitle, publish: tourPreviewPublishes) else { return false }
        cancelTourPreview(); cancelPicking()
        if let savedFocus, let preset = presets.first(where: { $0.id == savedFocus }) { presetDraft = preset; editingPresetID = preset.id }
        return true
    }
    func cancelTourPreview() {
        tourPreview = nil; tourPreviewSession = nil; tourPreviewTitle = ""; tourPreviewPublishes = false
        tourPreviewSource = nil
        focusPickID = nil; focusBaseSession = nil; focusDraftPresetID = nil; pendingTarget = nil
    }
    func resetTourAssignment(_ ids: Set<UUID>) {
        guard var session = tour else { return }
        for id in ids { session.programming.units[id] = nil; session.programming.releasedUnits[id] = Set(0..<16) }
        do {
            let updated = try fixtures.map { ids.contains($0.id) ? try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) : $0 }
            _ = commitTour(session, fixtures: updated, title: "Reset \(ids.count) units to group defaults")
        } catch { message = error.localizedDescription }
    }
    @discardableResult private func saveTourPreset(asNew: Bool) -> Bool {
        guard var session = tour else { return false }
        beginHistoryAction(asNew ? "Save new touring preset" : "Save touring preset"); defer { endHistoryAction() }
        var preset = presetDraft; preset.name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if asNew { preset.id = UUID() }
        if let issue = preset.validationIssue { presetMessage = issue; return false }
        // Removing a parameter still used by a binding requires a new preset. This
        // avoids silently changing inheritance for existing assignments.
        if let old = session.presets.first(where: { $0.id == preset.id }), !old.channelMask.isSubset(of: preset.channelMask) {
            let bound = [session.programming, session.show.programming].contains { p in
                (Array(p.units.values) + Array(p.groups.values)).contains { bindings in bindings.contains { !preset.channelMask.contains($0.key) && $0.value == preset.id } }
            }
            if bound { presetMessage = "This parameter is assigned. Save as new to change the included parameters."; return false }
        }
        if tourEditShow {
            session.show.presets.removeAll { $0.id == preset.id }; session.show.presets.append(preset)
            session.presetOverrides.removeAll { $0.id == preset.id }; session.show.revision += 1
        } else { session.presetOverrides.removeAll { $0.id == preset.id }; session.presetOverrides.append(preset) }
        do {
            try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            guard commitTour(session, fixtures: updated, title: "Save preset · \(preset.name) · \(tourEditShow ? "show" : "venue")", publish: tourEditShow) else { return false }
            choosePreset(preset); presetMessage = "Saved \(tourEditShow ? "show preset" : "venue override"). Apply to change an assignment."
            return true
        } catch { presetMessage = error.localizedDescription; return false }
    }
    private func deleteTourPreset(_ id: UUID) {
        guard var session = tour else { return }
        let bound = [session.programming, session.show.programming].contains { p in (Array(p.units.values) + Array(p.groups.values)).contains { $0.values.contains(id) } }
        guard !bound else { presetMessage = "Preset is assigned to units or groups. Reassign those parameters before deleting."; return }
        session.presetOverrides.removeAll { $0.id == id }
        let shared = session.show.presets.contains { $0.id == id }
        if shared && !tourEditShow { presetMessage = "Switch scope to Show to remove a shared preset."; return }
        session.show.presets.removeAll { $0.id == id }; if shared { session.show.revision += 1 }
        if commitTour(session, fixtures: fixtures, title: "Delete unused preset", publish: shared) { newPreset() }
    }
    func resetPresetToShow(_ id: UUID) {
        guard var session = tour else { return }
        session.presetOverrides.removeAll { $0.id == id }
        do {
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            if commitTour(session, fixtures: updated, title: "Reset preset to show") { if let preset = presets.first(where: { $0.id == id }) { choosePreset(preset) } }
        } catch { presetMessage = error.localizedDescription }
    }
    func createFocusTarget(name: String) { editTourShow("Create focus target · \(name)") { $0.show.targets.append(FocusTarget(name: name)) } }
    func beginFocusLocation(_ id: UUID) {
        guard canPlace, tour?.show.targets.contains(where: { $0.id == id }) == true else { return }
        cancelPicking(); cancelTourPreview(); gizmoVisible = false; previewDraft = false
        focusPickID = id; focusBaseSession = tour; message = "Look and pinch to preview the target. Save or Cancel in Venue controls."
    }
    private func beginTourTarget(_ preset: DMXPreset, fromDraft: Bool) {
        guard canPlace, var session = tour, !tourSelection.isEmpty else { return }
        var updated = preset
        if updated.validationIssue != nil { presetMessage = updated.validationIssue; return }
        if updated.focusTargetID == nil {
            let target = FocusTarget(name: String((preset.name + " target").prefix(120)))
            session.show.targets.append(target); session.show.revision += 1; updated.focusTargetID = target.id
        }
        updated.includedChannels = Array(updated.channelMask.union([4, 5])).sorted()
        session.presetOverrides.removeAll { $0.id == updated.id }
        if fromDraft && tourEditShow {
            session.show.presets.removeAll { $0.id == updated.id }; session.show.presets.append(updated); session.show.revision += 1
        } else { session.presetOverrides.append(updated) }
        if fromDraft {
            for id in tourSelection { for channel in updated.channelMask { session.programming.units[id, default: [:]][channel] = updated.id } }
        }
        do {
            try session.validate()
            cancelPicking(); cancelTourPreview(); gizmoVisible = false; previewDraft = false
            focusPickID = updated.focusTargetID; focusBaseSession = session; focusDraftPresetID = fromDraft ? updated.id : nil
            tourPreviewPublishes = session.show != tour?.show
            message = "Preview \(updated.name) target. Each assigned fixture solves its own Pan/Tilt."
        } catch { message = error.localizedDescription }
    }
    private func focusBindingChanged(_ fixture: Fixture, in session: TourSession) -> Bool {
        guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let newID = session.binding(for: unit, channel: 4),
              let newTarget = session.presets.first(where: { $0.id == newID })?.focusTargetID else { return false }
        guard let old = tour, let oldUnit = old.allUnits.first(where: { $0.id == fixture.id }), let oldID = old.binding(for: oldUnit, channel: 4) else { return true }
        return oldID != newID || old.presets.first(where: { $0.id == oldID })?.focusTargetID != newTarget
    }
    private func hasLocatedFocus(_ fixture: Fixture, in session: TourSession) -> Bool {
        guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let id = session.binding(for: unit, channel: 4),
              let target = session.presets.first(where: { $0.id == id })?.focusTargetID else { return false }
        return session.targetLocations[target] != nil
    }
    @discardableResult private func previewFocusLocation(_ id: UUID, at point: Position3D) -> Bool {
        guard var session = focusBaseSession ?? tour, [point.x, point.y, point.z].allSatisfy(\.isFinite) else { return false }
        session.targetLocations[id] = point
        do {
            let updated = try fixtures.map { fixture in
                guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let binding = session.binding(for: unit, channel: 4),
                      session.presets.first(where: { $0.id == binding })?.focusTargetID == id else { return fixture }
                return try Touring.resolved(fixture, in: session, solveFocus: true)
            }
            try session.validate(fixtures: updated)
            let publishes = tourPreviewPublishes
            setTourPreview(session, fixtures: updated, title: "Locate \(session.show.targets.first { $0.id == id }?.name ?? "target")", publish: publishes)
            pendingTarget = point; return true
        } catch { tourPreview = nil; tourPreviewSession = nil; pendingTarget = nil; message = error.localizedDescription; return false }
    }
    func refocusSelection() {
        guard let session = tour, !tourSelection.isEmpty else { return }
        do {
            for fixture in fixtures where tourSelection.contains(fixture.id) {
                guard hasLocatedFocus(fixture, in: session) else { throw PresetError("\(fixture.name): assign a focus preset and locate its target first.") }
            }
            let updated = try fixtures.map { tourSelection.contains($0.id) ? try Touring.resolved($0, in: session, solveFocus: true) : $0 }
            setTourPreview(session, fixtures: updated, title: "Refocus \(tourSelection.count) units")
        } catch { message = error.localizedDescription }
    }
    func previewGroupTransform(translation: Position3D, yaw: Float = 0, spacing: Float? = nil, mirror: Bool = false, align: FixtureAxis? = nil) {
        guard let session = tour else { return }
        do {
            let updated = try Touring.transformed(fixtures, ids: tourSelection, translation: translation, yaw: yaw, spacing: spacing, mirror: mirror, align: align)
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Transform \(tourSelection.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    private func validateTourPlacement(_ updated: [Fixture], in session: TourSession) throws {
        try session.validate(fixtures: updated)
        guard let environment else { throw PresetError("Open a venue first.") }
        for fixture in updated { if let issue = fixture.placementIssue(in: environment) { throw PresetError("\(fixture.name): \(issue)") } }
    }
    func previewGroupPlacement(origin: Position3D, spacing: Float) {
        guard let session = tour, let environment, spacing.isFinite, spacing > 0 else { return }
        let units = availableUnits.filter { tourSelection.contains($0.id) }
        guard !units.isEmpty, units.count == tourSelection.count, fixtures.count + units.count <= 64 else { message = "Select unplaced, available units for a row (64 placements maximum)."; return }
        do {
            var updated = fixtures
            for (index, unit) in units.enumerated() {
                var fixture = unit.fixture
                let hit = Position3D(x: origin.x + (Float(index)-Float(units.count-1)/2)*spacing, y: origin.y, z: origin.z)
                let radius = fixture.footprintRadius
                guard let surface = environment.surfaces.first(where: { abs($0.center[1] - hit.y) < 0.15 && $0.fixturePosition(hit: hit, halfSize: radius) != nil }),
                      let center = surface.fixturePosition(hit: hit, halfSize: radius) else { throw PresetError("\(fixture.name): no supported floor or tabletop at these coordinates.") }
                let base = Position3D(x: center.x, y: center.y-radius, z: center.z)
                if let scannedMesh, !scannedMesh.supports(base, radius: radius) { throw PresetError("\(fixture.name): scan more of the supporting surface.") }
                fixture.position = .init(x: base.x, y: base.y + (fixture.assetID == nil ? radius : 0), z: base.z); fixture.surfaceID = surface.id
                if fixture.validationIssue(among: updated + [fixture]) != nil {
                    guard let patch = Fixture.nextAvailablePatch(in: updated, footprint: fixture.channels.count) else { throw PresetError("No free patch.") }
                    fixture.universe = patch.universe; fixture.startAddress = patch.address
                }
                fixture = try Touring.resolved(fixture, in: session, solveFocus: true); updated.append(fixture)
            }
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Place row · \(units.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    func autoPatchSelection() {
        guard let session = tour, !tourSelection.isEmpty else { return }
        var patched = fixtures.filter { !tourSelection.contains($0.id) }
        for var fixture in fixtures where tourSelection.contains(fixture.id) {
            guard let patch = Fixture.nextAvailablePatch(in: patched, footprint: fixture.channels.count) else { message = "No free patch."; return }
            fixture.universe = patch.universe; fixture.startAddress = patch.address; patched.append(fixture)
        }
        let updated = fixtures.map { fixture in patched.first { $0.id == fixture.id }! }
        setTourPreview(session, fixtures: updated, title: "Auto-patch \(tourSelection.count) fixtures")
    }
    func saveConfiguration(name: String, selectionOnly: Bool) {
        editTourShow("Save configuration · \(name)") { session in
            let ids = selectionOnly ? tourSelection.intersection(session.show.units.map(\.id)) : Set(session.show.units.map(\.id))
            var configuration = TourConfiguration(name: name, unitIDs: ids)
            configuration.layout = fixtures.filter { ids.contains($0.id) }
            session.show.configurations.append(configuration)
        }
    }
    func previewConfigurationLayout(translation: Position3D, yaw: Float) {
        guard let session = tour, let layout = session.configuration?.layout, !layout.isEmpty else { message = "Save a configuration with a placed layout first."; return }
        guard fixtures.isEmpty else { message = "Return the current placements before adapting a saved layout."; return }
        do {
            let included = layout.filter { session.eligibleIDs.contains($0.id) }
            let moved = try Touring.transformed(included, ids: Set(included.map(\.id)), translation: translation, yaw: yaw)
            let updated = try moved.map { try Touring.resolved($0, in: session) }
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Adapt saved configuration layout · \(updated.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    var availableShowUpdate: TouringShow? {
        guard let session = tour else { return nil }
        return touring.shows.first { $0.id == session.show.id && $0.revision > session.show.revision }
    }
    var showUpdateChanges: [String] {
        guard let previous = tour?.show, let latest = availableShowUpdate else { return [] }
        var changes: [String] = []
        for unit in previous.units {
            if let updated = latest.units.first(where: { $0.id == unit.id }) {
                if updated != unit { changes.append("Update equipment · \(unit.fixture.name)") }
            } else { changes.append("Remove equipment · \(unit.fixture.name)") }
        }
        for unit in latest.units where !previous.units.contains(where: { $0.id == unit.id }) { changes.append("Add equipment · \(unit.fixture.name)") }
        for preset in previous.presets {
            if let updated = latest.presets.first(where: { $0.id == preset.id }) {
                if updated != preset { changes.append("Update preset · \(preset.name)") }
            } else { changes.append("Remove preset · \(preset.name)") }
        }
        for preset in latest.presets where !previous.presets.contains(where: { $0.id == preset.id }) { changes.append("Add preset · \(preset.name)") }
        if previous.groups != latest.groups { changes.append("Group hierarchy or names changed") }
        if previous.programming != latest.programming { changes.append("Shared programming changed; venue overrides retain priority") }
        if previous.configurations != latest.configurations { changes.append("Configurations or layouts changed") }
        if previous.targets != latest.targets { changes.append("Focus target definitions changed") }
        if previous.quantities != latest.quantities { changes.append("Quantity equipment changed") }
        if previous.name != latest.name { changes.append("Rename show · \(latest.name)") }
        return changes
    }
    func previewShowUpdate() {
        guard var session = tour, let latest = availableShowUpdate else { return }
        session.show = latest
        do {
            try session.validate(fixtures: fixtures)
            let updated = try fixtures.map { try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) }
            setTourPreview(session, fixtures: updated, title: "Adopt show revision \(latest.revision) · \(latest.units.count) units, \(latest.groups.count) groups, \(latest.presets.count) presets")
        } catch { message = "Update blocked; pinned version retained. \(error.localizedDescription)" }
    }
    func importTouringShow(_ data: Data) {
        do {
            guard data.count < 20_000_000 else { throw PresetError("Show import is too large.") }
            let show = try JSONDecoder().decode(TouringShow.self, from: data); try show.validate()
            if let existing = touring.shows.first(where: { $0.id == show.id }), existing.revision >= show.revision, existing != show { throw PresetError("This show identity already has an equal or newer revision. Export a newer revision from its source.") }
            var archive = touring; archive.shows.removeAll { $0.id == show.id }; archive.shows.append(show); try archive.validate()
            var journal = tourHistory ?? AuditHistory(state: touring)
            if history == nil { journal.record("Import show · \(show.name)", state: archive); if !isDemoMode { try journal.save(to: touringHistoryURL) } }
            beginHistoryAction("Import show · \(show.name)"); defer { endHistoryAction() }
            touring = archive; tourHistory = journal; persistTouring(); message = "Imported \(show.name). Active venues keep their pinned revision until Review changes."
        } catch { message = "Import failed; current show preserved. \(error.localizedDescription)" }
    }
}
