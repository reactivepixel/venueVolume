import Foundation
import Testing
@testable import VenueVolumeCore

@Test func budgetsRespectHardwareThermalAndSelection() {
    #expect(LightingBudget.effective(requested: 64, extendedHardware: false, thermal: .nominal) == 8)
    #expect(LightingBudget.effective(requested: 64, extendedHardware: true, thermal: .nominal) == 64)
    #expect(LightingBudget.effective(requested: 64, extendedHardware: true, thermal: .fair) == 16)
    #expect(LightingBudget.effective(requested: 64, extendedHardware: true, thermal: .serious) == 4)
    #expect(LightingBudget.effective(requested: 64, extendedHardware: true, thermal: .critical) == 0)
    let a = UUID(), b = UUID(), black = UUID()
    let demands: [LightingBudget.Demand] = [.init(id: a, emitters: 4, emitting: true), .init(id: black, emitters: 32, emitting: false),
                                          .init(id: b, emitters: 6, emitting: true)]
    let budgets = LightingBudget.allocate(demands, selected: b, limit: 8)
    #expect(budgets == [a: 2, b: 6])
    #expect(LightingBudget.allocate(demands, selected: black, limit: 0).isEmpty)
    #expect(LightingBudget.allocate(demands, selected: nil, limit: -1).isEmpty)
}

@Test func benchmarkKeepsIdenticalGeometryAndPatchAcrossRooms() throws {
    let a = try #require(LightingBenchmark(arguments: ["--lighting-benchmark=baseline", "--benchmark-lights=0"]))
    let b = try #require(LightingBenchmark(arguments: ["--lighting-benchmark=mappedRoom", "--benchmark-lights=64"]))
    #expect(a.fixtures() == b.fixtures())
    #expect(a.fixtures().count == 64)
    for fixture in a.fixtures() { #expect(fixture.validationIssue(among: a.fixtures()) == nil) }
    #expect(LightingBenchmark(arguments: ["--lighting-benchmark=mappedRoom", "--benchmark-lights=900"]) == nil)
    #expect(LightingBenchmark(arguments: ["--lighting-benchmark=fortress"]) == nil)
    #expect(LightingBenchmark(arguments: ["--lighting-benchmark=baseline", "--benchmark-seconds=nan"]) == nil)
}

@Test func cadenceRetainsHitchesAndRejectsNonFiniteSamples() throws {
    var cadence = SceneCadence()
    #expect(cadence.summary == nil)
    cadence.append(seconds: .nan); cadence.append(seconds: -1)
    for _ in 0..<99 { cadence.append(seconds: 0.01) }
    cadence.append(seconds: 0.5)
    let report = try #require(cadence.summary)
    #expect(report.samples == 100 && report.maximumMS == 500)
    #expect(report.p95MS == 10 && report.p99MS == 10 && report.intervalsOver16_67MS == 1)
    #expect(abs(report.meanMS-14.9) < 0.0001)
}

@Test func mappedRoomPreservesClassroomInteractionAndResolvesSeparately() async throws {
    let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../VenueVolume/Environments").standardizedFileURL
    let repo = BundledEnvironmentRepository(directory: folder)
    let a = try await repo.resolve(id: "img3153-classroom-v1")
    let b = try await repo.resolve(id: "mappedRoom")
    try a.manifest.validate(); try b.manifest.validate()
    #expect(a.manifest.bounds == b.manifest.bounds && a.manifest.spawn == b.manifest.spawn)
    #expect(a.manifest.colliders == b.manifest.colliders && a.manifest.surfaces == b.manifest.surfaces)
    #expect(a.manifest.version != b.manifest.version && a.assetURL != b.assetURL)
    await #expect(throws: EnvironmentError.self) { try await repo.resolve(id: "../../Classroom") }
}
