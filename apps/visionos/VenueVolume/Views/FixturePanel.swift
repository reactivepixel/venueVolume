import SwiftUI
import VenueVolumeCore

/// Object info is deliberately read-only. Channel editing belongs to presets.
struct FixturePanel: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    let fixture: Fixture

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Object", value: fixture.assetID == nil ? "Legacy cube · 24 cm" : "CHAUVET Rogue R1X Spot")
            if fixture.assetID == LightingPreview.assetID {
                LabeledContent("Model", value: "Moving head pilot · visual proxy")
                LabeledContent("Controls", value: LightingPreview.profileName)
                Text("Head pan/tilt and the beam respond to preview values. This is not the manufacturer's DMX map or calibrated photometry.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Pilot travel: about 270° pan / 120° tilt. The physical Rogue R1X Spot is specified for up to 540° / 250°.")
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
                            Text(String(format: "CH %02d", index + 1)).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(fixture.channels[index])").foregroundStyle(.cyan)
                        }.font(.caption.monospacedDigit())
                    }
                }
            }.frame(height: 132)
            Button {
                model.openPreset(fixture.presetID)
                model.record(.presets)
                openWindow(id: "presets")
            } label: { Label("Open fixture controls", systemImage: "slider.horizontal.3") }
            Text("Drag a preset from the toolbox onto this fixture to apply it.")
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
