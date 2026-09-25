import Foundation
import VenueVolumeCore

@main
struct SessionSmoke {
    @MainActor static func main() async throws {
        let suite = "venue-volume-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
        }
        let model = VenueModel(arguments: [], defaults: defaults)
        check(model.recent.items.isEmpty, "New session must show the recent guide")
        model.canPlace = true
        model.beginPlacement()
        model.place(at: [0, 1, -2])
        let fixtureID = model.fixtures[0].id
        let presetID = model.presets[0].id
        check(model.applyPreset(presetID, to: fixtureID), "Apply saved preset")
        let applied = model.fixtures[0].channels
        model.choosePreset(model.presets[0])
        model.presetDraft.channels[0] = 42
        check(model.fixtures[0].channels == applied, "Drafts must not affect fixtures")
        let revision = model.revision
        check(model.savePreset(), "Save succeeds")
        check(model.fixtures[0].channels[0] == 42 && model.revision == revision + 1, "Saving updates fixtures and sync revision")
        model.presetDraft.channels[0] = 100
        model.presetDraft.name = "Independent copy"
        check(model.savePreset(asNew: true), "Save as succeeds")
        check(model.fixtures[0].presetID == presetID && model.fixtures[0].channels[0] == 42, "Save as must preserve original assignments")
        let restored = VenueModel(arguments: [], defaults: defaults)
        check(restored.presets == model.presets, "Saved presets survive relaunch")
        check(restored.fixtures.isEmpty, "Fixture locations remain session-only")
        let savedCount = model.presets.count
        model.newPreset()
        model.presetDraft.name = " "
        check(!model.savePreset() && model.presets.count == savedCount, "Invalid preset must not save")
        model.clearAssignment(fixtureID)
        check(model.fixtures[0].presetID == nil && model.fixtures[0].channels.allSatisfy { $0 == 0 }, "Clear assignment zeros channels")
        check(model.applyPreset(presetID, to: fixtureID), "Reassign")
        model.deletePreset(presetID)
        check(model.fixtures[0].presetID == nil && model.fixtures[0].channels.allSatisfy { $0 == 0 }, "Delete clears assigned values")
        check(!model.recent.items.contains(.preset(presetID)), "Delete removes stale recent preset")
        await model.sync()
        check(!model.hasUnsyncedChanges && model.syncStatus.contains("HTTP 200"), "Sync accepts the new snapshot")
        model.remove(fixtureID)
        check(!model.recent.items.contains(.fixture(fixtureID)), "Delete removes stale recent object")
        check(model.selectedID == nil && model.expandedID == nil, "Delete clears selection")
        print("Session smoke checks passed: drafts, Save, Save As, persistence, clear, delete, recents, mock sync.")
    }
}
