import SwiftUI
import VenueVolumeCore

/// The wrist's right column follows selection; the scene list returns on deselect.
struct SceneSelectionPane: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var confirmClear = false

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            if let id = model.selectedID, let fixture = model.fixture(id) {
                HStack {
                    Text("SELECTED ITEM").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Button { model.deselect() } label: { Image(systemName: "xmark").frame(minWidth: 60, minHeight: 60) }
                        .accessibilityLabel("Deselect \(fixture.name)")
                }
                Text(model.selectedFixtureIDs.count > 1 ? "\(model.selectedFixtureIDs.count) selected fixtures" : fixture.name).font(.title3.weight(.semibold))
                if model.selectedFixtureIDs.count > 1 { Button("Create group", systemImage: "square.3.layers.3d") { model.groupSelection() } }
                if let group = fixture.groupID { Button("Break group", systemImage: "square.3.layers.3d.slash") { model.ungroup(group) } }
                Button(model.multiSelectionMode ? "Finish selecting" : "Select multiple") { model.multiSelectionMode.toggle() }
                if model.multiSelectionMode {
                    ForEach(model.fixtures) { item in
                        Button { model.select(item.id) } label: {
                            Label(item.name, systemImage: model.selectedFixtureIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }
                Button { model.presetEditor.request(presetID: fixture.presetID) } label: {
                    Label("Palette editor", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                }
                Button { openWindow(id: "fixture-editor", value: "selection") } label: {
                    Label("Pop out item editor", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                }
                Group {
                    VStack(alignment: .leading, spacing: 14) {
                        FixtureActions(fixture: fixture)
                        Divider()
                        FixturePanel(fixture: model.renderedFixture(fixture))
                    }.padding(.trailing, 4)
                }
            } else {
                HStack {
                    ForEach(model.fixtureGroups, id: \.self) { group in
                    HStack {
                        Text("Group · \(model.fixtures.filter { $0.groupID == group }.count) fixtures")
                        Spacer()
                        Button("Select") { if let item = model.fixtures.first(where: { $0.groupID == group }) { model.select(item.id) } }
                        Button("Break group") { model.ungroup(group) }
                    }
                }
                Text("SCENE · \(model.fixtures.count) ITEMS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear all", role: .destructive) { confirmClear = true }.disabled(model.fixtures.isEmpty)
                }
                Text("\(model.totalChannels) DMX channels · \(Set(model.fixtures.map(\.universe)).count) universes")
                    .font(.caption).foregroundStyle(.secondary)
                if model.fixtures.isEmpty {
                    ContentUnavailableView("Empty scene", systemImage: "cube.transparent",
                        description: Text("Drag a fixture from the library into the room. Select it here or in the scene to inspect and edit it."))
                } else {
                    Group {
                        VStack(spacing: 10) {
                            ForEach(model.fixtures) { fixture in
                                HStack {
                                    Button { model.select(fixture.id) } label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(fixture.name).font(.callout.weight(.semibold))
                                            Text("U\(fixture.universe) · \(fixture.startAddress)–\(fixture.endAddress)")
                                            Text(model.presets.first { $0.id == fixture.presetID }?.name ?? "No palette · dark")
                                        }.font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                                    }.buttonStyle(.plain)
                                    Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash").frame(minWidth: 60, minHeight: 60) }
                                        .accessibilityLabel("Clear \(fixture.name) from scene")
                                }.padding(12).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
        }
        }
        .confirmationDialog("Clear all scene fixtures?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear all fixtures", role: .destructive) { model.clearScene() }
        } message: { Text("The room and saved setups remain available. Undo restores these fixtures.") }
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
                .accessibilityLabel("Delete \(fixture.name)")
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
