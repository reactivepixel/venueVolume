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
            } label: { Label(fixture.presetID == nil ? "Choose or create palette" : "Edit assigned palette", systemImage: "slider.horizontal.3") }
            Text("Select fixtures in the Toolbox, then recall or edit a palette for the current cue.")
                .font(.caption).foregroundStyle(.secondary)
        }.font(.callout)
    }
}
