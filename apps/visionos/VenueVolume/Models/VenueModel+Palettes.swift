import SwiftUI
import VenueVolumeCore

extension VenueModel {
    func choosePreset(_ preset: DMXPreset) {
        guard !libraryBusy else { return }
        beginHistoryAction("Open palette · \(preset.name)"); defer { endHistoryAction() }
        loadingProgrammer = true
        defer { loadingProgrammer = false; programmerEdited = false; programmerSelection = selectedFixtureIDs; programmerCue = currentCue }
        cancelTourPreview(); cancelPicking()
        previewDraft = true; previewBlackout = false
        paletteDraftTarget = nil
        presetDraft = preset
        editingPresetID = preset.id
        presetMessage = nil
        recent.use(.preset(preset.id))
    }

    func newPreset(pool: PaletteCategory = .all) {
        guard !libraryBusy else { return }
        beginHistoryAction("New palette draft"); defer { endHistoryAction() }
        loadingProgrammer = true
        defer { loadingProgrammer = false; programmerEdited = false; programmerSelection = selectedFixtureIDs; programmerCue = currentCue }
        editingPresetID = nil; paletteDraftTarget = nil
        cancelTourPreview(); cancelPicking()
        previewDraft = true; previewBlackout = false
        presetDraft = DMXPreset(name: "", channels: [255,255,255,255,128,128,128] + Array(repeating: 0, count: 9))
        presetDraft.setPool(pool)
        presetMessage = nil
    }

    @discardableResult func savePreset(asNew: Bool = false) -> Bool {
        var validationCandidate = presetDraft
        if asNew { validationCandidate.id = UUID() }
        let candidateLibrary = presets.filter { $0.id != validationCandidate.id } + [validationCandidate]
        if let issue = candidateLibrary.compactMap({ $0.referenceIssue(in: candidateLibrary) }).first { presetMessage = issue; return false }
        do {
            for var sheet in cueSheets.values { sheet.updateLibrary(validationCandidate); try sheet.validate() }
        } catch { presetMessage = "This library change would invalidate a recorded cue: \(error.localizedDescription) Store it as a new palette instead."; return false }
        if touring.active != nil { return saveTourPreset(asNew: asNew) }
        guard !libraryBusy else { return false }
        beginHistoryAction(asNew ? "Save palette as new" : "Save palette"); defer { endHistoryAction() }
        var candidate = presetDraft
        candidate.name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if asNew { candidate.id = UUID() }
        do {
            let updated = try PresetOperations.saving(candidate, fixtures: fixtures)
            var library = presets
            if let index = library.firstIndex(where: { $0.id == candidate.id }) { library[index] = candidate }
            else { library.append(candidate) }
            // Persist the validated library before publishing the new live snapshot.
            if !isDemoMode { defaults.set(try JSONEncoder().encode(library), forKey: "venue.presets.v1") }
            presets = library
            if !asNew { updateCueLibrary(candidate) }
            if fixtures != updated { fixtures = updated; revision += 1; persist() }
            choosePreset(candidate)
            presetMessage = asNew ? "Saved as a new palette. Existing assignments are unchanged." : "Saved. Assigned fixtures are updated."
            return true
        } catch {
            presetMessage = error.localizedDescription
            return false
        }
    }

    func deletePreset(_ id: UUID) {
        if presets.contains(where: { $0.phaser?.steps.contains(where: { $0.paletteID == id }) == true }) {
            presetMessage = "This palette is linked by a phaser. Change its step sources before deleting."; return
        }
        if touring.active != nil { deleteTourPreset(id); return }
        guard !libraryBusy else { return }
        beginHistoryAction("Delete palette"); defer { endHistoryAction() }
        guard presets.contains(where: { $0.id == id }) else { return }
        let updated = PresetOperations.clearing(id, fixtures: fixtures)
        if fixtures != updated { fixtures = updated; revision += 1; persist() }
        presets.removeAll { $0.id == id }
        recent.remove(.preset(id))
        if !isDemoMode, tour == nil, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        if let first = presets.first { choosePreset(first) } else { newPreset() }
        previewDraft = false
        presetMessage = "Palette deleted. Its attributes are cleared; other palette layers and aim overrides are preserved."
    }

