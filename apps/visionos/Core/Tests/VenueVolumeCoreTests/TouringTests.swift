import Foundation
import Testing
@testable import VenueVolumeCore

private func touringRig() -> TourSession {
    var show = TouringShow(name: "Tour")
    let front = FixtureGroup(name: "Front")
    let left = FixtureGroup(name: "Left", parentID: front.id)
    show.groups = [front, left]
    for index in 0..<3 {
        let fixture = Fixture(name: "Spot \(index+1)", assetID: LightingPreview.assetID,
                              startAddress: index*16+1, channels: FixtureKind.movingHead.asset!.neutralChannels,
                              position: .init(x: Float(index)*2, y: 0, z: -2))
        show.units.append(InventoryUnit(fixture: fixture, groupID: index == 0 ? left.id : front.id))
    }
    show.configurations[0].unitIDs = Set(show.units.map(\.id))
    return TourSession(show: show)
}
private func colourPreset(_ name: String, red: Int) -> DMXPreset {
    var preset = DMXPreset(name: name); preset.includedChannels = [1,2,3]
    preset.channels[1] = red; preset.channels[2] = 32; preset.channels[3] = 16
    return preset
}

@Test func tourHierarchyRejectsCyclesAndDanglingParents() throws {
    var tour = touringRig(); try tour.validate()
    tour.show.groups[0].parentID = tour.show.groups[1].id
    #expect(throws: (any Error).self) { try tour.validate() }
    tour.show.groups[0].parentID = UUID()
    #expect(throws: (any Error).self) { try tour.validate() }
}
@Test func tourSelectionResolvesHierarchyAndConfiguration() throws {
    var tour = touringRig()
    #expect(tour.members(of: tour.show.groups[0].id).count == 3)
    #expect(tour.members(of: tour.show.groups[1].id).count == 1)
    tour.excluded.insert(tour.show.units[0].id)
    #expect(tour.members(of: tour.show.groups[1].id).isEmpty)
    #expect(tour.members(of: nil).count == 2)
}
@Test func tourIdentityAndFootprintCannotChangeAtPlacement() throws {
    let tour = touringRig(); let fixture = tour.show.units[0].fixture
    try tour.validate(fixtures: [fixture])
    #expect(throws: (any Error).self) { try tour.validate(fixtures: [fixture, fixture]) }
    var resized = fixture; resized.channels.removeLast()
    #expect(throws: (any Error).self) { try tour.validate(fixtures: [resized]) }
    var unknown = Fixture(name: "Extra"); unknown.channels = Array(repeating: 0, count: 16)
    #expect(throws: (any Error).self) { try tour.validate(fixtures: [unknown]) }
}
@Test func tourColourPreservesIntensityAndFocus() throws {
    var tour = touringRig(); let preset = colourPreset("Red", red: 255); tour.show.presets = [preset]
    var fixture = tour.show.units[0].fixture
    fixture.channels[0] = 154; fixture.channels[4] = 87
    tour.show.units[0].fixture.channels = fixture.channels
    let (updated, output) = try Touring.applying(preset.id, to: [fixture.id], in: tour, fixtures: [fixture])
    #expect(output[0].channels[1] == 255)
    #expect(output[0].channels[0] == 154 && output[0].channels[4] == 87)
    #expect(output[0].startAddress == fixture.startAddress && output[0].channels.count == 16)
    #expect(updated.programming.units[fixture.id]?[1] == preset.id)
}
@Test func tourGroupDefaultsPreserveAndExplicitlyReplaceExceptions() throws {
    var tour = touringRig(); let red = colourPreset("Red", red: 255), blue = colourPreset("Blue", red: 0)
    tour.show.presets = [red, blue]
    let parent = tour.show.groups[0].id, child = tour.show.groups[1].id, units = tour.show.units.map(\.fixture)
    tour.show.programming.units[units[1].id] = [1: blue.id]
    tour.show.programming.groups[child] = [1: blue.id]
    let (defaults, output) = try Touring.applying(red.id, to: tour.members(of: parent), group: parent, in: tour, fixtures: units)
    #expect(output.map { $0.channels[1] } == [0,0,255])
    let (all, result) = try Touring.applying(red.id, to: defaults.members(of: parent), group: parent, replaceDescendants: true, in: defaults, fixtures: output)
    #expect(result.allSatisfy { $0.channels[1] == 255 })
    var newMember = InventoryUnit(fixture: Fixture(name: "Later", assetID: LightingPreview.assetID, startAddress: 65, channels: units[0].channels), groupID: child)
    newMember.fixture.channels[1] = 10
    var expanded = all; expanded.show.units.append(newMember); expanded.show.configurations[0].unitIDs.insert(newMember.id)
    #expect(try Touring.resolved(newMember.fixture, in: expanded).channels[1] == 255)
}
@Test func tourResetIndividualFallsBackToClosestGroup() throws {
    var tour = touringRig(); let red = colourPreset("Red", red: 255), blue = colourPreset("Blue", red: 0)
    tour.show.presets = [red, blue]; let unit = tour.show.units[0]
    tour.show.programming.units[unit.id] = [1: blue.id]
    tour.show.programming.groups[unit.groupID!] = [1: red.id]
    #expect(try Touring.resolved(unit.fixture, in: tour).channels[1] == 0)
    tour.programming.releasedUnits[unit.id] = [1]
    #expect(try Touring.resolved(unit.fixture, in: tour).channels[1] == 255)
}
@Test func tourGroupApplyIsAtomicOnIncompatibleMember() throws {
    var tour = touringRig(); var focus = DMXPreset(name: "Pan"); focus.includedChannels = [4,5]
    tour.show.presets = [focus]
    let cube = InventoryUnit(fixture: Fixture(name: "Cube", channels: Array(repeating: 0, count: 16)), groupID: tour.show.groups[0].id)
    tour.show.units.append(cube); tour.show.configurations[0].unitIDs.insert(cube.id)
    let before = tour
    #expect(throws: (any Error).self) { try Touring.applying(focus.id, to: tour.members(of: nil), in: tour, fixtures: []) }
    #expect(tour == before)
}
@Test func tourNamedFocusSolvesEachMountIndependently() throws {
    var tour = touringRig(); let target = FocusTarget(name: "Vocal")
    var preset = DMXPreset(name: "Focus"); preset.includedChannels = [4,5]; preset.focusTargetID = target.id
    tour.show.targets = [target]; tour.show.presets = [preset]
    tour.targetLocations[target.id] = .init(x: 1.2, y: 1.6, z: -6)
    let originals = tour.show.units.map(\.fixture)
    let (session, output) = try Touring.applying(preset.id, to: tour.members(of: nil), in: tour, fixtures: originals)
    #expect(Set(output.map { $0.channels[4] }).count > 1)
    for fixture in output {
        let expected = try FixtureAiming.articulated(fixture, target: session.targetLocations[target.id]!)
        #expect(fixture.channels[4] == expected.pan && fixture.channels[5] == expected.tilt)
        #expect(fixture.channels[1] == originals[0].channels[1])
    }
    var moved = output[0]; moved.position.x += 0.8
    #expect(try Touring.resolved(moved, in: session).channels == moved.channels)
    #expect(try Touring.resolved(moved, in: session, solveFocus: true).channels[4] != moved.channels[4])
}
@Test func tourMissingFocusLocationBlocksOutput() throws {
    var tour = touringRig(); let target = FocusTarget(name: "Vocal")
    var preset = DMXPreset(name: "Focus"); preset.includedChannels = [4,5]; preset.focusTargetID = target.id
    tour.show.targets = [target]; tour.show.presets = [preset]
    #expect(throws: (any Error).self) { try Touring.applying(preset.id, to: tour.members(of: nil), in: tour, fixtures: tour.show.units.map(\.fixture)) }
}
@Test func tourTransformPreservesScalePatchAndProgramming() throws {
    let fixtures = touringRig().show.units.map(\.fixture)
    let result = try Touring.transformed(fixtures, ids: Set(fixtures.map(\.id)), translation: .init(x: 1,y: 0,z: 2), yaw: 90)
    for (before, after) in zip(fixtures, result) {
        #expect(before.id == after.id && before.scale == after.scale && before.channels == after.channels && before.startAddress == after.startAddress)
    }
    let d1 = FixtureAiming.vector(fixtures[1].position)-FixtureAiming.vector(fixtures[0].position)
    let d2 = FixtureAiming.vector(result[1].position)-FixtureAiming.vector(result[0].position)
    #expect(abs(d1.x*d1.x+d1.z*d1.z - d2.x*d2.x-d2.z*d2.z) < 0.001)
    #expect(throws: (any Error).self) { try Touring.transformed(fixtures, ids: [UUID()], translation: .init(x: 0,y: 0,z: 0)) }
}
@Test func tourArchiveRoundTripRetainsUnplacedAndUnusedPresets() throws {
    var tour = touringRig(); tour.show.presets = [colourPreset("Unused", red: 42)]
    tour.show.quantities = [EquipmentQuantity(name: "Clamps", quantity: 12)]
    var archive = TouringArchive(); archive.active = tour; archive.shows = [tour.show]
    let decoded = try JSONDecoder().decode(TouringArchive.self, from: JSONEncoder().encode(archive))
    try decoded.validate(); #expect(decoded == archive)
}
@Test func tourPinnedSessionUnaffectedByShowLibraryEdits() throws {
    let original = touringRig(); var archive = TouringArchive(); archive.active = original; archive.shows = [original.show]
    archive.shows[0].units.removeLast(); archive.shows[0].revision += 1
    #expect(archive.active?.show.units.count == 3)
    #expect(archive.active?.show.revision == 1)
}
@Test func legacyPresetDecodesAsFullFrame() throws {
    let data = Data("{\"id\":\"10000000-0000-0000-0000-000000000001\",\"name\":\"Legacy\",\"channels\":[0,12,0,255]}".utf8)
    let preset = try JSONDecoder().decode(DMXPreset.self, from: data)
    #expect(preset.includedChannels == nil && preset.channelMask == Set(0..<4) && preset.focusTargetID == nil)
}
@Test func tourRejectsEmptyMasksDuplicateIDsAndDanglingBindings() throws {
    var preset = DMXPreset(name: "Bad"); preset.includedChannels = []; #expect(preset.validationIssue != nil)
    preset.includedChannels = [1,1]; #expect(preset.validationIssue != nil)
    var tour = touringRig(); tour.show.revision = Int.max
    #expect(throws: (any Error).self) { try tour.validate() }
    tour = touringRig(); tour.show.units.append(tour.show.units[0]); #expect(throws: (any Error).self) { try tour.validate() }
    tour = touringRig(); tour.programming.groups[tour.show.groups[0].id] = [0: UUID()]
    #expect(throws: (any Error).self) { try tour.validate() }
}

