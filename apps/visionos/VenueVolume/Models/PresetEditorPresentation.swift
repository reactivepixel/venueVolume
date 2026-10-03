import Foundation
import Observation

/// Window requests stay separate from the draft so recalling the editor never
/// discards edits. The presenter closes every old window before opening this ID.
@Observable @MainActor
final class PresetEditorPresentation {
    struct Request: Equatable {
        let id: UUID
        let presetID: UUID?
    }

    private(set) var latestRequest: Request?
    private(set) var windowIDs: Set<UUID> = []
    private(set) var handledRequestID: UUID?
    private var presentingRequestID: UUID?
    var failureMessage: String?

    func request(presetID: UUID? = nil) {
        latestRequest = Request(id: UUID(), presetID: presetID)
        failureMessage = nil
    }

    func canPresent(_ request: Request) -> Bool {
        latestRequest?.id == request.id && handledRequestID != request.id && windowIDs.isEmpty
    }

    /// Several restored companion windows can offer a presenter, but only one
    /// may perform the close/open sequence for a request.
    func claim(_ request: Request) -> Bool {
        guard latestRequest?.id == request.id, handledRequestID != request.id,
              presentingRequestID != request.id else { return false }
        presentingRequestID = request.id
        return true
    }

    func release(_ request: Request) {
        if presentingRequestID == request.id { presentingRequestID = nil }
    }

    func didOpen(_ request: Request) {
        guard latestRequest?.id == request.id else { return }
        handledRequestID = request.id
    }

    func registerWindow(_ id: UUID) {
        windowIDs.insert(id)
        if windowIDs.count > 1 {
            // Restored windows can arrive after a dismissal. Consolidate them
            // through the same serialized path instead of leaving duplicates.
            request(presetID: latestRequest?.presetID)
        }
    }

    /// True only when the user closed the last editor, not while recalling it.
    func unregisterWindow(_ id: UUID) -> Bool {
        windowIDs.remove(id)
        return windowIDs.isEmpty && latestRequest?.id == handledRequestID
    }

    func requestedPreset(for windowID: UUID) -> UUID? {
        guard latestRequest?.id == windowID else { return nil }
        return latestRequest?.presetID
    }
}
