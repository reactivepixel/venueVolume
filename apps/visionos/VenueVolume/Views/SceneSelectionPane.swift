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
            Button("Axes", systemImage: "rotate.3d") { model.beginTransform(fixture.id) }.disabled(!model.canPlace)
            Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash").frame(minWidth: 60, minHeight: 60) }
                .accessibilityLabel(model.tour == nil ? "Delete \(fixture.name)" : "Return \(fixture.name) to inventory")
        }.font(.caption)
    }
}
