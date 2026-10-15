import Foundation
import Observation
import VenueVolumeCore

enum ScenePick: Equatable { case move(UUID), aim(UUID) }
enum TargetPresetSource { case saved(UUID), draft(UUID), cueDraft(UUID) }
enum FixtureTransformMode: String, CaseIterable, Identifiable { case move = "Move", rotate = "Rotate"; var id: String { rawValue } }
struct FixtureTransformDrag {
    var fixture: Fixture
    var members: [Fixture]
    var axis: FixtureAxis
    var mode: FixtureTransformMode
    var start: SIMD3<Float>
    var lastAngle: Float?
    var totalAngle: Float = 0
    var pivot: Position3D?
}
struct FixtureSurfaceDrag {
    var fixture: Fixture
    var plane: FixtureMountPlane
    var members: [Fixture]
    var start: SIMD3<Float>
}
struct RoomRequest { var room: LibraryRoom; var setup: VenueSetup?; var blank: Bool; var configurationID: UUID? = nil }

@MainActor @Observable
final class VenueModel {
    var history: AuditHistory<VenueAuditState>?
    var historyMessage: String?
    var historyBlocked = false
    var restoringHistory = false
    var actionDepth = 0
    var actionTitle = "Edit"
    var pendingEdit: (title: String, state: VenueAuditState)?
    var editTask: Task<Void, Never>?
    var historyDestination: (id: UUID, kind: AuditHistory<VenueAuditState>.Entry.Kind?)?
    var preparedHistory: AuditHistory<VenueAuditState>?
    var canUndo: Bool { if history == nil { return !libraryBusy && !touringBlocked && tourHistory?.undoTarget != nil }; return !libraryBusy && !historyBlocked && (pendingEdit != nil || history?.undoTarget != nil || (actionDepth > 0 && auditState != history?.current.state)) }
    var canRedo: Bool { if history == nil { return !libraryBusy && !touringBlocked && tourHistory?.redoTarget != nil }; return !libraryBusy && !historyBlocked && pendingEdit == nil && history?.redoTarget != nil }
    var historyURL: URL { library.directory.appendingPathComponent("audit-history.json") }
    let library: RoomLibraryStore
    var rooms: [LibraryRoom] = []
    var savedSetups: [VenueSetup] = []
    var pendingFixturePlacement: PendingFixturePlacement?
    var placementLinkMessage: String?
    var roomRequest: RoomRequest?
    var roomLoadToken = UUID()
    var venueIntentID = UUID()
    var libraryMessage: String?
    var libraryBusy = false
    var newVenuePresented = false
    let presetEditor = PresetEditorPresentation()
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
    var tourPreviewCueSheet: CueSheet?
    var tourPreviewTitle = ""
    var focusPickID: UUID?
    var touringPanelPresented = false
    var tourPreviewPublishes = false
    var tourPreviewRevision = 0
    var tourPreviewSource: TouringArchive?
    var focusBaseSession: TourSession?
    var focusDraftPresetID: UUID?
    /// Keep the compact overflow reachable even without a fixture selection.
    var contextBarVisible: Bool {
        isImmersed && !palmMapVisible
    }
    var contextBarHasSelection: Bool { !selectedFixtureIDs.isEmpty || focusPickID != nil }
    var setupName = "Untitled setup" { didSet { queueHistoryEdit("Rename setup") } }
    var activeSetupID: UUID?
    var savedSetup: VenueSetup?
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
    var draggingFixture: FixtureKind?
    var activeRoom: LibraryRoom? { rooms.first { $0.manifest.id == environment?.id && $0.manifest.version == environment?.version } }
    var hasUnsavedSetup: Bool {
        if let savedSetup, (savedSetup.cues ?? CueSheet()) != cueSheet { return true }
        if let savedSetup, savedSetup.tour != touring.active { return true }
        guard let savedSetup else {
            if let tour, tour != TourSession(show: tour.show, configurationID: tour.configurationID) { return true }
            guard let activeRoom else { return !fixtures.isEmpty }
            return !fixtures.isEmpty || setupName != "Untitled setup" || houseLight != 0.15 || whiteRoom != (activeRoom.manifest.id != "mappedRoom" && activeRoom.manifest.id != "the-fortress")
        }
        let assignedPresets = touring.active == nil ? PaletteLibrary.dependencies(for: fixtures, in: presets) : presets
        return fixtures != savedSetup.placements.fixtures || assignedPresets != savedSetup.presets || setupName != savedSetup.name || whiteRoom != savedSetup.whiteRoom || houseLight != savedSetup.houseLight
    }
    var fixtures: [Fixture] = []
    var selectedID: UUID?
    var groupActionActive = false
    var multiSelectionMode = false
    var additionalSelection: Set<UUID> = []
    var selectedFixtureIDs: Set<UUID> {
        if tour != nil { return tourSelection.intersection(Set(fixtures.map(\.id))) }
        var ids = additionalSelection
        if let selectedID { ids.insert(selectedID) }
        let groups = Set(fixtures.filter { ids.contains($0.id) }.compactMap(\.groupID))
        ids.formUnion(fixtures.filter { $0.groupID.map(groups.contains) ?? false }.map(\.id))
        return ids.intersection(Set(fixtures.map(\.id)))
    }
    var selectedFixtures: [Fixture] { fixtures.filter { selectedFixtureIDs.contains($0.id) } }
    var fixtureGroups: [UUID] { Array(Set(fixtures.compactMap(\.groupID))).sorted { $0.uuidString < $1.uuidString } }
    func actionIDs(for id: UUID) -> Set<UUID> {
        if selectedFixtureIDs.contains(id) { return selectedFixtureIDs }
        guard let group = fixture(id)?.groupID else { return [id] }
        return Set(fixtures.filter { $0.groupID == group }.map(\.id))
    }
    @discardableResult func groupSelection(name: String = "Group") -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 120, !libraryBusy else { return false }
        if var session = tour {
            let ids = tourSelection
            guard ids.count > 1 else { return false }
            let group = FixtureGroup(name: name)
            // Preserve the existing effective palette layers when moving between groups.
            for unit in session.allUnits where ids.contains(unit.id) {
                for channel in unit.fixture.channels.indices {
                    if let palette = session.binding(for: unit, channel: channel) {
                        session.programming.units[unit.id, default: [:]][channel] = palette
                    }
                }
            }
            session.show.groups.append(group)
            for i in session.show.units.indices where ids.contains(session.show.units[i].id) { session.show.units[i].groupID = group.id }
            for i in session.localUnits.indices where ids.contains(session.localUnits[i].id) { session.localUnits[i].groupID = group.id }
            session.show.revision += 1
            do {
                let updated = try fixtures.map { try Touring.resolved($0, in: session) }
                beginHistoryAction("Group fixtures · \(name)"); defer { endHistoryAction() }
                guard commitTour(session, fixtures: updated, title: "Group fixtures · \(name)", publish: true) else { return false }
                selectedGroupID = group.id; selectedUnitIDs = ids; multiSelection = false
                return true
            } catch { message = error.localizedDescription; return false }
        }
        guard selectedFixtureIDs.count > 1 else { return false }
        beginHistoryAction("Group fixtures · \(name)"); defer { endHistoryAction() }
        let ids = selectedFixtureIDs, group = UUID()
        for i in fixtures.indices where ids.contains(fixtures[i].id) { fixtures[i].groupID = group; fixtures[i].groupName = name }
        additionalSelection = []; multiSelectionMode = false; revision += 1; persist()
        return true
    }
    func ungroup(_ group: UUID) {
        beginHistoryAction("Ungroup fixtures"); defer { endHistoryAction() }
        for i in fixtures.indices where fixtures[i].groupID == group { fixtures[i].groupID = nil; fixtures[i].groupName = nil }
        additionalSelection = []; revision += 1; persist()
    }
    private var toolboxAttention = PalmMapToggle()
    /// Both sides of the left wrist recall the same selection toolbox. The map
    /// is now explicitly opened from Room placement in the context menu.
    func updateHandToolboxActivation(attended: Bool, now: Double) {
        let wasVisible = toolboxAttention.isVisible
        guard isImmersed, canPlace, !libraryBusy, !navigationBlackoutActive else {
            toolboxAttention = PalmMapToggle()
            return
        }
        let revealed = toolboxAttention.update(attended: attended, now: now)
        if revealed && !wasVisible {
            requestToolbox()
        }
    }
    private(set) var palmMapRequestID: UUID?
    var palmMapVisible: Bool { palmMapRequestID != nil }
    func togglePalmMap() {
        if palmMapVisible { closePalmMap(); return }
        guard isImmersed, canPlace, !libraryBusy, !navigationBlackoutActive else { return }
        palmMapRequestID = UUID()
    }
    func closePalmMap() { palmMapRequestID = nil }
    var navigationBlackoutActive = false
    var navigationFadeMilliseconds: Double = 333 {
        didSet { defaults.set(navigationFadeMilliseconds, forKey: "venue.navigationFadeMilliseconds") }
    }
    var presets: [DMXPreset] = PaletteLibrary.baseline
    var recent = RecentItems()
    var presetDraft = DMXPreset(name: "New palette") { didSet { programmerDidChange(from: oldValue); queueHistoryEdit("Edit palette draft") } }
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

    func requestToolbox() { closePalmMap(); toolboxTab = 0; toolboxRequestID = UUID() }
    func resetToolboxActivation() {
        toolboxAttention = PalmMapToggle()
        toolboxRequestID = nil
    }
    var needsManualToolbox = false
    var handTrackingStatus = "Left index: move · left middle: rotate · double pinch: reset"
    var viewerPose = ViewerNavigationPose()
    var navigationInputReserved = false
    @ObservationIgnored var leftUIReservedUntil: Double = 0
    func reserveLeftHandInput() {
        leftUIReservedUntil = ProcessInfo.processInfo.systemUptime+0.35
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(360))
            if let self, !self.viewerNavigationActive, ProcessInfo.processInfo.systemUptime >= self.leftUIReservedUntil { self.navigationInputReserved = false }
        }
    }
    private(set) var viewerNavigationActive = false
    var viewerResetToken = UUID()
    func beginViewerNavigation(_ finger: NavigationFinger) {
        guard !viewerNavigationActive, !libraryBusy else { return }
        finishHistoryGesture()
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
    var fixtureDragLease: Task<Void, Never>?
    var palettePlayback = PalettePlayback(now: ProcessInfo.processInfo.systemUptime)
    var cueSheets: [String: CueSheet] = [:]
    var loadingProgrammer = false
    var programmerEdited = false
    var programmerSelection = Set<UUID>()
    var programmerCue = 1
    let defaults: UserDefaults
    let arguments: [String]
    var previewDraft = false { didSet { queueHistoryEdit("Change draft preview") } }
    var previewBlackout = false { didSet { queueHistoryEdit("Change palette simulation blackout") } }
    var toolboxBlackout: Bool { blackout || (previewDraft && previewBlackout && selectedID != nil) }
    var targetPresetSource: TargetPresetSource?
    var paletteDraftTarget: Position3D?
    var blackout = false { didSet { queueHistoryEdit("Change blackout") } }
    var houseLight: Float = 0.15 { didSet { queueHistoryEdit("Adjust room light") } }
    var whiteRoom = true { didSet { queueHistoryEdit("Change room materials") } }
    var requestedLightLimit = 8
    var supportsExtendedLights = false
    var lightingThermal = LightingBudget.Thermal.nominal
    var effectiveLightLimit: Int {
        LightingBudget.effective(requested: requestedLightLimit, extendedHardware: supportsExtendedLights, thermal: lightingThermal)
    }
    var bundledRooms: [LibraryRoom] = []
    var scenePick: ScenePick?
    var lastTarget: Position3D?
    var pendingTarget: Position3D?
    var targetPreview: Fixture?
    var canSaveTarget: Bool { focusPickID != nil ? tourPreviewSession != nil : isRetargeting && targetPreview != nil && pendingTarget != nil }
    var gizmoVisible = false
    var transformMode = FixtureTransformMode.rotate
    var transformDrag: FixtureTransformDrag?
    var surfaceDrag: FixtureSurfaceDrag?
    var activeTransformAxis: FixtureAxis? { transformDrag?.axis }
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
        case nil: "Move the box onto a clear floor or tabletop, then pinch to place there."
        }
    }
    var programmingMacros: [ProgrammingMacro] = ProgrammingMacro.starters
    var macroMessage: String?
    var macrosPresented = false
    var macroSeed: ProgrammingMacro?
    var recentPhaserSteps: [PhaserStep] = []
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

    var isImmersed = false { didSet { if !isImmersed { closePalmMap() } } }
    var isTransitioning = false
    private(set) var placementSessionID = UUID()
    var isPlacing = false {
        didSet { if oldValue != isPlacing { placementSessionID = UUID() } }
    }
    var trackingStatus = "Starting spatial tracking…"
    var canPlace = false {
        didSet {
            if oldValue && !canPlace { placementSessionID = UUID() }
            if !canPlace { closePalmMap() }
        }
    }
    var environment: EnvironmentManifest?
    var environmentStatus = "Loading classroom…"
    private(set) var persistenceStatus = "Placements save on this device"
    var persistenceBlocked = false
    let placements: PlacementStore
    var message: String?
    var revision = 0
    let isDemoMode: Bool
    var nextFixtureNumber = 1
    private var didRequestDemoSpace = false

    init(arguments: [String] = ProcessInfo.processInfo.arguments, defaults: UserDefaults = .standard, placementDirectory: URL? = nil) {
        self.defaults = defaults
        self.arguments = arguments
        if let duration = defaults.object(forKey: "venue.navigationFadeMilliseconds") as? Double, duration.isFinite { navigationFadeMilliseconds = min(2000, max(0, duration)) }
        placements = PlacementStore(directory: placementDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VenueVolume/Placements"))
        library = RoomLibraryStore(directory: placements.directory.appendingPathComponent(isDemoModeDirectory(arguments) ? "DemoLibrary" : "Library"))
        isDemoMode = isDemoModeDirectory(arguments)
        if !isDemoMode, let data = defaults.data(forKey: "venue.programming-macros.v1"),
           let saved = try? JSONDecoder().decode([ProgrammingMacro].self, from: data) {
            programmingMacros = saved
        }
        var seenKinds = Set<FixtureKind>()
        recentFixtureKinds = Array((defaults.stringArray(forKey: "venue.fixture-recents.v1") ?? []).compactMap(FixtureKind.init(rawValue:)).filter { seenKinds.insert($0).inserted }.prefix(6))
        if !isDemoMode {
            do {
                try PaletteReleaseReset.run(placements: placements.directory, library: library.directory, defaults: defaults)
                if let data = defaults.data(forKey: "venue.presets.v1"),
                   let saved = try? JSONDecoder().decode([DMXPreset].self, from: data),
                   saved.allSatisfy({ $0.validationIssue == nil }), Set(saved.map(\.id)).count == saved.count {
                    presets = saved
                }
            } catch {
                persistenceBlocked = true; historyBlocked = true; touringBlocked = true
                message = "Could not reset incompatible saves: \(error.localizedDescription)"
                return
            }
        }
        loadTouring()
        if let first = presets.first { presetDraft = first; editingPresetID = first.id }
        guard isDemoMode else { return }

    }

    func activate(environment: EnvironmentManifest) {
        closePalmMap()
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

        beginHistoryAction(roomRequest?.setup.map { "Load setup · \($0.name)" } ?? "Open blank room · \(environment.title)")
        defer { endHistoryAction(); startHistoryIfNeeded() }
        if let request = roomRequest {
            guard request.room.manifest == environment else { return }
            viewerPose = .init()
            let preserveDirtyDraft = draftHasChanges
            self.environment = environment
            additionalSelection = []
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
                        if let equivalent = presets.first(where: { candidate in
                            var normalized = candidate
                            normalized.id = original.id
                            return normalized == original
                        }) { copy = equivalent }
                        else { copy.id = UUID(); presets.append(copy) }
                        for i in fixtures.indices {
                            if fixtures[i].presetID == original.id { fixtures[i].presetID = copy.id }
                            if let owners = fixtures[i].channelPaletteIDs {
                                fixtures[i].channelPaletteIDs = owners.mapValues { $0 == original.id ? copy.id : $0 }
                            }
                        }
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
            if let setup = request.setup { cueSheets[cueScope] = setup.cues }
            else if request.blank { cueSheets[cueScope] = nil }
            revision += 1; activeSetupID = request.setup?.id
            setupName = request.setup?.name ?? "Untitled setup"
            savedSetup = request.setup.map { setup in
                var copy = setup; copy.placements = .init(environment: environment, fixtures: fixtures, revision: revision)
                copy.presets = touring.active == nil ? PaletteLibrary.dependencies(for: fixtures, in: presets) : presets; return copy
            }
            roomRequest = nil; libraryBusy = false
            selectedGroupID = nil; selectedUnitIDs = []; tourPreview = nil
            cancelPicking(); selectedID = fixtures.first?.id; selectedUnitIDs = tour == nil ? [] : Set(selectedID.map { [$0] } ?? []); lastTarget = nil
            previewDraft = false; blackout = false; recent = RecentItems(); draggingFixture = nil
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
        fixtures = []
        revision = 0
        persistenceBlocked = false
        if isDemoMode {
            let look = arguments.contains("--blue") ? presets[1] : presets[0]
            fixtures = [Fixture(presetID: look.id, name: "Rogue R1X 01", assetID: LightingPreview.assetID,
                                channels: look.channels, position: .init(x: 4.04, y: 0.74, z: -3.68), surfaceID: "table-r2-c2-top")]
            selectedID = fixtures[0].id
            presetDraft = look; editingPresetID = look.id
            blackout = arguments.contains("--blackout")
            if arguments.contains("--aim-left") { fixtures[0].channels[4] = 155 }
            if arguments.contains("--fixture-near") { fixtures[0].position = .init(x: 2.66, y: 0, z: -2.3); fixtures[0].surfaceID = "floor" }
            if arguments.contains("--rooms-tab") { toolboxTab = 1 }
            if arguments.contains("--scene-overview") { selectedID = nil }
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

    func persist() {
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
        additionalSelection = []
        isPlacing = true
        draggingFixture = nil
        revision += 1
        persist()
    }

    func select(_ id: UUID, extendSelection: Bool = true) {
        guard !libraryBusy else { return }
        guard savePendingCueEdits() else { return }
        defer { refreshPaletteSelection() }
        endTransformDrag()
        beginHistoryAction("Select fixture"); defer { endHistoryAction() }
        guard fixture(id) != nil else { return }
        if extendSelection, multiSelection, touring.active != nil { toggleUnitSelection(id); return }
        cancelTourPreview(); selectedUnitIDs = [id]; selectedGroupID = nil
        if selectedID != id { lastTarget = nil }
        if extendSelection && multiSelectionMode {
            if selectedFixtureIDs.contains(id) {
                let removed: Set<UUID> = fixture(id)?.groupID.map { group in Set(fixtures.filter { $0.groupID == group }.map(\.id)) } ?? [id]
                additionalSelection.subtract(removed)
                if let selectedID, removed.contains(selectedID) { self.selectedID = additionalSelection.first }
                return
            }
            if let selectedID { additionalSelection.insert(selectedID) }
            additionalSelection.insert(id)
        } else if !selectedFixtureIDs.contains(id) { additionalSelection = [] }
        cancelPicking()
        selectedID = id
        toolboxTab = 0
        recent.use(.fixture(id))
        if let fixture = fixture(id) { rememberFixtureKind(fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube) }
        isPlacing = false
    }

    func focusSelection(_ id: UUID) {
        let multiple = multiSelectionMode
        multiSelectionMode = false
        select(id, extendSelection: false)
        multiSelectionMode = multiple
    }

    func deselect() {
        guard savePendingCueEdits() else { return }
        defer { refreshPaletteSelection() }
        cancelTourPreview(); selectedUnitIDs = []; selectedGroupID = nil
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction("Deselect fixture"); defer { endHistoryAction() }
        cancelPicking(); selectedID = nil; additionalSelection = []; lastTarget = nil
        gizmoVisible = false; previewDraft = false
    }

    func beginPlacement() {
        rememberFixtureKind(fixtureKind)
        endTransformDrag(); gizmoVisible = false
        targetPreview = nil; pendingTarget = nil
        scenePick = nil
        isPlacing.toggle()
        message = nil
        recent.use(.addFixture)
    }

    func beginFixtureDrag(_ kind: FixtureKind) {
        endTransformDrag(); gizmoVisible = false; cancelPicking()
        selectFixtureKind(kind); draggingFixture = kind; isPlacing = true; scenePick = nil
        fixtureDragLease?.cancel()
        fixtureDragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            self?.draggingFixture = nil
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

    func record(_ item: ToolboxItem) { recent.use(item) }

    func remove(_ id: UUID) {
        selectedUnitIDs.remove(id)
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction(touring.active == nil ? "Delete fixture" : "Return fixture to inventory"); defer { endHistoryAction() }
        guard fixtures.contains(where: { $0.id == id }) else { return }
        let ids = actionIDs(for: id)
        fixtures.removeAll { ids.contains($0.id) }
        additionalSelection.subtract(ids)
        cancelPicking(); lastTarget = nil
        recent.remove(.fixture(id))
        if let selectedID, ids.contains(selectedID) { self.selectedID = nil; gizmoVisible = false }
        revision += 1
        persist()
    }

    func clearScene() {
        guard !libraryBusy, !fixtures.isEmpty else { return }
        endTransformDrag()
        beginHistoryAction("Clear scene fixtures"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); fixtures = []; additionalSelection = []; selectedID = nil; selectedUnitIDs = []; selectedGroupID = nil
        gizmoVisible = false; lastTarget = nil; previewDraft = false; recent = RecentItems()
        revision += 1; persist()
    }




}
