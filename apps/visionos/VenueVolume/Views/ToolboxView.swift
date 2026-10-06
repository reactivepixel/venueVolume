import SwiftUI
import VenueVolumeCore

struct ToolboxView: View {
    let instanceID: UUID?
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var fixtureSearch = ""
    @State private var presetSearch = ""
    @State private var settingsPresented = false
    @State private var fixtureFamily = "all"

    private var visibleFixtures: [FixtureKind] {
        FixtureKind.allCases.filter { kind in
            let asset = kind.asset
            let text = [kind.name, asset?.manufacturer ?? "", asset?.family ?? ""].joined(separator: " ")
            return (fixtureFamily == "all" || asset?.family == fixtureFamily) &&
                (fixtureSearch.isEmpty || text.localizedCaseInsensitiveContains(fixtureSearch))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = textSize.isAccessibilitySize || geometry.size.width < 900
            let columnHeight = max(420, geometry.size.height - 330)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(compact: compact)
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
                                SceneSelectionPane().frame(maxWidth: .infinity).frame(height: columnHeight)
                            }
                        }
                    }.disabled(model.libraryBusy)
                    Divider()
                    roomControls(compact: compact).disabled(model.libraryBusy)
                    VStack(alignment: .leading, spacing: 8) {
                        if model.libraryBusy { ProgressView("Loading venue…") }
                        Text(model.presetEditor.failureMessage ?? model.historyMessage ?? model.message ?? model.handTrackingStatus)
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
        .onAppear { model.toolboxVisible = true; model.toolboxPresentedID = instanceID }
        .onDisappear {
            if model.toolboxPresentedID == instanceID { model.toolboxVisible = false; model.toolboxPresentedID = nil }
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
                    Button("New venue…", systemImage: "plus") { model.requestNewVenue(); if !model.isImmersed { openWindow(id: "launch") } }
                    Button("Venue controls", systemImage: "scope") { openWindow(id: "venue-controls", value: "controls") }
                    Button("Diagnostics & sync") { openWindow(id: "diagnostics") }
                    Button("Leave venue") { model.flushHistoryEdits(); model.auditExternal("Leave venue"); Task { await dismissSpace() } }
                } label: { Image(systemName: "ellipsis").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Wrist menu options")
                Button { dismissWindow(id: "toolbox") } label: { Image(systemName: "xmark").frame(minWidth: 60, minHeight: 60) }.accessibilityLabel("Close toolbox")
            }
            HistoryControls()
        }
    }

    private var library: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            Picker("Library", selection: $model.toolboxLibraryTab) {
                Text("Fixtures").tag(0)
                Text("Palettes").tag(1)
            }.pickerStyle(.segmented)
            if model.toolboxLibraryTab == 0 {
                TextField("Search \(FixtureCatalog.all.count) fixtures", text: $fixtureSearch)
                    .textFieldStyle(.roundedBorder).accessibilityLabel("Search fixture models or manufacturers")
                Picker("Category", selection: $fixtureFamily) {
                    Text("All categories").tag("all")
                    ForEach(Array(Set(FixtureCatalog.all.map(\.family))).sorted(), id: \.self) { family in
                        Text(family.replacingOccurrences(of: "_", with: " ").capitalized).tag(family)
                    }
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if visibleFixtures.isEmpty { ContentUnavailableView.search(text: fixtureSearch) }
                        ForEach(visibleFixtures) { kind in
                            Button { model.fixtureKind = kind; model.beginPlacement() } label: {
                                row(kind.name, subtitle: [kind.asset?.manufacturer, kind.asset?.motionLabel].compactMap { $0 }.joined(separator: " · "), icon: kind.asset?.joints.isEmpty == false ? "light.beacon.max" : "cube.transparent")
                            }.buttonStyle(.plain).disabled(!model.canPlace)
                                .accessibilityHint("Select, then choose a surface in the venue. You can also drag this fixture into the scene.")
                                .onDrag { model.beginFixtureDrag(kind); return NSItemProvider(object: kind.dragToken as NSString) }
                        }
                    }
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

/// System window controls stay where placed; no interactive UI follows the head.
struct VenueControlsView: View {
    @State private var attended = false
    @Environment(VenueModel.self) private var model
    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Venue controls").font(.title).accessibilityAddTraits(.isHeader)
                if model.isImmersed {
                    Button("Open / recall wrist menu", systemImage: "rectangle.on.rectangle") { model.requestToolbox() }.frame(minHeight: 60)
                    Button(model.palmMapVisible ? "Close Palm Map" : "Palm Map", systemImage: "map") { model.togglePalmMap() }
                        .disabled(!model.palmMapVisible && (!model.canPlace || model.libraryBusy || model.navigationBlackoutActive))
                    if model.isPickingRoom || model.gizmoVisible { TargetingPrompt() }
                    if model.isPlacing { Button("Done placing fixtures", systemImage: "checkmark") { model.finishPlacement() } }
                    else { Text("Select a fixture to move, transform or retarget it.").foregroundStyle(.secondary) }
                    if model.canSimulatePalm { Toggle("Left hand facing me", isOn: $model.simulatedPalm).frame(minHeight: 60) }
                } else { VenueEntryButton() }
            }.padding(24)
        }.frame(minWidth: 480, minHeight: 300)
        .opacity(attended ? 1 : 0.35)
        .onHover { attended = $0 }
        .animation(.easeInOut(duration: 0.2), value: attended)
        .onAppear { model.venueControlsVisible = true }
        .onDisappear {
            model.venueControlsVisible = false
            model.cancelPicking(); model.endTransformDrag(); model.gizmoVisible = false
        }
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
