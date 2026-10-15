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
                Button { withAnimation(reduceMotion ? nil : .smooth) { model.tapFixture(fixture.id) } } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fixture.name).font(.headline)
                        if selected {
                            Text("Cue \(model.currentCueLabel)")
                                .font(.callout).foregroundStyle(.secondary)
                        }
                    }
                }.buttonStyle(.plain).frame(minHeight: 60).hoverEffect(.highlight)
                    .accessibilityLabel("Select \(fixture.name)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                if selected {
                    HStack(spacing: 12) {
                    Button(role: .destructive) { model.remove(fixture.id) } label: { Image(systemName: "trash").frame(minWidth: 60, minHeight: 60) }
                        .accessibilityLabel(model.tour == nil ? "Delete \(fixture.name)" : "Return \(fixture.name) to inventory")
                    }
                }
            }
            if selected {
                Menu("Fixture actions", systemImage: "ellipsis.circle") {
                    Button("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right") { model.beginReposition(fixture.id) }.disabled(!model.canPlace)
                    Button("Transform", systemImage: "rotate.3d") { model.beginTransform(fixture.id) }.disabled(!model.canPlace)
                    if fixture.aimOverride != nil { Button("Use palette aim") { model.resetAim(fixture.id) } }
                }.frame(minHeight: 60)
            }
        }
        .padding(18)
        .frame(width: selected ? 420 : 280)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: selected)

    }
}

struct TargetingPrompt: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        HStack(spacing: 16) {
            if model.gizmoVisible && !model.isRetargeting && !model.isPlacing {
                Text(model.selectedID.flatMap { model.fixture($0)?.name } ?? "Selected fixtures")
                    .font(.callout.weight(.semibold)).lineLimit(1).frame(width: 160, alignment: .leading)
                TransformModeButtons().frame(width: 300)
                Text(model.transformMode == .move ? "Drag an arrow to move on its axis, or drag the body to slide." : "Drag a ring to rotate on its axis.")
                    .font(.caption).foregroundStyle(.secondary).frame(width: 200, alignment: .leading)
                Button("Done") { model.endTransformDrag(); model.cancelPicking(); model.gizmoVisible = false }.frame(minHeight: 60)
            } else {
                Text(model.isRetargeting ? "Retarget palette" : "Place \(model.fixtureKind.name)")
                    .font(.callout.weight(.semibold)).frame(width: 220, alignment: .leading)
                Text(model.message ?? model.pickingInstruction).font(.caption).frame(width: 320, alignment: .leading)
                Button(model.isRetargeting ? "Cancel" : "Done") { model.cancelPicking() }.frame(minHeight: 60)
                if model.isRetargeting {
                    Button("Save palette target") { model.saveTarget() }.disabled(!model.canSaveTarget)
                        .buttonStyle(.borderedProminent).frame(minHeight: 60)
                }
            }
        }
    }
}

struct TransformModeButtons: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            ForEach(FixtureTransformMode.allCases) { mode in
                Button { model.selectTransformMode(mode) } label: {
                    Label(mode.rawValue, systemImage: mode == .move ? "arrow.up.and.down.and.arrow.left.and.right" : "rotate.3d")
                        .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.bordered)
                .tint(model.transformMode == mode ? Color.cyan : Color.gray)
                .accessibilityAddTraits(model.transformMode == mode ? [.isSelected] : [])
            }
        }.accessibilityElement(children: .contain).accessibilityLabel("Transform mode")
    }
}
