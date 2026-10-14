import SwiftUI
import UniformTypeIdentifiers
import VenueVolumeCore

struct TouringContextButton: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        Button { model.touringPanelPresented = true } label: {
            HStack {
                Image(systemName: "shippingbox")
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.tour?.show.name ?? "Prepare a touring show").font(.headline)
                    Text(model.tour.map { "\($0.configuration?.name ?? "Configuration") · pinned revision \($0.show.revision)" } ?? "Inventory, groups and presets that travel between venues")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }.frame(minHeight: 60)
        }.buttonStyle(.plain)
    }
}

struct TouringLibrarySheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var configurationName = ""
    @State private var selectionOnly = false
    @State private var importing = false
    @State private var exporting = false
    @State private var document: TouringDocument?
    @State private var importURL: URL?
    @State private var reading = false
    @State private var pendingShow: UUID?
    @State private var pendingConfiguration: UUID?
    @State private var confirmSwitch = false
    var body: some View {
        NavigationStack {
            Form {
                Section { HistoryControls() }
                Section("Show library") {
                    Text("A show owns equipment identities, groups and reusable presets. A saved venue pins its own copy.").foregroundStyle(.secondary)
                    ForEach(model.touring.shows) { show in
                        Button { pendingShow = show.id; pendingConfiguration = nil; if model.hasUnsavedSetup { confirmSwitch = true } else { chooseShow() } } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(show.name).font(.headline)
                                    Text("\(show.units.count) units · revision \(show.revision)").foregroundStyle(.secondary)
                                }
                                Spacer()
                                if model.tour?.show.id == show.id { Image(systemName: "checkmark") }
                            }.frame(minHeight: 60)
                        }.disabled(!model.fixtures.isEmpty)
                    }
                    if !model.fixtures.isEmpty { Text("Save the current venue, then return its placements before switching shows. Create a show below to adopt this legacy scene.").font(.callout) }
                    TextField("New show name", text: $name)
                    Button(model.tour == nil && !model.fixtures.isEmpty ? "Create show from this scene" : "Create show") {
                        model.createTouringShow(name: name); if model.tour?.show.name == name { name = "" }
                    }.disabled(!TouringShow.validName(name) || model.tour != nil && !model.fixtures.isEmpty)
                    if reading { ProgressView("Reading show…") }
                    Button("Import show…", systemImage: "square.and.arrow.down") { importing = true }.disabled(reading)
                }
                if let tour = model.tour {
                    Section("Configuration · \(tour.show.name)") {
                        Picker("Active configuration", selection: Binding(get: { tour.configurationID }, set: { pendingShow = tour.show.id; pendingConfiguration = $0; if model.hasUnsavedSetup { confirmSwitch = true } else { chooseShow() } })) {
                            ForEach(tour.show.configurations) { Text($0.name).tag($0.id) }
                        }.disabled(!model.fixtures.isEmpty)
                        TextField("Configuration name", text: $configurationName)
                        Toggle("Only selected inventory units", isOn: $selectionOnly)
                        Button("Save inventory and layout as configuration") {
                            model.saveConfiguration(name: configurationName, selectionOnly: selectionOnly); configurationName = ""
                        }.disabled(!TouringShow.validName(configurationName) || selectionOnly && model.tourSelection.isEmpty)
                        Text("Start another venue blank, then use Adapt layout in the selection pane to preview this configuration's arrangement.").font(.callout).foregroundStyle(.secondary)
                    }
                    Section("Revisions and sharing") {
                        Text("This venue uses revision \(tour.show.revision). Saved venues keep their original revision and local changes.")
                        if let latest = model.availableShowUpdate {
                            Text("Revision \(latest.revision) available · \(latest.units.count - tour.show.units.count) net equipment changes · \(latest.groups.count) groups · \(latest.presets.count) presets")
                            ForEach(Array(model.showUpdateChanges.enumerated()), id: \.offset) { _, change in Text(change).font(.callout) }
                            Button("Review changes in venue") { model.previewShowUpdate(); dismiss() }
                        }
                        Button("Export show library", systemImage: "square.and.arrow.up") {
                            do { document = try TouringDocument(show: tour.show); exporting = true }
                            catch { model.message = error.localizedDescription }
                        }
                        Text("Exports the pinned show, including unplaced equipment and unused shared presets. Venue-only preset overrides remain in Export save.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if model.history == nil, let history = model.tourHistory {
                    Section("Show preparation history") {
                        ForEach(Array(history.entries.reversed())) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.title)
                                    Text(entry.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if entry.kind != .external {
                                    Button("Restore") { model.restoreTouringEvent(entry.nodeID) }.disabled(entry.nodeID == history.cursor)
                                }
                            }
                        }
                    }
                }
                if let message = model.message { Section { Text(message).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Touring shows")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.frame(minWidth: 660, idealWidth: 760, minHeight: 640, idealHeight: 800)
        .confirmationDialog("Save this venue before changing shows?", isPresented: $confirmSwitch, titleVisibility: .visible) {
            Button("Save and continue") { if model.saveSetup() { chooseShow() } }
            Button("Discard and continue", role: .destructive) { chooseShow() }
            Button("Cancel", role: .cancel) { pendingShow = nil }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result { case .success(let url): importURL = url; reading = true
            case .failure(let error): model.message = error.localizedDescription }
        }
        .task(id: importURL) {
            guard let url = importURL else { return }
            defer { reading = false; importURL = nil }
            do {
                let data = try await TouringFileReader.read(url)
                try Task.checkCancellation(); model.importTouringShow(data)
            } catch is CancellationError {} catch { model.message = error.localizedDescription }
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Venue Volume Show") { result in
            switch result {
            case .success: model.auditExternal("Export touring show"); model.message = "Show exported."
            case .failure(let error): model.message = error.localizedDescription
            }
        }
    }
    private func chooseShow() { if let pendingShow { model.selectTouringShow(pendingShow, configuration: pendingConfiguration) }; pendingShow = nil; pendingConfiguration = nil }
}

