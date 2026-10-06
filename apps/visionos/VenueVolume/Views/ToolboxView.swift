import SwiftUI
import VenueVolumeCore

struct ToolboxView: View {
    let instanceID: UUID?
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var browsingFixtures = false
    @State private var presetSearch = ""
    @State private var settingsPresented = false
    var body: some View {
        GeometryReader { geometry in
            let compact = textSize.isAccessibilitySize || geometry.size.width < 900
            let columnHeight = max(420, geometry.size.height - 330)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(compact: compact)
                    TourPreviewControls()
                    if !model.isImmersed { VenueEntryButton() }
                    @Bindable var model = model
                    Picker("Toolbox section", selection: $model.toolboxTab) {
                        Text("Fixtures & palettes").tag(0)
                        Text("Rooms & saves").tag(1)
                        Text("History").tag(2)
                    }.pickerStyle(.menu).accessibilityLabel("Toolbox section")
                    Group {
                        if model.toolboxTab == 2 {
                            AuditHistoryView()
                        } else if model.toolboxTab == 1 {
                            RoomLibraryView()
                        } else {
                            let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24)) : AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                            layout {
                                library.frame(maxWidth: .infinity).frame(height: columnHeight)
                                if !compact { Divider() }
                                Group { if model.tour != nil { TourSelectionPane() } else { SceneSelectionPane() } }.frame(maxWidth: .infinity).frame(height: columnHeight)
                            }
                        }
                    }.disabled(model.libraryBusy || model.tourPreview != nil)
                    Divider()
                    roomControls(compact: compact).disabled(model.libraryBusy)
                    VStack(alignment: .leading, spacing: 8) {
                        if model.libraryBusy { ProgressView("Loading venue…") }
                        if let historyMessage = model.historyMessage, historyMessage.localizedCaseInsensitiveContains("failed") || historyMessage.localizedCaseInsensitiveContains("disabled") {
                            Text(historyMessage).fixedSize(horizontal: false, vertical: true)
                        }
                        Text(model.presetEditor.failureMessage ?? model.message ?? model.historyMessage ?? model.handTrackingStatus)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(model.fixtures.count) objects · \(model.totalChannels) channels · \(model.effectiveLightLimit) shadow beams")
                            .monospacedDigit()
                    }.font(.callout).foregroundStyle(.secondary)
                }.padding(26)
            }
        }
        .frame(minWidth: 680, minHeight: 560)
        .background { if model.toolboxBlackout { BlackoutStarfield().allowsHitTesting(false).accessibilityHidden(true) } }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .sheet(isPresented: $settingsPresented) {
            VStack(alignment: .leading, spacing: 20) {
                Text("User preferences").font(.title)
                Text("Navigation blackout fade · \(Int(model.navigationFadeMilliseconds)) ms")
                Slider(value: Binding(get: { model.navigationFadeMilliseconds }, set: { model.navigationFadeMilliseconds = $0 }), in: 0...2000, step: 1)
                    .accessibilityLabel("Navigation fade duration in milliseconds")
                Text("Teleport and viewpoint rotation fade back after the new position is ready.").foregroundStyle(.secondary)
                HStack {
                    Button("Reset to 333 ms") { model.navigationFadeMilliseconds = 333 }
                    Spacer()
                    Button("Done") { settingsPresented = false }
                }
            }.padding(28).frame(width: 560)
        }
        .presetEditorPresenter(when: !model.isImmersed)
        .sheet(isPresented: Binding(get: { model.isImmersed && model.newVenuePresented }, set: { model.newVenuePresented = $0 })) {
            NewVenueSheet().environment(model)
        }
        .sheet(isPresented: Binding(get: { model.touringPanelPresented }, set: { model.touringPanelPresented = $0 })) { TouringLibrarySheet() }
        .onAppear {
            model.toolboxAppeared(instanceID)
            if !model.isImmersed { openWindow(id: "launch"); closeToolbox(); return }
            if model.isImmersed, let request = model.toolboxRequestID, instanceID != request { closeToolbox() }
        }
        .onChange(of: model.toolboxRequestID) { _, request in
            if model.isImmersed && request != instanceID { closeToolbox() }
        }
        .onChange(of: model.isImmersed) { wasImmersed, isImmersed in
            if wasImmersed && !isImmersed { closeToolbox() }
        }
        .onDisappear {
            model.toolboxDisappeared(instanceID)
        }
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Toolbox").font(.largeTitle.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Text("Wrist menu · \(appVersion)").font(.callout).foregroundStyle(.secondary)
                    if model.toolboxBlackout {
                        Text(model.blackout ? "Blackout · all fixtures" : "Blackout · palette simulation").font(.headline)
                    }
                }
                Spacer(minLength: 12)
                Button(model.palmMapVisible ? "Close Palm Map" : "Palm Map", systemImage: "map") { model.togglePalmMap() }
                    .disabled(!model.palmMapVisible && (!model.isImmersed || !model.canPlace || model.libraryBusy || model.navigationBlackoutActive))
                Menu {
                    Button("Settings", systemImage: "gearshape") { settingsPresented = true }
                    Button("Touring shows…", systemImage: "shippingbox") { model.touringPanelPresented = true }
                    Button("New venue…", systemImage: "plus") { model.requestNewVenue(); if !model.isImmersed { openWindow(id: "launch") } }
                    Button("Venue controls", systemImage: "scope") { model.showVenueControls() }
                    Button("Diagnostics & sync") { openWindow(id: "diagnostics") }
                    Button("Leave venue") {
                        model.flushHistoryEdits(); model.auditExternal("Leave venue")
                        model.resetToolboxActivation()
                        closeToolbox()
                        Task { await dismissSpace() }
                    }
                } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Wrist menu options")
                Button { closeToolbox() } label: { Image(systemName: "xmark").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Close toolbox")
            }
            HistoryControls()
            TouringContextButton()
        }
    }

    private func closeToolbox() {
        // Address this UUID-valued window while its scene is still active.
        if let instanceID { dismissWindow(id: "toolbox", value: instanceID) }
        else { dismissWindow(id: "toolbox") }
    }

    private var library: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            Picker("Library", selection: $model.toolboxLibraryTab) {
                Text("Fixtures").tag(0)
                Text("Palettes").tag(1)
            }.pickerStyle(.segmented)
            if model.toolboxLibraryTab == 0, model.tour != nil {
                InventoryLibraryView()
            } else if model.toolboxLibraryTab == 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pinned fixture").font(.caption).foregroundStyle(.secondary)
                        fixtureChoice(.movingHead, pinned: true)
                        if model.quickFixtureKinds.count > 1 {
                            Text("Recent fixtures").font(.caption).foregroundStyle(.secondary)
                            ForEach(Array(model.quickFixtureKinds.dropFirst())) { kind in fixtureChoice(kind) }
                        }
                        Button("Browse all \(FixtureCatalog.all.count) fixtures", systemImage: "square.grid.2x2") { browsingFixtures = true }
                            .frame(minHeight: 60)
                    }
                }
                .sheet(isPresented: $browsingFixtures) {
                    FixtureCatalogBrowser { kind in model.selectFixtureKind(kind); model.beginPlacement() }
                }
            } else {
                HStack {
                    TextField("Search palettes", text: $presetSearch).textFieldStyle(.roundedBorder)
                    Button { model.presetEditor.request() } label: { Image(systemName: "slider.horizontal.3").frame(minWidth: 60, minHeight: 60) }
                        .accessibilityLabel("Open palette editor")
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(model.presets.filter { presetSearch.isEmpty || $0.name.localizedCaseInsensitiveContains(presetSearch) }) { preset in
                            PresetDragSource(preset: preset, openEditor: { model.record(.preset(preset.id)); model.presetEditor.request(presetID: preset.id) })
                        }
                        if model.presets.isEmpty { Text("Create a palette with the editor button above, then drag its handle onto a fixture or use Apply.") }
                        else if !presetSearch.isEmpty && !model.presets.contains(where: { $0.name.localizedCaseInsensitiveContains(presetSearch) }) { ContentUnavailableView.search(text: presetSearch) }
                    }
                }
            }
        }
    }

    private func roomControls(compact: Bool) -> some View {
        @Bindable var model = model
        let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18)) : AnyLayout(HStackLayout(spacing: 20))
        return layout {
            Toggle("White model", isOn: $model.whiteRoom).toggleStyle(.button).frame(minHeight: 60)
            Toggle("Blackout", isOn: $model.blackout).toggleStyle(.button).frame(minHeight: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text("Room light").font(.callout)
                Slider(value: $model.houseLight, in: 0...1, onEditingChanged: { editing in
                    if editing { model.beginHistoryAction("Adjust room light") } else { model.endHistoryAction() }
                }).frame(minWidth: 160, minHeight: 60).accessibilityLabel("Room light")
                    .accessibilityValue("\(Int(model.houseLight * 100)) percent")
            }
        }
    }

    private var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty else { return "Version unavailable" }
        return "v\(version)"
    }
    private func fixtureChoice(_ kind: FixtureKind, pinned: Bool = false) -> some View {
        Button { model.selectFixtureKind(kind); model.beginPlacement() } label: {
            row(kind.name, subtitle: [kind.asset?.manufacturer, kind.asset?.motionLabel].compactMap { $0 }.joined(separator: " · "), icon: pinned ? "pin.fill" : "light.beacon.max")
        }.buttonStyle(.plain).disabled(!model.canPlace)
            .accessibilityHint("Select and click a surface, or drag to place this model.")
            .onDrag { model.beginFixtureDrag(kind); return NSItemProvider(object: kind.dragToken as NSString) }
    }

    private func row(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.cyan).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.padding(12).frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 12)).hoverEffect(.highlight)
    }
}

