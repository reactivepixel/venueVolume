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
                        if fixture.assetID == LightingPreview.assetID {
                            Text("MOVING HEAD PILOT · VV PREVIEW 16")
                                .font(.caption2.weight(.semibold)).foregroundStyle(.cyan)
                        }
                        Text(model.presets.first(where: { $0.id == fixture.presetID })?.name ?? "No preset")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.buttonStyle(.plain)
                if selected {
                    Spacer()
                    Button { withAnimation(.smooth(duration: 0.2)) { model.select(fixture.id) } } label: {
                        Image(systemName: "info.circle")
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
                        Button("Aim head (preview)") { model.beginRetarget(fixture.id, method: .head) }.disabled(fixture.asset?.headAim != true)
                        Button("Aim mount") { model.beginRetarget(fixture.id, method: .mount) }
                    }.disabled(!model.canPlace || fixture.asset?.emitters.isEmpty != false)
                    Button("Transform", systemImage: "rotate.3d") { model.beginTransform(fixture.id) }
                }.font(.caption)
                if let aim = fixture.aimOverride {
                    HStack {
                        Text("Aim override · Pan \(aim.pan) · Tilt \(aim.tilt)").font(.caption2)
                        Spacer()
                        Button("Reset") { model.resetAim(fixture.id) }.font(.caption2)
                    }
                }
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
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 10) {
            if !model.isPickingRoom && model.gizmoVisible {
                HStack {
                    Label("Transform selected fixture", systemImage: "rotate.3d").font(.headline)
                    Spacer()
                    Button("Done") { model.endTransformDrag(); model.gizmoVisible = false }
                }
                Picker("Transform mode", selection: $model.transformMode) {
                    ForEach(FixtureTransformMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }.pickerStyle(.segmented).disabled(model.isTransformDragging)
                Text(model.transformMode == .rotate ? "Hold and drag a ring: X red · Y green · Z blue." : "Hold and drag an arrow along its axis: X red · Y green · Z blue.")
                    .font(.callout)
            } else {
            HStack {
                Label(model.isRetargeting ? "Retarget fixture" : "Position fixture", systemImage: "scope").font(.headline)
                Spacer()
                Button("Cancel") { model.cancelPicking() }
                if model.isRetargeting {
                    Button("Save target") { model.saveTarget() }.disabled(!model.canSaveTarget)
                        .buttonStyle(.borderedProminent)
                }
            }
            Text(model.message ?? model.pickingInstruction).font(.callout)
            }
        }.padding(20).frame(width: 560).glassBackgroundEffect()
    }
}
