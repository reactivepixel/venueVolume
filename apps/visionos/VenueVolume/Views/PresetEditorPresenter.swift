import SwiftUI

private struct PresetEditorPresenter: ViewModifier {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    let enabled: Bool

    func body(content: Content) -> some View {
        content.task(id: enabled ? model.presetEditor.taskID : nil) {
            guard enabled, let request = model.presetEditor.latestRequest,
                  model.presetEditor.claim(request) else { return }
            var retryIfUnfinished = true
            defer { model.presetEditor.release(request, retryIfUnfinished: retryIfUnfinished) }
            dismissWindow(id: "presets")
            for _ in 0..<60 where !model.presetEditor.windowIDs.isEmpty {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
            }
            guard !Task.isCancelled, model.presetEditor.latestRequest?.id == request.id else { return }
            guard model.presetEditor.canPresent(request) else {
                retryIfUnfinished = false
                model.presetEditor.failureMessage = "The previous preset editor is still closing. Try opening it again."
                return
            }
            model.presetEditor.didOpen(request)
            openWindow(id: "presets", value: request.id)
        }
    }
}

extension View {
    func presetEditorPresenter(when enabled: Bool = true) -> some View {
        modifier(PresetEditorPresenter(enabled: enabled))
    }
}
