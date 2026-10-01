import Foundation

public struct RoomPlacements: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public let environmentID: String
    public let environmentVersion: String
    public let revision: Int
    public let fixtures: [Fixture]

    public init(environment: EnvironmentManifest, fixtures: [Fixture], revision: Int) {
        environmentID = environment.id
        environmentVersion = environment.version
        self.fixtures = fixtures
        self.revision = revision
    }

    public func validate(environment: EnvironmentManifest) throws {
        guard schemaVersion == 1, environmentID == environment.id, environmentVersion == environment.version,
              revision >= 0, fixtures.count <= 64, Set(fixtures.map(\.id)).count == fixtures.count else {
            throw EnvironmentError.invalid("saved placements belong to a different room version or are invalid")
        }
        for fixture in fixtures {
            if let issue = fixture.validationIssue(among: fixtures) { throw EnvironmentError.invalid(issue) }
            if let surfaceID = fixture.surfaceID, !environment.surfaces.contains(where: { $0.id == surfaceID }) {
                throw EnvironmentError.invalid("saved placement surface no longer exists")
            }
        }
    }
}

/// Room-relative state; deliberately separate from the immutable asset bundle / future download cache.
public struct PlacementStore: Sendable {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }

    private func url(for environment: EnvironmentManifest) throws -> URL {
        try environment.validate()
        return directory.appendingPathComponent(environment.id + "-" + environment.version + ".json")
    }

    public func load(environment: EnvironmentManifest) throws -> RoomPlacements? {
        let file = try url(for: environment)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let saved = try JSONDecoder().decode(RoomPlacements.self, from: Data(contentsOf: file))
        try saved.validate(environment: environment)
        return saved
    }

    public func save(_ placements: RoomPlacements, environment: EnvironmentManifest) throws {
        try placements.validate(environment: environment)
        guard placements.environmentID == environment.id, placements.environmentVersion == environment.version else {
            throw EnvironmentError.invalid("cannot save placements against another room")
        }
        let file = try url(for: environment)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(placements).write(to: file, options: .atomic)
    }
}