private struct TouringDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(show: TouringShow) throws { try show.validate(); data = try JSONEncoder().encode(show) }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count < 20_000_000 else { throw PresetError("Show is missing or too large.") }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
private actor TouringFileReader {
    static func read(_ url: URL) async throws -> Data {
        try await shared.readFile(url)
    }
    private static let shared = TouringFileReader()
    private func readFile(_ url: URL) throws -> Data {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size < 20_000_000 else { throw PresetError("Show is too large.") }
        return try Data(contentsOf: url)
    }
}

struct InventoryLibraryView: View {
    @Environment(VenueModel.self) private var model
    @State private var search = ""
    @State private var browseAll = false
    @State private var adding = false
    @State private var groups = false
    @State private var renameID: UUID?
    @State private var name = ""
    @State private var rename = false
    private var visible: [InventoryUnit] {
        guard let tour = model.tour else { return [] }
        return tour.allUnits.filter { unit in (tour.configuration?.unitIDs.contains(unit.id) == true || tour.localUnits.contains(where: { $0.id == unit.id })) && (search.isEmpty || unit.fixture.name.localizedCaseInsensitiveContains(search)) }
    }
    private var modelIDs: [String] {
        var ids: [String] = []
        for unit in visible { let id = unit.fixture.assetID ?? "cube"; if !ids.contains(id) { ids.append(id) } }
        if browseAll || !search.isEmpty { return ids }
        return model.quickFixtureKinds.compactMap { $0.assetID ?? "cube" }.filter { ids.contains($0) }
    }
    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Add equipment", systemImage: "plus") { adding = true }
                Button("Groups", systemImage: "folder") { groups = true }
            }.frame(minHeight: 60)
            Button(browseAll ? "Show recent fixtures" : "Browse all inventory", systemImage: "square.grid.2x2") { browseAll.toggle() }.frame(minHeight: 60)
            TextField("Search inventory", text: $search).textFieldStyle(.roundedBorder)
            Toggle("Select multiple", isOn: $model.multiSelection).toggleStyle(.button).frame(minHeight: 60)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(modelIDs, id: \.self) { assetID in
                        let units = visible.filter { ($0.fixture.assetID ?? "cube") == assetID }
                        let available = model.availableUnits.filter { ($0.fixture.assetID ?? "cube") == assetID }
                        let placed = units.filter { model.fixture($0.id) != nil }.count
                        VStack(alignment: .leading, spacing: 6) {
                            Text(units.first?.fixture.asset?.name ?? "DMX cube").font(.headline)
                            Text("\(placed) placed · \(available.count) available · \(units.count) total").font(.caption).foregroundStyle(.secondary)
                            if let first = available.first {
                                Button("Place remaining \(available.count)") { model.beginInventoryPlacement(first.id, repeatAll: true) }.disabled(!model.canPlace)
                            }
                        }
                        ForEach(units) { unit in inventoryRow(unit) }
                        Divider()
                    }
                    if visible.isEmpty { Text("Add equipment once, then use the same units in every venue.").foregroundStyle(.secondary) }
                    ForEach(model.tour?.show.quantities ?? []) { item in
                        HStack { Label("\(item.name) × \(item.quantity)", systemImage: "shippingbox"); Spacer(); Button("Remove", role: .destructive) { model.removeQuantity(item.id) } }
                    }
                }
            }
        }
        .sheet(isPresented: $adding) { AddEquipmentSheet() }
        .sheet(isPresented: $groups) { GroupManagerSheet() }
        .alert("Rename equipment", isPresented: $rename) {
            TextField("Equipment name", text: $name)
            Button("Save") { if let renameID { model.renameInventory(renameID, name: name) } }.disabled(!TouringShow.validName(name))
            Button("Cancel", role: .cancel) {}
        }
    }
    private func inventoryRow(_ unit: InventoryUnit) -> some View {
        let placed = model.fixture(unit.id) != nil
        let excluded = model.tour?.excluded.contains(unit.id) == true
        let local = model.tour?.localUnits.contains { $0.id == unit.id } == true
        return HStack(spacing: 12) {
            Button { model.selectInventory(unit.id) } label: {
                HStack {
                    Image(systemName: model.tourSelection.contains(unit.id) ? "checkmark.circle.fill" : "circle")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.fixture.name).font(.callout.weight(.semibold))
                        Text(excluded ? "Excluded at this venue" : unit.unavailable ? "Unavailable" : placed ? "Placed" : "Available")
                            .font(.caption).foregroundStyle(.secondary)
                        if local { Text("Venue only").font(.caption).foregroundStyle(.secondary) }
                    }
                }.frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            }.buttonStyle(.plain).disabled(excluded)
                .onDrag {
                    guard !placed, !excluded, !unit.unavailable, model.canPlace else { return NSItemProvider() }
                    model.beginInventoryDrag(unit.id)
                    return NSItemProvider(object: model.fixtureKind.dragToken as NSString)
                }
            Menu {
                if placed { Button("Return to inventory") { model.remove(unit.id) } }
                else {
                    Button("Place") { model.beginInventoryPlacement(unit.id) }.disabled(excluded || unit.unavailable || !model.canPlace)
                    Button(excluded ? "Include at this venue" : "Exclude at this venue") { model.excludeInventory(unit.id) }
                    Button(unit.unavailable ? "Mark available" : "Mark unavailable") { model.setUnitUnavailable(unit.id, !unit.unavailable) }
                }
                Button("Rename") { renameID = unit.id; name = unit.fixture.name; rename = true }
                Button("Remove equipment from show", role: .destructive) { model.removeInventory(unit.id) }.disabled(placed)
            } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Actions for \(unit.fixture.name)")
        }
    }
}

