import SwiftUI
import VenueVolumeCore

struct ToolboxView: View {
    let instanceID: UUID?
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @State private var fixtureSearch = ""
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Toolbox").font(.largeTitle.weight(.semibold))
                    if model.toolboxBlackout {
                        Text(model.blackout ? "BLACKOUT · ALL FIXTURES" : "BLACKOUT · PRESET SIMULATION")
                            .font(.caption2.weight(.bold)).foregroundStyle(.white)
                    }
                }
                Spacer()
                HistoryControls()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Palm activated", systemImage: "hand.raised")
                    Text(appVersion).font(.caption.weight(.semibold)).foregroundStyle(.cyan).monospacedDigit()
                        .accessibilityLabel("Venue Volume version \(appVersion)")
                }.font(.caption).foregroundStyle(.secondary)
                Menu {
                    Button("Diagnostics & sync") { openWindow(id: "diagnostics") }
                    Button("Leave venue") { model.flushHistoryEdits(); model.auditExternal("Leave venue"); Task { await dismissSpace() } }
                } label: { Image(systemName: "ellipsis") }
                Button { dismissWindow(id: "toolbox") } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("Close toolbox")
            }
            if !model.isImmersed { VenueEntryButton() }
            @Bindable var model = model
            Picker("Toolbox section", selection: $model.toolboxTab) {
                Text("Fixtures & presets").tag(0)
                Text("Rooms & saved setups").tag(1)
                Text("History").tag(2)
            }.pickerStyle(.segmented)
            if model.toolboxTab == 2 {
                AuditHistoryView()
            } else if model.toolboxTab == 1 {
                RoomLibraryView()
            } else {
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("LIBRARY").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    TextField("Search \(FixtureCatalog.all.count) assets", text: $fixtureSearch)
                    Picker("Category", selection: $fixtureFamily) {
                        Text("All categories").tag("all")
                        ForEach(Array(Set(FixtureCatalog.all.map(\.family))).sorted(), id: \.self) { family in
                            Text(family.replacingOccurrences(of: "_", with: " ").capitalized).tag(family)
                        }
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            section("Actions")
                            item(.addFixture)
                            item(.presets)
                            item(.sync)
                            section("Fixtures · drag into the room")
                            ForEach(visibleFixtures) { kind in
                                Button { model.fixtureKind = kind; model.beginPlacement() } label: {
                                    row(kind.name, subtitle: [kind.asset?.manufacturer, kind.asset?.motionLabel].compactMap { $0 }.joined(separator: " · "), icon: kind.asset?.joints.isEmpty == false ? "light.beacon.max" : "cube.transparent")
                                }.buttonStyle(.plain).disabled(!model.canPlace)
                                    .onDrag { model.beginFixtureDrag(kind); return NSItemProvider(object: kind.dragToken as NSString) }
                            }
                            if model.isPlacing {
                                Text("Look at a clear floor or tabletop and pinch to place the fixture.").font(.caption)
                            }
                            section("Presets · drag onto a fixture")
                            ForEach(model.presets) { preset in item(.preset(preset.id)) }
                            if model.presets.isEmpty { Text("Create a preset in the preset editor.").font(.caption).foregroundStyle(.secondary) }
                        }.padding(.trailing, 6)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                SceneSelectionPane().frame(maxWidth: .infinity, alignment: .leading)
            }.frame(height: 410)
            }
            Divider()
            HStack {
                @Bindable var model = model
                Toggle("White model", isOn: $model.whiteRoom).toggleStyle(.button)
                Toggle("Blackout", isOn: $model.blackout).toggleStyle(.button)
                Text("Room light").font(.caption)
                Slider(value: $model.houseLight, in: 0...1, onEditingChanged: { editing in
                    if editing { model.beginHistoryAction("Adjust room light") } else { model.endHistoryAction() }
                }).frame(width: 150).accessibilityLabel("Room light")
                Spacer()
                Text("\(model.effectiveLightLimit) shadow beams · selection first").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text(model.historyMessage ?? model.message ?? model.handTrackingStatus).lineLimit(2)
                Spacer()
                Text("\(model.fixtures.count) objects · \(model.totalChannels) channels").monospacedDigit()
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(26).frame(width: 720)
        .background { if model.toolboxBlackout { BlackoutStarfield().allowsHitTesting(false).accessibilityHidden(true) } }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .disabled(model.libraryBusy)
        .onAppear { model.toolboxVisible = true; model.toolboxPresentedID = instanceID }
        .onDisappear {
            if model.toolboxPresentedID == instanceID {
                model.toolboxVisible = false; model.toolboxPresentedID = nil
            }
        }
    }

    private var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !version.isEmpty else { return "Version unavailable" }
        return "v\(version)"
    }

    private func section(_ title: String) -> some View {
        Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.top, 12)
    }

    @ViewBuilder private func item(_ entry: ToolboxItem) -> some View {
        switch entry {
        case .preset(let id):
            if let preset = model.presets.first(where: { $0.id == id }) {
                Button {
                    model.openPreset(id)
                    model.record(.preset(id))
                    openWindow(id: "presets")
                } label: {
                    row(preset.name, subtitle: "\(preset.channels.count) channels · drag to apply", icon: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .onDrag {
                    model.beginPresetDrag(id)
                    return NSItemProvider(object: preset.dragToken as NSString)
                } preview: {
                    Label(preset.name, systemImage: "slider.horizontal.3").padding(16).glassBackgroundEffect()
                }
            }
        case .fixture(let id):
            if let fixture = model.fixture(id) {
                Button { withAnimation { model.select(id) } } label: {
                    row(fixture.name, subtitle: "U\(fixture.universe) · \(fixture.startAddress)–\(fixture.endAddress)", icon: "cube.transparent")
                }.buttonStyle(.plain)
            }
        case .addFixture:
            Button { model.beginPlacement() } label: {
                row(model.isPlacing ? "Cancel placement" : "Add selected model", subtitle: model.fixtureKind.name, icon: "plus")
            }.buttonStyle(.plain).disabled(!model.canPlace && !model.isPlacing)
        case .presets:
            Button { model.record(.presets); openWindow(id: "presets") } label: {
                row("Preset editor", subtitle: "Create and edit saved DMX presets", icon: "slider.horizontal.3")
            }.buttonStyle(.plain)
        case .sync:
            Button { Task { await model.sync() } } label: {
                row(model.isSyncing ? "Syncing…" : "Sync configurations", subtitle: model.syncStatus, icon: "arrow.triangle.2.circlepath")
            }.buttonStyle(.plain).disabled(model.isSyncing)
        }
    }

    private func row(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.cyan).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.weight(.medium)).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 12)).hoverEffect(.highlight)
    }
}

struct SimulatorPalmControl: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 8) {
            Text(model.canSimulatePalm ? "SIMULATOR" : "HAND TRACKING UNAVAILABLE").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Button("Open / recall toolbox", systemImage: "rectangle.on.rectangle") { model.requestToolbox() }
            if model.canSimulatePalm {
                Toggle("Left palm facing me", isOn: $model.simulatedPalm).font(.callout)
            }
        }.padding(16).frame(width: 270).glassBackgroundEffect()
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
