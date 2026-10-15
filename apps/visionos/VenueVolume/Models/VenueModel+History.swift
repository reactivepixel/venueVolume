import SwiftUI
import VenueVolumeCore

extension VenueModel {
    var auditState: VenueAuditState? {
        guard let room = activeRoom else { return nil }
        return .init(rooms: rooms, setups: savedSetups, roomID: room.id, fixtures: fixtures, presets: presets,
                     draft: presetDraft, editingPresetID: editingPresetID, setupName: setupName, activeSetupID: activeSetupID,
                     savedSetup: savedSetup, whiteRoom: whiteRoom, houseLight: houseLight, blackout: blackout,
                     selectedID: selectedID, previewDraft: previewDraft, previewBlackout: previewBlackout, touring: touring, selectedUnitIDs: tour == nil ? nil : selectedUnitIDs, selectedGroupID: selectedGroupID, viewerPose: viewerPose == .init() ? nil : viewerPose, cueSheets: cueSheets.isEmpty ? nil : cueSheets)
    }

    func startHistoryIfNeeded() {
        guard history == nil, !historyBlocked, let state = auditState else { return }
        let initial = AuditHistory(state: state)
        do { try state.validate(); try initial.save(to: historyURL); history = initial }
        catch { historyMessage = "History could not start: \(error.localizedDescription)" }
    }

