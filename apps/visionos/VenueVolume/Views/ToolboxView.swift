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
    @State private var settingsPresented = false
    @State private var confirmClearScene = false
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
                        Text("History").tag(2)
                    }.pickerStyle(.menu).accessibilityLabel("Toolbox section")
                    Group {
                        if model.toolboxTab == 2 {
                            AuditHistoryView()
                        } else {
                            let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24)) : AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                            layout {
                                library.frame(maxWidth: .infinity).frame(height: columnHeight)
                                if !compact { Divider() }
                                Group { if model.tour != nil { TourSelectionPane() } else { SceneSelectionPane() } }.frame(maxWidth: .infinity).frame(height: columnHeight)
                            }
                        }
                    }.disabled(model.libraryBusy || model.tourPreview != nil)
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
        .confirmationDialog(model.tour == nil ? "Clear all scene fixtures?" : "Return all fixtures to inventory?", isPresented: $confirmClearScene, titleVisibility: .visible) {
            Button(model.tour == nil ? "Clear all fixtures" : "Return all fixtures", role: .destructive) { model.clearScene() }
        } message: { Text("Undo restores the placements. Saved setups stay available.") }
        .presetEditorPresenter(when: !model.isImmersed)
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
                    Button("New venue…", systemImage: "plus") { model.requestNewVenue(); openWindow(id: model.isImmersed ? "room-placement" : "launch") }
                    Button("Diagnostics & sync") { openWindow(id: "diagnostics") }
                    Button(model.tour == nil ? "Clear all scene fixtures…" : "Return all fixtures to inventory…", role: .destructive) { confirmClearScene = true }
                        .disabled(model.fixtures.isEmpty || model.libraryBusy)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Fixtures").font(.headline)
                Spacer()
                Button("Palettes", systemImage: "slider.horizontal.3") {
                    // Generic recall preserves the current draft and fixture selection.
                    model.presetEditor.request()
                }
                .frame(minHeight: 60)
                .accessibilityLabel("Open palettes and phasers")
                .accessibilityHint("Opens the palette editor with your current fixture selection.")
                Button("Macros", systemImage: "list.bullet.rectangle") { model.macroSeed = nil; model.macrosPresented = true; model.presetEditor.request() }
            }
            if model.tour != nil {
                InventoryLibraryView()
            } else {
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