    func clearAssignment(_ id: UUID) {
        if touring.active != nil { resetTourAssignment([id]); return }
        if !groupActionActive, actionIDs(for: id).count > 1 {
            beginHistoryAction("Clear group palette"); groupActionActive = true
            defer { groupActionActive = false; endHistoryAction() }
            for member in actionIDs(for: id) { clearAssignment(member) }
            return
        }
        guard !libraryBusy else { return }
        beginHistoryAction("Clear fixture palette"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }), !fixtures[index].referencedPaletteIDs.isEmpty else { return }
        if case .aim(let targetID) = scenePick, targetID == id { cancelPicking() }
        let cleared = DMXPreset(name: "Clear assignment", channels: Array(repeating: 0, count: fixtures[index].channels.count))
        guard recordCuePalette(cleared, targets: [id]) else { return }
        fixtures[index].presetID = nil
        fixtures[index].channelPaletteIDs = nil
        fixtures[index].channels = Array(repeating: 0, count: fixtures[index].channels.count)
        fixtures[index].preserveAimOverride()
        revision += 1
        persist()
        presetMessage = "Assignment cleared. Output is zero; any aim override is preserved."
    }

    func hasAnimatedPalette(for fixture: Fixture) -> Bool {
        if cueSheet.look(for: fixture.id)?.layers.contains(where: { $0.palette.phaser != nil }) == true { return true }
        if previewDraft && selectedFixtureIDs.contains(fixture.id) && presetDraft.phaser != nil { return true }
        if let session = tour, let unit = session.allUnits.first(where: { $0.id == fixture.id }) {
            return session.presets.contains { palette in
                palette.phaser != nil && fixture.channels.indices.contains { session.binding(for: unit, channel: $0) == palette.id }
            }
        }
        return presets.contains { fixture.referencedPaletteIDs.contains($0.id) && $0.phaser != nil }
    }

    func renderedChannels(for fixture: Fixture, at time: Double? = nil) -> [Int] {
        if isRetargeting, let targetPreview, actionIDs(for: targetPreview.id).contains(fixture.id) { return renderedFixture(fixture).channels }
        return channelsWithoutTarget(for: fixture, at: time)
    }
    private func channelsWithoutTarget(for fixture: Fixture, at time: Double? = nil) -> [Int] {
        if let preview = tourPreview?.first(where: { $0.id == fixture.id }) { return preview.channels }
        if let channels = cueSheet.sample(fixture.id, at: time ?? paletteSeconds(), order: fixtures.map(\.id)) {
            var rendered = fixture; rendered.channels = channels
            if previewDraft && selectedFixtureIDs.contains(fixture.id) {
                let draft = (try? cuePalette(presetDraft, fixtureID: fixture.id)) ?? presetDraft
                rendered.channels = PresetOperations.mergedChannels(draft, existing: channels, at: time ?? paletteSeconds(), fixtureIndex: selectedFixtures.firstIndex(where: { $0.id == fixture.id }) ?? 0, fixtureCount: max(1, selectedFixtures.count), palettes: presets)
            }
            return rendered.channels
        }
        if touring.active != nil, previewDraft, selectedUnitIDs.contains(fixture.id), Touring.compatible(presetDraft, with: fixture) {
            if presetDraft.focusTargetID != nil, var session = tour {
                session.presetOverrides.removeAll { $0.id == presetDraft.id }; session.presetOverrides.append(presetDraft)
                for channel in presetDraft.channelMask { session.programming.units[fixture.id, default: [:]][channel] = presetDraft.id }
                return (try? Touring.resolved(fixture, in: session, solveFocus: true).channels) ?? fixture.channels
            }
            var values = fixture.channels
            let sample = presetDraft.sampledChannels(at: time ?? paletteSeconds(), fixtureIndex: selectedFixtures.firstIndex(where: { $0.id == fixture.id }) ?? 0, fixtureCount: max(1, selectedFixtures.count), palettes: presets)
            for i in presetDraft.channelMask { values[i] = sample[i] }
            return values
        }
        if let session = tour, let unit = session.allUnits.first(where: { $0.id == fixture.id }) {
            let seconds = time ?? paletteSeconds()
            var values = fixture.channels
            for channel in values.indices {
                guard let id = session.binding(for: unit, channel: channel),
                      let palette = session.presets.first(where: { $0.id == id }), palette.phaser != nil,
                      !(palette.focusTargetID != nil && [4,5].contains(channel)) else { continue }
                let members = fixtures.filter { placed in
                    session.allUnits.first(where: { $0.id == placed.id }).map { session.binding(for: $0, channel: channel) == id } ?? false
                }
                let sample = palette.sampledChannels(at: seconds, fixtureIndex: members.firstIndex(where: { $0.id == fixture.id }) ?? 0, fixtureCount: max(1,members.count), palettes: presets)
                values[channel] = sample[channel]
            }
            return values
        }
        let seconds = time ?? paletteSeconds()
        func phasePosition(for paletteID: UUID, draft: Bool = false) -> (index: Int, count: Int) {
            let members = fixtures.filter { draft ? selectedFixtureIDs.contains($0.id) : $0.referencedPaletteIDs.contains(paletteID) }
            return (members.firstIndex(where: { $0.id == fixture.id }) ?? 0, max(1, members.count))
        }
        var rendered = fixture
        if let owners = fixture.channelPaletteIDs {
            for paletteID in Set(owners.values) {
                guard let palette = presets.first(where: { $0.id == paletteID }) else { continue }
                let phase = phasePosition(for: paletteID)
                let sampled = palette.sampledChannels(at: seconds, fixtureIndex: phase.index, fixtureCount: phase.count, palettes: presets)
                for (channel, owner) in owners where owner == paletteID && rendered.channels.indices.contains(channel) && sampled.indices.contains(channel) {
                    rendered.channels[channel] = sampled[channel]
                }
            }
        } else if let palette = presets.first(where: { $0.id == fixture.presetID }) {
            let phase = phasePosition(for: palette.id)
            rendered.channels = PresetOperations.mergedChannels(palette, existing: rendered.channels, at: seconds, fixtureIndex: phase.index, fixtureCount: phase.count, palettes: presets)
        }
        if previewDraft && selectedFixtureIDs.contains(fixture.id) {
            let phase = phasePosition(for: presetDraft.id, draft: true)
            rendered.channels = PresetOperations.mergedChannels(presetDraft, existing: rendered.channels, at: seconds, fixtureIndex: phase.index, fixtureCount: phase.count, palettes: presets)
        }
        rendered.preserveAimOverride()
        return rendered.channels
    }

    func renderedFixture(_ fixture: Fixture) -> Fixture {
        if let preview = tourPreview?.first(where: { $0.id == fixture.id }) { return preview }
        if isPaletteCueTarget, selectedFixtureIDs.contains(fixture.id), let target = pendingTarget,
           let aimed = try? paletteTargetFixture(fixture, at: target) { return aimed }
        guard let preview = targetPreview, isRetargeting else { return fixture }
        if preview.id != fixture.id {
            guard actionIDs(for: preview.id).contains(fixture.id), let target = pendingTarget else { return fixture }
            var current = fixture
            current.channels = targetingPreset?.channels ?? fixture.channels
            current.aimOverride = nil
            if let aim = try? FixtureAiming.articulated(current, target: target), current.channels.count >= 6 {
                current.channels[4] = aim.pan; current.channels[5] = aim.tilt
            }
            return current
        }
        var current = fixture
        current.channels = targetingPreset?.channels ?? preview.channels
        if current.channels.count >= 6 {
            current.channels[4] = preview.channels[4]; current.channels[5] = preview.channels[5]
        }
        current.aimOverride = nil
        return current
    }

    func isBlackedOut(_ fixture: Fixture) -> Bool {
        blackout || (previewDraft && previewBlackout && (selectedFixtureIDs.contains(fixture.id) || selectedUnitIDs.contains(fixture.id)))
    }

    /// Scene retarget always starts from the fixture's assigned, saved preset.
    func beginRetarget(_ id: UUID) {
        if let tour {
            guard let unit = tour.allUnits.first(where: { $0.id == id }), let binding = tour.binding(for: unit, channel: 4), let preset = presets.first(where: { $0.id == binding }) else { message = "Apply a focus preset first."; return }
            select(id, extendSelection: false); beginTourTarget(preset, fromDraft: false); return
        }
        guard canPlace, let fixture = fixture(id), fixture.asset?.headAim == true else { return }
        guard let presetID = fixture.channelPaletteIDs?[4] ?? fixture.presetID, presets.contains(where: { $0.id == presetID }) else {
            message = "Apply a palette before retargeting, or create one in the palette editor."
            return
        }
        focusSelection(id)
        gizmoVisible = false; previewDraft = false
        targetPresetSource = .saved(presetID)
        scenePick = .aim(id); lastTarget = nil; message = nil
    }

    var isPaletteCueTarget: Bool {
        if case .cueDraft = targetPresetSource { return isRetargeting }
        return false
    }
    var paletteTargetIssue: String? {
        if !canPlace { return "Enter a venue before targeting fixtures." }
        if selectedFixtures.isEmpty { return "Select fixtures to target." }
        if presetDraft.channels.count < 6 { return "This palette needs Pan and Tilt channels before targeting." }
        if selectedFixtures.contains(where: { $0.asset?.headAim != true }) {
            return "Select fixtures that support Pan/Tilt targeting. Use mount controls for fixed or multi-head fixtures."
        }
        return presetDraft.validationIssue ?? presetDraft.referenceIssue(in: presets)
    }
    /// Targeting from the cue programmer never rewrites a shared library palette.
    func beginPaletteTarget() {
        guard !libraryBusy, let first = selectedFixtures.first else { return }
        if let issue = paletteTargetIssue { presetMessage = issue; return }
        cancelPicking(); gizmoVisible = false; previewDraft = true
        targetPresetSource = .cueDraft(presetDraft.id)
        scenePick = .aim(first.id); lastTarget = nil
        message = "Look at a room surface and pinch to preview the target. Hold and move to adjust. Save records the selected fixtures in cue \(currentCueLabel)."
    }
    private func paletteTargetFixture(_ fixture: Fixture, at target: Position3D) throws -> Fixture {
        var candidate = fixture
        candidate.channels = channelsWithoutTarget(for: fixture)
        guard candidate.channels.count >= 6 else { throw PresetError("Target requires Pan and Tilt channels.") }
        let aim = try FixtureAiming.articulated(candidate, target: target)
        candidate.channels[4] = aim.pan; candidate.channels[5] = aim.tilt
        candidate.aimOverride = nil
        candidate.jointOverrides?.removeValue(forKey: "pan")
        candidate.jointOverrides?.removeValue(forKey: "tilt")
        return candidate
    }
    private func previewPaletteTarget(_ target: Position3D) -> Bool {
        guard !libraryBusy, paletteTargetIssue == nil, targetingPreset != nil else { return false }
        do {
            let previews = try selectedFixtures.map { fixture in
                do { return try paletteTargetFixture(fixture, at: target) }
                catch { throw PresetError("\(fixture.name): \(error.localizedDescription)") }
            }
            targetPreview = previews.first; pendingTarget = target
            message = "Previewing \(previews.count) fixtures at one target. Save to cue \(currentCueLabel), or Cancel to restore."
            return true
        } catch {
            targetPreview = nil; pendingTarget = nil
            message = error.localizedDescription
            return false
        }
    }
    private func savePaletteTarget() -> Bool {
        guard let target = pendingTarget, previewPaletteTarget(target) else { return false }
        do {
            // Validate every fixture and cue layer before publishing any of them.
            let aimed = try selectedFixtures.map { try paletteTargetFixture($0, at: target) }
            var sheet = cueSheet
            sheet.include(fixtures, palettes: presets)
            for fixture in aimed {
                try sheet.record(try cuePalette(presetDraft, fixtureID: fixture.id), for: [fixture.id], sources: presets)
                let position = DMXPreset(name: "Target · \(presetDraft.name)", channels: fixture.channels,
                                         category: .position, attributeIndices: [4,5])
                try sheet.record(position, for: [fixture.id], sources: presets)
            }
            try sheet.validate()
            beginHistoryAction("Target fixtures · cue \(currentCueLabel)"); defer { endHistoryAction() }
            cueSheets[cueScope] = sheet
            // Show the primary fixture's solved values without projecting its
            // angles onto other fixtures or marking another auto-save pending.
            loadingProgrammer = true
            if let first = aimed.first {
                presetDraft = paletteHoldingAim(presetDraft, aim: .init(pan: first.channels[4], tilt: first.channels[5]))
            }
            paletteDraftTarget = target
            loadingProgrammer = false; programmerEdited = false; previewDraft = false
            cancelPicking(); lastTarget = target; revision += 1; fixtureRenderRevision += 1
            presetMessage = "Targeted \(aimed.count) fixtures · cue \(currentCueLabel). Pan/Tilt holds the target; other phaser attributes keep playing."
            message = presetMessage
            return true
        } catch { message = error.localizedDescription; return false }
    }

    /// Editor targeting uses all current draft values and saves/assigns that preset.
    func beginPresetTarget() {
        if tour != nil { beginTourTarget(presetDraft, fromDraft: true); return }
        guard canPlace, let id = selectedID, fixture(id)?.asset?.headAim == true else { return }
        guard presetDraft.validationIssue == nil, presetDraft.channels.count >= 6 else {
            presetMessage = presetDraft.validationIssue ?? "Target requires at least six channels."
            return
        }
        cancelPicking(); gizmoVisible = false; previewDraft = true
        targetPresetSource = .draft(presetDraft.id)
        scenePick = .aim(id); lastTarget = nil; message = nil
    }

    private var targetingPreset: DMXPreset? {
        switch targetPresetSource {
        case .saved(let id): return presets.first { $0.id == id }
        case .draft(let id), .cueDraft(let id): return presetDraft.id == id ? presetDraft : nil
        case nil: return nil
        }
    }

    func beginReposition(_ id: UUID) { beginTransform(id) }

    func cancelPicking() {
        fixtureDragLease?.cancel(); fixtureDragLease = nil
        if focusPickID != nil { cancelTourPreview() }
        focusPickID = nil; placementUnitID = nil; repeatPlacement = false; placementQueue = []
        scenePick = nil; targetPreview = nil; pendingTarget = nil; targetPresetSource = nil
        isPlacing = false; draggingFixture = nil; message = nil
    }

    @discardableResult func acceptTarget(_ target: Position3D) -> Bool {
        if isPaletteCueTarget { return previewPaletteTarget(target) }
        if let focusPickID { return previewFocusLocation(focusPickID, at: target) }
        guard !libraryBusy, canPlace, case .aim(let id) = scenePick,
              var candidate = fixture(id), let preset = targetingPreset else { return false }
        do {
            guard preset.channels.count >= 6 else { throw PresetError("Target requires a palette with at least six channels.") }
            candidate.channels = preset.channels
            candidate.presetID = preset.id
            candidate.aimOverride = nil
            candidate.jointOverrides?.removeValue(forKey: "pan")
            candidate.jointOverrides?.removeValue(forKey: "tilt")
            candidate.preserveAimOverride()
            let aim = try FixtureAiming.articulated(candidate, target: target)
            candidate.channels[4] = aim.pan; candidate.channels[5] = aim.tilt
            if let issue = candidate.validationIssue(among: fixtures) { throw PresetError(issue) }
            targetPreview = candidate; pendingTarget = target
            message = "Previewing \(preset.name) · Save updates palette Pan/Tilt and assigned fixtures. Cancel restores."
            return true
        } catch {
            targetPreview = nil; pendingTarget = nil
            message = error.localizedDescription; return false
        }
    }

    @discardableResult func saveTarget() -> Bool {
        if isPaletteCueTarget { return savePaletteTarget() }
        if focusPickID != nil { return commitTourPreview() }
        guard !libraryBusy, canPlace, case .aim(let id) = scenePick, let target = pendingTarget,
              var preset = targetingPreset, acceptTarget(target), let candidate = targetPreview else { return false }
        // Re-solve using the latest preset/draft, then validate the entire assignment
        // before changing either the library or fixtures. One Save is one Undo step.
        preset.channels = candidate.channels
        preset.name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            var assigned = fixtures
            for index in assigned.indices where assigned[index].presetID == preset.id || actionIDs(for: id).contains(assigned[index].id) {
                assigned[index].presetID = preset.id
                if assigned[index].channelPaletteIDs != nil {
                    assigned[index].channelPaletteIDs?[4] = preset.id
                    assigned[index].channelPaletteIDs?[5] = preset.id
                }
                assigned[index].aimOverride = nil
                assigned[index].jointOverrides?.removeValue(forKey: "pan")
                assigned[index].jointOverrides?.removeValue(forKey: "tilt")
            }
            var updated = try PresetOperations.saving(preset, fixtures: assigned)
            let memberIDs = actionIDs(for: id)
            if memberIDs.count > 1 {
                for index in updated.indices where memberIDs.contains(updated[index].id) && updated[index].asset?.headAim == true {
                    let aim = try FixtureAiming.articulated(updated[index], target: target)
                    updated[index].aimOverride = .init(pan: aim.pan, tilt: aim.tilt)
                    updated[index].preserveAimOverride()
                    if let issue = updated[index].validationIssue(among: updated) { throw PresetError(issue) }
                }
            }
            var library = presets
            if let index = library.firstIndex(where: { $0.id == preset.id }) { library[index] = preset }
            else { library.append(preset) }
            let encoded = try JSONEncoder().encode(library)
            let refreshEditor = editingPresetID == preset.id && !draftHasChanges
            beginHistoryAction("Retarget palette · \(preset.name)"); defer { endHistoryAction() }
            if !isDemoMode { defaults.set(encoded, forKey: "venue.presets.v1") }
            for fixture in updated where memberIDs.contains(fixture.id) {
                guard recordCuePalette(DMXPreset(name: "Target · \(preset.name)", channels: fixture.channels, category: .position, attributeIndices: [4,5]), targets: [fixture.id]) else { return false }
            }
            presets = library; fixtures = updated; updateCueLibrary(preset)
            // Preserve an unrelated unsaved editor draft when targeting from the scene.
            if case .draft = targetPresetSource { presetDraft = preset; editingPresetID = preset.id }
            else if refreshEditor { presetDraft = preset }
            cancelPicking(); lastTarget = target; revision += 1; persist()
            message = "Saved \(preset.name) target · palette Pan/Tilt updated."
            presetMessage = message
            return true
        } catch { message = error.localizedDescription; return false }
    }

}
