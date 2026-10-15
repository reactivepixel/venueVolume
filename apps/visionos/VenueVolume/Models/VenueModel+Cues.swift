import SwiftUI
import VenueVolumeCore

extension VenueModel {
    var cueScope: String {
        if let tour { return "show:\(tour.show.id.uuidString):\(tour.configurationID.uuidString)" }
        return "room:\(environment?.id ?? "none"):\(environment?.version ?? "none")"
    }
    var cueSheet: CueSheet { cueSheets[cueScope] ?? CueSheet() }
    var currentCue: Int { cueSheet.current }
    var currentCueLabel: String { CueSheet.label(currentCue) }
    var canSaveCue: Bool { !selectedFixtureIDs.isEmpty && !libraryBusy && !isRetargeting && tourPreview == nil && presetDraft.validationIssue == nil && presetDraft.referenceIssue(in: presets) == nil }
    var paletteSelectionIsMixed: Bool {
        guard let first = selectedFixtures.first else { return false }
        let sample = renderedChannels(for: first, at: 0)
        return selectedFixtures.dropFirst().contains { renderedChannels(for: $0, at: 0) != sample }
    }
    func paletteSeconds(at now: Double = ProcessInfo.processInfo.systemUptime) -> Double { palettePlayback.seconds(at: now) }
    func setPalettePlaying(_ playing: Bool, at now: Double = ProcessInfo.processInfo.systemUptime) {
        palettePlayback.setPlaying(playing, at: now); fixtureRenderRevision += 1
    }
    func setPhaserMode(_ enabled: Bool) {
        guard enabled != (presetDraft.phaser != nil) else { return }
        beginHistoryAction(enabled ? "Use phaser values" : "Use static values"); defer { endHistoryAction() }
        if enabled {
            let values = Dictionary(uniqueKeysWithValues: presetDraft.channelMask.map { ($0, presetDraft.channels[$0]) })
            presetDraft.phaser = Phaser(steps: [.init(values: values), .init(values: values)], beatsPerMinute: 120, measure: 4)
        } else {
            let channels = presetDraft.sampledChannels(at: paletteSeconds(), palettes: presets)
            presetDraft.phaser = nil; presetDraft.channels = channels
        }
    }
    func programmerDidChange(from old: DMXPreset) {
        guard old != presetDraft, !loadingProgrammer, !restoringHistory, presetWindowVisible else { return }
        if [4,5].contains(where: { old.channels.indices.contains($0) && presetDraft.channels.indices.contains($0) && old.channels[$0] != presetDraft.channels[$0] }) {
            paletteDraftTarget = nil
        }
        previewDraft = !selectedFixtureIDs.isEmpty
        programmerEdited = true
        programmerSelection = selectedFixtureIDs
        programmerCue = currentCue
    }
    /// Call whenever the editor opens or selection changes. Cue layers take
    /// priority over pool definitions, so edits start from the selected output.
    func paletteSelectionChanged() {
        guard savePendingCueEdits() else { return }
        refreshPaletteSelection()
    }
    func finishPaletteEditing() { _ = savePendingCueEdits() }
    func refreshPaletteSelection() {
        guard presetWindowVisible, !restoringHistory else { return }
        paletteDraftTarget = nil
        loadingProgrammer = true
        defer { loadingProgrammer = false; programmerEdited = false; programmerSelection = selectedFixtureIDs; programmerCue = currentCue }
        previewDraft = false
        guard let first = selectedFixtures.first else { return }
        let pool = presetDraft.pool
        let look = cueSheet.look(for: first.id)
        let layer = look?.layers.last(where: { $0.palette.pool == pool }) ?? look?.layers.last
        let assigned = layer?.palette ?? presets.last(where: { first.referencedPaletteIDs.contains($0.id) && $0.pool == pool }) ?? presets.last(where: { first.referencedPaletteIDs.contains($0.id) })
        if var assigned {
            // Keep the values pinned in this cue even if a library source was
            // subsequently edited. Selecting a source again opts into its update.
            if let layer, var phaser = assigned.phaser {
                for index in phaser.steps.indices {
                    if let id = phaser.steps[index].paletteID, let source = layer.sources.first(where: { $0.id == id }), !presets.contains(source) {
                        for channel in assigned.channelMask { phaser.steps[index].values[channel] = source.channels[channel] }
                        phaser.steps[index].paletteID = nil
                    }
                }
                assigned.phaser = phaser
            }
            presetDraft = assigned
            editingPresetID = presets.contains(where: { $0.id == assigned.id }) ? assigned.id : nil
        } else {
            var draft = DMXPreset(name: "\(pool.label) · \(first.name)", channels: renderedChannels(for: first, at: 0))
            draft.setPool(pool); presetDraft = draft; editingPresetID = nil
        }
        // Reading a mixed selection must never project the first fixture's look
        // onto every other fixture. The first deliberate edit enables preview.
        presetMessage = nil
    }
    /// Preserve other dynamic attributes, including linked step values, while
    /// holding position. The cue stores a separate solution for each fixture.
    func paletteHoldingAim(_ palette: DMXPreset, aim: PanTiltOverride) -> DMXPreset {
        var result = palette
        result.focusTargetID = nil
        result.channels[4] = aim.pan; result.channels[5] = aim.tilt
        if var phaser = result.phaser, !result.channelMask.isDisjoint(with: [4,5]) {
            for index in phaser.steps.indices {
                if let id = phaser.steps[index].paletteID, let source = presets.first(where: { $0.id == id }) {
                    for channel in result.channelMask { phaser.steps[index].values[channel] = source.channels[channel] }
                    phaser.steps[index].paletteID = nil
                }
                phaser.steps[index].values[4] = aim.pan; phaser.steps[index].values[5] = aim.tilt
            }
            result.phaser = phaser
        }
        return result
    }
    func cuePalette(_ palette: DMXPreset, fixtureID: UUID) throws -> DMXPreset {
        if let target = paletteDraftTarget, palette.id == presetDraft.id, let fixture = fixture(fixtureID),
           palette.channels.count >= 6, !palette.channelMask.isDisjoint(with: [4,5]) {
            return paletteHoldingAim(palette, aim: try FixtureAiming.articulated(fixture, target: target))
        }
        guard palette.focusTargetID != nil, var session = tour, let fixture = fixture(fixtureID) else { return palette }
        session.presetOverrides.removeAll { $0.id == palette.id }; session.presetOverrides.append(palette)
        for channel in palette.channelMask { session.programming.units[fixtureID, default: [:]][channel] = palette.id }
        let channels = try Touring.resolved(fixture, in: session, solveFocus: true).channels
        var resolved = palette; resolved.focusTargetID = nil
        for channel in [4,5] { resolved.channels[channel] = channels[channel] }
        if var phaser = resolved.phaser {
            for index in phaser.steps.indices {
                if let id = phaser.steps[index].paletteID, let source = presets.first(where: { $0.id == id }) {
                    for channel in resolved.channelMask { phaser.steps[index].values[channel] = source.channels[channel] }
                    phaser.steps[index].paletteID = nil
                }
                for channel in [4,5] { phaser.steps[index].values[channel] = channels[channel] }
            }
            resolved.phaser = phaser
        }
        return resolved
    }
    func updateCueLibrary(_ palette: DMXPreset) {
        for scope in cueSheets.keys { cueSheets[scope]?.updateLibrary(palette) }
        fixtureRenderRevision += 1
    }
    @discardableResult func recordCuePalette(_ palette: DMXPreset, targets: Set<UUID>, number: Int? = nil, linked: Bool = false) -> Bool {
        var sheet = cueSheet
        sheet.include(fixtures, palettes: presets)
        do {
            for id in targets {
                let resolved = try cuePalette(palette, fixtureID: id)
                try sheet.record(resolved, for: [id], at: number, sources: presets, linked: linked && palette.focusTargetID == nil)
            }
            try sheet.validate()
            cueSheets[cueScope] = sheet
            fixtureRenderRevision += 1
            return true
        } catch { presetMessage = error.localizedDescription; return false }
    }
    @discardableResult func saveCue(number: Int? = nil) -> Bool {
        guard canSaveCue else { presetMessage = presetDraft.validationIssue ?? "Select fixtures before recording a cue."; return false }
        let number = number ?? currentCue
        beginHistoryAction("Record cue \(CueSheet.label(number)) · \(presetDraft.name)"); defer { endHistoryAction() }
        guard recordCuePalette(presetDraft, targets: selectedFixtureIDs, number: number) else { return false }
        revision += 1; programmerEdited = false; previewDraft = false
        if number != currentCue { refreshPaletteSelection() }
        presetMessage = "Saved \(selectedFixtureIDs.count) fixtures to cue \(CueSheet.label(number))."
        return true
    }
    @discardableResult func savePendingCueEdits() -> Bool {
        guard programmerEdited, presetWindowVisible, !programmerSelection.isEmpty, !restoringHistory else { return true }
        beginHistoryAction("Record cue \(CueSheet.label(programmerCue))"); defer { endHistoryAction() }
        guard recordCuePalette(presetDraft, targets: programmerSelection, number: programmerCue) else { return false }
        revision += 1; programmerEdited = false; previewDraft = false
        return true
    }
    func selectCue(_ number: Int) {
        guard !libraryBusy, !isRetargeting, tourPreview == nil, CueSheet.numbers.contains(number), number != currentCue, savePendingCueEdits() else { return }
        beginHistoryAction("Go to cue \(CueSheet.label(number))"); defer { endHistoryAction() }
        var sheet = cueSheet; sheet.include(fixtures, palettes: presets); sheet.select(number)
        cueSheets[cueScope] = sheet
        previewDraft = false; revision += 1; fixtureRenderRevision += 1
        refreshPaletteSelection()
        presetMessage = "Cue \(currentCueLabel) · unchanged attributes track from earlier cues."
    }
    func stepCue(_ offset: Int) { selectCue(currentCue + offset) }
}