@Test func touringVenuePortableRoundTripKeepsPinnedInventoryAndUnusedPresets() throws {
    let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../VenueVolume/Environments/Classroom").standardizedFileURL
    let manifest = try JSONDecoder().decode(EnvironmentManifest.self, from: Data(contentsOf: folder.appendingPathComponent("environment.json")))
    let room = LibraryRoom(manifest: manifest, origin: .bundled)
    var tour = touringRig(); tour.show.presets = [colourPreset("Unused", red: 42)]
    var fixture = tour.show.units[0].fixture; fixture.position = .init(x: 2,y: 0,z: -2)
    let setup = VenueSetup(name: "Touring room", room: room, fixtures: [fixture], presets: tour.presets, revision: 1, whiteRoom: true, houseLight: 0.15, tour: tour)
    let source = VenueSave(room: room, setup: setup, asset: try Data(contentsOf: folder.appendingPathComponent("environment.usdz")))
    let decoded = try JSONDecoder().decode(VenueSave.self, from: JSONEncoder().encode(source))
    try decoded.validate(assetChecksum: manifest.asset.sha256)
    #expect(decoded.setup.tour == tour && decoded.setup.presets.count == 1)
    #expect(decoded.setup.tour?.activeUnits.count == 3 && decoded.setup.placements.fixtures.count == 1)
    var bad = decoded.setup; bad.presets = []
    #expect(throws: (any Error).self) { try bad.validate(room: room) }
}
@Test func touringUnavailableUnitsAndMismatchedLayoutAreRejected() throws {
    var tour = touringRig(); tour.show.units[0].unavailable = true
    #expect(throws: (any Error).self) { try tour.validate(fixtures: [tour.show.units[0].fixture]) }
    var wrong = tour.show.units[1].fixture; wrong.channels.removeLast()
    tour.show.configurations[0].layout = [wrong]
    #expect(throws: (any Error).self) { try tour.validate() }
}
@Test func touringFocusMaskMustKeepThePairTogether() {
    var preset = DMXPreset(name: "Half focus"); preset.includedChannels = [4]
    #expect(preset.validationIssue != nil)
    preset.includedChannels = [4,5]; #expect(preset.validationIssue == nil)
}
