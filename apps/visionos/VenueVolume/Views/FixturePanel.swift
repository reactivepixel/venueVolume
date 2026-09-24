import SwiftUI
import VenueVolumeCore

struct FixturePanel: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture
    @State private var name: String
    @State private var universe: String
    @State private var address: String
    @State private var channelCount: Int
    @State private var issue: String?

    init(fixture: Fixture) {
        self.fixture = fixture
        _name = State(initialValue: fixture.name)
        _universe = State(initialValue: String(fixture.universe))
        _address = State(initialValue: String(fixture.startAddress))
        _channelCount = State(initialValue: fixture.channels.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(fixture.name).font(.title2.weight(.semibold)).lineLimit(1)
                    Text("GENERIC DMX · 8-BIT").font(.caption.weight(.medium)).foregroundStyle(.cyan)
                }
                Spacer()
                Button { model.expandedID = nil } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless).accessibilityLabel("Close fixture controls")
            }
            TextField("Fixture name", text: $name).textFieldStyle(.roundedBorder)
                .accessibilityLabel("Fixture name")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Universe").font(.caption).foregroundStyle(.secondary)
                    TextField("1", text: $universe).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("DMX universe")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Start address").font(.caption).foregroundStyle(.secondary)
                    TextField("1", text: $address).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("DMX start address")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Channels").font(.caption).foregroundStyle(.secondary)
                    Picker("Channel count", selection: $channelCount) {
                        ForEach(1...16, id: \.self) { Text("\($0)").tag($0) }
                    }.labelsHidden().frame(width: 90)
                }
            }
            HStack {
                Text("Patch \(fixture.startAddress)–\(fixture.endAddress) · U\(fixture.universe)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                Spacer()
                Button("Apply patch", action: applyPatch).disabled(!hasPatchChanges)
            }
            if let issue { Text(issue).font(.caption).foregroundStyle(.orange) }
            if channelCount < fixture.channels.count {
                Text("Applying removes values from channels above \(channelCount).")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(fixture.channels.indices, id: \.self) { index in
                        VStack(spacing: 6) {
                            HStack {
                                Text(String(format: "CH %02d", index + 1)).font(.caption.weight(.semibold))
                                Text("· \(fixture.startAddress + index)").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(fixture.channels[index])").font(.body.monospacedDigit().weight(.medium)).foregroundStyle(.cyan)
                            }
                            Slider(value: Binding(
                                get: { Double(model.fixture(fixture.id)?.channels[safe: index] ?? 0) },
                                set: { model.setChannel(fixture.id, index: index, value: Int($0)) }
                            ), in: 0...255, step: 1)
                            .accessibilityLabel("Channel \(index + 1), DMX address \(fixture.startAddress + index)")
                            .accessibilityValue("\(fixture.channels[index]) of 255")
                        }
                    }
                }
            }.frame(height: 250)
            HStack {
                Button("Zero channels") {
                    for index in fixture.channels.indices { model.setChannel(fixture.id, index: index, value: 0) }
                }
                Spacer()
                Button(role: .destructive) { model.remove(fixture.id) } label: { Label("Remove", systemImage: "trash") }
            }.font(.callout)
        }
        .padding(24).frame(width: 520)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
    }

    private var hasPatchChanges: Bool {
        name != fixture.name || universe != String(fixture.universe) || address != String(fixture.startAddress) || channelCount != fixture.channels.count
    }

    private func applyPatch() {
        guard let universeValue = Int(universe), let addressValue = Int(address) else {
            issue = "Universe and address must be whole numbers."
            return
        }
        issue = model.configure(fixture.id, name: name, universe: universeValue, address: addressValue, channelCount: channelCount)
        if issue == nil, let saved = model.fixture(fixture.id) {
            name = saved.name
            universe = String(saved.universe)
            address = String(saved.startAddress)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