private struct AddEquipmentSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var browsing = false
    @State private var kind = FixtureKind.movingHead
    @State private var quantity = 1
    @State private var venueOnly = false
    @State private var quantityOnly = false
    @State private var useSelectedGroup = true
    @State private var name = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Quantity-only equipment (no DMX)", isOn: $quantityOnly)
                    if quantityOnly { TextField("Equipment name", text: $name) }
                    else {
                        Toggle("Only for this venue", isOn: $venueOnly)
                        if let group = model.tour?.show.groups.first(where: { $0.id == model.selectedGroupID }) {
                            Toggle("Add to \(group.name)", isOn: $useSelectedGroup)
                        }
                        Picker("Fixture model", selection: $kind) {
                            ForEach(model.quickFixtureKinds.contains(kind) ? model.quickFixtureKinds : model.quickFixtureKinds + [kind]) { Text($0.name).tag($0) }
                        }
                        Button("Browse all fixtures", systemImage: "square.grid.2x2") { browsing = true }
                        Text("VV Preview 16 · Simulated personality. Manufacturer DMX modes are not provided.").font(.caption).foregroundStyle(.secondary)
                    }
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...64)
                }
                if let message = model.message { Text(message).foregroundStyle(.secondary) }
            }.navigationTitle("Add equipment")
                .sheet(isPresented: $browsing) { FixtureCatalogBrowser { chosen in kind = chosen; model.rememberFixtureKind(chosen) } }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let before = model.tour
                            if quantityOnly { model.addQuantity(name: name, quantity: quantity) }
                            else { model.addInventory(kind, quantity: quantity, venueOnly: venueOnly, groupID: useSelectedGroup ? model.selectedGroupID : nil) }
                            if before != model.tour { dismiss() }
                        }.disabled(quantityOnly && !TouringShow.validName(name))
                    }
                }
        }.frame(minWidth: 620, minHeight: 500)
    }
}

