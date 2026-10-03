import SwiftUI
import VenueVolumeCore

/// Object info is deliberately read-only. Channel editing belongs to presets.
struct FixturePanel: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Object", value: fixture.asset.map { $0.manufacturer + " " + $0.name } ?? "Legacy cube · 24 cm")
            if let asset = fixture.asset {
                LabeledContent("Motion", value: asset.motionLabel)
                LabeledContent("Controls", value: LightingPreview.profileName)
                Text(asset.notes)
                    .font(.caption).foregroundStyle(.secondary)
            }
            LabeledContent("Preview patch", value: "U\(fixture.universe) · \(fixture.startAddress)–\(fixture.endAddress)")
            LabeledContent("Channels", value: "\(fixture.channels.count) · 8-bit preview values")
            Text(String(format: "Position  %.2f, %.2f, %.2f m", fixture.position.x, fixture.position.y, fixture.position.z))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Text(fixture.id.uuidString).font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(fixture.channels.indices, id: \.self) { index in
                        HStack {
                            Text("\(index + 1) · \(fixture.asset?.channelName(index) ?? "Channel")").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(fixture.channels[index])").foregroundStyle(.cyan)
                        }.font(.caption.monospacedDigit())
                    }
                }
            }.frame(height: 132)
            Button {
                model.presetEditor.request(presetID: fixture.presetID)
                model.record(.presets)
                model.controlsTab = 0
            } label: { Label(fixture.presetID == nil ? "Choose or create preset" : "Edit assigned preset", systemImage: "slider.horizontal.3") }
            Text("Drag a preset using its handle in the wrist menu, or choose a fixture from the preset’s Apply menu.")
                .font(.caption).foregroundStyle(.secondary)
        }.font(.callout)
    }
}

struct FixtureDropTarget: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture
    @State private var targeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.cyan.opacity(targeted ? 0.22 : 0.001))
            .overlay {
                if model.draggingPresetID != nil || targeted {
                    RoundedRectangle(cornerRadius: 18).stroke(.cyan, lineWidth: 2)
                    Text(targeted ? "Release to apply" : "Drop preset")
                        .font(.headline).padding(12).glassBackgroundEffect()
                }
            }
            .frame(width: 300, height: 300)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { model.select(fixture.id) } }
            .accessibilityLabel("\(fixture.name), preset drop target")
            .dropDestination(for: String.self) { tokens, _ in
                guard let token = tokens.first, let id = DMXPreset.id(from: token) else { return false }
                return model.applyPreset(id, to: fixture.id)
            } isTargeted: { targeted = $0 }
    }
}