/// A single row attached below the viewer in the immersive venue.
struct VenueControlsView: View {
    @State private var attended = false
    @Environment(VenueModel.self) private var model
    var body: some View {
        @Bindable var model = model
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                Label("Venue controls", systemImage: "scope").font(.headline)
                Divider().frame(height: 56)
                Button(model.palmMapVisible ? "Close Palm Map" : "Palm Map", systemImage: "map") { model.togglePalmMap() }
                    .disabled(!model.palmMapVisible && (!model.canPlace || model.libraryBusy || model.navigationBlackoutActive))
                if model.palmMapVisible {
                    Text("Drag the marker to teleport; tap it for rotation rings.").font(.callout).frame(width: 460, alignment: .leading)
                    Button("Done") { model.closePalmMap() }.frame(minHeight: 60)
                } else if let session = model.presetDrag.session {
                    let presetName = model.presets.first { $0.id == session.presetID }?.name ?? "Preset"
                    let target = model.presetDrag.proposedFixtureID.flatMap { model.fixture($0) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apply · \(presetName)").font(.headline).lineLimit(1)
                        Text(target.map { "Pinch to apply to \($0.name)" } ?? "Aim toward a fixture, then pinch. Hold to adjust.")
                            .font(.callout).foregroundStyle(.secondary).lineLimit(2)
                    }.frame(width: 460, alignment: .leading)
                    Button("Cancel", role: .cancel) { model.endPresetDrag() }.frame(minHeight: 60)
                    Button("Apply to fixture") { model.applyProposedPreset() }
                        .buttonStyle(.borderedProminent).disabled(target == nil).frame(minHeight: 60)
                } else if model.tourPreview != nil {
                    Text(model.tourPreviewTitle).font(.callout).frame(width: 300, alignment: .leading)
                    Button("Cancel") { model.cancelTourPreview() }.frame(minHeight: 60)
                    Button("Save change") { model.commitTourPreview() }.buttonStyle(.borderedProminent).frame(minHeight: 60)
                } else if model.isPickingRoom || model.gizmoVisible {
                    TargetingPrompt()
                } else if let feedback = model.presetDrag.feedback {
                    Label(feedback.succeeded ? "Preset applied" : feedback.message ?? "Could not apply preset",
                          systemImage: feedback.succeeded ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.callout).frame(width: 460, alignment: .leading)
                    Button("Done") { model.presetDrag.clearFeedback() }.frame(minHeight: 60)
                } else {
                    Text("Select a fixture, then click it again to move or transform.")
                        .font(.callout).foregroundStyle(.secondary).frame(width: 460, alignment: .leading)
                }
                Spacer(minLength: 12)
                Menu {
                    Button("Toolbox", systemImage: "rectangle.on.rectangle") { model.requestToolbox() }
                    Button("Return to spawn", systemImage: "location") { model.resetViewerToSpawn() }
                    Menu("Navigation controls") {
                        Button("Forward") { model.stepViewer(offset: [0,0,-0.5]) }
                        Button("Backward") { model.stepViewer(offset: [0,0,0.5]) }
                        Button("Left") { model.stepViewer(offset: [-0.5,0,0]) }
                        Button("Right") { model.stepViewer(offset: [0.5,0,0]) }
                        Button("Up") { model.stepViewer(offset: [0,0.5,0]) }
                        Button("Down") { model.stepViewer(offset: [0,-0.5,0]) }
                        Button("Turn left") { model.stepViewer(yaw: 15) }
                        Button("Turn right") { model.stepViewer(yaw: -15) }
                        Button("Look up") { model.stepViewer(pitch: 15) }
                        Button("Look down") { model.stepViewer(pitch: -15) }
                        Button("Roll left") { model.stepViewer(roll: 15) }
                        Button("Roll right") { model.stepViewer(roll: -15) }
                    }
                    Text("Left index pinch + drag: move")
                    Text("Left middle pinch + drag: rotate")
                    Text("Double index: spawn · double middle: orientation")
                } label: { Image(systemName: "ellipsis").frame(minWidth: 60,minHeight: 60) }
                    .accessibilityLabel("Venue and navigation options")
                HistoryControls()
            }.padding(20).frame(minWidth: 1560, minHeight: 100)
        }.frame(width: 1560)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        .hoverEffect { effect, active, _ in effect.opacity(active ? 1 : 0.35) }
        .onAppear { model.showVenueControls() }
        .onDisappear { model.venueControlsVisible = false }
    }
}

