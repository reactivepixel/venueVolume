import SwiftUI
import VenueVolumeCore

struct ToolboxView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Toolbox").font(.largeTitle.weight(.semibold))
                Spacer()
                HistoryControls()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Left wrist", systemImage: "hand.raised")
                    Text(appVersion).font(.caption.weight(.semibold)).foregroundStyle(.cyan).monospacedDigit()
                        .accessibilityLabel("Venue Volume version \(appVersion)")
                }.font(.caption).foregroundStyle(.secondary)
                Menu {
                    Button("Diagnostics & sync") { openWindow(id: "diagnostics") }
                    Button("Leave venue") { model.flushHistoryEdits(); model.auditExternal("Leave venue"); Task { await dismissSpace() } }
                } label: { Image(systemName: "ellipsis") }
            }
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            section("Actions")
                            item(.addFixture)
                            item(.presets)
                            item(.sync)
                            section("Fixtures · drag into the room")
                            ForEach(FixtureKind.allCases) { kind in
                                Button { model.fixtureKind = kind; model.beginPlacement() } label: {
                                    row(kind.name, subtitle: "Drag onto a floor or tabletop", icon: kind == .movingHead ? "light.beacon.max" : "cube.transparent")
                                }.buttonStyle(.plain).disabled(!model.canPlace)
                                    .onDrag { model.beginFixtureDrag(kind); return NSItemProvider(object: kind.dragToken as NSString) }
                            }
                            if model.isPlacing {
                                Text("Look at a clear floor or tabletop and pinch to place the fixture.").font(.caption)
                            }
                            section("Presets · drag onto a fixture")
                            ForEach(model.presets) { preset in item(.preset(preset.id)) }
                            if model.presets.isEmpty { Text("Create a preset in the preset editor.").font(.caption).foregroundStyle(.secondary) }
                            section("Objects · \(model.fixtures.count)")
                            ForEach(model.fixtures) { fixture in item(.fixture(fixture.id)) }
                            if model.fixtures.isEmpty { Text("Place your first fixture using Add fixture.").font(.caption).foregroundStyle(.secondary) }
                        }.padding(.trailing, 6)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("RECENT · \(model.recent.items.count)/10").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    if model.recent.items.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "hand.draw").font(.system(size: 30)).foregroundStyle(.cyan)
                            Text("Use the toolbox").font(.title3.weight(.semibold))
                            Text("Raise your left palm to reveal the toolbox. Choose an action, select an object, or drag a preset onto a fixture.")
                            Text("Your ten most recently used items will appear here.").foregroundStyle(.secondary)
                        }.font(.callout).padding(.top, 24)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(model.recent.items, id: \.self) { item($0) }
                            }.padding(.trailing, 6)
                        }
                    }
                    Spacer(minLength: 0)
                }.frame(maxWidth: .infinity, alignment: .leading)
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
                Text("VV Preview 16").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text(model.historyMessage ?? model.message ?? model.handTrackingStatus).lineLimit(2)
                Spacer()
                Text("\(model.fixtures.count) objects · \(model.totalChannels) channels").monospacedDigit()
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(26).frame(width: 720)
        .disabled(model.libraryBusy)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 30))
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
            Button { model.fixtureKind = .movingHead; model.beginPlacement() } label: {
                row(model.isPlacing ? "Cancel placement" : "Add fixture", subtitle: "Rogue R1X · moving head", icon: "plus")
            }.buttonStyle(.plain).disabled(!model.canPlace && !model.isPlacing)
        case .presets:
            Button { model.record(.presets); openWindow(id: "presets") } label: {
                row("Fixture controls", subtitle: "Position, aim & edit presets", icon: "square.stack.3d.up")
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
            Toggle(model.canSimulatePalm ? "Left palm facing me" : "Show toolbox", isOn: $model.simulatedPalm).font(.callout)
        }.padding(16).frame(width: 270).glassBackgroundEffect()
    }
}
