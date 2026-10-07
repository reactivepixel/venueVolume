import SwiftUI

/// Selection-specific controls attached below the viewer in the immersive venue.
struct VenueContextBar: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if model.contextBarVisible {
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    Label("Context bar", systemImage: "scope").font(.headline)
                    Divider().frame(height: 56)
                    if let session = model.presetDrag.session {
                        let paletteName = model.presets.first { $0.id == session.presetID }?.name ?? "Palette"
                        let target = model.presetDrag.proposedFixtureID.flatMap { model.fixture($0) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apply · \(paletteName)").font(.headline).lineLimit(1)
                            Text(target.map { "Pinch to apply to \($0.name)" } ?? "Aim toward a fixture, then pinch. Hold to adjust.")
                                .font(.callout).foregroundStyle(.secondary).lineLimit(2)
                        }.frame(width: 360, alignment: .leading)
                        Button("Cancel", role: .cancel) { model.endPresetDrag() }.frame(minHeight: 60)
                        Button("Apply to fixture") { model.applyProposedPreset() }
                            .buttonStyle(.borderedProminent).disabled(target == nil).frame(minHeight: 60)
                    } else if model.isRetargeting {
                        TargetingPrompt()
                    } else if model.tourPreview != nil {
                        Text(model.tourPreviewTitle).font(.callout).frame(width: 300, alignment: .leading)
                        Button("Cancel") { model.cancelTourPreview() }.frame(minHeight: 60)
                        Button("Save change") { model.commitTourPreview() }.buttonStyle(.borderedProminent).frame(minHeight: 60)
                    } else if model.isPickingRoom || model.gizmoVisible {
                        TargetingPrompt()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.selectedFixtures.count == 1 ? model.selectedFixtures[0].name : "\(model.selectedFixtures.count) fixtures selected")
                                .font(.headline).lineLimit(1)
                            Text("Select again to move or transform.")
                                .font(.callout).foregroundStyle(.secondary)
                        }.frame(width: 360, alignment: .leading)
                        Button("Edit selection", systemImage: "slider.horizontal.3") {
                            openWindow(id: "fixture-editor", value: "selection")
                        }.frame(minHeight: 60)
                    }
                }.padding(20).frame(minHeight: 100)
            }.frame(width: 1120)
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Context bar")
                .hoverEffect { effect, active, _ in effect.opacity(active ? 1 : 0.35) }
        }
    }
}