    /// Nestable transactions keep multi-object operations and slider gestures atomic.
    func beginHistoryAction(_ title: String) {
        if actionDepth == 0 { flushHistoryEdits(); actionTitle = title }
        actionDepth += 1
    }
    func endHistoryAction() {
        guard actionDepth > 0 else { return }
        actionDepth -= 1
        if actionDepth == 0, let state = auditState { recordHistory(actionTitle, state: state) }
    }
    func queueHistoryEdit(_ title: String) {
        guard history != nil, !historyBlocked, !restoringHistory, actionDepth == 0, !libraryBusy, let state = auditState else { return }
        if let pendingEdit, pendingEdit.title != title { flushHistoryEdits() }
        pendingEdit = (title, state)
        editTask?.cancel()
        editTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            self?.flushHistoryEdits()
        }
    }
    func flushHistoryEdits() {
        editTask?.cancel(); editTask = nil
        guard let edit = pendingEdit else { return }
        pendingEdit = nil
        recordHistory(edit.title, state: edit.state)
    }
    private func recordHistory(_ title: String, state: VenueAuditState) {
        guard !restoringHistory, !historyBlocked, var next = history else { return }
        do {
            try state.validate()
            guard next.record(title, state: state) else { return }
            try next.save(to: historyURL); history = next; historyMessage = nil
            if historyDestination != nil { historyDestination = (next.cursor, nil) }
        } catch { historyMessage = "History save failed: \(error.localizedDescription)" }
    }
    func auditExternal(_ title: String) {
        flushHistoryEdits()
        if history == nil, !touringBlocked, var journal = tourHistory {
            journal.append(title)
            do { if !isDemoMode { try journal.save(to: touringHistoryURL) }; tourHistory = journal }
            catch { message = error.localizedDescription }
            return
        }
        guard !historyBlocked, var next = history else { return }
        next.append(title)
        do { try next.save(to: historyURL); history = next }
        catch { historyMessage = "Audit save failed: \(error.localizedDescription)" }
    }
    func registerRoom(_ room: LibraryRoom) {
        beginHistoryAction("\(room.origin == .scanned ? "Scan" : "Import") room · \(room.manifest.title)")
        defer { endHistoryAction() }
        if !rooms.contains(where: { $0.id == room.id }) { rooms.append(room) }
    }

    func undo() {
        if history == nil { undoTouring(redo: false); return }
        finishHistoryGesture()
        flushHistoryEdits()
        if let id = history?.undoTarget { restoreHistory(id, kind: .undo) }
    }
    func redo() {
        if history == nil { undoTouring(redo: true); return }
        finishHistoryGesture()
        flushHistoryEdits()
        if let id = history?.redoTarget { restoreHistory(id, kind: .redo) }
    }
    func restoreHistory(_ id: UUID, kind: AuditHistory<VenueAuditState>.Entry.Kind = .jump) {
        cancelPlacementHandoff()
        guard !libraryBusy, !historyBlocked else { return }
        // Undo/Redo always includes an in-progress edit before choosing its destination.
        finishHistoryGesture()
        flushHistoryEdits()
        guard let state = history?.node(id)?.state, history?.cursor != id,
              let room = state.rooms.first(where: { $0.id == state.roomID }) else { return }
        do {
            try state.validate()
            historyDestination = (id, kind)
            if room.id == activeRoom?.id {
                try prepareHistoryRestore()
                if let preparedHistory { history = preparedHistory }
                self.preparedHistory = nil; historyDestination = nil
                applyHistoryState(state)
            } else {
                libraryBusy = true; canPlace = false
                roomRequest = .init(room: room, setup: nil, blank: true)
                roomLoadToken = UUID()
            }
        } catch { historyRestoreFailed(error.localizedDescription) }
    }

    func finishHistoryGesture() {
        endViewerNavigation()
        endTransformDrag()
        if actionDepth > 0 { actionDepth = 1; endHistoryAction() }
    }

    /// Called after async asset validation but before publishing a replacement scene.
    /// Failure leaves the old renderer and history cursor untouched.
    func prepareHistoryRestore() throws {
        guard preparedHistory == nil, let destination = historyDestination, var next = history else { return }
        if let kind = destination.kind { try next.move(to: destination.id, kind: kind); try next.save(to: historyURL) }
        preparedHistory = next
    }
    func historyRestoreFailed(_ reason: String) {
        if pendingFixturePlacement != nil { cancelPlacementHandoff(message: "The linked Load Out could not open: \(reason)") }
        if historyDestination != nil { historyMessage = "Could not restore history: \(reason)" }
        historyDestination = nil; preparedHistory = nil; roomRequest = nil; libraryBusy = false
    }
    func applyHistoryState(_ state: VenueAuditState) {
        touring = state.touring ?? TouringArchive(); selectedUnitIDs = state.selectedUnitIDs ?? []; selectedGroupID = state.selectedGroupID; tourPreview = nil; tourPreviewSession = nil
        restoringHistory = true; message = nil; paletteDraftTarget = nil
        defer { restoringHistory = false }
        cancelPicking(); gizmoVisible = false; lastTarget = nil; recent = RecentItems()
        rooms = state.rooms; mergeBundledRooms(); savedSetups = state.setups
        environment = state.rooms.first { $0.id == state.roomID }!.manifest
        cueSheets = state.cueSheets ?? [:]; programmerEdited = false
        fixtures = state.fixtures; presets = state.presets; presetDraft = state.draft; editingPresetID = state.editingPresetID
        setupName = state.setupName; activeSetupID = state.activeSetupID; savedSetup = state.savedSetup
        viewerPose = state.viewerPose ?? .init()
        whiteRoom = state.whiteRoom; houseLight = state.houseLight; blackout = state.blackout
        additionalSelection = []; selectedID = state.selectedID; previewDraft = state.previewDraft; previewBlackout = state.previewBlackout ?? false
        revision += 1; nextFixtureNumber = fixtures.count+1
        if !isDemoMode, tour == nil, let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "venue.presets.v1") }
        persistenceBlocked = false
        if let environment { do { _ = try placements.load(environment: environment) } catch { persistenceBlocked = true } }
        persist()
        programmerSelection = selectedFixtureIDs; programmerCue = currentCue
        environmentStatus = environment!.title
        historyMessage = "Restored · \(history?.current.title ?? "state")"
    }
}

func isDemoModeDirectory(_ arguments: [String]) -> Bool {
    arguments.contains("--demo")
}

// Touring operations validate a complete candidate before publishing one history state.
