import SwiftUI
import VenueVolumeCore

struct PresetEditorView: View {
    let instanceID: UUID?
    @State private var restoredWindowID = UUID()
    @Environment(VenueModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @State private var pendingNavigation: Navigation?
    @State private var showUnsaved = false
    @State private var showDelete = false
    @State private var showSaveAs = false
    @State private var copyName = ""
    private enum Navigation { case preset(UUID), new }
    private var windowID: UUID { instanceID ?? restoredWindowID }

    var body: some View {
        HStack(spacing: 0) {
            library
            Divider()
            VStack(alignment: .leading, spacing: 18) {
                navigation
                HistoryControls()
                editor
                footer
            }.padding(28).frame(maxWidth: .infinity)
        }.frame(width: 1040, height: 820)
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
        VStack(alignment: .leading, spacing: 18) {
            Text("Presets").font(.largeTitle.weight(.semibold))
            Text("\(model.presets.count) saved presets").font(.caption).foregroundStyle(.secondary)
            Button { request(.new) } label: { Label("New preset", systemImage: "plus") }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.presets) { preset in
                        Button { request(.preset(preset.id)) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(preset.name).font(.headline).lineLimit(2)
                                Text("\(preset.channels.count) channels · \(model.fixtures.filter { $0.presetID == preset.id }.count) objects")
                                    .font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                                .background(model.editingPresetID == preset.id ? Color.cyan.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
            if !model.isImmersed { VenueEntryButton() }
            Text("Simulation profile, not manufacturer DMX. Presets own light values; objects keep their patch and position.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(24).frame(width: 270)
    }

    private var navigation: some View {
        HStack {
            Label("Preset editor", systemImage: "slider.horizontal.3").font(.title2.weight(.semibold))
            Spacer()
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

    private var editor: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                TextField("Preset name", text: $model.presetDraft.name).textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Preset name")
                Picker("Channels", selection: Binding(
                    get: { model.presetDraft.channels.count },
                    set: { count in model.presetDraft.channels = Array((model.presetDraft.channels + Array(repeating: 0, count: 16)).prefix(count)) }
                )) { ForEach(1...16, id: \.self) { Text("\($0) channels").tag($0) } }.frame(width: 170)
            }
            HStack {
                Text(model.draftHasChanges ? "Unsaved changes" : "Saved preset").foregroundStyle(model.draftHasChanges ? Color.orange : .secondary)
                Spacer()
                Text("VV PREVIEW 16 · SIMULATION").foregroundStyle(.secondary)
            }.font(.caption)
            HStack {
                Toggle("Simulate on selected fixture", isOn: $model.previewDraft)
                    .disabled(model.selectedID == nil)
                Toggle("Blackout simulation", isOn: $model.previewBlackout)
                    .toggleStyle(.button).disabled(!model.previewDraft || model.selectedID == nil)
            }.font(.caption)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(model.presetDraft.channels.indices, id: \.self) { index in
                        channel(index)
                    }
                }.padding(.vertical, 6)
            }.frame(maxHeight: .infinity)
            Divider()
            if model.isRetargeting {
                HStack {
                    Text(model.message ?? model.pickingInstruction).font(.caption)
                    Button("Cancel target") { model.cancelPicking() }
                    Button("Save target") { model.saveTarget() }.disabled(!model.canSaveTarget)
                }
            }
            if let id = model.selectedID, let fixture = model.fixture(id) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fixture.name).font(.headline)
                        Text("Assigned: \(model.presets.first(where: { $0.id == fixture.presetID })?.name ?? "None")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Target", systemImage: "scope") { model.beginPresetTarget() }
                        .disabled(!model.canPlace || fixture.asset?.headAim != true || model.isRetargeting)
                    Button("Clear assignment") { model.clearAssignment(id) }.disabled(fixture.presetID == nil)
                    Button("Apply saved") {
                        if let presetID = model.editingPresetID {
                            _ = model.applyPreset(presetID, to: id)
                            model.presetMessage = model.message
                        }
                    }.disabled(model.editingPresetID == nil || model.draftHasChanges)
                }
            } else {
                Text("Select an object or drag a saved preset from the toolbox onto a fixture.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func channel(_ index: Int) -> some View {
        VStack(spacing: 5) {
            HStack {
                let asset = model.selectedID.flatMap { model.fixture($0)?.asset }
                Text("\(index + 1) · \(asset?.channelName(index) ?? (index < LightingPreview.channelNames.count ? LightingPreview.channelNames[index] : "Unused"))").font(.caption.weight(.semibold))
                Spacer()
                Text("\(model.presetDraft.channels[index])").font(.body.monospacedDigit()).foregroundStyle(.cyan)
            }
            Slider(value: Binding(
                get: { model.presetDraft.channels.indices.contains(index) ? Double(model.presetDraft.channels[index]) : 0 },
                set: { if model.presetDraft.channels.indices.contains(index) { model.presetDraft.channels[index] = Int($0) } }
            ), in: 0...255, step: 1, onEditingChanged: { editing in
                if editing { model.beginHistoryAction("Edit DMX channel \(index+1)") } else { model.endHistoryAction() }
            }).accessibilityLabel("Preset channel \(index + 1)")
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.presetMessage ?? "Saving updates all objects assigned to this preset.")
                .font(.caption).foregroundStyle(.secondary).frame(height: 32, alignment: .topLeading)
            HStack {
                Button("Save as new…") { copyName = ""; showSaveAs = true }.disabled(model.isRetargeting)
                Spacer()
                Button("Save preset") { model.savePreset() }.buttonStyle(.borderedProminent).disabled(!model.draftHasChanges || model.isRetargeting)
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
