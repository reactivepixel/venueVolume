import Foundation
import Observation
import VenueVolumeCore

@MainActor @Observable
final class VenueModel {
    private(set) var fixtures: [Fixture] = []
    var selectedID: UUID?
    var expandedID: UUID?
    var isImmersed = false
    var isTransitioning = false
    var isPlacing = false
    var trackingStatus = "Starting spatial tracking…"
    var canPlace = false
    private(set) var environment: EnvironmentManifest?
    var environmentStatus = "Loading classroom…"
    private(set) var persistenceStatus = "Placements save on this device"
    private var persistenceBlocked = false
    private let placements = PlacementStore(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VenueVolume/Placements"))
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

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if targetEnvironment(simulator)
        isDemoMode = arguments.contains("--demo")
        #else
        isDemoMode = false
        #endif
    }

    func activate(environment: EnvironmentManifest) {
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
            if let desk = environment.surfaces.first(where: { $0.id == "instructor-desk-top" }) {
                fixtures = [Fixture(name: "Desk test fixture", position: .init(x: desk.center[0], y: desk.center[1]+0.12, z: desk.center[2]), surfaceID: desk.id)]
            }
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
              let center = surface.fixturePosition(hit: .init(x: position.x, y: position.y, z: position.z)) else {
            message = "Choose the top of a floor or table with space for the fixture."
            return
        }
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 8) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: String(format: "Fixture %02d", nextFixtureNumber),
                              universe: patch.universe, startAddress: patch.address,
                              position: center, surfaceID: surfaceID)
        message = nil
        fixtures.append(fixture)
        nextFixtureNumber += 1
        selectedID = fixture.id
        isPlacing = false
        revision += 1
        persist()
    }

    func select(_ id: UUID, expand: Bool = false) {
        selectedID = id
        isPlacing = false
        if expand { expandedID = expandedID == id ? nil : id }
    }

    func configure(_ id: UUID, name: String, universe: Int, address: Int, channelCount: Int) -> String? {
        guard let index = fixtures.firstIndex(where: { $0.id == id }) else { return "Fixture no longer exists." }
        guard (1...16).contains(channelCount) else { return "Choose between 1 and 16 channels." }
        var candidate = fixtures[index]
        candidate.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.universe = universe
        candidate.startAddress = address
        candidate.channels = Array((candidate.channels + Array(repeating: 0, count: 16)).prefix(channelCount))
        if let issue = candidate.validationIssue(among: fixtures) { return issue }
        if fixtures[index] != candidate {
            fixtures[index] = candidate
            revision += 1
            persist()
        }
        return nil
    }

    func setChannel(_ id: UUID, index: Int, value: Int) {
        guard let fixtureIndex = fixtures.firstIndex(where: { $0.id == id }),
              fixtures[fixtureIndex].channels.indices.contains(index) else { return }
        let clamped = min(255, max(0, value))
        guard fixtures[fixtureIndex].channels[index] != clamped else { return }
        fixtures[fixtureIndex].channels[index] = clamped
        revision += 1
        persist()
    }

    func remove(_ id: UUID) {
        guard fixtures.contains(where: { $0.id == id }) else { return }
        fixtures.removeAll { $0.id == id }
        if selectedID == id { selectedID = nil }
        if expandedID == id { expandedID = nil }
        revision += 1
        persist()
    }

    func sync() async {
        guard !isSyncing else { return }
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
