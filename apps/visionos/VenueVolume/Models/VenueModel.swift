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
}
struct RoomRequest { var room: LibraryRoom; var setup: VenueSetup?; var blank: Bool }

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
    var canUndo: Bool { !libraryBusy && !historyBlocked && (pendingEdit != nil || history?.undoTarget != nil || (actionDepth > 0 && auditState != history?.current.state)) }
    var canRedo: Bool { !libraryBusy && !historyBlocked && pendingEdit == nil && history?.redoTarget != nil }
    private var historyURL: URL { library.directory.appendingPathComponent("audit-history.json") }
    let library: RoomLibraryStore
    private(set) var rooms: [LibraryRoom] = []
    private(set) var savedSetups: [VenueSetup] = []
    var roomRequest: RoomRequest?
    var roomLoadToken = UUID()
    var libraryMessage: String?
    var libraryBusy = false
    var toolboxTab = 0
    var setupName = "Untitled setup" { didSet { queueHistoryEdit("Rename setup") } }
    private(set) var activeSetupID: UUID?
    private var savedSetup: VenueSetup?
    var scannedMesh: ScannedMesh?
    var fixtureKind = FixtureKind.movingHead
    var draggingFixture: FixtureKind?
    var activeRoom: LibraryRoom? { rooms.first { $0.manifest.id == environment?.id && $0.manifest.version == environment?.version } }
    var hasUnsavedSetup: Bool {
        guard let savedSetup else { return !fixtures.isEmpty }
        return fixtures != savedSetup.placements.fixtures || setupName != savedSetup.name || whiteRoom != savedSetup.whiteRoom || houseLight != savedSetup.houseLight
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
    private(set) var toolboxRequestID: UUID?
    private var palmActivationHeld = false

    /// A raised palm requests a window once; lowering the hand never closes it.
    func updateToolboxActivation(raised: Bool) {
        if raised && !palmActivationHeld { requestToolbox() }
        palmActivationHeld = raised
    }

    func requestToolbox() { toolboxRequestID = UUID() }
    func resetToolboxActivation() { palmActivationHeld = false }
    var simulatedPalm = true
    var needsManualToolbox = false
    var handTrackingStatus = "Raise your left palm toward you"
    private(set) var draggingPresetID: UUID?
    private var dragLease: Task<Void, Never>?
    private let defaults: UserDefaults
    private let arguments: [String]
    var previewDraft = false { didSet { queueHistoryEdit("Change draft preview") } }
    var previewBlackout = false { didSet { queueHistoryEdit("Change preset simulation blackout") } }
    var toolboxBlackout: Bool { blackout || (previewDraft && previewBlackout && selectedID != nil) }
    private var targetPresetSource: TargetPresetSource?
    var blackout = false { didSet { queueHistoryEdit("Change blackout") } }
    var houseLight: Float = 0.15 { didSet { queueHistoryEdit("Adjust room light") } }
    var whiteRoom = true { didSet { queueHistoryEdit("Change room materials") } }
    var scenePick: ScenePick?
    var lastTarget: Position3D?
    private(set) var pendingTarget: Position3D?
    private(set) var targetPreview: Fixture?
    var canSaveTarget: Bool { isRetargeting && targetPreview != nil && pendingTarget != nil }
    var gizmoVisible = false
    var transformMode = FixtureTransformMode.rotate
    private var transformDrag: FixtureTransformDrag?
    var isTransformDragging: Bool { transformDrag != nil }
    var isRetargeting: Bool { if case .aim = scenePick { true } else { false } }
    var isPickingRoom: Bool { isPlacing || scenePick != nil }
    var pickingInstruction: String {
        switch scenePick {
        case .move: "Look at a clear floor or tabletop, then pinch to reposition."
        case .aim: "Look and click to preview DMX aim. Hold and move your hand to adjust. Save updates this preset and its assigned fixtures; Cancel restores."
        case nil: "Look at a clear floor or tabletop, then pinch to place."
        }
    }
    var controlsTab = 0
    var presetWindowVisible = false
    var fixtureAssetStatus = "Loading fixture asset…"

    var draftHasChanges: Bool {
        guard let saved = presets.first(where: { $0.id == editingPresetID }) else { return true }
        return presetDraft != saved
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
        placements = PlacementStore(directory: placementDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VenueVolume/Placements"))
        library = RoomLibraryStore(directory: placements.directory.appendingPathComponent(isDemoModeDirectory(arguments) ? "DemoLibrary" : "Library"))
        isDemoMode = arguments.contains("--demo")
        if !isDemoMode, let data = defaults.data(forKey: "venue.presets.v1"),
           let saved = try? JSONDecoder().decode([DMXPreset].self, from: data),
           saved.allSatisfy({ $0.validationIssue == nil }), Set(saved.map(\.id)).count == saved.count {
            presets = saved
        }
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
        beginHistoryAction(roomRequest?.setup.map { "Load setup · \($0.name)" } ?? "Open blank room · \(environment.title)")
        defer { endHistoryAction(); startHistoryIfNeeded() }
        if let request = roomRequest {
            guard request.room.manifest == environment else { return }
            self.environment = environment
            fixtures = request.setup?.placements.fixtures ?? []
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
                if !isDemoMode, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
                whiteRoom = setup.whiteRoom; houseLight = setup.houseLight
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
                copy.presets = presets.filter { preset in fixtures.contains { $0.presetID == preset.id } }; return copy
            }
            roomRequest = nil; libraryBusy = false
            cancelPicking(); selectedID = fixtures.first?.id; expandedID = nil; lastTarget = nil
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
                if let saved = try placements.load(environment: environment) {
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
        beginHistoryAction("Place \(fixtureKind.name)"); defer { endHistoryAction() }
        guard fixtures.count < 64 else { message = "This setup supports up to 64 objects."; return }
        guard fixtureKind != .movingHead || fixtures.filter({ $0.assetID != nil }).count < 4 else {
            message = "This lighting proof of concept supports four fixtures."; return
        }
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 16) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: String(format: fixtureKind == .movingHead ? "Rogue R1X %02d" : "DMX cube %02d", nextFixtureNumber), assetID: fixtureKind.assetID,
                              universe: patch.universe, startAddress: patch.address, channels: Array(repeating: 0, count: 16),
                              position: .init(x: base.x, y: base.y+(fixtureKind == .cube ? fixtureKind.radius : 0), z: base.z), surfaceID: surfaceID)
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

    func select(_ id: UUID, expand: Bool = false) {
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction(expand ? "Toggle fixture info" : "Select fixture"); defer { endHistoryAction() }
        guard fixture(id) != nil else { return }
        if selectedID != id { expandedID = nil; lastTarget = nil }
        cancelPicking()
        selectedID = id
        toolboxTab = 0
        recent.use(.fixture(id))
        isPlacing = false
        if expand { expandedID = expandedID == id ? nil : id }
    }

    func deselect() {
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction("Deselect fixture"); defer { endHistoryAction() }
        cancelPicking(); selectedID = nil; expandedID = nil; lastTarget = nil
        gizmoVisible = false; previewDraft = false
    }

    func beginPlacement() {
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
        fixtureKind = kind; draggingFixture = kind; isPlacing = true; scenePick = nil
        dragLease?.cancel()
        dragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            self?.draggingFixture = nil; self?.isPlacing = false
        }
    }

    func dropFixture(_ tokens: [String], at point: Position3D, surfaceID: String) -> Bool {
        guard let token = tokens.first, let kind = FixtureKind(token: token), canPlace else { return false }
        fixtureKind = kind; isPlacing = true
        let count = fixtures.count
        place(at: FixtureAiming.vector(point), surfaceID: surfaceID)
        draggingFixture = nil; dragLease?.cancel()
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
        cancelPicking()
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
        cancelPicking()
        previewDraft = true; previewBlackout = false
        presetDraft = DMXPreset(name: "")
        presetMessage = nil
    }

    @discardableResult func savePreset(asNew: Bool = false) -> Bool {
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
        guard !libraryBusy else { return }
        beginHistoryAction("Delete preset"); defer { endHistoryAction() }
        guard presets.contains(where: { $0.id == id }) else { return }
        let updated = PresetOperations.clearing(id, fixtures: fixtures)
        if fixtures != updated { fixtures = updated; revision += 1; persist() }
        presets.removeAll { $0.id == id }
        recent.remove(.preset(id))
        if !isDemoMode, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        if let first = presets.first { choosePreset(first) } else { newPreset() }
        presetMessage = "Preset deleted. Assigned fixtures are dark and unassigned; aim overrides are preserved."
    }

    @discardableResult func applyPreset(_ presetID: UUID, to fixtureID: UUID) -> Bool {
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
        if targetPreview?.id == fixture.id { return renderedFixture(fixture).channels }
        return previewDraft && selectedID == fixture.id ? presetDraft.channels : fixture.channels
    }

    func renderedFixture(_ fixture: Fixture) -> Fixture {
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
        blackout || (previewDraft && previewBlackout && selectedID == fixture.id)
    }

    /// Direct preview articulation belongs to this placed fixture, not its shared preset.
    func setHeadAim(_ id: UUID, panDegrees: Float? = nil, tiltDegrees: Float? = nil) {
        guard !libraryBusy else { return }
        beginHistoryAction("Aim moving head"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }),
              fixtures[index].assetID == LightingPreview.assetID,
              fixtures[index].channels.count >= 6,
              [panDegrees, tiltDegrees].compactMap({ $0 }).allSatisfy(\.isFinite) else { return }
        var candidate = fixtures[index]
        let pan = panDegrees.map(FixtureAiming.panByte(for:)) ?? candidate.channels[4]
        let tilt = tiltDegrees.map(FixtureAiming.tiltByte(for:)) ?? candidate.channels[5]
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

    func moveFixture(_ id: UUID, position: Position3D, yawDegrees: Float) {
        guard let fixture = fixture(id) else { return }
        let angles = FixtureAiming.angles(fixture.orientation)
        transformFixture(id, position: position, yaw: yawDegrees, pitch: angles.pitch, roll: angles.roll)
    }

    func transformFixture(_ id: UUID, position: Position3D, yaw: Float, pitch: Float, roll: Float) {
        guard !libraryBusy else { return }
        beginHistoryAction("Transform fixture"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }), let environment else { return }
        if let issue = LightingPreview.placementIssue(position, in: environment) { message = issue; return }
        guard [yaw,pitch,roll].allSatisfy(\.isFinite) else { return }
        var candidate = fixtures[index]
        candidate.position = position
        candidate.orientation = FixtureAiming.euler(yaw: yaw, pitch: pitch, roll: roll)
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
        guard canPlace, let fixture = fixture(id), fixture.assetID == LightingPreview.assetID else { return }
        guard let presetID = fixture.presetID, presets.contains(where: { $0.id == presetID }) else {
            message = "Apply a preset before retargeting, or create one in the preset editor."
            return
        }
        select(id)
        gizmoVisible = false; previewDraft = false
        targetPresetSource = .saved(presetID)
        scenePick = .aim(id); lastTarget = nil; message = nil
    }

    /// Editor targeting uses all current draft values and saves/assigns that preset.
    func beginPresetTarget() {
        guard canPlace, let id = selectedID, fixture(id)?.assetID == LightingPreview.assetID else { return }
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

    func beginReposition(_ id: UUID) {
        guard canPlace, fixture(id) != nil else { return }
        select(id)
        gizmoVisible = false
        scenePick = .move(id)
        previewDraft = false
        lastTarget = nil
        message = nil
    }

    func cancelPicking() {
        scenePick = nil; targetPreview = nil; pendingTarget = nil; targetPresetSource = nil
        isPlacing = false; draggingFixture = nil; message = nil
    }

    @discardableResult func acceptTarget(_ target: Position3D) -> Bool {
        guard !libraryBusy, canPlace, case .aim(let id) = scenePick,
              var candidate = fixture(id), let preset = targetingPreset else { return false }
        do {
            guard preset.channels.count >= 6 else { throw PresetError("Target requires a preset with at least six channels.") }
            candidate.channels = preset.channels
            candidate.presetID = preset.id
            candidate.aimOverride = nil
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
        select(id); gizmoVisible = true; previewDraft = false
    }

    @discardableResult func updateFixtureDetails(_ id: UUID, name: String, universe: Int, address: Int) -> Bool {
        guard !libraryBusy, let i = fixtures.firstIndex(where: { $0.id == id }) else { return false }
        var candidate = fixtures[i]
        candidate.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.universe = universe; candidate.startAddress = address
        if let issue = candidate.validationIssue(among: fixtures) { message = issue; return false }
        endTransformDrag()
        beginHistoryAction("Edit fixture details"); defer { endHistoryAction() }
        cancelPicking(); fixtures[i] = candidate; revision += 1; persist()
        message = "Saved item details."
        return true
    }

    func beginTransformDrag(axis: FixtureAxis, mode: FixtureTransformMode, at point: SIMD3<Float>) {
        guard canPlace, gizmoVisible, transformDrag == nil, let id = selectedID, let fixture = fixture(id) else { return }
        let center = FixtureAiming.vector(fixture.position) + [0, fixture.assetID == nil ? 0 : LightingPreview.height/2, 0]
        let angle = axis.angle(at: point, about: center)
        guard mode == .move || angle != nil else { return }
        cancelPicking(); previewDraft = false
        beginHistoryAction("\(mode.rawValue) fixture · \(axis.rawValue.uppercased()) axis")
        transformDrag = .init(fixture: fixture, axis: axis, mode: mode, start: point, lastAngle: angle)
    }

    func updateTransformDrag(to point: SIMD3<Float>) {
        guard var drag = transformDrag, point.x.isFinite, point.y.isFinite, point.z.isFinite,
              selectedID == drag.fixture.id, let i = fixtures.firstIndex(where: { $0.id == drag.fixture.id }), let environment else { return }
        var candidate = drag.fixture
        if drag.mode == .move {
            var position = FixtureAiming.vector(candidate.position)
            position[drag.axis.index] += point[drag.axis.index]-drag.start[drag.axis.index]
            candidate.position = .init(x: position.x, y: position.y, z: position.z)
            if let issue = LightingPreview.placementIssue(candidate.position, in: environment) { message = issue; return }
        } else {
            let center = FixtureAiming.vector(candidate.position) + [0, candidate.assetID == nil ? 0 : LightingPreview.height/2, 0]
            guard let next = drag.axis.angle(at: point, about: center), let previous = drag.lastAngle else { return }
            drag.totalAngle += FixtureAiming.angleDelta(from: previous, to: next); drag.lastAngle = next
            candidate.orientation = FixtureAiming.rotatedMount(candidate.orientation, around: drag.axis, radians: drag.totalAngle)
        }
        transformDrag = drag; candidate.surfaceID = nil
        guard candidate != fixtures[i], candidate.validationIssue(among: fixtures) == nil else { return }
        fixtures[i] = candidate; lastTarget = nil; revision += 1; persist(); message = nil
    }

    func endTransformDrag() {
        guard transformDrag != nil else { return }
        transformDrag = nil; endHistoryAction()
    }

    func reposition(at hit: Position3D, surfaceID: String) {
        guard !libraryBusy else { return }
        beginHistoryAction("Reposition fixture"); defer { endHistoryAction() }
        guard canPlace, case .move(let id) = scenePick,
              let index = fixtures.firstIndex(where: { $0.id == id }),
              let surface = environment?.surfaces.first(where: { $0.id == surfaceID }) else { return }
        let radius: Float = fixtures[index].assetID == nil ? 0.12 : LightingPreview.footprintRadius
        guard let center = surface.fixturePosition(hit: hit, halfSize: radius) else {
            message = "Choose a top surface with enough space for the fixture."; return
        }
        fixtures[index].position = .init(x: center.x, y: center.y-(fixtures[index].assetID == nil ? 0 : radius), z: center.z)
        fixtures[index].surfaceID = surfaceID
        scenePick = nil; lastTarget = nil
        revision += 1; persist(); message = "Fixture repositioned. Its orientation and DMX values are preserved."
    }

    func repositionOnMesh(at point: Position3D) {
        guard !libraryBusy else { return }
        beginHistoryAction("Reposition fixture on mesh"); defer { endHistoryAction() }
        guard canPlace, case .move(let id) = scenePick, let i = fixtures.firstIndex(where: { $0.id == id }), let scannedMesh else { return }
        let radius: Float = fixtures[i].assetID == nil ? 0.12 : LightingPreview.footprintRadius
        guard scannedMesh.supports(point, radius: radius) else { message = "Choose a scanned horizontal surface with enough space."; return }
        fixtures[i].position = .init(x: point.x, y: point.y+(fixtures[i].assetID == nil ? radius : 0), z: point.z)
        fixtures[i].surfaceID = nil; scenePick = nil; lastTarget = nil
        revision += 1; persist()
    }

    func resetAim(_ id: UUID) {
        guard !libraryBusy else { return }
        beginHistoryAction("Reset fixture aim"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }), fixtures[index].aimOverride != nil else { return }
        cancelPicking()
        let saved = presets.first(where: { $0.id == fixtures[index].presetID })
        fixtures[index].aimOverride = nil
        for channel in 4...5 {
            fixtures[index].channels[channel] = saved.flatMap { $0.channels.indices.contains(channel) ? $0.channels[channel] : nil } ?? 128
        }
        previewDraft = false; lastTarget = nil
        revision += 1; persist(); message = saved == nil ? "Head returned to neutral pan and tilt." : "Restored the preset's pan and tilt."
    }

    func beginPresetDrag(_ id: UUID) {
        draggingPresetID = id
        dragLease?.cancel()
        // Preserve the source while the wearer looks away toward the destination.
        // A cancelled system drag cannot leave the toolbox pinned indefinitely.
        dragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            self?.draggingPresetID = nil
        }
    }

    func endPresetDrag() {
        dragLease?.cancel()
        dragLease = nil
        draggingPresetID = nil
    }

    func record(_ item: ToolboxItem) { recent.use(item) }

    func remove(_ id: UUID) {
        guard !libraryBusy else { return }
        endTransformDrag()
        beginHistoryAction("Delete fixture"); defer { endHistoryAction() }
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
        cancelPicking(); fixtures = []; selectedID = nil; expandedID = nil
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

    func bootstrapLibrary(defaultRoom: EnvironmentManifest) {
        guard rooms.isEmpty else { return }
        rooms = [LibraryRoom(manifest: defaultRoom, origin: .bundled)]
        refreshLibrary()
        guard !isDemoMode else { return }
        do {
            if let saved = try AuditHistory<VenueAuditState>.load(from: historyURL) {
                for node in saved.nodes { try node.state.validate() }
                history = saved
                let state = saved.current.state
                rooms = state.rooms; savedSetups = state.setups
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

    func refreshLibrary() {
        guard history == nil else { return }
        do {
            let imported = try library.rooms()
            let bundled = rooms.filter { $0.origin == .bundled }
            rooms = bundled + imported.filter { room in !bundled.contains { $0.id == room.id } }
            savedSetups = try library.setups(rooms: rooms)
        } catch { libraryMessage = "Library could not be read: \(error.localizedDescription). Existing files are preserved." }
    }

    func requestRoom(_ room: LibraryRoom, setup: VenueSetup? = nil, blank: Bool = true) {
        endTransformDrag(); gizmoVisible = false
        guard !libraryBusy else { return }
        flushHistoryEdits()
        do { if let setup { try setup.validate(room: room) } }
        catch { libraryMessage = error.localizedDescription; return }
        libraryBusy = true; canPlace = false; previewDraft = false; cancelPicking()
        roomRequest = .init(room: room, setup: setup, blank: blank)
        roomLoadToken = UUID()
    }

    @discardableResult func saveSetup(asNew: Bool = false) -> Bool {
        guard let room = activeRoom, !libraryBusy else { return false }
        beginHistoryAction(asNew ? "Save setup as new" : "Save setup"); defer { endHistoryAction() }
        let name = setupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = VenueSetup(id: asNew ? UUID() : (activeSetupID ?? UUID()), name: name, room: room,
                                  fixtures: fixtures, presets: presets, revision: revision, whiteRoom: whiteRoom, houseLight: houseLight)
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
                     selectedID: selectedID, expandedID: expandedID, previewDraft: previewDraft, previewBlackout: previewBlackout)
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
        } catch { historyMessage = "History save failed: \(error.localizedDescription)" }
    }
    func auditExternal(_ title: String) {
        flushHistoryEdits()
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
        finishHistoryGesture()
        flushHistoryEdits()
        if let id = history?.undoTarget { restoreHistory(id, kind: .undo) }
    }
    func redo() {
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
        restoringHistory = true
        defer { restoringHistory = false }
        cancelPicking(); endPresetDrag(); gizmoVisible = false; lastTarget = nil; recent = RecentItems()
        rooms = state.rooms; savedSetups = state.setups
        environment = state.rooms.first { $0.id == state.roomID }!.manifest
        fixtures = state.fixtures; presets = state.presets; presetDraft = state.draft; editingPresetID = state.editingPresetID
        setupName = state.setupName; activeSetupID = state.activeSetupID; savedSetup = state.savedSetup
        whiteRoom = state.whiteRoom; houseLight = state.houseLight; blackout = state.blackout
        selectedID = state.selectedID; expandedID = state.expandedID; previewDraft = state.previewDraft; previewBlackout = state.previewBlackout ?? false
        revision += 1; syncedRevision = nil; nextFixtureNumber = fixtures.count+1
        if !isDemoMode, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        persistenceBlocked = false
        if let environment { do { _ = try placements.load(environment: environment) } catch { persistenceBlocked = true } }
        persist()
        environmentStatus = environment!.title
        historyMessage = "Restored · \(history?.current.title ?? "state")"
    }
}

private func isDemoModeDirectory(_ arguments: [String]) -> Bool { arguments.contains("--demo") }