private struct GroupManagerSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var editing: UUID?
    @State private var name = ""
    @State private var parent: UUID?
    var body: some View {
        NavigationStack {
            Form {
                Section("Select group") {
                    Button("All fixtures") { model.selectGroup(nil); dismiss() }
                    ForEach(model.tour?.show.groups ?? []) { group in
                        HStack {
                            Button { model.selectGroup(group.id); dismiss() } label: {
                                VStack(alignment: .leading) {
                                    Text(groupPath(group))
                                    Text("\(model.tour?.members(of: group.id).count ?? 0) active units").font(.caption).foregroundStyle(.secondary)
                                }.frame(minHeight: 60)
                            }
                            Spacer()
                            Menu {
                                Button("Rename / reparent") { editing = group.id; name = group.name; parent = group.parentID }
                                Button("Remove group; keep equipment", role: .destructive) { model.previewRemoveGroup(group.id); dismiss() }
                            } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Manage \(group.name)")
                        }
                    }
                }
                Section(editing == nil ? "New group" : "Edit group") {
                    TextField("Group name", text: $name)
                    Picker("Parent", selection: $parent) {
                        Text("Top level").tag(nil as UUID?)
                        ForEach((model.tour?.show.groups ?? []).filter { group in
                            guard let editing else { return true }
                            return !((model.tour?.show.ancestors(of: group.id) ?? []).contains(editing))
                        }) { Text(groupPath($0)).tag(Optional($0.id)) }
                    }
                    Button(editing == nil ? "Create group" : "Preview group change") {
                        model.saveGroup(id: editing, name: name, parentID: parent)
                        if editing != nil { dismiss() } else { name = ""; parent = nil }
                    }.disabled(!TouringShow.validName(name))
                    if editing != nil { Button("New group instead") { editing = nil; name = ""; parent = nil } }
                }
                if let message = model.message { Text(message).foregroundStyle(.secondary) }
            }.navigationTitle("Fixture groups")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.frame(minWidth: 640, minHeight: 600)
    }
    private func groupPath(_ group: FixtureGroup) -> String {
        (model.tour?.show.ancestors(of: group.id).reversed().compactMap { id in model.tour?.show.groups.first { $0.id == id }?.name } ?? []).joined(separator: " / ")
    }
}

