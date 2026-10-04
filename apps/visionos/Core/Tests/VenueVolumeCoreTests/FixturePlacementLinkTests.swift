import Foundation
import Testing
@testable import VenueVolumeCore

@Test func placementLinkRoundTripAndContract() throws {
    let loadOut = UUID(uuidString: "10000000-0000-4000-8000-000000000001")!
    let fixture = UUID(uuidString: "20000000-0000-4000-8000-000000000002")!
    let link = FixturePlacementLink(loadOutID: loadOut, fixtureID: fixture)
    #expect(link.url.absoluteString == "venuevolume://place?version=1&loadout=10000000-0000-4000-8000-000000000001&fixture=20000000-0000-4000-8000-000000000002")
    #expect(try FixturePlacementLink(url: link.url) == link)
}

@Test func rejectsMalformedPlacementLinks() {
    let good = FixturePlacementLink(loadOutID: UUID(), fixtureID: UUID()).url.absoluteString
    let bad = [good.replacingOccurrences(of: "venuevolume:", with: "https:"),
               good.replacingOccurrences(of: "://place?", with: "://delete?"),
               good.replacingOccurrences(of: "://place?", with: "://user@place?"),
               good.replacingOccurrences(of: "://place?", with: "://place:80?"),
               good.replacingOccurrences(of: "://place?", with: "://place/path?"),
               good.replacingOccurrences(of: "version=1", with: "version=2"),
               good + "&version=1", good + "&download=https://example.com", good + "#fragment",
               "venuevolume://place?version=1&loadout=room&fixture=fixture",
               "venuevolume://place?version=1&loadout=10000000-0000-4000-8000-000000000001&loadout=20000000-0000-4000-8000-000000000002"]
    for value in bad { #expect(throws: (any Error).self) { try FixturePlacementLink(url: URL(string: value)!) } }
}