/// Left pinches are reserved for navigation; avoid activating a button on release.
struct NavigationInputShield: ViewModifier {
    var model: VenueModel
    func body(content: Content) -> some View {
        content
            .disabled(model.isImmersed && model.navigationInputReserved)
            .allowsHitTesting(!model.isImmersed || !model.navigationInputReserved)
            .simultaneousGesture(SpatialEventGesture().onChanged { events in
                if model.isImmersed && events.contains(where: { $0.chirality == .left }) { model.reserveLeftHandInput() }
            })
    }
}
extension View {
    func navigationInputShield(model: VenueModel) -> some View { modifier(NavigationInputShield(model: model)) }
}

/// Full discovery is one explicit step away from the compact placement list.
struct FixtureCatalogBrowser: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var family = "all"
    let onSelect: (FixtureKind) -> Void
    private var matches: [FixtureKind] {
        FixtureKind.allCases.filter { kind in
            let text = [kind.name,kind.asset?.manufacturer ?? ""].joined(separator: " ")
            return (family == "all" || kind.asset?.family == family)
                && (search.isEmpty || text.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Category", selection: $family) {
                    Text("All categories").tag("all")
                    ForEach(Array(Set(FixtureCatalog.all.map(\.family))).sorted(), id: \.self) { family in
                        Text(family.replacingOccurrences(of: "_", with: " ").capitalized).tag(family)
                    }
                }.padding(.horizontal, 24)
                List(matches) { kind in
                    Button { onSelect(kind); dismiss() } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(kind.name).font(.headline)
                            Text(kind.asset?.manufacturer ?? "Transparent DMX fixture").font(.callout).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    }.buttonStyle(.plain)
                }.overlay { if matches.isEmpty { ContentUnavailableView.search(text: search) } }
            }.navigationTitle("All fixtures")
                .searchable(text: $search, prompt: "Model or manufacturer")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }.frame(minWidth: 680, minHeight: 600)
    }
}

/// Restrained local feedback for blackout; never adds geometry or input targets.
private struct BlackoutStarfield: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<65 {
                    let x = CGFloat((index * 137 + 31) % 997) / 997 * size.width
                    let start = Double((index * 89 + 17) % 991) / 991
                    let y = CGFloat((start + time * (0.004 + Double(index % 3) * 0.002)).truncatingRemainder(dividingBy: 1)) * size.height
                    let radius: CGFloat = index % 5 == 0 ? 1.3 : 0.7
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                                 with: .color(.white.opacity(index % 5 == 0 ? 0.45 : 0.2)))
                }
            }
        }
    }
}