struct TourPreviewControls: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        if model.tourPreview != nil {
            VStack(alignment: .leading, spacing: 12) {
                Label("Preview · \(model.tourPreviewTitle)", systemImage: "eye").font(.headline)
                Text("Save applies the complete change as one Undo step.").foregroundStyle(.secondary)
                HStack {
                    Button("Cancel", role: .cancel) { model.cancelTourPreview() }.frame(minHeight: 60)
                    Button("Save change") { model.commitTourPreview() }.buttonStyle(.borderedProminent).frame(minHeight: 60)
                }
            }
        }
    }
}

struct TourSelectionPane: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var arranging = false
    @State private var adapting = false
    @State private var choosing = false
    @State private var namingGroup = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.tourSelection.isEmpty {
                    ContentUnavailableView("No fixtures selected", systemImage: "cursorarrow.click",
                        description: Text("Select inventory units in the library or add fixtures to the selection."))
                    Button("Add fixtures…", systemImage: "plus") { choosing = true }.disabled(model.tourUnits.isEmpty)
                    Button("Adapt configuration layout…") { adapting = true }.disabled(!model.fixtures.isEmpty || model.tour?.configuration?.layout.isEmpty != false)
                } else {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(model.tourSelectionName).font(.title3.weight(.semibold))
                            Text("\(model.fixtures.filter { model.tourSelection.contains($0.id) }.count) placed · \(model.tourSelection.count) selected").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { model.deselect() } label: { Image(systemName: "xmark").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Deselect inventory")
                    }
                    Button("Add fixtures…", systemImage: "plus") { choosing = true }
                    if model.tourSelection.count > 1 {
                        Button("Group", systemImage: "square.3.layers.3d") { namingGroup = true }
                    }
                    Button("Preset editor", systemImage: "slider.horizontal.3") { model.presetEditor.request() }.frame(minHeight: 60)
                    TourApplyMenu()
                    Menu("Move selection into group") {
                        Button("Ungrouped") { model.assignSelectionToGroup(nil) }
                        ForEach(model.tour?.show.groups ?? []) { group in Button(group.name) { model.assignSelectionToGroup(group.id) } }
                    }.frame(minHeight: 60)
                    Button("Arrange / place row…", systemImage: "arrow.left.and.right") { arranging = true }.frame(minHeight: 60)
                    if model.selectedID != nil {
                        Button("Transform axes", systemImage: "rotate.3d") { model.beginSelectionTransform() }.frame(minHeight: 60)
                        Button("Refocus named targets", systemImage: "scope") { model.refocusSelection() }.frame(minHeight: 60)
                        Button("Auto-patch selection") { model.autoPatchSelection() }.frame(minHeight: 60)
                        Button("Return selected to inventory") { model.returnSelection() }.frame(minHeight: 60)
                    }
                    Button("Reset individual assignments to group") { model.resetTourAssignment(model.tourSelection) }.frame(minHeight: 60)
                    ForEach(model.tourUnits.filter { model.tourSelection.contains($0.id) }) { unit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(unit.fixture.name).font(.headline)
                            Text(model.programmingSummary(unit)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if model.tourSelection.count == 1, let id = model.selectedID, let fixture = model.fixture(id) {
                        Divider()
                        FixtureActions(fixture: fixture)
                        FixturePanel(fixture: model.renderedFixture(fixture))
                    }
                }
                Divider()
                FocusTargetList()
            }
        }
        .sheet(isPresented: $arranging) { ArrangementSheet(adapting: false) }
        .sheet(isPresented: $adapting) { ArrangementSheet(adapting: true) }
        .sheet(isPresented: $choosing) { FixtureSelectionSheet() }
        .sheet(isPresented: $namingGroup) { SelectionGroupSheet() }
    }
}

