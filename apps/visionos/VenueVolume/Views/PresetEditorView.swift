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
    @State private var copyName = ""
    private enum Navigation { case preset(UUID), new }
    private var windowID: UUID { instanceID ?? restoredWindowID }

    var body: some View {
        GeometryReader { geometry in
            let showsSidebar = geometry.size.width >= 1000 && !dynamicTypeSize.isAccessibilitySize
            let sidebarWidth = min(380, max(290, geometry.size.width * 0.28))
            let detailWidth = geometry.size.width - (showsSidebar ? sidebarWidth : 0) - 56
            let stacked = detailWidth < 660 || dynamicTypeSize >= .xxLarge
            HStack(spacing: 0) {
                if showsSidebar {
                    library.frame(width: sidebarWidth)
                    Divider()
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !showsSidebar { compactLibrary }
                        navigation(stacked: stacked)
                        HistoryControls()
                        editor(stacked: stacked)
                        footer(stacked: stacked)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .disabled(model.libraryBusy)
        .onAppear {
            model.presetEditor.registerWindow(windowID)
            if !model.isImmersed && model.presetEditor.windowIDs.count > 1 {
                // A relaunch can restore only companion windows. The launch
                // scene hosts the presenter that safely consolidates them.
                openWindow(id: "launch")
            }
            model.presetWindowVisible = true
            model.previewDraft = true
            model.previewBlackout = false
            if let presetID = model.presetEditor.requestedPreset(for: windowID), presetID != model.editingPresetID {
                request(.preset(presetID))
            }
        }
        .onDisappear {
            model.finishHistoryGesture()
            if model.presetEditor.unregisterWindow(windowID) {
                model.previewDraft = false
                model.previewBlackout = false
                model.cancelPicking()
            }
            model.presetWindowVisible = !model.presetEditor.windowIDs.isEmpty
            model.flushHistoryEdits()
        }
        .onChange(of: model.selectedID) { _, id in
            guard let id, let presetID = model.fixture(id)?.presetID, presetID != model.editingPresetID else { return }
            request(.preset(presetID))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() }
        }
        .confirmationDialog("Unsaved preset changes", isPresented: $showUnsaved, titleVisibility: .visible) {
            Button("Save and continue") { if model.savePreset() { navigate() } }
            Button("Discard changes", role: .destructive) { navigate() }
            Button("Keep editing", role: .cancel) { pendingNavigation = nil }
        } message: { Text("Save or discard your draft before switching presets. Simulation is paused until you choose a preset or turn it back on.") }
        .confirmationDialog("Delete this preset?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete preset", role: .destructive) {
                if let id = model.editingPresetID { model.deletePreset(id) }
            }
        } message: { Text("Assigned objects will be unassigned and their channels set to zero. Unsaved edits will be discarded.") }
        .alert("Save as new preset", isPresented: $showSaveAs) {
            TextField("Preset name", text: $copyName)
            Button("Save new preset") {
                let previousName = model.presetDraft.name
                model.presetDraft.name = copyName
                if model.savePreset(asNew: true) { copyName = "" }
                else { model.presetDraft.name = previousName }
            }.disabled(copyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: { Text("Creates an independent preset. Existing object assignments stay on the original.") }
    }

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Presets").font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(model.presets.count) saved presets").foregroundStyle(.secondary)
                Button { request(.new) } label: {
                    Label("New preset", systemImage: "plus").frame(minHeight: 60)
                }
                LazyVStack(spacing: 12) {
                    ForEach(model.presets) { preset in
                        Button { request(.preset(preset.id)) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(preset.name).font(.headline)
                                    Text("\(preset.channels.count) channels · \(model.fixtures.filter { $0.presetID == preset.id }.count) objects")
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
                Button("New preset", systemImage: "plus") { request(.new) }
                Divider()
                ForEach(model.presets) { preset in
                    Button { request(.preset(preset.id)) } label: {
                        if model.editingPresetID == preset.id {
                            Label(preset.name, systemImage: "checkmark")
                        } else { Text(preset.name) }
                    }
                }
            } label: {
                Label("Presets: \(model.presets.first(where: { $0.id == model.editingPresetID })?.name ?? "New preset")", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            }
            .accessibilityLabel("Choose preset")
            .accessibilityValue(model.presets.first(where: { $0.id == model.editingPresetID })?.name ?? "New preset")
            if !model.isImmersed { VenueEntryButton() }
            profileExplanation
        }
    }

    private var profileExplanation: some View {
        Text("Simulation profile, not manufacturer DMX. Presets own light values; objects keep their patch and position.")
            .font(.subheadline).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func actionLayout<Content: View>(stacked: Bool, @ViewBuilder content: () -> Content) -> some View {
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        return layout { content() }
    }

    private func navigation(stacked: Bool) -> some View {
        actionLayout(stacked: stacked) {
            Label("Preset editor", systemImage: "slider.horizontal.3").font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if !stacked { Spacer() }
            HStack(spacing: 12) {
                Button { adjacent(-1) } label: { Image(systemName: "chevron.left").frame(minWidth: 60, minHeight: 60) }
                    .disabled(adjacentID(-1) == nil).accessibilityLabel("Previous preset")
                Button { adjacent(1) } label: { Image(systemName: "chevron.right").frame(minWidth: 60, minHeight: 60) }
                    .disabled(adjacentID(1) == nil).accessibilityLabel("Next preset")
                Menu {
                    Button("Clear channel values") {
                        model.presetDraft.channels = Array(repeating: 0, count: model.presetDraft.channels.count)
                        model.presetMessage = "Draft cleared. Save to update assigned objects."
                    }
                    Button("Revert to saved") {
                        if let preset = model.presets.first(where: { $0.id == model.editingPresetID }) { model.choosePreset(preset) }
                    }.disabled(model.editingPresetID == nil)
                    Divider()
                    Button("Delete preset", role: .destructive) { showDelete = true }.disabled(model.editingPresetID == nil)
                } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Manage preset")
            }
        }
    }

    private func editor(stacked: Bool) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 20) {
            actionLayout(stacked: stacked) {
                TextField("Preset name", text: $model.presetDraft.name).textFieldStyle(.roundedBorder)
                    .frame(minHeight: 60).accessibilityLabel("Preset name")
                Picker("Channels", selection: Binding(
                    get: { model.presetDraft.channels.count },
                    set: { count in model.presetDraft.channels = Array((model.presetDraft.channels + Array(repeating: 0, count: 16)).prefix(count)) }
                )) { ForEach(1...16, id: \.self) { Text("\($0) channels").tag($0) } }
                    .frame(minHeight: 60).accessibilityLabel("Number of preset channels")
            }
            actionLayout(stacked: stacked) {
                Text(model.draftHasChanges ? "Unsaved changes" : "Saved preset").foregroundStyle(model.draftHasChanges ? Color.orange : .secondary)
                if !stacked { Spacer() }
                Text("VV Preview 16 · Simulation").foregroundStyle(.secondary)
            }.font(.subheadline)
            actionLayout(stacked: stacked) {
                Toggle("Simulate on selected fixture", isOn: $model.previewDraft)
                    .frame(minHeight: 60).disabled(model.selectedID == nil)
                Toggle(isOn: $model.previewBlackout) {
                    Text("Blackout simulation").frame(minHeight: 60)
                }.toggleStyle(.button).disabled(!model.previewDraft || model.selectedID == nil)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: stacked ? 1 : 2), spacing: 24) {
                ForEach(model.presetDraft.channels.indices, id: \.self) { index in channel(index) }
            }
            Divider()
            if model.isRetargeting {
                VStack(alignment: .leading, spacing: 12) {
                    Text(model.message ?? model.pickingInstruction)
                        .fixedSize(horizontal: false, vertical: true)
                    actionLayout(stacked: stacked) {
                        Button { model.cancelPicking() } label: { Text("Cancel target").frame(minHeight: 60) }
                        Button { model.saveTarget() } label: { Text("Save target").frame(minHeight: 60) }
                            .disabled(!model.canSaveTarget)
                    }
                }
            }
            if let id = model.selectedID, let fixture = model.fixture(id) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(fixture.name).font(.headline)
                    Text("Assigned: \(model.presets.first(where: { $0.id == fixture.presetID })?.name ?? "None")")
                        .foregroundStyle(.secondary)
                    actionLayout(stacked: stacked) {
                        Button { model.beginPresetTarget() } label: {
                            Label("Target", systemImage: "scope").frame(minHeight: 60)
                        }.disabled(!model.canPlace || fixture.asset?.headAim != true || model.isRetargeting)
                        Button { model.clearAssignment(id) } label: { Text("Clear assignment").frame(minHeight: 60) }
                            .disabled(fixture.presetID == nil)
                        Button {
                            if let presetID = model.editingPresetID {
                                _ = model.applyPreset(presetID, to: id)
                                model.presetMessage = model.message
                            }
                        } label: { Text("Apply saved").frame(minHeight: 60) }
                            .disabled(model.editingPresetID == nil || model.draftHasChanges)
                    }
                }
            } else {
                Text("Select an object or drag a saved preset from the toolbox onto a fixture.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func channel(_ index: Int) -> some View {
        let asset = model.selectedID.flatMap { model.fixture($0)?.asset }
        let name = asset?.channelName(index) ?? (index < LightingPreview.channelNames.count ? LightingPreview.channelNames[index] : "Unused")
        let value = model.presetDraft.channels.indices.contains(index) ? model.presetDraft.channels[index] : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(index + 1) · \(name)").font(.headline)
                Spacer(minLength: 0)
                Text("\(value)").font(.body.monospacedDigit()).foregroundStyle(.cyan)
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
            .accessibilityHint("Adjusts this channel in the preset draft.")
        }
    }

    private func footer(stacked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.presetMessage ?? "Saving updates all objects assigned to this preset.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            actionLayout(stacked: stacked) {
                Button { copyName = ""; showSaveAs = true } label: { Text("Save as new…").frame(minHeight: 60) }
                    .disabled(model.isRetargeting)
                if !stacked { Spacer() }
                Button { model.savePreset() } label: { Text("Save preset").frame(minHeight: 60) }
                    .buttonStyle(.borderedProminent).disabled(!model.draftHasChanges || model.isRetargeting)
            }
        }
    }

    private func request(_ destination: Navigation) {
        pendingNavigation = destination
        if model.draftHasChanges {
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
        case .new: model.newPreset()
        case nil: break
        }
        pendingNavigation = nil
    }
    private func adjacentID(_ offset: Int) -> UUID? {
        guard let index = model.presets.firstIndex(where: { $0.id == model.editingPresetID }),
              model.presets.indices.contains(index + offset) else { return nil }
        return model.presets[index + offset].id
    }
    private func adjacent(_ offset: Int) { if let id = adjacentID(offset) { request(.preset(id)) } }
}
