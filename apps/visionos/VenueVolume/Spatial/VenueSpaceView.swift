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
            Attachment(id: "debug") { DebugPanel().environment(model) }
            ForEach(model.fixtures) { fixture in
                Attachment(id: "label-\(fixture.id)") {
                    FixtureLabel(fixture: fixture).environment(model)
                }
                if model.expandedID == fixture.id {
                    Attachment(id: "panel-\(fixture.id)") {
                        FixturePanel(fixture: fixture).environment(model).id(fixture.id)
                    }
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
        .onAppear {
            model.isImmersed = true
            dismissWindow(id: "launch")
        }
        .onDisappear {
            model.isImmersed = false
            model.isPlacing = false
            model.canPlace = false
            model.expandedID = nil
            scene.clearAttachments()
            openWindow(id: "launch")
        }
    }
}