struct TourApplyMenu: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 12) {
        Picker("Assignment scope", selection: $model.tourAssignmentToShow) {
            Text("This venue").tag(false); Text("Shared show").tag(true)
        }.pickerStyle(.menu)
        Menu("Apply preset to \(model.tourSelection.count) units", systemImage: "slider.horizontal.3") {
            ForEach(model.presets) { preset in
                if let group = model.selectedGroupID {
                    Menu(preset.name) {
                        Button("Edit group default; preserve exceptions") { model.applyTourPreset(preset.id, group: group, preview: true, toShow: model.tourAssignmentToShow) }
                        Button("Apply to all descendants") { model.applyTourPreset(preset.id, group: group, allDescendants: true, preview: true, toShow: model.tourAssignmentToShow) }
                    }
                } else { Button(preset.name) { model.applyTourPreset(preset.id, preview: true, toShow: model.tourAssignmentToShow) } }
            }
        }.frame(minHeight: 60).disabled(model.tourSelection.isEmpty)
        }
    }
}

private struct ArrangementSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let adapting: Bool
    @State private var x: Float = 0
    @State private var y: Float = 0
    @State private var z: Float = 0
    @State private var yaw: Float = 0
    @State private var spacing: Float = 1
    @State private var equalSpacing = false
    @State private var mirror = false
    @State private var align: FixtureAxis?
    private var placing: Bool { !adapting && model.fixtures.allSatisfy { !model.tourSelection.contains($0.id) } }
    var body: some View {
        NavigationStack {
            Form {
                Section(placing ? "Row centre in room (metres)" : "Offset from current layout (metres)") {
                    coordinate("X", value: $x); coordinate("Y", value: $y); coordinate("Z", value: $z)
                    if !placing { coordinate("Rotate around centre (degrees)", value: $yaw) }
                }
                if !adapting {
                    Section("Arrangement") {
                        if !placing { Toggle("Even spacing along X", isOn: $equalSpacing); Toggle("Mirror across centre X", isOn: $mirror) }
                        if !placing {
                            Picker("Align on a shared coordinate", selection: $align) {
                                Text("Keep current offsets").tag(nil as FixtureAxis?)
                                ForEach(FixtureAxis.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag(Optional($0)) }
                            }
                        }
                        if placing || equalSpacing { coordinate("Spacing (metres)", value: $spacing) }
                        Text(placing ? "Every selected unit must be available. Use the floor or tabletop height for Y. All positions are checked before Save." : "Models keep their physical size. Moving a mount preserves DMX angles; choose Refocus afterward to solve named targets again.").font(.callout).foregroundStyle(.secondary)
                    }
                }
                if let message = model.message { Text(message).foregroundStyle(.secondary) }
            }.navigationTitle(adapting ? "Adapt configuration layout" : placing ? "Place a row" : "Transform selection")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Preview") {
                            let offset = Position3D(x: x, y: y, z: z)
                            if adapting { model.previewConfigurationLayout(translation: offset, yaw: yaw) }
                            else if placing { model.previewGroupPlacement(origin: offset, spacing: spacing) }
                            else { model.previewGroupTransform(translation: offset, yaw: yaw, spacing: equalSpacing ? spacing : nil, mirror: mirror, align: align) }
                            if model.tourPreview != nil { dismiss() }
                        }
                    }
                }
        }.frame(minWidth: 640, minHeight: 600)
    }
    private func coordinate(_ label: String, value: Binding<Float>) -> some View {
        HStack { Text(label); Spacer(); TextField(label, value: value, format: .number.precision(.fractionLength(0...3))).multilineTextAlignment(.trailing).frame(width: 160) }
    }
}

