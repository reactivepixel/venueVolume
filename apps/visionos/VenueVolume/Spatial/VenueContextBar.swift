import SwiftUI

/// Selection-specific controls attached below the viewer in the immersive venue.
struct VenueContextBar: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var expanded = false

    var body: some View {
        if model.contextBarVisible {
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    Button { expanded.toggle() } label: {
                        Image(systemName: "ellipsis").frame(width: 60, height: 60)
                    }.buttonStyle(.plain).hoverEffect(.highlight)
                        .accessibilityLabel(expanded ? "Collapse context menu" : "Expand context menu")
                        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                    if expanded {
                        HistoryControls()
                        Button("Toolbox", systemImage: "wrench.and.screwdriver") { model.requestToolbox() }.frame(minHeight: 60)
                        CueControlsView()
                        Button("Room placement", systemImage: "building.2") {
                            openWindow(id: "room-placement"); expanded = false
                        }.frame(minHeight: 60)
                    }
                    if model.contextBarHasSelection {
                    Divider().frame(height: 56)
                    if model.isRetargeting {
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
                        if !expanded {
                            Button("Toolbox", systemImage: "slider.horizontal.3") { model.requestToolbox() }.frame(minHeight: 60)
                        }
                    }
                    }
                }.padding(model.contextBarHasSelection ? 20 : 10).frame(minHeight: model.contextBarHasSelection ? 100 : 80)
            }.frame(width: model.contextBarHasSelection ? (expanded ? 1440 : model.gizmoVisible ? 1080 : 880) : (expanded ? 1140 : 80))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Context bar")
                .onChange(of: model.contextBarHasSelection) { _, _ in expanded = false }
                .onChange(of: model.palmMapVisible) { _, _ in expanded = false }
        }
    }
}
