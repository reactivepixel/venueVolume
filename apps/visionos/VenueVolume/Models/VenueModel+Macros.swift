import SwiftUI
import VenueVolumeCore

extension VenueModel {
    var macroGroups: [(id: UUID, name: String)] {
        if let tour { return tour.show.groups.map { ($0.id, $0.name) } }
        return fixtureGroups.map { id in (id, fixtures.first { $0.groupID == id }?.groupName ?? "Group") }
    }
    private var macroGroupMembers: [UUID: Set<UUID>] {
        Dictionary(uniqueKeysWithValues: macroGroups.map { group in
            (group.id, tour.map { $0.members(of: group.id).intersection(Set(fixtures.map(\.id))) }
                ?? Set(fixtures.filter { $0.groupID == group.id }.map(\.id)))
        })
    }
    private func prepareMacro(_ macro: ProgrammingMacro) throws -> (MacroPlan, TourSession?, [Fixture]) {
        guard !libraryBusy, !historyBlocked, !touringBlocked, !isRetargeting, tourPreview == nil else {
            throw PresetError("Finish the current placement or preview before running a macro.")
        }
        let plan = try macro.plan(selection: selectedFixtureIDs, groups: macroGroupMembers, fixtures: fixtures, palettes: presets)
        guard var session = tour else { return (plan, nil, plan.fixtures) }
        var updated = fixtures
        for palette in plan.palettes {
            (session, updated) = try Touring.applying(palette.id, to: plan.targetIDs, in: session, fixtures: updated)
        }
        return (plan, session, updated)
    }
    func inspectMacro(_ macro: ProgrammingMacro) -> String {
        do {
            let (plan, _, _) = try prepareMacro(macro)
            return "Ready · \(plan.targetIDs.count) fixtures · " + plan.palettes.map(\.name).joined(separator: " → ")
        } catch { return error.localizedDescription }
    }
    func canRunMacro(_ macro: ProgrammingMacro) -> Bool { (try? prepareMacro(macro)) != nil }
    @discardableResult func runMacro(_ macro: ProgrammingMacro) -> Bool {
        do {
            let (plan, session, updated) = try prepareMacro(macro)
            var sheet = cueSheet
            sheet.include(fixtures, palettes: presets)
            for palette in plan.palettes { try sheet.record(palette, for: plan.targetIDs, sources: presets, linked: true) }
            try sheet.validate()
            beginHistoryAction("Run macro · \(macro.name)"); defer { endHistoryAction() }
            let previousCues = cueSheets
            cueSheets[cueScope] = sheet
            if let session {
                guard commitTour(session, fixtures: updated, title: "Run macro · \(macro.name)") else { cueSheets = previousCues; macroMessage = message; return false }
            } else if fixtures != updated { fixtures = updated; revision += 1; persist() }
            programmerEdited = false; previewDraft = false; refreshPaletteSelection()
            macroMessage = "Ran \(macro.name) on \(plan.targetIDs.count) fixtures. Undo restores the whole run."
            return true
        } catch { macroMessage = error.localizedDescription; return false }
    }
    @discardableResult func storeMacro(_ macro: ProgrammingMacro) -> Bool {
        if let issue = macro.validationIssue { macroMessage = issue; return false }
        var saved = macro; saved.name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = programmingMacros
        if let index = next.firstIndex(where: { $0.id == saved.id }) { next[index] = saved } else { next.append(saved) }
        do {
            let data = try JSONEncoder().encode(next)
            if !isDemoMode { defaults.set(data, forKey: "venue.programming-macros.v1") }
            programmingMacros = next; macroMessage = "Stored macro · \(saved.name)"; return true
        } catch { macroMessage = error.localizedDescription; return false }
    }
    func rememberPhaserStep(_ step: PhaserStep) {
        recentPhaserSteps.removeAll { $0 == step }; recentPhaserSteps.insert(step, at: 0)
        recentPhaserSteps = Array(recentPhaserSteps.prefix(6))
    }
}

// Cue programming is independent of fixture placement and the reusable library.
