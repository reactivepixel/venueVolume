import RealityKit
import SwiftUI

struct VenueSpaceView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @State private var scene = VenueScene()

    var body: some View {
        RealityView { content, attachments in
            content.add(scene.root)
            content.add(scene.headAnchor)
            scene.update(model: model, attachments: attachments)
        } update: { _, attachments in
            scene.update(model: model, attachments: attachments)
        } attachments: {
            Attachment(id: "toolbox") { ToolboxView().environment(model) }
            if model.canSimulatePalm || model.needsManualToolbox {
                Attachment(id: "palm-preview") { SimulatorPalmControl().environment(model) }
            }
            ForEach(model.fixtures) { fixture in
                Attachment(id: "label-\(fixture.id)") {
                    FixtureLabel(fixture: fixture).environment(model)
                }
                Attachment(id: "drop-\(fixture.id)") {
                    FixtureDropTarget(fixture: fixture).environment(model)
                }
            }
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            if value.entity.name == "placement-surface" {
                let position = value.convert(value.location3D, from: .local, to: scene.root)
                model.place(at: position)
            } else if let id = UUID(uuidString: value.entity.name) {
                model.select(id)
            }
        })
        .task { await scene.runTracking(model: model) }
        .task {
            if model.isDemoMode && ProcessInfo.processInfo.arguments.contains("--show-preset-editor") {
                // Wait for the immersive transition before opening its companion window.
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                openWindow(id: "presets")
            }
        }
        .onAppear {
            model.isImmersed = true
            dismissWindow(id: "launch")
        }
        .onDisappear {
            model.isImmersed = false
            model.isPlacing = false
            model.canPlace = false
            model.expandedID = nil
            model.toolboxVisible = false
            model.endPresetDrag()
            scene.clearAttachments()
            openWindow(id: "launch")
        }
    }
}
