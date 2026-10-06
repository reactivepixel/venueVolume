import SwiftUI

/// Fixed lower-view controls stay available, with system hover restoring full
/// contrast when attended. visionOS does not expose a raw eye-gaze stream.
struct VenueContextBar: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        @Bindable var model = model
        HStack(spacing: 18) {
            if model.isPlacing {
                Label("Place \(model.fixtureKind.name)", systemImage: "plus.viewfinder")
                Text("Look at a surface and pinch. Repeat to place more.").font(.caption)
                Button("Done", systemImage: "checkmark") { model.finishPlacement() }
            } else if model.isRetargeting {
                Label("Aim selection", systemImage: "scope")
                Button("Save", systemImage: "checkmark") { _ = model.saveTarget() }.disabled(!model.canSaveTarget)
                Button("Cancel") { model.cancelPicking() }
            } else if model.scenePick != nil {
                Label("Move selection", systemImage: "move.3d")
                Button("Done", systemImage: "checkmark") { model.cancelPicking() }
            } else if model.gizmoVisible {
                Picker("Transform", selection: $model.transformMode) {
                    ForEach(FixtureTransformMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }.pickerStyle(.segmented).frame(width: 220)
                Button("Done", systemImage: "checkmark") { model.endTransformDrag(); model.gizmoVisible = false }
            } else {
                Button("Wrist toolbox", systemImage: "rectangle.on.rectangle") { model.requestToolbox() }
                Text("Look at your left palm for the venue map").font(.caption)
                Button("Venue controls", systemImage: "slider.horizontal.3") { openWindow(id: "venue-controls", value: "controls") }
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 12)
        .glassBackgroundEffect()
        .hoverEffect { effect, active, _ in effect.opacity(active ? 1 : 0.3) }
    }
}
