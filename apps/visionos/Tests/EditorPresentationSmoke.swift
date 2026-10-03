import Foundation

@MainActor enum EditorPresentationSmoke {
    static func run() {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
        let presentation = PresetEditorPresentation()
        let firstPreset = UUID(), secondPreset = UUID()
        presentation.request(presetID: firstPreset)
        let first = presentation.latestRequest!
        check(presentation.claim(first) && !presentation.claim(first), "Multiple restored presenters cannot open the same request")
        check(presentation.canPresent(first), "Initial request can open when no editor exists")
        presentation.didOpen(first)
        presentation.registerWindow(first.id)
        presentation.release(first)
        check(!presentation.canPresent(first), "An already handled request cannot open another window")
        check(presentation.requestedPreset(for: first.id) == firstPreset, "The new editor receives its preset context")

        presentation.request(presetID: secondPreset)
        let second = presentation.latestRequest!
        check(!presentation.canPresent(second), "Replacement must wait for the old editor to close")
        check(!presentation.unregisterWindow(first.id), "Recall does not end the draft simulation session")
        check(presentation.canPresent(second), "Replacement can open only after every prior editor closes")

        presentation.request(presetID: firstPreset)
        let latest = presentation.latestRequest!
        check(!presentation.canPresent(second) && presentation.canPresent(latest), "Latest request wins over an in-flight earlier request")
        presentation.didOpen(second)
        check(presentation.handledRequestID == first.id, "Stale completion cannot consume the latest request")
        presentation.didOpen(latest)
        presentation.registerWindow(latest.id)
        check(presentation.requestedPreset(for: second.id) == nil, "An old window cannot consume a new preset context")

        let restored = UUID()
        presentation.registerWindow(restored)
        let recovery = presentation.latestRequest!
        check(recovery.id != latest.id && recovery.presetID == firstPreset, "Duplicate restoration triggers consolidation and retains latest context")
        check(!presentation.unregisterWindow(restored) && !presentation.canPresent(recovery), "Consolidation waits for all duplicates")
        check(!presentation.unregisterWindow(latest.id) && presentation.canPresent(recovery), "Consolidation preserves the draft session")
        presentation.didOpen(recovery)
        presentation.registerWindow(recovery.id)
        check(presentation.unregisterWindow(recovery.id), "User closing the only editor ends simulation")
        presentation.request()
        check(presentation.latestRequest?.presetID == nil, "Generic recall retains the current draft instead of requesting another preset")
        print("Editor presentation checks passed: single window, duplicate restoration, latest request wins, selected context and draft-session preservation.")
    }
}
