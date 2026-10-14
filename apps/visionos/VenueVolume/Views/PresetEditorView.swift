import SwiftUI
import VenueVolumeCore

struct PresetEditorView: View {
    let instanceID: UUID?
    @State private var restoredWindowID = UUID()
    @Environment(VenueModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pendingNavigation: Navigation?
    @State private var showUnsaved = false
    @State private var showDelete = false
    @State private var showSaveAs = false
    @State private var showCueSave = false
    @State private var copyName = ""
    @State private var poolFilter: PaletteCategory?
    @State private var selectedStep = 0
    private var pooledPresets: [DMXPreset] { model.presets.filter { poolFilter == nil || $0.pool == poolFilter } }
    private enum Navigation { case preset(UUID), new }
    private var windowID: UUID { instanceID ?? restoredWindowID }
    private var visibleChannels: [Int] {
        model.presetDraft.channels.indices.filter { index in
            return model.presetDraft.channelMask.contains(index) && !(model.presetDraft.focusTargetID != nil && [4,5].contains(index))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let showsSidebar = geometry.size.width >= 1000 && !dynamicTypeSize.isAccessibilitySize
            let sidebarWidth = min(380, max(290, geometry.size.width * 0.28))
            let detailWidth = geometry.size.width - (showsSidebar ? sidebarWidth : 0) - 56
            let stacked = detailWidth < 660 || dynamicTypeSize >= .xxLarge
            HStack(spacing: 0) {
                if showsSidebar {
                    library.frame(width: sidebarWidth).disabled(model.tourPreview != nil)
                    Divider()
                }
                VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !showsSidebar { compactLibrary.disabled(model.tourPreview != nil) }
                        navigation(stacked: stacked).disabled(model.tourPreview != nil)
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .center, spacing: 24) {
                                PalettePreviewView(palette: model.presetDraft).frame(minWidth: 310)
                                if model.presetDraft.phaser != nil { PhaserCurveView(palette: model.presetDraft).frame(minWidth: 280) }
                            }
                            PalettePreviewView(palette: model.presetDraft)
                        }
                        if model.tourPreview != nil { TourPreviewControls() }
                        else { editor(stacked: stacked); footer(stacked: stacked) }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                }
            }
        }
        .disabled(model.libraryBusy)
        .ornament(visibility: model.selectedFixtures.isEmpty ? .hidden : .visible, attachmentAnchor: .scene(.bottom)) {
            selectionBar.padding(20).frame(width: 850).glassBackgroundEffect()
        }
        .sheet(isPresented: $showCueSave) { SaveCueSheet(current: model.currentCue) }
        .sheet(isPresented: Binding(get: { model.macrosPresented }, set: { model.macrosPresented = $0 })) { MacroEditorView(seed: model.macroSeed) }
        .onAppear {
            model.presetEditor.registerWindow(windowID)
            if !model.isImmersed && model.presetEditor.windowIDs.count > 1 {
                // A relaunch can restore only companion windows. The launch
                // scene hosts the presenter that safely consolidates them.
                openWindow(id: "launch")
            }
            model.presetWindowVisible = true
            model.refreshPaletteSelection()
            model.previewBlackout = false
            if let presetID = model.presetEditor.requestedPreset(for: windowID), presetID != model.editingPresetID {
                request(.preset(presetID))
            }
        }
        .onChange(of: model.selectedFixtureIDs) { _, _ in model.paletteSelectionChanged() }
        .onDisappear {
            model.finishPaletteEditing()
            model.finishHistoryGesture()
            if model.presetEditor.unregisterWindow(windowID) {
                model.previewDraft = false
                model.previewBlackout = false
                model.cancelPicking()
            }
            model.presetWindowVisible = !model.presetEditor.windowIDs.isEmpty
            model.flushHistoryEdits()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() }
        }
        .confirmationDialog("Unsaved palette changes", isPresented: $showUnsaved, titleVisibility: .visible) {
            Button("Save and continue") { if model.selectedFixtures.isEmpty ? model.savePreset() : model.saveCue() { navigate() } }
            Button("Discard changes", role: .destructive) { navigate() }
            Button("Keep editing", role: .cancel) { pendingNavigation = nil }
        } message: { Text("Save or discard your draft before switching palettes. Simulation is paused until you choose a palette or turn it back on.") }
        .confirmationDialog("Delete this palette?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete palette", role: .destructive) {
                if let id = model.editingPresetID { model.deletePreset(id) }
            }
        } message: { Text(model.tour == nil ? "Assigned objects will be unassigned and their channels set to zero. Unsaved edits will be discarded." : "Assigned touring palettes must be reassigned before deletion. Saved venues retain their pinned copies.") }
        .alert("Save as new palette", isPresented: $showSaveAs) {
            TextField("Palette name", text: $copyName)
            Button("Save new palette") {
                let previousName = model.presetDraft.name
                model.presetDraft.name = copyName
                if model.savePreset(asNew: true) { copyName = "" }
                else { model.presetDraft.name = previousName }
            }.disabled(copyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: { Text("Creates an independent palette. Existing object assignments stay on the original.") }
    }

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Palettes & phasers").font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(model.presets.count) saved palettes").foregroundStyle(.secondary)
                Button { request(.new) } label: {
                    Label("New palette", systemImage: "plus").frame(minHeight: 60)
                }
                Picker("Attribute pool", selection: $poolFilter) {
                    Text("All pools").tag(nil as PaletteCategory?)
                    ForEach(PaletteCategory.allCases, id: \.self) { Text($0.label).tag(Optional($0)) }
                }
                LazyVStack(spacing: 12) {
                    ForEach(pooledPresets) { preset in
                        Button { request(.preset(preset.id)) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                PaletteSwatch(palette: preset)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(preset.name).font(.headline)
                                    Text("\(preset.pool.label) · \(preset.phaser.map { "\($0.steps.count) steps" } ?? "Static") · \(model.fixtures.filter { $0.referencedPaletteIDs.contains(preset.id) }.count) fixtures")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                if model.editingPresetID == preset.id {
                                    Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .padding(14)
                            .background(model.editingPresetID == preset.id ? Color.cyan.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(.highlight)
                        .accessibilityAddTraits(model.editingPresetID == preset.id ? [.isSelected] : [])
                    }
                }
                if !model.isImmersed { VenueEntryButton() }
                profileExplanation
            }.padding(24)
        }
    }

    private var compactLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                Button("New palette", systemImage: "plus") { request(.new) }
                Divider()
                ForEach(model.presets) { preset in
                    Button { request(.preset(preset.id)) } label: {
                        if model.editingPresetID == preset.id {
                            Label(preset.name, systemImage: "checkmark")
                        } else { Text(preset.name) }
                    }
                }
            } label: {
                Label("Palettes & phasers: \(model.presets.first(where: { $0.id == model.editingPresetID })?.name ?? "New palette")", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            }
            .accessibilityLabel("Choose palette")
            .accessibilityValue(model.presets.first(where: { $0.id == model.editingPresetID })?.name ?? "New palette")
            if !model.isImmersed { VenueEntryButton() }
            profileExplanation
        }
    }

    private var profileExplanation: some View {
        Text("Simulation profile, not manufacturer DMX. Palettes & phasers own light values; objects keep their patch and position.")
            .font(.subheadline).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func actionLayout<Content: View>(stacked: Bool, @ViewBuilder content: () -> Content) -> some View {
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        return layout { content() }
    }

    private func navigation(stacked: Bool) -> some View {
        actionLayout(stacked: stacked) {
            Text(model.presetDraft.name.isEmpty ? "New palette" : model.presetDraft.name).font(.title.weight(.semibold)).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if !stacked { Spacer() }
            HStack(spacing: 12) {
                Button { model.macroSeed = nil; model.macrosPresented = true } label: {
                    Image(systemName: "list.bullet.rectangle").frame(width: 60, height: 60)
                }.accessibilityLabel("Macros")
                Button { adjacent(-1) } label: { Image(systemName: "chevron.left").frame(minWidth: 60, minHeight: 60) }
                    .disabled(adjacentID(-1) == nil).accessibilityLabel("Previous palette")
                Button { adjacent(1) } label: { Image(systemName: "chevron.right").frame(minWidth: 60, minHeight: 60) }
                    .disabled(adjacentID(1) == nil).accessibilityLabel("Next palette")
                Menu {
                    Button("Make macro from saved palette") {
                        model.macroSeed = ProgrammingMacro(name: model.presetDraft.name, lines: [.init(paletteID: model.editingPresetID)])
                        model.macrosPresented = true
                    }.disabled(model.editingPresetID == nil || model.draftHasChanges)
                    Button("Clear channel values") {
                        model.presetDraft.channels = Array(repeating: 0, count: model.presetDraft.channels.count)
                        model.presetMessage = "Draft cleared. Save to update assigned objects."
                    }
                    Button("Revert to saved") {
                        if let preset = model.presets.first(where: { $0.id == model.editingPresetID }) { model.choosePreset(preset) }
                    }.disabled(model.editingPresetID == nil)
                    Divider()
                    Button("Delete palette", role: .destructive) { showDelete = true }.disabled(model.editingPresetID == nil)
                } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Manage palette")
            }
        }
    }

    private func editor(stacked: Bool) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 20) {
            actionLayout(stacked: stacked) {
                TextField("Palette name", text: $model.presetDraft.name).textFieldStyle(.roundedBorder)
                    .frame(minHeight: 60).accessibilityLabel("Palette name")
                Picker("Store in pool", selection: Binding(get: { model.presetDraft.pool }, set: { model.presetDraft.setPool($0) })) {
                    ForEach(PaletteCategory.allCases, id: \.self) { Text($0.label).tag($0) }
                }.frame(minHeight: 60)

            }
            actionLayout(stacked: stacked) {
                Text(model.programmerEdited ? "Live edits · cue \(model.currentCueLabel)" : "Cue \(model.currentCueLabel)").foregroundStyle(model.programmerEdited ? Color.orange : .secondary)
                if !stacked { Spacer() }
                Text("\(model.selectedFixtures.count) fixtures selected").foregroundStyle(.secondary)
            }.font(.subheadline)
            if model.tour != nil { TouringPresetOptions() }
            TourPreviewControls()
            Divider()
            if !model.isRetargeting {
                Button { model.beginPaletteTarget() } label: {
                    Label("Target Fixture(s)", systemImage: "scope").frame(minHeight: 60)
                }.disabled(model.paletteTargetIssue != nil)
                Text(model.paletteTargetIssue ?? "Aim the selection at a room surface. Each fixture gets its own Pan/Tilt. Targeting holds position while color and intensity phasers continue.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if model.isRetargeting {
                VStack(alignment: .leading, spacing: 12) {
                    Text(model.message ?? model.pickingInstruction)
                        .fixedSize(horizontal: false, vertical: true)
                    actionLayout(stacked: stacked) {
                        Button { model.cancelPicking() } label: { Text("Cancel target").frame(minHeight: 60) }
                        Button { model.saveTarget() } label: { Text(model.isPaletteCueTarget ? "Save target to cue \(model.currentCueLabel)" : "Save target").frame(minHeight: 60) }
                            .disabled(!model.canSaveTarget)
                    }
                }
            }
            phaserEditor
            if model.presetDraft.phaser == nil {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: stacked ? 1 : 2), spacing: 24) {
                ForEach(visibleChannels, id: \.self) { index in channel(index) }
            }
            }
            if model.selectedFixtures.isEmpty {
                Text("Select fixtures to edit their cue output. You can also create a palette in the library.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(model.selectedFixtures.count) fixtures selected").font(.headline)
                Text(model.paletteSelectionIsMixed && !model.previewDraft ? "Mixed look · editing affects the selection" : model.palettePlayback.isPlaying ? "Live fixture output" : "Diagram and fixtures paused")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            CueControlsView()
            Button("Save to cue \(model.currentCueLabel)") { model.saveCue() }
                .buttonStyle(.borderedProminent).disabled(!model.canSaveCue)
        }.frame(minHeight: 60)
    }

    private var phaserEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            PhaserProgrammerView()
            if let issue = model.presetDraft.referenceIssue(in: model.presets) { Text(issue).foregroundStyle(.orange) }
        }
    }

    private func channel(_ index: Int) -> some View {
        let name = LightingPreview.channelName(at: index)
        let value = model.presetDraft.channels.indices.contains(index) ? model.presetDraft.channels[index] : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(name).font(.headline)
                Spacer(minLength: 0)
                Text("\(Int((Double(value) / 255 * 100).rounded()))%").font(.body.monospacedDigit()).foregroundStyle(.cyan)
            }.accessibilityHidden(true)
            Slider(value: Binding(
                get: { model.presetDraft.channels.indices.contains(index) ? Double(model.presetDraft.channels[index]) : 0 },
                set: { if model.presetDraft.channels.indices.contains(index) { model.presetDraft.channels[index] = Int($0) } }
            ), in: 0...255, step: 1, onEditingChanged: { editing in
                if editing { model.beginHistoryAction("Edit DMX channel \(index+1)") } else { model.endHistoryAction() }
            })
            .frame(minHeight: 60)
            .accessibilityLabel("Channel \(index + 1), \(name)")
            .accessibilityValue("\(value) of 255")
            .accessibilityHint("Adjusts this channel in the palette draft.")
        }
    }

    private func footer(stacked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.presetMessage ?? (model.selectedFixtures.isEmpty ? "Store a reusable palette, or select fixtures to record a cue." : "Changes preview live. Save records this cue; changing selection or cue also records your edits here."))
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            actionLayout(stacked: stacked) {
                Menu("Palette library") {
                    Button("Store as new palette…") { copyName = model.presetDraft.name; showSaveAs = true }
                    Button("Update library palette") { model.savePreset() }.disabled(model.editingPresetID == nil || !model.canSavePreset)
                }.frame(minHeight: 60)
                if !stacked { Spacer() }
                if !model.selectedFixtures.isEmpty {
                    Button("Save to specific cue…") { showCueSave = true }.disabled(!model.canSaveCue).frame(minHeight: 60)
                    Button("Save to cue \(model.currentCueLabel)") { model.saveCue() }
                        .buttonStyle(.borderedProminent).disabled(!model.canSaveCue).frame(minHeight: 60)
                } else {
                    Button("Store palette") { model.savePreset() }.buttonStyle(.borderedProminent).disabled(!model.canSavePreset)
                }
            }
        }
    }

    private func request(_ destination: Navigation) {
        pendingNavigation = destination
        if !model.selectedFixtureIDs.isEmpty {
            if !model.programmerEdited || model.saveCue() { navigate() }
        } else if model.draftHasChanges {
            // Keep the draft intact without projecting it onto a newly selected
            // fixture while the user is deciding which preset to edit.
            model.previewDraft = false
            showUnsaved = true
        } else { navigate() }
    }
    private func navigate() {
        switch pendingNavigation {
        case .preset(let id):
            if let preset = model.presets.first(where: { $0.id == id }) { model.choosePreset(preset) }
        case .new: model.newPreset(pool: poolFilter ?? .intensity)
        case nil: break
        }
        pendingNavigation = nil
        selectedStep = 0
    }
    private func adjacentID(_ offset: Int) -> UUID? {
        guard let index = model.presets.firstIndex(where: { $0.id == model.editingPresetID }),
              model.presets.indices.contains(index + offset) else { return nil }
        return model.presets[index + offset].id
    }
    private func adjacent(_ offset: Int) { if let id = adjacentID(offset) { request(.preset(id)) } }
}
