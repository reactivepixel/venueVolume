import SwiftUI
import VenueVolumeCore

/// One attachment grows upward, keeping the object and its label together.
struct FixtureLabel: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture
    private var selected: Bool { model.selectedID == fixture.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Circle().fill(selected ? .cyan : .white.opacity(0.5)).frame(width: 7, height: 7)
                Button { withAnimation { model.select(fixture.id) } } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fixture.name).font(.headline)
                        Text(model.presets.first(where: { $0.id == fixture.presetID })?.name ?? "No preset")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.buttonStyle(.plain)
                if selected {
                    Spacer()
                    Button { withAnimation(.smooth(duration: 0.2)) { model.select(fixture.id, expand: true) } } label: {
                        Image(systemName: model.expandedID == fixture.id ? "info.circle.fill" : "info.circle")
                    }.accessibilityLabel("Info for \(fixture.name)")
                    Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Delete \(fixture.name)")
                }
            }
            if selected && model.expandedID == fixture.id {
                Divider()
                FixturePanel(fixture: fixture)
            }
        }
        .padding(18)
        .frame(width: selected ? 410 : 250)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        .animation(.smooth(duration: 0.2), value: selected)
        .dropDestination(for: String.self) { tokens, _ in
            guard let token = tokens.first, let id = DMXPreset.id(from: token) else { return false }
            return model.applyPreset(id, to: fixture.id)
        }
    }
}
