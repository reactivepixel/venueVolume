import Foundation

/// Navigation only: never imports data, creates a fixture or changes its placement.
public struct FixturePlacementLink: Equatable, Sendable {
    public let loadOutID: UUID
    public let fixtureID: UUID

    public init(loadOutID: UUID, fixtureID: UUID) {
        self.loadOutID = loadOutID
        self.fixtureID = fixtureID
    }

    public init(url: URL) throws {
        guard url.absoluteString.utf8.count <= 512,
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "venuevolume", parts.host?.lowercased() == "place",
              parts.path.isEmpty, parts.user == nil, parts.password == nil, parts.port == nil,
              parts.fragment == nil,
              let items = parts.queryItems, items.count == 3,
              Set(items.map(\.name)) == Set(["version", "loadout", "fixture"]),
              items.first(where: { $0.name == "version" })?.value == "1",
              let loadOut = items.first(where: { $0.name == "loadout" })?.value,
              let fixture = items.first(where: { $0.name == "fixture" })?.value,
              let loadOutID = UUID(uuidString: loadOut), let fixtureID = UUID(uuidString: fixture),
              loadOut.lowercased() == loadOutID.uuidString.lowercased(),
              fixture.lowercased() == fixtureID.uuidString.lowercased() else {
            throw EnvironmentError.invalid("This placement link is invalid or uses an unsupported version.")
        }
        self.init(loadOutID: loadOutID, fixtureID: fixtureID)
    }

    public var url: URL {
        var parts = URLComponents()
        parts.scheme = "venuevolume"
        parts.host = "place"
        parts.queryItems = [URLQueryItem(name: "version", value: "1"),
                            URLQueryItem(name: "loadout", value: loadOutID.uuidString.lowercased()),
                            URLQueryItem(name: "fixture", value: fixtureID.uuidString.lowercased())]
        return parts.url!
    }
}