private struct FocusTargetList: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var newTarget = false
    @State private var name = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Venue focus targets").font(.headline); Spacer(); Button { name = ""; newTarget = true } label: { Image(systemName: "plus").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("New focus target") }
            ForEach(model.tour?.show.targets ?? []) { target in
                Button {
                    model.beginFocusLocation(target.id)
                } label: {
                    HStack {
                        Text(target.name); Spacer()
                        Text(model.tour?.targetLocations[target.id] == nil ? "Locate" : "Relocate").foregroundStyle(.secondary)
                    }.frame(minHeight: 60)
                }.disabled(!model.canPlace)
            }
            if model.tour?.show.targets.isEmpty == true { Text("Name a target once, locate it in each venue, then include it in a Focus preset.").font(.caption).foregroundStyle(.secondary) }
        }
        .alert("New focus target", isPresented: $newTarget) {
            TextField("Lead vocal, Drums…", text: $name)
            Button("Create") { model.createFocusTarget(name: name) }.disabled(!TouringShow.validName(name))
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct TouringPresetOptions: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 16) {
            Text("Target: \(model.tourSelectionName)").font(.headline)
            Picker("Save scope", selection: $model.tourEditShow) {
                Text("This venue").tag(false); Text("Shared show").tag(true)
            }.pickerStyle(.segmented)
            Text(model.tourEditShow ? "Updates the reusable show draft. Existing saved venues retain their pinned copies." : "Creates an override only in this venue setup.").font(.caption).foregroundStyle(.secondary)
            Text("Included parameters").font(.headline)
            parameter("Intensity", indices: [0]); parameter("Colour", indices: [1, 2, 3]); parameter("Beam", indices: [6]); parameter("Focus", indices: [4, 5])
            DisclosureGroup("Advanced preview channels") {
                ForEach(7..<16, id: \.self) { index in parameter("Channel \(index+1)", indices: [index]) }
            }
            Picker("Named focus target", selection: $model.presetDraft.focusTargetID) {
                Text("Use stored Pan / Tilt").tag(nil as UUID?)
                ForEach(model.tour?.show.targets ?? []) { Text($0.name).tag(Optional($0.id)) }
                if let id = model.presetDraft.focusTargetID, model.tour?.show.targets.contains(where: { $0.id == id }) != true {
                    Text("Target from another show — choose a target").tag(Optional(id))
                }
            }.onChange(of: model.presetDraft.focusTargetID) { _, id in
                if id != nil { model.presetDraft.includedChannels = Array(model.presetDraft.channelMask.union([4,5])).sorted() }
            }
            if let target = model.presetDraft.focusTargetID {
                Label(model.tour?.show.targets.contains(where: { $0.id == target }) != true ? "This preserved draft needs a target from the current show." : model.tour?.targetLocations[target] == nil ? "Locate this target in the venue before applying." : "Pan / Tilt is solved separately for each fixture from this target.", systemImage: "scope")
                    .font(.callout).foregroundStyle(.secondary)
            }
            if model.tour?.presetOverrides.contains(where: { $0.id == model.editingPresetID }) == true {
                Label("Venue override", systemImage: "pin").font(.caption)
                Button("Reset preset to show") { if let id = model.editingPresetID { model.resetPresetToShow(id) } }
            }
            TourApplyMenu()
            Button("Target draft", systemImage: "scope") { model.beginPresetTarget() }.disabled(model.selectedID == nil || model.presetDraft.validationIssue != nil)
            Text("Only included values change. Applying validates every member; unsupported fixture capabilities block the whole change.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func parameter(_ label: String, indices: Set<Int>) -> some View {
        Toggle(label, isOn: Binding(get: { indices.isSubset(of: model.presetDraft.channelMask) }, set: { enabled in
            var mask = model.presetDraft.channelMask
            if enabled { mask.formUnion(indices) } else { mask.subtract(indices); if indices.contains(4) { model.presetDraft.focusTargetID = nil } }
            model.presetDraft.includedChannels = Array(mask).sorted()
        })).frame(minHeight: 60)
    }
}
