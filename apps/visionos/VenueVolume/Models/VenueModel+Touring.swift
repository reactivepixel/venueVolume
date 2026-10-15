import SwiftUI
import VenueVolumeCore

extension VenueModel {
    var tour: TourSession? { touring.active }
    var tourUnits: [InventoryUnit] { tour?.activeUnits ?? [] }
    var tourSelection: Set<UUID> { selectedUnitIDs.intersection(tour?.eligibleIDs ?? []) }
    var tourSelectionName: String {
        if let group = tour?.show.groups.first(where: { $0.id == selectedGroupID }) { return group.name }
        if tourSelection.count == 1, let unit = tourUnits.first(where: { tourSelection.contains($0.id) }) { return unit.fixture.name }
        return "\(tourSelection.count) fixtures"
    }
    var availableUnits: [InventoryUnit] {
        let placed = Set(fixtures.map(\.id))
        return tourUnits.filter { !placed.contains($0.id) && !$0.unavailable }
    }
    var sceneFixtures: [Fixture] { tourPreview ?? fixtures }
    private var touringURL: URL { library.directory.appendingPathComponent("touring-shows.json") }
    var touringHistoryURL: URL { library.directory.appendingPathComponent("touring-history.json") }

    func loadTouring() {
        guard !isDemoMode else { return }
        do {
            touring = try TouringArchive.load(from: touringURL)
            tourHistory = try AuditHistory<TouringArchive>.load(from: touringHistoryURL)
            // Once venue history exists it restores the authoritative complete state.
            if !FileManager.default.fileExists(atPath: historyURL.path), let tourHistory {
                try tourHistory.current.state.validate(); touring = tourHistory.current.state
            }
            refreshTourPresets()
        } catch { touringBlocked = true; message = "Show library is unreadable and has been preserved: \(error.localizedDescription)" }
    }
    func persistTouring() {
        guard !isDemoMode, !touringBlocked else { return }
        do { try touring.save(to: touringURL) }
        catch { message = "Show save failed: \(error.localizedDescription)" }
    }
    func undoTouring(redo: Bool) {
        guard !libraryBusy, !touringBlocked, var journal = tourHistory,
              let target = redo ? journal.redoTarget : journal.undoTarget else { return }
        do {
            try journal.move(to: target, kind: redo ? .redo : .undo)
            try journal.current.state.validate()
            if !isDemoMode { try journal.save(to: touringHistoryURL) }
            tourHistory = journal; touring = journal.current.state; refreshTourPresets(); persistTouring()
            selectedUnitIDs = []; selectedGroupID = nil; cancelTourPreview()
        } catch { message = error.localizedDescription }
    }
    func restoreTouringEvent(_ id: UUID) {
        guard history == nil, !touringBlocked, !libraryBusy, var journal = tourHistory else { return }
        do {
            try journal.move(to: id, kind: .jump); try journal.current.state.validate()
            if !isDemoMode { try journal.save(to: touringHistoryURL) }
            tourHistory = journal; touring = journal.current.state; refreshTourPresets(); persistTouring()
            selectedUnitIDs = []; selectedGroupID = nil; cancelTourPreview()
        } catch { message = error.localizedDescription }
    }
    func refreshTourPresets() {
        if let tour { presets = tour.presets }
        else if let data = defaults.data(forKey: "venue.presets.v1"), let legacy = try? JSONDecoder().decode([DMXPreset].self, from: data), legacy.allSatisfy({ $0.validationIssue == nil && $0.focusTargetID == nil }) {
            presets = legacy
        } else { presets = PaletteLibrary.baseline }
        if !presets.contains(where: { $0.id == editingPresetID }) { editingPresetID = nil }
    }
    @discardableResult func commitTour(_ session: TourSession, fixtures updated: [Fixture], title: String, publish: Bool = false) -> Bool {
        guard !libraryBusy, !touringBlocked, !historyBlocked else { message = "Show changes are unavailable while loading or while the saved history is unreadable."; return false }
        do {
            try session.validate(fixtures: updated)
            if let environment { for fixture in updated { if let issue = fixture.placementIssue(in: environment) { throw PresetError(issue) } } }
            var archive = touring; archive.active = session
            if publish, let latest = archive.shows.first(where: { $0.id == session.show.id }), latest.revision >= session.show.revision, latest != session.show {
                throw PresetError("A newer shared revision already exists. Review changes before editing the show.")
            }
            if publish || !archive.shows.contains(where: { $0.id == session.show.id }) {
                archive.shows.removeAll { $0.id == session.show.id }; archive.shows.append(session.show)
            }
            try archive.validate()
            var journal = tourHistory ?? AuditHistory(state: touring)
            if history == nil {
                journal.record(title, state: archive)
                if !isDemoMode { try journal.save(to: touringHistoryURL) }
            }
            beginHistoryAction(title); defer { endHistoryAction() }
            touring = archive; fixtures = updated; tourHistory = journal; refreshTourPresets()
            selectedUnitIDs.formIntersection(session.eligibleIDs)
            if let selectedID, !updated.contains(where: { $0.id == selectedID }) { self.selectedID = nil }
            if let selectedGroupID, !session.show.groups.contains(where: { $0.id == selectedGroupID }) { self.selectedGroupID = nil }
            previewDraft = false; revision += 1; message = title; persist()
            return true
        } catch { message = error.localizedDescription; presetMessage = message; return false }
    }
    func createTouringShow(name: String) {
        guard tour == nil || fixtures.isEmpty else { message = "Save and return this show’s placements before creating another show."; return }
        var show = TouringShow(name: name.trimmingCharacters(in: .whitespacesAndNewlines), presets: tour == nil ? presets : PaletteLibrary.baseline)
        show.units = fixtures.map { InventoryUnit(fixture: $0) }
        show.configurations[0].unitIDs = Set(fixtures.map(\.id))
        for fixture in fixtures {
            if let id = fixture.presetID, let preset = presets.first(where: { $0.id == id }) {
                for channel in preset.channelMask { show.programming.units[fixture.id, default: [:]][channel] = id }
            }
        }
        if commitTour(TourSession(show: show), fixtures: fixtures, title: "Create show · \(name)", publish: true) {
            selectedUnitIDs = Set(selectedID.map { [$0] } ?? [])
        }
    }
    func selectTouringShow(_ id: UUID, configuration: UUID? = nil) {
        guard fixtures.isEmpty else { message = "Save this venue and return its fixtures to inventory before switching shows or configurations."; return }
        guard let show = (tour?.show.id == id ? tour?.show : nil) ?? touring.shows.first(where: { $0.id == id }) else { return }
        _ = commitTour(TourSession(show: show, configurationID: configuration), fixtures: [], title: "Choose show · \(show.name)")
    }
    private func editTourShow(_ title: String, change: (inout TourSession) throws -> Void) {
        guard var session = tour else { return }
        do {
            try change(&session); session.show.revision += 1; try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            _ = commitTour(session, fixtures: updated, title: title, publish: true)
        } catch { message = error.localizedDescription }
    }
    func addInventory(_ kind: FixtureKind, quantity: Int, venueOnly: Bool = false, groupID: UUID? = nil) {
        guard var session = tour, (1...64).contains(quantity), session.allUnits.count + quantity <= 256 else { message = "Choose 1–64 units, up to 256 per show."; return }
        for _ in 0..<quantity {
            let count = session.allUnits.filter { $0.fixture.assetID == kind.assetID }.count + 1
            let patch = Fixture.nextAvailablePatch(in: session.allUnits.map(\.fixture), footprint: 16)
            let fixture = Fixture(name: kind.name + String(format: " %02d", count), assetID: kind.assetID,
                                  universe: patch?.universe ?? 1, startAddress: patch?.address ?? 1,
                                  channels: kind.asset?.neutralChannels ?? Array(repeating: 0, count: 16))
            let unit = InventoryUnit(fixture: fixture, groupID: groupID)
            if venueOnly { session.localUnits.append(unit) }
            else {
                session.show.units.append(unit)
                if let i = session.show.configurations.firstIndex(where: { $0.id == session.configurationID }) { session.show.configurations[i].unitIDs.insert(unit.id) }
            }
        }
        if !venueOnly { session.show.revision += 1 }
        if commitTour(session, fixtures: fixtures, title: "Add \(quantity) × \(kind.name) · \(venueOnly ? "venue" : "show")", publish: !venueOnly) { rememberFixtureKind(kind) }
    }
    func addQuantity(name: String, quantity: Int) {
        editTourShow("Add quantity equipment · \(name)") { $0.show.quantities.append(EquipmentQuantity(name: name, quantity: quantity)) }
    }
    func removeQuantity(_ id: UUID) { editTourShow("Remove quantity equipment") { $0.show.quantities.removeAll { $0.id == id } } }
    func renameInventory(_ id: UUID, name: String) {
        guard var session = tour else { return }
        if let i = session.show.units.firstIndex(where: { $0.id == id }) { session.show.units[i].fixture.name = name; session.show.revision += 1 }
        if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].fixture.name = name }
        var updated = fixtures
        if let i = updated.firstIndex(where: { $0.id == id }) { updated[i].name = name }
        _ = commitTour(session, fixtures: updated, title: "Rename equipment", publish: session.show.units.contains { $0.id == id })
    }
    func setUnitUnavailable(_ id: UUID, _ unavailable: Bool) {
        guard fixture(id) == nil else { message = "Return this fixture to inventory first."; return }
        editTourShow("Change equipment availability") { session in
            if let i = session.show.units.firstIndex(where: { $0.id == id }) { session.show.units[i].unavailable = unavailable }
            if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].unavailable = unavailable }
        }
    }
    func excludeInventory(_ id: UUID) {
        guard var session = tour, fixture(id) == nil else { message = "Return the fixture to inventory before excluding it."; return }
        if session.excluded.contains(id) { session.excluded.remove(id) } else { session.excluded.insert(id) }
        _ = commitTour(session, fixtures: fixtures, title: "Change venue equipment inclusion")
    }
    func removeInventory(_ id: UUID) {
        guard var session = tour, let unit = session.allUnits.first(where: { $0.id == id }) else { return }
        let references = fixture(id) != nil || unit.groupID != nil || session.programming.units[id]?.isEmpty == false || session.show.programming.units[id]?.isEmpty == false || session.show.configurations.contains { $0.layout.contains { $0.id == id } }
        guard !references else { message = "Return this unit, ungroup it, and remove its programming/layout dependencies before removing equipment."; return }
        // Saved venues retain their own pinned copy; their historical identities remain intact.
        session.show.units.removeAll { $0.id == id }; session.localUnits.removeAll { $0.id == id }
        for i in session.show.configurations.indices { session.show.configurations[i].unitIDs.remove(id) }
        session.excluded.remove(id); session.programming.units[id] = nil; session.programming.releasedUnits[id] = nil
        session.show.programming.units[id] = nil; session.show.programming.releasedUnits[id] = nil; session.show.revision += 1
        _ = commitTour(session, fixtures: fixtures, title: "Remove equipment · \(unit.fixture.name)", publish: true)
    }
    func saveGroup(id: UUID? = nil, name: String, parentID: UUID?) {
        if let id, var session = tour, let i = session.show.groups.firstIndex(where: { $0.id == id }) {
            session.show.groups[i].name = name; session.show.groups[i].parentID = parentID; session.show.revision += 1
            previewMembership(session, title: "Edit group · \(name)")
        } else {
            editTourShow("Create group · \(name)") { $0.show.groups.append(FixtureGroup(name: name, parentID: parentID)) }
        }
    }
    func previewRemoveGroup(_ id: UUID) {
        guard var session = tour, let group = session.show.groups.first(where: { $0.id == id }) else { return }
        session.show.groups.removeAll { $0.id == id }
        for i in session.show.groups.indices where session.show.groups[i].parentID == id { session.show.groups[i].parentID = group.parentID }
        for i in session.show.units.indices where session.show.units[i].groupID == id { session.show.units[i].groupID = group.parentID }
        for i in session.localUnits.indices where session.localUnits[i].groupID == id { session.localUnits[i].groupID = group.parentID }
        session.programming.groups[id] = nil; session.show.programming.groups[id] = nil; session.show.revision += 1
        previewMembership(session, title: "Remove group · \(group.name); keep equipment")
    }
    func previewMembership(_ session: TourSession, title: String) {
        do {
            try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) }
            try session.validate(fixtures: updated)
            setTourPreview(session, fixtures: updated, title: title, publish: true)
        } catch { message = error.localizedDescription }
    }
    func assignSelectionToGroup(_ group: UUID?) {
        guard var session = tour, !tourSelection.isEmpty else { return }
        for i in session.show.units.indices where tourSelection.contains(session.show.units[i].id) { session.show.units[i].groupID = group }
        for i in session.localUnits.indices where tourSelection.contains(session.localUnits[i].id) { session.localUnits[i].groupID = group }
        session.show.revision += 1
        previewMembership(session, title: "Move \(tourSelection.count) units into \(session.show.groups.first { $0.id == group }?.name ?? "Ungrouped")")
    }
    func selectGroup(_ id: UUID?) {
        guard !libraryBusy, let tour else { return }
        guard savePendingCueEdits() else { return }; defer { refreshPaletteSelection() }
        endTransformDrag(); beginHistoryAction("Select fixture group"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); previewDraft = false; gizmoVisible = false
        selectedGroupID = id; selectedUnitIDs = tour.members(of: id)
        selectedID = fixtures.first { selectedUnitIDs.contains($0.id) }?.id
    }
    func toggleUnitSelection(_ id: UUID) {
        guard !libraryBusy, tour?.eligibleIDs.contains(id) == true else { return }
        guard savePendingCueEdits() else { return }; defer { refreshPaletteSelection() }
        endTransformDrag(); beginHistoryAction("Change inventory selection"); defer { endHistoryAction() }
        cancelTourPreview(); cancelPicking(); previewDraft = false; selectedGroupID = nil
        if selectedUnitIDs.contains(id) { selectedUnitIDs.remove(id) } else { selectedUnitIDs.insert(id) }
        selectedID = fixtures.first { selectedUnitIDs.contains($0.id) }?.id
    }
    func selectInventory(_ id: UUID) {
        if let unit = tour?.allUnits.first(where: { $0.id == id }) {
            rememberFixtureKind(unit.fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube)
        }
        if multiSelection { toggleUnitSelection(id); return }
        beginHistoryAction("Select inventory unit"); defer { endHistoryAction() }
        deselect(); selectedUnitIDs = [id]; selectedID = fixture(id)?.id
    }
    func beginInventoryPlacement(_ id: UUID, repeatAll: Bool = false) {
        guard canPlace, let unit = availableUnits.first(where: { $0.id == id }) else { message = "This unit is already placed or unavailable."; return }
        cancelTourPreview(); cancelPicking(); gizmoVisible = false
        selectFixtureKind(unit.fixture.assetID.flatMap { $0 == LightingPreview.assetID ? .movingHead : FixtureKind(rawValue: $0) } ?? .cube)
        placementUnitID = id; repeatPlacement = repeatAll
        placementQueue = [id] + (repeatAll ? availableUnits.filter { $0.id != id && $0.fixture.assetID == unit.fixture.assetID }.map(\.id) : [])
        isPlacing = true; message = "Place \(unit.fixture.name) · \(placementQueue.count) remaining"
    }
    func beginInventoryDrag(_ id: UUID) {
        beginInventoryPlacement(id)
        guard placementUnitID == id, isPlacing else { return }
        draggingFixture = fixtureKind
        fixtureDragLease?.cancel()
        fixtureDragLease = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            self?.cancelPicking()
        }
    }
    func insertInventoryFixture(at base: Position3D, surfaceID: String?) {
        guard let session = tour, fixtures.count < 64,
              let unit = availableUnits.first(where: { placementUnitID == nil ? $0.fixture.assetID == fixtureKind.assetID : $0.id == placementUnitID }) else { message = "No available unit. Add equipment to the show first."; isPlacing = false; return }
        do {
            var fixture = unit.fixture
            fixture.position = .init(x: base.x, y: base.y + (fixture.assetID == nil ? fixtureKind.radius : 0), z: base.z); fixture.surfaceID = surfaceID; fixture.mountPlane = nil
            if fixture.validationIssue(among: fixtures + [fixture]) != nil {
                guard let patch = Fixture.nextAvailablePatch(in: fixtures, footprint: fixture.channels.count) else { throw PresetError("No free patch is available.") }
                fixture.universe = patch.universe; fixture.startAddress = patch.address
            }
            fixture = try Touring.resolved(fixture, in: session, solveFocus: true)
            guard commitTour(session, fixtures: fixtures + [fixture], title: "Place \(fixture.name)") else { return }
            selectedID = fixture.id; selectedUnitIDs = [fixture.id]; selectedGroupID = nil
            placementQueue.removeAll { $0 == fixture.id }; draggingFixture = nil
            if repeatPlacement, let next = placementQueue.first { placementUnitID = next; message = "Next: \(session.allUnits.first { $0.id == next }?.fixture.name ?? "fixture") · \(placementQueue.count) remaining" }
            else { cancelPicking(); message = "Placed \(fixture.name)" }
        } catch { message = error.localizedDescription }
    }
    @discardableResult func applyTourPreset(_ id: UUID, ids: Set<UUID>? = nil, group: UUID? = nil, allDescendants: Bool = false, preview: Bool = false, toShow: Bool = false) -> Bool {
        guard let session = tour, savePendingCueEdits() else { return false }
        let chosen = ids ?? tourSelection
        do {
            var (next, updated) = try Touring.applying(id, to: chosen, group: group, replaceDescendants: allDescendants, in: session, fixtures: fixtures)
            if toShow {
                guard let preset = session.show.presets.first(where: { $0.id == id }), session.presetOverrides.first(where: { $0.id == id }) == nil,
                      chosen.isSubset(of: Set(session.show.units.map(\.id))) else { throw PresetError("Shared assignments require a shared preset and show equipment. Save the preset in Shared show scope first.") }
                if let group {
                    let groups = allDescendants ? session.show.groups.filter { session.show.ancestors(of: $0.id).contains(group) }.map(\.id) : [group]
                    for groupID in groups { for channel in preset.channelMask {
                        next.show.programming.groups[groupID, default: [:]][channel] = id
                        next.programming.groups[groupID]?[channel] = nil
                    } }
                    if allDescendants { for unit in chosen { for channel in preset.channelMask {
                        next.show.programming.units[unit]?[channel] = nil; next.programming.units[unit]?[channel] = nil
                        next.programming.releasedUnits[unit]?.remove(channel)
                    } } }
                } else { for unit in chosen { for channel in preset.channelMask {
                    next.show.programming.units[unit, default: [:]][channel] = id; next.programming.units[unit]?[channel] = nil
                    next.programming.releasedUnits[unit]?.remove(channel)
                } } }
                next.show.revision += 1; try next.validate(fixtures: updated)
            }
            let scope = toShow ? "show" : "venue"
            let title = "Apply \(session.presets.first { $0.id == id }?.name ?? "preset") to \(chosen.count) units · \(scope)\(group != nil && !allDescendants ? " · preserve exceptions" : "")"
            let proposedCues = try tourCueSheet(applying: id, to: chosen, in: next, fixtures: updated)
            if preview { setTourPreview(next, fixtures: updated, title: title, publish: toShow, cues: proposedCues); return true }
            beginHistoryAction(title); defer { endHistoryAction() }
            let oldCues = cueSheets
            cueSheets[cueScope] = proposedCues
            let result = commitTour(next, fixtures: updated, title: title, publish: toShow)
            if !result { cueSheets = oldCues }
            else { programmerEdited = false; previewDraft = false; refreshPaletteSelection() }
            return result
        } catch { message = error.localizedDescription; presetMessage = message; return false }
    }
    /// Prepare the cue and assignment together; group exceptions retain their owners.
    private func tourCueSheet(applying id: UUID, to ids: Set<UUID>, in session: TourSession, fixtures updated: [Fixture]) throws -> CueSheet {
        var sheet = cueSheet
        sheet.include(fixtures, palettes: presets)
        guard let palette = session.presets.first(where: { $0.id == id }) else { throw PresetError("That palette no longer exists.") }
        for fixture in updated where ids.contains(fixture.id) {
            guard let unit = session.allUnits.first(where: { $0.id == fixture.id }) else { continue }
            let channels = palette.channelMask.filter { session.binding(for: unit, channel: $0) == id }
            guard !channels.isEmpty else { continue }
            var resolved = palette
            resolved.includedChannels = channels.sorted()
            if palette.focusTargetID != nil, fixture.channels.count >= 6 {
                resolved = paletteHoldingAim(resolved, aim: .init(pan: fixture.channels[4], tilt: fixture.channels[5]), sources: session.presets)
            }
            try sheet.record(resolved, for: [fixture.id], sources: session.presets, linked: palette.focusTargetID == nil)
        }
        try sheet.validate()
        return sheet
    }
    private func focusCueSheet(_ updated: [Fixture], ids: Set<UUID>) throws -> CueSheet {
        var sheet = cueSheet
        sheet.include(fixtures, palettes: presets)
        for fixture in updated where ids.contains(fixture.id) {
            let palette = DMXPreset(name: "Focus · \(fixture.name)", channels: fixture.channels, category: .position, attributeIndices: [4,5])
            try sheet.record(palette, for: [fixture.id], sources: [])
        }
        try sheet.validate()
        return sheet
    }
    private func setTourPreview(_ session: TourSession, fixtures: [Fixture], title: String, publish: Bool = false, cues: CueSheet? = nil) {
        guard !libraryBusy else { return }
        endTransformDrag(); gizmoVisible = false
        tourPreviewRevision = revision; tourPreviewSource = touring
        tourPreviewCueSheet = cues
        tourPreviewSession = session; tourPreview = fixtures; tourPreviewTitle = title; tourPreviewPublishes = publish; previewDraft = false; message = "Preview · \(title)"
    }
    @discardableResult func commitTourPreview() -> Bool {
        guard let session = tourPreviewSession, let updated = tourPreview else { return false }
        guard tourPreviewRevision == revision, tourPreviewSource == touring else { cancelTourPreview(); message = "The scene changed after this preview. Preview again before saving."; return false }
        beginHistoryAction(tourPreviewTitle); defer { endHistoryAction() }
        let savedFocus = focusDraftPresetID
        let oldCues = cueSheets
        if let proposedCues = tourPreviewCueSheet { cueSheets[cueScope] = proposedCues }
        guard commitTour(session, fixtures: updated, title: tourPreviewTitle, publish: tourPreviewPublishes) else { cueSheets = oldCues; return false }
        cancelTourPreview(); cancelPicking()
        programmerEdited = false; previewDraft = false; fixtureRenderRevision += 1; refreshPaletteSelection()
        if let savedFocus, let preset = presets.first(where: { $0.id == savedFocus }) { presetDraft = preset; editingPresetID = preset.id }
        return true
    }
    func cancelTourPreview() {
        tourPreview = nil; tourPreviewSession = nil; tourPreviewTitle = ""; tourPreviewPublishes = false
        tourPreviewSource = nil; tourPreviewCueSheet = nil
        focusPickID = nil; focusBaseSession = nil; focusDraftPresetID = nil; pendingTarget = nil
    }
    func resetTourAssignment(_ ids: Set<UUID>) {
        guard var session = tour else { return }
        for id in ids { session.programming.units[id] = nil; session.programming.releasedUnits[id] = Set(0..<16) }
        do {
            let updated = try fixtures.map { ids.contains($0.id) ? try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) : $0 }
            _ = commitTour(session, fixtures: updated, title: "Reset \(ids.count) units to group defaults")
        } catch { message = error.localizedDescription }
    }
    @discardableResult func saveTourPreset(asNew: Bool) -> Bool {
        guard var session = tour else { return false }
        beginHistoryAction(asNew ? "Save new touring preset" : "Save touring preset"); defer { endHistoryAction() }
        var preset = presetDraft; preset.name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if asNew { preset.id = UUID() }
        if let issue = preset.validationIssue { presetMessage = issue; return false }
        // Removing a parameter still used by a binding requires a new preset. This
        // avoids silently changing inheritance for existing assignments.
        if let old = session.presets.first(where: { $0.id == preset.id }), !old.channelMask.isSubset(of: preset.channelMask) {
            let bound = [session.programming, session.show.programming].contains { p in
                (Array(p.units.values) + Array(p.groups.values)).contains { bindings in bindings.contains { !preset.channelMask.contains($0.key) && $0.value == preset.id } }
            }
            if bound { presetMessage = "This parameter is assigned. Save as new to change the included parameters."; return false }
        }
        if tourEditShow {
            session.show.presets.removeAll { $0.id == preset.id }; session.show.presets.append(preset)
            session.presetOverrides.removeAll { $0.id == preset.id }; session.show.revision += 1
        } else { session.presetOverrides.removeAll { $0.id == preset.id }; session.presetOverrides.append(preset) }
        do {
            try session.validate()
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            let previousCues = cueSheets
            if !asNew { updateCueLibrary(preset) }
            guard commitTour(session, fixtures: updated, title: "Save preset · \(preset.name) · \(tourEditShow ? "show" : "venue")", publish: tourEditShow) else { cueSheets = previousCues; return false }
            choosePreset(preset); presetMessage = "Saved \(tourEditShow ? "show preset" : "venue override"). Apply to change an assignment."
            return true
        } catch { presetMessage = error.localizedDescription; return false }
    }
    func deleteTourPreset(_ id: UUID) {
        guard var session = tour else { return }
        let bound = [session.programming, session.show.programming].contains { p in (Array(p.units.values) + Array(p.groups.values)).contains { $0.values.contains(id) } }
        guard !bound else { presetMessage = "Preset is assigned to units or groups. Reassign those parameters before deleting."; return }
        session.presetOverrides.removeAll { $0.id == id }
        let shared = session.show.presets.contains { $0.id == id }
        if shared && !tourEditShow { presetMessage = "Switch scope to Show to remove a shared preset."; return }
        session.show.presets.removeAll { $0.id == id }; if shared { session.show.revision += 1 }
        if commitTour(session, fixtures: fixtures, title: "Delete unused preset", publish: shared) { newPreset() }
    }
    func resetPresetToShow(_ id: UUID) {
        guard var session = tour else { return }
        session.presetOverrides.removeAll { $0.id == id }
        do {
            let updated = try fixtures.map { try Touring.resolved($0, in: session) }
            if commitTour(session, fixtures: updated, title: "Reset preset to show") { if let preset = presets.first(where: { $0.id == id }) { choosePreset(preset) } }
        } catch { presetMessage = error.localizedDescription }
    }
    func createFocusTarget(name: String) { editTourShow("Create focus target · \(name)") { $0.show.targets.append(FocusTarget(name: name)) } }
    func beginFocusLocation(_ id: UUID) {
        guard canPlace, tour?.show.targets.contains(where: { $0.id == id }) == true, savePendingCueEdits() else { return }
        cancelPicking(); cancelTourPreview(); gizmoVisible = false; previewDraft = false
        focusPickID = id; focusBaseSession = tour; message = "Look and pinch to preview the target. Save or Cancel in the context bar."
    }
    func beginTourTarget(_ preset: DMXPreset, fromDraft: Bool) {
        guard canPlace, var session = tour, !tourSelection.isEmpty, savePendingCueEdits() else { return }
        var updated = preset
        if updated.validationIssue != nil { presetMessage = updated.validationIssue; return }
        if updated.focusTargetID == nil {
            let target = FocusTarget(name: String((preset.name + " target").prefix(120)))
            session.show.targets.append(target); session.show.revision += 1; updated.focusTargetID = target.id
        }
        updated.includedChannels = Array(updated.channelMask.union([4, 5])).sorted()
        session.presetOverrides.removeAll { $0.id == updated.id }
        if fromDraft && tourEditShow {
            session.show.presets.removeAll { $0.id == updated.id }; session.show.presets.append(updated); session.show.revision += 1
        } else { session.presetOverrides.append(updated) }
        if fromDraft {
            for id in tourSelection { for channel in updated.channelMask { session.programming.units[id, default: [:]][channel] = updated.id } }
        }
        do {
            try session.validate()
            cancelPicking(); cancelTourPreview(); gizmoVisible = false; previewDraft = false
            focusPickID = updated.focusTargetID; focusBaseSession = session; focusDraftPresetID = fromDraft ? updated.id : nil
            tourPreviewPublishes = session.show != tour?.show
            message = "Preview \(updated.name) target. Each assigned fixture solves its own Pan/Tilt."
        } catch { message = error.localizedDescription }
    }
    private func focusBindingChanged(_ fixture: Fixture, in session: TourSession) -> Bool {
        guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let newID = session.binding(for: unit, channel: 4),
              let newTarget = session.presets.first(where: { $0.id == newID })?.focusTargetID else { return false }
        guard let old = tour, let oldUnit = old.allUnits.first(where: { $0.id == fixture.id }), let oldID = old.binding(for: oldUnit, channel: 4) else { return true }
        return oldID != newID || old.presets.first(where: { $0.id == oldID })?.focusTargetID != newTarget
    }
    private func hasLocatedFocus(_ fixture: Fixture, in session: TourSession) -> Bool {
        guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let id = session.binding(for: unit, channel: 4),
              let target = session.presets.first(where: { $0.id == id })?.focusTargetID else { return false }
        return session.targetLocations[target] != nil
    }
    @discardableResult func previewFocusLocation(_ id: UUID, at point: Position3D) -> Bool {
        guard var session = focusBaseSession ?? tour, [point.x, point.y, point.z].allSatisfy(\.isFinite) else { return false }
        session.targetLocations[id] = point
        do {
            let updated = try fixtures.map { fixture in
                guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let binding = session.binding(for: unit, channel: 4),
                      session.presets.first(where: { $0.id == binding })?.focusTargetID == id else { return fixture }
                return try Touring.resolved(fixture, in: session, solveFocus: true)
            }
            try session.validate(fixtures: updated)
            let publishes = tourPreviewPublishes
            let ids = Set(updated.filter { fixture in
                guard let unit = session.allUnits.first(where: { $0.id == fixture.id }), let binding = session.binding(for: unit, channel: 4) else { return false }
                return session.presets.first(where: { $0.id == binding })?.focusTargetID == id
            }.map(\.id))
            let proposedCues = try focusCueSheet(updated, ids: ids)
            setTourPreview(session, fixtures: updated, title: "Locate \(session.show.targets.first { $0.id == id }?.name ?? "target")", publish: publishes, cues: proposedCues)
            pendingTarget = point; return true
        } catch { tourPreview = nil; tourPreviewSession = nil; tourPreviewCueSheet = nil; pendingTarget = nil; message = error.localizedDescription; return false }
    }
    func refocusSelection() {
        guard let session = tour, !tourSelection.isEmpty, savePendingCueEdits() else { return }
        do {
            for fixture in fixtures where tourSelection.contains(fixture.id) {
                guard hasLocatedFocus(fixture, in: session) else { throw PresetError("\(fixture.name): assign a focus preset and locate its target first.") }
            }
            let updated = try fixtures.map { tourSelection.contains($0.id) ? try Touring.resolved($0, in: session, solveFocus: true) : $0 }
            setTourPreview(session, fixtures: updated, title: "Refocus \(tourSelection.count) units", cues: try focusCueSheet(updated, ids: tourSelection))
        } catch { message = error.localizedDescription }
    }
    func previewGroupTransform(translation: Position3D, yaw: Float = 0, spacing: Float? = nil, mirror: Bool = false, align: FixtureAxis? = nil) {
        guard let session = tour else { return }
        do {
            let updated = try Touring.transformed(fixtures, ids: tourSelection, translation: translation, yaw: yaw, spacing: spacing, mirror: mirror, align: align)
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Transform \(tourSelection.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    private func validateTourPlacement(_ updated: [Fixture], in session: TourSession) throws {
        try session.validate(fixtures: updated)
        guard let environment else { throw PresetError("Open a venue first.") }
        for fixture in updated { if let issue = fixture.placementIssue(in: environment) { throw PresetError("\(fixture.name): \(issue)") } }
    }
    func previewGroupPlacement(origin: Position3D, spacing: Float) {
        guard let session = tour, let environment, spacing.isFinite, spacing > 0 else { return }
        let units = availableUnits.filter { tourSelection.contains($0.id) }
        guard !units.isEmpty, units.count == tourSelection.count, fixtures.count + units.count <= 64 else { message = "Select unplaced, available units for a row (64 placements maximum)."; return }
        do {
            var updated = fixtures
            for (index, unit) in units.enumerated() {
                var fixture = unit.fixture
                let hit = Position3D(x: origin.x + (Float(index)-Float(units.count-1)/2)*spacing, y: origin.y, z: origin.z)
                let radius = fixture.footprintRadius
                guard let surface = environment.surfaces.first(where: { abs($0.center[1] - hit.y) < 0.15 && $0.fixturePosition(hit: hit, halfSize: radius) != nil }),
                      let center = surface.fixturePosition(hit: hit, halfSize: radius) else { throw PresetError("\(fixture.name): no supported floor or tabletop at these coordinates.") }
                let base = Position3D(x: center.x, y: center.y-radius, z: center.z)
                if let scannedMesh, !scannedMesh.supports(base, radius: radius) { throw PresetError("\(fixture.name): scan more of the supporting surface.") }
                fixture.position = .init(x: base.x, y: base.y + (fixture.assetID == nil ? radius : 0), z: base.z); fixture.surfaceID = surface.id
                if fixture.validationIssue(among: updated + [fixture]) != nil {
                    guard let patch = Fixture.nextAvailablePatch(in: updated, footprint: fixture.channels.count) else { throw PresetError("No free patch.") }
                    fixture.universe = patch.universe; fixture.startAddress = patch.address
                }
                fixture = try Touring.resolved(fixture, in: session, solveFocus: true); updated.append(fixture)
            }
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Place row · \(units.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    func autoPatchSelection() {
        guard let session = tour, !tourSelection.isEmpty else { return }
        var patched = fixtures.filter { !tourSelection.contains($0.id) }
        for var fixture in fixtures where tourSelection.contains(fixture.id) {
            guard let patch = Fixture.nextAvailablePatch(in: patched, footprint: fixture.channels.count) else { message = "No free patch."; return }
            fixture.universe = patch.universe; fixture.startAddress = patch.address; patched.append(fixture)
        }
        let updated = fixtures.map { fixture in patched.first { $0.id == fixture.id }! }
        setTourPreview(session, fixtures: updated, title: "Auto-patch \(tourSelection.count) fixtures")
    }
    func saveConfiguration(name: String, selectionOnly: Bool) {
        editTourShow("Save configuration · \(name)") { session in
            let ids = selectionOnly ? tourSelection.intersection(session.show.units.map(\.id)) : Set(session.show.units.map(\.id))
            var configuration = TourConfiguration(name: name, unitIDs: ids)
            configuration.layout = fixtures.filter { ids.contains($0.id) }
            session.show.configurations.append(configuration)
        }
    }
    func previewConfigurationLayout(translation: Position3D, yaw: Float) {
        guard let session = tour, let layout = session.configuration?.layout, !layout.isEmpty else { message = "Save a configuration with a placed layout first."; return }
        guard fixtures.isEmpty else { message = "Return the current placements before adapting a saved layout."; return }
        do {
            let included = layout.filter { session.eligibleIDs.contains($0.id) }
            let moved = try Touring.transformed(included, ids: Set(included.map(\.id)), translation: translation, yaw: yaw)
            let updated = try moved.map { try Touring.resolved($0, in: session) }
            try validateTourPlacement(updated, in: session)
            setTourPreview(session, fixtures: updated, title: "Adapt saved configuration layout · \(updated.count) fixtures")
        } catch { message = error.localizedDescription }
    }
    var availableShowUpdate: TouringShow? {
        guard let session = tour else { return nil }
        return touring.shows.first { $0.id == session.show.id && $0.revision > session.show.revision }
    }
    var showUpdateChanges: [String] {
        guard let previous = tour?.show, let latest = availableShowUpdate else { return [] }
        var changes: [String] = []
        for unit in previous.units {
            if let updated = latest.units.first(where: { $0.id == unit.id }) {
                if updated != unit { changes.append("Update equipment · \(unit.fixture.name)") }
            } else { changes.append("Remove equipment · \(unit.fixture.name)") }
        }
        for unit in latest.units where !previous.units.contains(where: { $0.id == unit.id }) { changes.append("Add equipment · \(unit.fixture.name)") }
        for preset in previous.presets {
            if let updated = latest.presets.first(where: { $0.id == preset.id }) {
                if updated != preset { changes.append("Update preset · \(preset.name)") }
            } else { changes.append("Remove preset · \(preset.name)") }
        }
        for preset in latest.presets where !previous.presets.contains(where: { $0.id == preset.id }) { changes.append("Add preset · \(preset.name)") }
        if previous.groups != latest.groups { changes.append("Group hierarchy or names changed") }
        if previous.programming != latest.programming { changes.append("Shared programming changed; venue overrides retain priority") }
        if previous.configurations != latest.configurations { changes.append("Configurations or layouts changed") }
        if previous.targets != latest.targets { changes.append("Focus target definitions changed") }
        if previous.quantities != latest.quantities { changes.append("Quantity equipment changed") }
        if previous.name != latest.name { changes.append("Rename show · \(latest.name)") }
        return changes
    }
    func previewShowUpdate() {
        guard var session = tour, let latest = availableShowUpdate else { return }
        session.show = latest
        do {
            try session.validate(fixtures: fixtures)
            let updated = try fixtures.map { try Touring.resolved($0, in: session, solveFocus: focusBindingChanged($0, in: session)) }
            setTourPreview(session, fixtures: updated, title: "Adopt show revision \(latest.revision) · \(latest.units.count) units, \(latest.groups.count) groups, \(latest.presets.count) presets")
        } catch { message = "Update blocked; pinned version retained. \(error.localizedDescription)" }
    }
    func importTouringShow(_ data: Data) {
        do {
            guard data.count < 20_000_000 else { throw PresetError("Show import is too large.") }
            let show = try JSONDecoder().decode(TouringShow.self, from: data); try show.validate()
            if let existing = touring.shows.first(where: { $0.id == show.id }), existing.revision >= show.revision, existing != show { throw PresetError("This show identity already has an equal or newer revision. Export a newer revision from its source.") }
            var archive = touring; archive.shows.removeAll { $0.id == show.id }; archive.shows.append(show); try archive.validate()
            var journal = tourHistory ?? AuditHistory(state: touring)
            if history == nil { journal.record("Import show · \(show.name)", state: archive); if !isDemoMode { try journal.save(to: touringHistoryURL) } }
            beginHistoryAction("Import show · \(show.name)"); defer { endHistoryAction() }
            touring = archive; tourHistory = journal; persistTouring(); message = "Imported \(show.name). Active venues keep their pinned revision until Review changes."
        } catch { message = "Import failed; current show preserved. \(error.localizedDescription)" }
    }
}
