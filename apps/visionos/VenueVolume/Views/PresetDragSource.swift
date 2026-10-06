import SwiftUI
import VenueVolumeCore

/// The row activates Apply; the spatial connector belongs to the viewer, never this window.
struct PresetDragSource: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dynamicTypeSize) private var textSize
    let preset: DMXPreset
    let openEditor: () -> Void

    private var unavailableReason: String? {
        if !model.isImmersed { return "Enter a venue to apply palettes." }
        if model.libraryBusy || !model.canPlace { return "Wait for the venue to finish loading." }
        if model.tourPreview != nil { return "Save or cancel the current preview before applying a palette." }
        if model.isPickingRoom || model.isTransformDragging { return "Finish positioning or targeting before applying a palette." }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
            layout {
                Button(action: openEditor) {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3").frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name).font(.headline)
                            Text("\(preset.channels.count) channels · Edit palette")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }.frame(minHeight: 60).contentShape(Rectangle())
                }.buttonStyle(.plain)
                HStack(spacing: 16) {
                Button {
                    model.activatePresetApplication(preset.id)
                } label: {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.title3).frame(width: 60, height: 60)
                }
                .disabled(unavailableReason != nil)
                .accessibilityLabel("Apply \(preset.name) in venue")
                .accessibilityHint("Activates a connector from you. Pinch a fixture to apply, or cancel in Venue controls.")
                Menu {
                    if model.tour != nil {
                        Button("Preview on selected \(model.tourSelection.count) units") { model.applyTourPreset(preset.id, preview: true) }.disabled(model.tourSelection.isEmpty)
                        ForEach(model.tour?.show.groups ?? []) { group in
                            Button("Preview group · \(group.name)") {
                                model.selectGroup(group.id); model.applyTourPreset(preset.id, group: group.id, preview: true)
                            }
                        }
                        Divider()
                    }
                    if model.fixtures.isEmpty { Text("Place a fixture to apply a preset") }
                    ForEach(model.fixtures) { fixture in
                        Button("Apply to \(fixture.name)") { apply(to: fixture.id) }
                    }
                } label: {
                    Image(systemName: "arrow.up.right.circle").frame(width: 60, height: 60)
                }
                .accessibilityLabel("Apply \(preset.name) to fixture")
                }
            }
            if let reason = unavailableReason {
                Text(reason).font(.caption).foregroundStyle(.secondary)
            }
            if model.presetDrag.session?.presetID == preset.id {
                Label("Applying in venue · controls below", systemImage: "scope")
                    .font(.caption).foregroundStyle(.secondary)
            } else if let feedback = model.presetDrag.feedback, feedback.presetID == preset.id {
                Label(feedback.succeeded ? "Palette applied" : "Could not apply palette · \(feedback.message ?? "Try again")",
                      systemImage: feedback.succeeded ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func apply(to fixtureID: UUID) {
        let succeeded = model.applyPreset(preset.id, to: fixtureID)
        model.presetDrag.showFeedback(presetID: preset.id, fixtureID: fixtureID, succeeded: succeeded, message: succeeded ? nil : model.message)
    }
}
