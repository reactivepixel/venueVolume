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

        let handoff = PresetEditorPresentation()
        let previousWindow = UUID()
        handoff.registerWindow(previousWindow)
        handoff.request(presetID: secondPreset)
        let pending = handoff.latestRequest!, firstAttempt = handoff.taskID
        check(handoff.claim(pending) && !handoff.claim(pending), "Launch owns the recall while immersive presenter waits")
        handoff.release(pending)
        check(handoff.taskID != firstAttempt && handoff.latestRequest == pending,
              "Cancelled owner invalidates waiting presenter task without losing requested preset context")
        check(handoff.claim(pending), "Surviving immersive presenter can take over the same request")
        check(!handoff.canPresent(pending), "Handoff still waits for the old editor window to close")
        check(!handoff.unregisterWindow(previousWindow) && handoff.canPresent(pending), "Handoff preserves the draft session")
        let successfulAttempt = handoff.taskID
        handoff.didOpen(pending)
        handoff.release(pending)
        check(handoff.taskID == successfulAttempt && !handoff.claim(pending), "Completed handoff does not retry or duplicate the editor")
        check(handoff.requestedPreset(for: pending.id) == secondPreset, "Requested selection survives owner handoff")

        handoff.request(presetID: firstPreset)
        let timedOut = handoff.latestRequest!, timeoutAttempt = handoff.taskID
        check(handoff.claim(timedOut), "Next recall owns presentation")
        handoff.release(timedOut, retryIfUnfinished: false)
        check(handoff.taskID == timeoutAttempt, "Explicit close timeout does not create an automatic retry loop")
        check(handoff.claim(timedOut), "Retry can acquire the unfinished claim")
        handoff.request(presetID: secondPreset)
        let replacement = handoff.latestRequest!, replacementAttempt = handoff.taskID
        check(handoff.claim(replacement), "A newer request supersedes an older presentation owner")
        handoff.release(timedOut)
        check(handoff.taskID == replacementAttempt && !handoff.claim(replacement), "Stale owner cleanup cannot release or restart the newer owner")
        handoff.release(replacement)
        print("Editor presentation checks passed: single window, duplicate restoration, latest request wins, owner handoff, selected context and draft-session preservation.")
    }
}
