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

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if targetEnvironment(simulator)
        isDemoMode = arguments.contains("--demo")
        #else
        isDemoMode = false
        #endif
        guard isDemoMode else { return }

        let frontWash = Fixture(
            name: "Front Wash",
            universe: 1,
            startAddress: 1,
            channels: [255, 212, 180, 255, 36, 0, 118, 0, 64, 32, 0, 0, 0, 0, 0, 0],
            position: .init(x: -0.28, y: 1.43, z: -1.65)
        )
        let stageLeft = Fixture(
            name: "Stage Left Beam",
            universe: 1,
            startAddress: 17,
            channels: [196, 24, 232, 0, 145, 12, 90, 255],
            position: .init(x: 0.48, y: 1.58, z: -2.05)
        )
        fixtures = [frontWash, stageLeft]
        selectedID = frontWash.id
        expandedID = frontWash.id
        revision = 1
        nextFixtureNumber = 3
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
        guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: 8) else {
            message = "No free DMX patch is available."
            return
        }
        let fixture = Fixture(name: String(format: "Fixture %02d", nextFixtureNumber),
                              universe: patch.universe, startAddress: patch.address,
                              position: .init(x: position.x, y: position.y, z: position.z))
        fixtures.append(fixture)
        nextFixtureNumber += 1
        selectedID = fixture.id
        isPlacing = false
        revision += 1
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
    }

    func remove(_ id: UUID) {
        guard fixtures.contains(where: { $0.id == id }) else { return }
        fixtures.removeAll { $0.id == id }
        if selectedID == id { selectedID = nil }
        if expandedID == id { expandedID = nil }
        revision += 1
    }

    func sync() async {
        guard !isSyncing else { return }
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
