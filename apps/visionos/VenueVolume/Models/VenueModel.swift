import Foundation
import Observation
import VenueVolumeCore

enum AimMethod: String, CaseIterable { case head = "Aim head (preview)", mount = "Aim mount" }
enum ScenePick: Equatable { case move(UUID), aim(UUID, AimMethod) }

@MainActor @Observable
final class VenueModel {
    private(set) var fixtures: [Fixture] = []
    var selectedID: UUID?
    var expandedID: UUID?
    private(set) var presets: [DMXPreset] = LightingPreview.presets
    private(set) var recent = RecentItems()
    var presetDraft = DMXPreset(name: "New preset")
    var editingPresetID: UUID?
    var presetMessage: String?
    var toolboxVisible = false
    var simulatedPalm = true
    var needsManualToolbox = false
    var handTrackingStatus = "Raise your left palm toward you"
    private(set) var draggingPresetID: UUID?
    private var dragLease: Task<Void, Never>?
    private let defaults: UserDefaults
    private let arguments: [String]
    var previewDraft = false
    var blackout = false
    var houseLight: Float = 0.15
    var whiteRoom = true
    var scenePick: ScenePick?
    var lastTarget: Position3D?
    var isRetargeting: Bool { if case .aim = scenePick { true } else { false } }
    var isPickingRoom: Bool { isPlacing || scenePick != nil }
    var pickingInstruction: String {
        switch scenePick {
        case .move: "Look at a clear floor or tabletop, then pinch to reposition."
        case .aim(_, .head): "Look at a point on the room, then pinch to aim the head."
        case .aim(_, .mount): "Look at a point on the room, then pinch to aim the mount."
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
        isDemoMode = arguments.contains("--demo")
        if !isDemoMode, let data = defaults.data(forKey: "venue.presets.v1"),
           let saved = try? JSONDecoder().decode([DMXPreset].self, from: data),
           saved.allSatisfy({ $0.validationIssue == nil }), Set(saved.map(\.id)).count == saved.count {
            presets = saved
        }
        if let first = presets.first { presetDraft = first; editingPresetID = first.id }
        guard isDemoMode else { return }
        simulatedPalm = !arguments.contains("--palm-hidden")
        toolboxVisible = simulatedPalm

    }

    func activate(environment: EnvironmentManifest) {
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
              let center = surface.fixturePosition(hit: .init(x: position.x, y: position.y, z: position.z), halfSize: LightingPreview.footprintRadius) else {
            message = "Choose the top of a floor or table with space for the fixture."
            return
        }
        guard fixtures.filter({ $0.assetID != nil }).count < 4 else {
            message = "This lighting proof of concept supports four fixtures."; return
        }
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 16) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: String(format: "Rogue R1X %02d", nextFixtureNumber), assetID: LightingPreview.assetID,
                              universe: patch.universe, startAddress: patch.address, channels: Array(repeating: 0, count: 16),
                              position: .init(x: center.x, y: center.y-LightingPreview.footprintRadius, z: center.z), surfaceID: surfaceID)
        message = nil
        fixtures.append(fixture)
        recent.use(.addFixture)
        nextFixtureNumber += 1
        selectedID = fixture.id
        isPlacing = false
        revision += 1
        persist()
    }

    func select(_ id: UUID, expand: Bool = false) {
        guard fixture(id) != nil else { return }
        if selectedID != id { expandedID = nil; lastTarget = nil }
        scenePick = nil
        selectedID = id
        recent.use(.fixture(id))
        isPlacing = false
        if expand { expandedID = expandedID == id ? nil : id }
    }

    func beginPlacement() {
        scenePick = nil
        isPlacing.toggle()
        expandedID = nil
        message = nil
        recent.use(.addFixture)
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
        presetDraft = preset
        editingPresetID = preset.id
        presetMessage = nil
        recent.use(.preset(preset.id))
    }

    func newPreset() {
        editingPresetID = nil
        presetDraft = DMXPreset(name: "New preset")
        presetMessage = nil
    }

    @discardableResult func savePreset(asNew: Bool = false) -> Bool {
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
        guard let index = fixtures.firstIndex(where: { $0.id == id }), fixtures[index].presetID != nil else { return }
        fixtures[index].presetID = nil
        fixtures[index].channels = Array(repeating: 0, count: fixtures[index].channels.count)
        fixtures[index].preserveAimOverride()
        revision += 1
        persist()
        presetMessage = "Assignment cleared. Output is zero; any aim override is preserved."
    }

    func renderedChannels(for fixture: Fixture) -> [Int] {
        previewDraft && selectedID == fixture.id ? presetDraft.channels : fixture.channels
    }

    /// Direct preview articulation belongs to this placed fixture, not its shared preset.
    func setHeadAim(_ id: UUID, panDegrees: Float? = nil, tiltDegrees: Float? = nil) {
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
        guard let index = fixtures.firstIndex(where: { $0.id == id }), let environment else { return }
        if let issue = LightingPreview.placementIssue(position, in: environment) { message = issue; return }
        guard [yaw,pitch,roll].allSatisfy(\.isFinite) else { return }
        var candidate = fixtures[index]
        candidate.position = position
        candidate.orientation = FixtureAiming.euler(yaw: yaw, pitch: pitch, roll: roll)
        candidate.surfaceID = nil
        guard candidate != fixtures[index] else { return }
        fixtures[index] = candidate
        lastTarget = nil
        revision += 1; persist(); message = nil
    }

    func yawDegrees(for fixture: Fixture) -> Float { FixtureAiming.angles(fixture.orientation).yaw }

    func beginRetarget(_ id: UUID, method: AimMethod) {
        guard canPlace, fixture(id)?.assetID == LightingPreview.assetID else { return }
        select(id)
        previewDraft = false
        scenePick = .aim(id, method)
        lastTarget = nil
        message = nil
    }

    func beginReposition(_ id: UUID) {
        guard canPlace, fixture(id) != nil else { return }
        select(id)
        scenePick = .move(id)
        previewDraft = false
        lastTarget = nil
        message = nil
    }

    func cancelPicking() { scenePick = nil; isPlacing = false; message = nil }

    @discardableResult func acceptTarget(_ target: Position3D) -> Bool {
        guard canPlace, case .aim(let id, let method) = scenePick,
              let index = fixtures.firstIndex(where: { $0.id == id }) else { return false }
        var candidate = fixtures[index]
        do {
            switch method {
            case .head:
                guard candidate.channels.count >= 6 else { throw PresetError("Apply a preset with at least six channels before aiming the head.") }
                candidate.aimOverride = try FixtureAiming.articulated(candidate, target: target)
                candidate.preserveAimOverride()
            case .mount:
                candidate.orientation = try FixtureAiming.mounted(candidate, target: target)
                candidate.surfaceID = nil
            }
            if let issue = candidate.validationIssue(among: fixtures) { throw PresetError(issue) }
            fixtures[index] = candidate
            lastTarget = target
            scenePick = nil
            revision += 1; persist()
            message = method == .head ? "Head retargeted · pan/tilt override saved for this fixture." : "Mount retargeted · DMX values unchanged."
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func reposition(at hit: Position3D, surfaceID: String) {
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

    func resetAim(_ id: UUID) {
        guard let index = fixtures.firstIndex(where: { $0.id == id }), fixtures[index].aimOverride != nil else { return }
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
        guard fixtures.contains(where: { $0.id == id }) else { return }
        fixtures.removeAll { $0.id == id }
        scenePick = nil; lastTarget = nil
        recent.remove(.fixture(id))
        if selectedID == id { selectedID = nil }
        if expandedID == id { expandedID = nil }
        revision += 1
        persist()
    }

    func sync() async {
        guard !isSyncing else { return }
        recent.use(.sync)
        isSyncing = true
        syncFailed = false
        defer { isSyncing = false }
        // Capture before suspension: edits made during the request stay marked as unsynced.
        let payload = SyncPayload(fixtures: fixtures, revision: revision, environment: environment)
        do {
            lastRequestJSON = String(decoding: try payload.jsonData(), as: UTF8.self)
            syncStatus = "Sending \(payload.totalFixtures) fixtures…"
            let receipt = try await client.send(payload, simulateFailure: simulateSyncFailure)
            if environment?.id == payload.environmentID && environment?.version == payload.environmentVersion {
                syncedRevision = receipt.revision
            }
            syncStatus = "HTTP 200 · \(receipt.acceptedFixtures) fixtures · \(receipt.acceptedChannels) channels"
        } catch {
            syncFailed = true
            syncStatus = error.localizedDescription
        }
    }
}
