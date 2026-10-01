import Foundation
import Observation
import VenueVolumeCore

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
            fixtures = [Fixture(presetID: look.id, name: "Room wash 01", assetID: LightingPreview.assetID,
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
        let fixture = Fixture(name: String(format: "Room wash %02d", nextFixtureNumber), assetID: LightingPreview.assetID,
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
        if selectedID != id { expandedID = nil }
        selectedID = id
        recent.use(.fixture(id))
        isPlacing = false
        if expand { expandedID = expandedID == id ? nil : id }
    }

    func beginPlacement() {
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
        presetMessage = "Preset deleted. Its assigned fixtures are now zeroed and unassigned."
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
        revision += 1
        persist()
        presetMessage = "Object assignment cleared; channel values are zero."
    }

    func renderedChannels(for fixture: Fixture) -> [Int] {
        previewDraft && selectedID == fixture.id ? presetDraft.channels : fixture.channels
    }

    func moveFixture(_ id: UUID, position: Position3D, yawDegrees: Float) {
        guard let index = fixtures.firstIndex(where: { $0.id == id }), let environment else { return }
        if let issue = LightingPreview.placementIssue(position, in: environment) { message = issue; return }
        guard yawDegrees.isFinite else { return }
        let angle = yawDegrees * .pi / 180
        var candidate = fixtures[index]
        candidate.position = position
        candidate.orientation = .init(y: sin(angle/2), w: cos(angle/2))
        candidate.surfaceID = nil // manual rigging no longer claims a supporting surface
        guard candidate != fixtures[index] else { return }
        fixtures[index] = candidate
        revision += 1; persist(); message = nil
    }

    func yawDegrees(for fixture: Fixture) -> Float {
        2 * atan2(fixture.orientation.y, fixture.orientation.w) * 180 / .pi
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
