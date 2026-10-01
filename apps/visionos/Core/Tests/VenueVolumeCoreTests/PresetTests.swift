import Foundation
import Testing
@testable import VenueVolumeCore

@Test func presetDropPreservesObjectIdentityAndPatch() throws {
    let fixture = Fixture(name: "Cube", universe: 4, startAddress: 80)
    let preset = DMXPreset(name: "Look", channels: [255, 31, 7])
    let result = try PresetOperations.applying(preset, to: fixture.id, fixtures: [fixture])
    #expect(result[0].id == fixture.id)
    #expect(result[0].position == fixture.position)
    #expect(result[0].universe == 4)
    #expect(result[0].startAddress == 80)
    #expect(result[0].channels == [255, 31, 7])
    #expect(result[0].presetID == preset.id)
}

@Test func saveUpdatesEveryAssignedObjectButNotOtherPresets() throws {
    var preset = DMXPreset(name: "Shared", channels: [1, 2])
    let first = Fixture(presetID: preset.id, name: "A", channels: preset.channels)
    let second = Fixture(presetID: preset.id, name: "B", startAddress: 17, channels: preset.channels)
    let other = Fixture(name: "C", startAddress: 40, channels: [12, 13])
    preset.channels = [255, 127, 64, 0]
    let updated = try PresetOperations.saving(preset, fixtures: [first, second, other])
    #expect(updated[0].channels == preset.channels)
    #expect(updated[1].channels == preset.channels)
    #expect(updated[2] == other)
}

@Test func conflictingFootprintRejectsEntireSaveAndDrop() throws {
    let preset = DMXPreset(name: "Wide", channels: Array(repeating: 255, count: 16))
    let first = Fixture(presetID: preset.id, name: "A", channels: [1, 2])
    let second = Fixture(name: "B", startAddress: 8, channels: [3, 4])
    let original = [first, second]
    #expect(throws: PresetError.self) { try PresetOperations.saving(preset, fixtures: original) }
    #expect(throws: PresetError.self) { try PresetOperations.applying(preset, to: first.id, fixtures: original) }
    #expect(original[0].channels == [1, 2])
    let boundary = Fixture(name: "Boundary", startAddress: 512, channels: [0])
    #expect(throws: PresetError.self) { try PresetOperations.applying(preset, to: boundary.id, fixtures: [boundary]) }
}

@Test func copiedPresetDoesNotUpdateOriginalAssignments() throws {
    let original = DMXPreset(name: "Original", channels: [9, 10])
    let fixture = Fixture(presetID: original.id, name: "A", channels: original.channels)
    let copy = DMXPreset(name: "Copy", channels: [255, 255])
    #expect(try PresetOperations.saving(copy, fixtures: [fixture]) == [fixture])
}

@Test func deletingPresetClearsAssignmentsAndZerosChannels() {
    let preset = DMXPreset(name: "Look", channels: [9, 10])
    let fixture = Fixture(presetID: preset.id, name: "A", channels: preset.channels)
    let other = Fixture(name: "Other", startAddress: 17, channels: [255])
    let result = PresetOperations.clearing(preset.id, fixtures: [fixture, other])
    #expect(result[0].presetID == nil)
    #expect(result[0].channels == [0, 0])
    #expect(result[1] == other)
}

@Test func recentItemsAreUniqueOrderedAndCappedAtTen() {
    var recent = RecentItems()
    let ids = (0..<12).map { _ in UUID() }
    for id in ids { recent.use(.preset(id)) }
    #expect(recent.items.count == 10)
    #expect(recent.items.first == .preset(ids[11]))
    recent.use(.preset(ids[4]))
    #expect(recent.items.first == .preset(ids[4]))
    #expect(recent.items.count == 10)
    #expect(Set(recent.items).count == 10)
    recent.remove(.preset(ids[4]))
    #expect(!recent.items.contains(.preset(ids[4])))
}

@Test func presetPayloadAndAssignmentsRoundTrip() throws {
    let preset = DMXPreset(name: "Saved", channels: [0, 255])
    let decoded = try JSONDecoder().decode(DMXPreset.self, from: JSONEncoder().encode(preset))
    #expect(decoded == preset)
    #expect(DMXPreset.id(from: preset.dragToken) == preset.id)
    #expect(DMXPreset.id(from: preset.id.uuidString) == nil)
    #expect(DMXPreset.id(from: "venue-volume:preset:not-an-id") == nil)
    let fixture = Fixture(presetID: preset.id, name: "A", channels: preset.channels)
    #expect(try JSONDecoder().decode(Fixture.self, from: JSONEncoder().encode(fixture)) == fixture)
    #expect(DMXPreset(name: "", channels: [0]).validationIssue != nil)
    #expect(DMXPreset(name: "Invalid", channels: [256]).validationIssue != nil)
}

@Test func palmRevealDebouncesAndDismissesAfterTrackingLoss() {
    var gate = PalmRevealGate()
    let r0 = gate.update(eligible: true, now: 0)
    #expect(!r0)
    let state1 = gate.update(eligible: false, now: 0.1)
    #expect(!state1)
    let state2 = gate.update(eligible: true, now: 0.2)
    #expect(!state2)
    let state3 = gate.update(eligible: true, now: 0.5)
    #expect(state3)
    let state4 = gate.update(eligible: false, now: 0.8)
    #expect(state4)
    let state5 = gate.update(eligible: false, now: 1.4)
    #expect(!state5)
    let state6 = gate.update(eligible: true, now: 1.5)
    #expect(!state6)
    let state7 = gate.update(eligible: true, now: 1.8)
    #expect(state7)
}
