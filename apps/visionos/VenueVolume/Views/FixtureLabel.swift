import SwiftUI
import VenueVolumeCore

/// One attachment grows upward, keeping the object and its label together.
struct FixtureLabel: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fixture: Fixture
    private var selected: Bool { model.selectedID == fixture.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
            layout {
                Button { withAnimation(reduceMotion ? nil : .smooth) { model.select(fixture.id) } } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fixture.name).font(.headline)
                        if selected {
                            Text(model.presets.first(where: { $0.id == fixture.presetID })?.name ?? "No palette")
                                .font(.callout).foregroundStyle(.secondary)
                        }
                    }
                }.buttonStyle(.plain).frame(minHeight: 60).hoverEffect(.highlight)
                    .accessibilityLabel("Select \(fixture.name)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                if selected {
                    HStack(spacing: 12) {
                    Button {
                        model.select(fixture.id)
                        model.toolboxTab = 0
                        model.requestToolbox()
                    } label: {
                        Image(systemName: "info.circle").frame(minWidth: 60, minHeight: 60)
                    }.accessibilityLabel("Info for \(fixture.name)")
                    Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash").frame(minWidth: 60, minHeight: 60) }
                        .accessibilityLabel("Delete \(fixture.name)")
                    }
                }
            }
            if selected {
                Menu("Fixture actions", systemImage: "ellipsis.circle") {
                    Button("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right") { model.beginReposition(fixture.id) }.disabled(!model.canPlace)
                    Button("Retarget DMX", systemImage: "scope") { model.beginRetarget(fixture.id) }.disabled(!model.canPlace || fixture.asset?.headAim != true)
                    Button("Transform", systemImage: "rotate.3d") { model.beginTransform(fixture.id) }.disabled(!model.canPlace)
                    if fixture.aimOverride != nil { Button("Use palette aim") { model.resetAim(fixture.id) } }
                }.frame(minHeight: 60)
            }
        }
        .padding(18)
        .frame(width: selected ? 420 : 280)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: selected)
        .dropDestination(for: String.self) { tokens, _ in
            guard let token = tokens.first, let id = DMXPreset.id(from: token) else { return false }
            return model.applyPreset(id, to: fixture.id)
        }
    }
}

struct TargetingPrompt: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        @Bindable var model = model
        let layout = textSize >= .xxLarge ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
        VStack(alignment: .leading, spacing: 18) {
            if !model.isPickingRoom && model.gizmoVisible {
                layout {
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
            layout {
                Label(model.isRetargeting ? "Retarget palette" : "Position fixture", systemImage: "scope").font(.headline)
                Spacer()
                Button("Cancel") { model.cancelPicking() }
                if model.isRetargeting {
                    Button("Save palette target") { model.saveTarget() }.disabled(!model.canSaveTarget)
                        .buttonStyle(.borderedProminent)
                }
            }
            Text(model.message ?? model.pickingInstruction).font(.callout)
            }
        }.padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
    }
}
