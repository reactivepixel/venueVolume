import SwiftUI
import VenueVolumeCore

/// One attachment grows upward, keeping the object and its label together.
struct FixtureLabel: View {
    @Environment(\.openWindow) private var openWindow
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
            if selected {
                HStack {
                    Button("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right") { model.beginReposition(fixture.id) }
                        .disabled(!model.canPlace)
                    Menu("Retarget", systemImage: "scope") {
                        Button("Aim head (DMX)") { model.beginRetarget(fixture.id, method: .head) }
                        Button("Aim mount") { model.beginRetarget(fixture.id, method: .mount) }
                    }.disabled(!model.canPlace || fixture.assetID == nil)
                    Button("Transform", systemImage: "rotate.3d") { model.controlsTab = 1; openWindow(id: "presets") }
                }.font(.caption)
                if let aim = fixture.aimOverride {
                    HStack {
                        Text("Aim override · Pan \(aim.pan) · Tilt \(aim.tilt)").font(.caption2)
                        Spacer()
                        Button("Reset") { model.resetAim(fixture.id) }.font(.caption2)
                    }
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

struct TargetingPrompt: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(model.isRetargeting ? "Retarget fixture" : "Position fixture", systemImage: "scope").font(.headline)
                Spacer()
                Button("Cancel") { model.cancelPicking() }
            }
            Text(model.message ?? model.pickingInstruction).font(.callout)
        }.padding(20).frame(width: 560).glassBackgroundEffect()
    }
}
