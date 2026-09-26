import Foundation
import Testing
@testable import VenueVolumeCore

@Test func footprintMustFitUniverse() {
    var fixture = Fixture(name: "Boundary", startAddress: 505)
    #expect(fixture.validationIssue(among: []) == nil)
    fixture.startAddress = 506
    #expect(fixture.validationIssue(among: []) != nil)
    fixture.startAddress = 512
    fixture.channels = [255]
    #expect(fixture.validationIssue(among: []) == nil)
}

@Test func patchesCannotOverlapButMayShareAddressesAcrossUniverses() {
    let first = Fixture(name: "First", startAddress: 1)
    var second = Fixture(name: "Second", startAddress: 8)
    #expect(second.validationIssue(among: [first, second]) != nil)
    second.startAddress = 9
    #expect(second.validationIssue(among: [first, second]) == nil)
    second.startAddress = 1
    second.universe = 2
    #expect(second.validationIssue(among: [first, second]) == nil)
    #expect(first.validationIssue(among: [first]) == nil)
}

@Test func allocatorFillsGapsAndRollsToNextUniverse() {
    let fixtures = (0..<32).map { Fixture(name: "Fixture \($0)", startAddress: 1 + $0 * 16, channels: Array(repeating: 0, count: 16)) }
    let next = Fixture.nextAvailablePatch(in: fixtures, footprint: 8)
    #expect(next?.universe == 2)
    #expect(next?.address == 1)
    let gap = Fixture.nextAvailablePatch(in: Array(fixtures.dropFirst()), footprint: 16)
    #expect(gap?.universe == 1)
    #expect(gap?.address == 1)
    #expect(Fixture.nextAvailablePatch(in: [], footprint: 17) == nil)
}

@Test(arguments: [0, 17]) func channelCountBounds(count: Int) {
    let fixture = Fixture(name: "Invalid", channels: Array(repeating: 0, count: count))
    #expect(fixture.validationIssue(among: []) != nil)
}

@Test func namesValuesAndUniverseMustBeValid() {
    #expect(Fixture(name: " \n ").validationIssue(among: []) != nil)
    #expect(Fixture(name: "Test", universe: 0).validationIssue(among: []) != nil)
    #expect(Fixture(name: "Test", universe: 64000).validationIssue(among: []) != nil)
    #expect(Fixture(name: "Test", channels: [-1]).validationIssue(among: []) != nil)
    #expect(Fixture(name: "Test", channels: [256]).validationIssue(among: []) != nil)
    #expect(Fixture(name: "Test", channels: [0, 255]).validationIssue(among: []) == nil)
}

@Test func completePayloadRoundTripsAndIncludesEveryConfiguration() throws {
    let fixtures = [
        Fixture(name: "Front", channels: [0, 127, 255], position: .init(x: 1, y: 2, z: -3)),
        Fixture(name: "Back", universe: 2, channels: Array(repeating: 42, count: 16))
    ]
    let payload = SyncPayload(fixtures: fixtures, revision: 9)
    let data = try payload.jsonData()
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(SyncPayload.self, from: data)
    #expect(decoded.fixtures == fixtures)
    #expect(decoded.totalFixtures == 2)
    #expect(decoded.totalChannels == 19)
    #expect(decoded.revision == 9)
    #expect(decoded.requestID == payload.requestID)
}

@Test func mockHTTPTransportAcceptsEntireSnapshot() async throws {
    let client = MockSyncClient()
    let payload = SyncPayload(fixtures: [Fixture(name: "Front", channels: [0, 255])], revision: 7)
    let receipt = try await client.send(payload)
    #expect(receipt.mock)
    #expect(receipt.requestID == payload.requestID)
    #expect(receipt.acceptedFixtures == 1)
    #expect(receipt.acceptedChannels == 2)
    #expect(receipt.revision == 7)
}

@Test func emptySnapshotCanClearRemoteConfiguration() async throws {
    let receipt = try await MockSyncClient().send(SyncPayload(fixtures: [], revision: 12))
    #expect(receipt.acceptedFixtures == 0)
    #expect(receipt.acceptedChannels == 0)
}

@Test func mockFailureCanBeRetried() async throws {
    let client = MockSyncClient()
    let payload = SyncPayload(fixtures: [Fixture(name: "Retry")], revision: 3)
    do {
        _ = try await client.send(payload, simulateFailure: true)
        Issue.record("Expected the simulated server failure")
    } catch SyncError.rejected(let status) {
        #expect(status == 503)
    }
    let receipt = try await client.send(payload)
    #expect(receipt.revision == 3)
}

@Test func invalidPatchCannotBeSynced() async throws {
    do {
        _ = try await MockSyncClient().send(SyncPayload(fixtures: [Fixture(name: "Invalid", startAddress: 510)], revision: 0))
        Issue.record("Expected invalid patch to be rejected")
    } catch SyncError.invalidConfiguration { }
}
