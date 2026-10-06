import SwiftUI
import VenueVolumeCore

/// Only selected fixtures belong in the wrist selection column.
struct SceneSelectionPane: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var choosing = false
    @State private var namingGroup = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SELECTED · \(model.selectedFixtures.count)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    if !model.selectedFixtures.isEmpty {
                        Button("Clear selection", systemImage: "xmark") { model.deselect() }
                    }
                }
                Button("Add fixtures…", systemImage: "plus") { choosing = true }.disabled(model.fixtures.isEmpty)
                if model.selectedFixtures.isEmpty {
                    ContentUnavailableView("No fixtures selected", systemImage: "cursorarrow.click",
                        description: Text("Select fixtures in the room or use Add fixtures. Selecting the background clears the selection."))
                } else {
                    Button(model.multiSelectionMode ? "Finish selecting" : "Select multiple in room") { model.multiSelectionMode.toggle() }
                    ForEach(model.selectedFixtures) { fixture in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fixture.name).font(.headline)
                            Text(fixture.groupName ?? "U\(fixture.universe) · \(fixture.startAddress)–\(fixture.endAddress)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if model.selectedFixtures.count > 1 {
                        Button("Group", systemImage: "square.3.layers.3d") { namingGroup = true }
                    }
                    if let fixture = model.selectedFixtures.first {
                        if let group = fixture.groupID { Button("Break group", systemImage: "square.3.layers.3d.slash") { model.ungroup(group) } }
                        Button("Palette editor", systemImage: "slider.horizontal.3") { model.presetEditor.request(presetID: fixture.presetID) }
                        Button("Pop out item editor", systemImage: "arrow.up.right.square") { openWindow(id: "fixture-editor", value: "selection") }
                        FixtureActions(fixture: fixture)
                        if model.selectedFixtures.count == 1 {
                            Divider()
                            FixturePanel(fixture: model.renderedFixture(fixture))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $choosing) { FixtureSelectionSheet() }
        .sheet(isPresented: $namingGroup) { SelectionGroupSheet() }
    }
}

/// Separate discovery from the selected-only list; toggling always extends selection.
struct FixtureSelectionSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                if model.tour != nil {
                    ForEach(model.tourUnits) { unit in
                        Button { model.toggleUnitSelection(unit.id) } label: {
                            Label(unit.fixture.name, systemImage: model.tourSelection.contains(unit.id) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } else {
                    ForEach(model.fixtures) { fixture in
                        Button {
                            let previous = model.multiSelectionMode
                            model.multiSelectionMode = true; model.select(fixture.id); model.multiSelectionMode = previous
                        } label: {
                            Label(fixture.name, systemImage: model.selectedFixtureIDs.contains(fixture.id) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }
            }.navigationTitle("Add fixtures to selection")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.frame(width: 580, height: 520)
    }
}

struct SelectionGroupSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var failure: String?
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $name)
                if let failure { Text(failure).foregroundStyle(.red) }
                Text("Group \(model.tour == nil ? model.selectedFixtureIDs.count : model.tourSelection.count) selected fixtures.")
            }.navigationTitle("Name group")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create group") {
                            if model.groupSelection(name: trimmed) { dismiss() }
                            else { failure = model.message ?? "Select at least two fixtures and enter a name of at most 120 characters." }
                        }
                            .disabled(trimmed.isEmpty || trimmed.count > 120 || (model.tour == nil ? model.selectedFixtureIDs.count : model.tourSelection.count) < 2)
                    }
                }
        }.frame(width: 520, height: 300)
    }
}

struct FixtureActions: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        let layout = textSize >= .xxLarge ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
        layout {
            Button("Retarget DMX", systemImage: "scope") { model.beginRetarget(fixture.id) }.disabled(!model.canPlace || fixture.asset?.headAim != true)
            Button("Axes", systemImage: "rotate.3d") { model.beginTransform(fixture.id) }.disabled(!model.canPlace)
            Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash").frame(minWidth: 60, minHeight: 60) }
                .accessibilityLabel(model.tour == nil ? "Delete \(fixture.name)" : "Return \(fixture.name) to inventory")
        }.font(.caption)
    }
}

struct FixtureEditorView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var tab = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let id = model.selectedID, let fixture = model.fixture(id) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fixture.name).font(.largeTitle.weight(.semibold))
                        Text("Selected item editor").foregroundStyle(.secondary)
                    }
                    Spacer()
                    HistoryControls()
                }
                Picker("Item editor", selection: $tab) {
                    Text("Info & palette").tag(0)
                    Text("Transform").tag(1)
                }.pickerStyle(.segmented)
                if tab == 0 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Button("Palette editor", systemImage: "slider.horizontal.3") {
                                model.presetEditor.request(presetID: fixture.presetID)
                            }.frame(minHeight: 60)
                            FixtureActions(fixture: fixture)
                            FixtureDetailsEditor(fixture: fixture).id(fixture.id)
                            Divider()
                            FixturePanel(fixture: model.renderedFixture(fixture))
                        }
                    }
                } else { FixturePlacementView() }
            } else {
                ContentUnavailableView("Select a fixture", systemImage: "cube.transparent")
            }
            // visionOS may restore this companion window as the only scene.
            // Keep entry reachable until the room has restored selection.
            if !model.isImmersed { VenueEntryButton() }
        }.padding(28).frame(minWidth: 620, minHeight: 600)
        .presetEditorPresenter(when: !model.isImmersed)
        .onAppear {
            if model.isImmersed && model.selectedID == nil { dismissWindow(id: "fixture-editor") }
            if model.controlsTab == 1 { tab = 1 }
        }
        .onChange(of: model.selectedID) { _, id in if id == nil && model.isImmersed { dismissWindow(id: "fixture-editor") } }
        .disabled(model.libraryBusy)
    }
}

private struct FixtureDetailsEditor: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture
    @State private var name: String
    @State private var universe: Int
    @State private var address: Int
    init(fixture: Fixture) {
        self.fixture = fixture
        _name = State(initialValue: fixture.name)
        _universe = State(initialValue: fixture.universe)
        _address = State(initialValue: fixture.startAddress)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Item details").font(.headline)
            TextField("Fixture name", text: $name)
            HStack {
                VStack(alignment: .leading) {
                    Text("Universe").font(.caption)
                    TextField("Universe", value: $universe, format: .number)
                }
                VStack(alignment: .leading) {
                    Text("Start address").font(.caption)
                    TextField("Start address", value: $address, format: .number)
                }
            }
            Button("Save item details") { model.updateFixtureDetails(fixture.id, name: name, universe: universe, address: address) }
                .disabled(name == fixture.name && universe == fixture.universe && address == fixture.startAddress)
            if let message = model.message { Text(message).font(.caption).foregroundStyle(.secondary) }
        }.onChange(of: fixture) { _, current in
            name = current.name; universe = current.universe; address = current.startAddress
        }
    }
}
