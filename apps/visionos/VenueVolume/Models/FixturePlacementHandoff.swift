import Foundation
import VenueVolumeCore

struct PendingFixturePlacement {
    let id: UUID
    let link: FixturePlacementLink
    var roomToken: UUID?
    var prepared = false
}

enum PlacementHandoffPreparation { case needsSaveDecision, ready, failed }

extension VenueModel {
    @discardableResult func receivePlacementLink(_ url: URL) -> Bool {
        do {
            let link = try FixturePlacementLink(url: url)
            guard !libraryBusy, !isTransitioning else {
                placementLinkMessage = "A venue is already opening. Open the placement link again when it finishes."
                return false
            }
            pendingFixturePlacement = .init(id: UUID(), link: link)
            placementLinkMessage = "Looking for the linked Load Out on this Vision Pro…"
            return true
        } catch {
            placementLinkMessage = error.localizedDescription
            return false
        }
    }

    func cancelPlacementHandoff(_ id: UUID? = nil, message: String? = nil) {
        guard id == nil || pendingFixturePlacement?.id == id else { return }
        pendingFixturePlacement = nil
        if let message { placementLinkMessage = message }
    }

    /// Resolve exact identities before requesting a room. A URL cannot create units,
    /// revive a deleted fixture, infer a room from its name or discard unsaved work.
    func preparePlacementHandoff(_ id: UUID, discardChanges: Bool = false) -> PlacementHandoffPreparation {
        guard var request = pendingFixturePlacement, request.id == id else { return .failed }
        guard !libraryBusy, !isTransitioning else {
            cancelPlacementHandoff(id, message: "Wait for the current venue operation, then open the link again.")
            return .failed
        }
        let link = request.link
        if activeSetupID == link.loadOutID, activeRoom != nil {
            guard fixture(link.fixtureID) != nil else {
                cancelPlacementHandoff(id, message: "The selected fixture is not in the current Load Out. Refresh the fixture selection in SaaS.")
                return .failed
            }
            request.roomToken = roomLoadToken
            request.prepared = true
            pendingFixturePlacement = request
            placementLinkMessage = "Opening \(setupName) for fixture placement…"
            finishPlacementHandoffIfReady()
            return .ready
        }
        guard let setup = savedSetups.first(where: { $0.id == link.loadOutID }) else {
            cancelPlacementHandoff(id, message: "This Load Out is not on this Vision Pro. Automatic transfer from SaaS is not implemented yet. A placement link can only open a native save with the same Load Out and fixture IDs.")
            return .failed
        }
        guard setup.placements.fixtures.contains(where: { $0.id == link.fixtureID }) else {
            cancelPlacementHandoff(id, message: "This fixture is not in the saved Load Out. Refresh the fixture selection in SaaS.")
            return .failed
        }
        guard let room = rooms.first(where: { $0.id == setup.roomID }) else {
            cancelPlacementHandoff(id, message: "The scanned room for this Load Out is unavailable on this Vision Pro.")
            return .failed
        }
        do { try setup.validate(room: room) }
        catch { cancelPlacementHandoff(id, message: "This Load Out could not be validated: \(error.localizedDescription)"); return .failed }
        guard discardChanges || !hasUnsavedSetup else { return .needsSaveDecision }
        requestRoom(room, setup: setup, preservingPlacementLink: true)
        guard roomRequest?.setup?.id == setup.id else {
            cancelPlacementHandoff(id, message: "The Load Out could not be opened. Try again.")
            return .failed
        }
        request.roomToken = roomLoadToken
        request.prepared = true
        pendingFixturePlacement = request
        placementLinkMessage = "Opening \(setup.name) for fixture placement…"
        return .ready
    }

    /// Called after room assets AND tracking are ready. Selecting a fixture never
    /// adds a duplicate; the existing placement tool moves that exact unit.
    func finishPlacementHandoffIfReady() {
        guard let request = pendingFixturePlacement, request.prepared,
              isImmersed, canPlace, !libraryBusy else { return }
        guard request.roomToken == roomLoadToken,
              activeSetupID == request.link.loadOutID,
              let fixture = fixture(request.link.fixtureID) else {
            cancelPlacementHandoff(request.id, message: "The venue selection changed. Open the placement link again to continue.")
            return
        }
        pendingFixturePlacement = nil
        beginReposition(fixture.id)
        placementLinkMessage = "Placing \(fixture.name) in \(setupName). Look at a supported surface and pinch to place."
        message = placementLinkMessage
    }
}
