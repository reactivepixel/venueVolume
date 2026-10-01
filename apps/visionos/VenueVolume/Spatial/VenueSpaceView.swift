import RealityKit
import SwiftUI

struct VenueSpaceView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @State private var scene = VenueScene()

    var body: some View {
        RealityView { content, attachments in
            scene.startAnimation(in: content)
            content.add(scene.root)
            content.add(scene.overlayRoot)
            content.add(scene.headAnchor)
            scene.update(model: model, attachments: attachments)
        } update: { _, attachments in
            scene.update(model: model, attachments: attachments)
        } attachments: {
            Attachment(id: "targeting") { TargetingPrompt().environment(model) }
            Attachment(id: "toolbox") { ToolboxView().environment(model) }
            ForEach(model.environment?.surfaces ?? [], id: \.id) { surface in
                Attachment(id: "surface-drop-\(surface.id)") { FixtureSurfaceDrop(surface: surface).environment(model) }
            }
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
            let position = value.convert(value.location3D, from: .local, to: scene.root)
            scene.handleTap(entity: value.entity, position: position, model: model)
        })
        .task(id: model.roomLoadToken) {
            model.canPlace = false
            let loaded = await scene.load(model: model)
            if !Task.isCancelled && (loaded || model.environment != nil) {
                await scene.runTracking(model: model)
            }
        }
        .task {
            if model.isDemoMode && ProcessInfo.processInfo.arguments.contains("--show-preset-editor") {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                if !model.presetWindowVisible { openWindow(id: "presets") }
            }
        }
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            guard model.isDemoMode,
                  arguments.contains("--targeting") || arguments.contains("--retarget-head") || arguments.contains("--retarget-mount") else { return }
            // Reproducible presentation states exercise the same model commands
            // as the UI, after the room has loaded and aligned. They are not gesture tests.
            while !model.canPlace {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            }
            guard let id = model.selectedID else { return }
            model.beginRetarget(id, method: arguments.contains("--retarget-mount") ? .mount : .head)
            if !arguments.contains("--targeting") {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                _ = model.acceptTarget(.init(x: 2.9, y: 1.8, z: -7.67))
            }
        }
        .onAppear {
            model.isImmersed = true
            dismissWindow(id: "launch")
            if model.isDemoMode && !ProcessInfo.processInfo.arguments.contains("--show-preset-editor") {
                dismissWindow(id: "presets")
            }
        }
        .task {
            #if DEBUG
            await RoomLibrarySmoke.run(model: model)
            #endif
        }
        .onDisappear {
            model.isImmersed = false
            model.cancelPicking()
            model.canPlace = false
            model.expandedID = nil
            model.toolboxVisible = false
            model.endPresetDrag()
            model.previewDraft = false
            scene.clearAttachments()
            openWindow(id: "launch")
        }
    }
}
