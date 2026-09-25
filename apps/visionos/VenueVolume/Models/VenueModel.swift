import Foundation
import Observation
import VenueVolumeCore

@MainActor @Observable
final class VenueModel {
    private(set) var fixtures: [Fixture] = []
    var selectedID: UUID?
    var expandedID: UUID?
    private(set) var presets: [DMXPreset] = DMXPreset.examples
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
    var placementDistance: Float = 2
    var trackingStatus = "Starting spatial tracking…"
    var canPlace = false
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

    init(arguments: [String] = ProcessInfo.processInfo.arguments, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if targetEnvironment(simulator)
        isDemoMode = arguments.contains("--demo")
        #else
        isDemoMode = false
        #endif
        if !isDemoMode, let data = defaults.data(forKey: "venue.presets.v1"),
           let saved = try? JSONDecoder().decode([DMXPreset].self, from: data),
           saved.allSatisfy({ $0.validationIssue == nil }), Set(saved.map(\.id)).count == saved.count {
            presets = saved
        }
        if let first = presets.first { presetDraft = first; editingPresetID = first.id }
        guard isDemoMode else { return }
        simulatedPalm = !arguments.contains("--palm-hidden")
        toolboxVisible = simulatedPalm

        let frontWash = Fixture(
            presetID: presets[0].id, name: "Front Wash",
            universe: 1,
            startAddress: 1,
            channels: [255, 212, 180, 255, 36, 0, 118, 0, 64, 32, 0, 0, 0, 0, 0, 0],
            position: .init(x: 0.10, y: 1.25, z: -1.65)
        )
        let stageLeft = Fixture(
            presetID: presets[1].id, name: "Stage Left Beam",
            universe: 1,
            startAddress: 17,
            channels: presets[1].channels,
            position: .init(x: 0.48, y: 1.58, z: -2.05)
        )
        fixtures = [frontWash, stageLeft]
        selectedID = frontWash.id
        expandedID = arguments.contains("--show-info") ? frontWash.id : nil
        revision = 1
        nextFixtureNumber = 3
        if arguments.contains("--show-recents") {
            record(.addFixture)
            record(.fixture(frontWash.id))
            record(.preset(presets[0].id))
            record(.presets)
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

    func place(at position: SIMD3<Float>) {
        guard canPlace, isPlacing else { return }
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 16) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: String(format: "Fixture %02d", nextFixtureNumber),
                              universe: patch.universe, startAddress: patch.address, channels: Array(repeating: 0, count: 16),
                              position: .init(x: position.x, y: position.y, z: position.z))
        fixtures.append(fixture)
        recent.use(.addFixture)
        nextFixtureNumber += 1
        selectedID = fixture.id
        isPlacing = false
        revision += 1
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
            if fixtures != updated { fixtures = updated; revision += 1 }
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
        if fixtures != updated { fixtures = updated; revision += 1 }
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
            if updated != fixtures { fixtures = updated; revision += 1 }
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
        presetMessage = "Object assignment cleared; channel values are zero."
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
    }

    func sync() async {
        guard !isSyncing else { return }
        recent.use(.sync)
        isSyncing = true
        syncFailed = false
        defer { isSyncing = false }
        // Capture before suspension: edits made during the request stay marked as unsynced.
        let payload = SyncPayload(fixtures: fixtures, revision: revision)
        do {
            lastRequestJSON = String(decoding: try payload.jsonData(), as: UTF8.self)
            syncStatus = "Sending \(payload.totalFixtures) fixtures…"
            let receipt = try await client.send(payload, simulateFailure: simulateSyncFailure)
            syncedRevision = receipt.revision
            syncStatus = "HTTP 200 · \(receipt.acceptedFixtures) fixtures · \(receipt.acceptedChannels) channels"
        } catch {
            syncFailed = true
            syncStatus = error.localizedDescription
        }
    }
}
