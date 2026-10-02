import RealityKit
import SwiftUI

struct VenueSpaceView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = VenueScene()
    @State private var lastSpatialDragEnd = Date.distantPast
    @State private var handledDrag = false
    @State private var dragFixtureID: UUID?
    @State private var cancelledDrag = false
    @GestureState private var spatialDragActive = false

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
            guard Date().timeIntervalSince(lastSpatialDragEnd) > 0.25, !handledDrag else { return }
            let position = value.convert(value.location3D, from: .local, to: scene.root)
            scene.handleTap(entity: value.entity, position: position, model: model)
        })
        .simultaneousGesture(DragGesture(minimumDistance: 0).targetedToEntity(where: .has(SpatialDragTarget.self))
            .updating($spatialDragActive) { _, active, _ in active = true }
            .onChanged { value in
                guard !cancelledDrag, !handledDrag || dragFixtureID == model.selectedID else { return }
                let start = value.convert(value.startLocation3D, from: .local, to: scene.root)
                let point = value.convert(value.location3D, from: .local, to: scene.root)
                if scene.handleDrag(entity: value.entity, position: point, start: start, model: model) {
                    if !handledDrag { dragFixtureID = model.selectedID }
                    handledDrag = true
                }
            }
            .onEnded { value in
                if handledDrag && !cancelledDrag && dragFixtureID == model.selectedID {
                    let point = value.convert(value.location3D, from: .local, to: scene.root)
                    let start = value.convert(value.startLocation3D, from: .local, to: scene.root)
                    _ = scene.handleDrag(entity: value.entity, position: point, start: start, model: model)
                    model.endTransformDrag(); lastSpatialDragEnd = Date()
                }
                handledDrag = false; dragFixtureID = nil; cancelledDrag = false
            })
        .onChange(of: spatialDragActive) { _, active in
            if !active && handledDrag {
                model.endTransformDrag(); lastSpatialDragEnd = Date(); handledDrag = false
            }
            if !active { dragFixtureID = nil; cancelledDrag = false }
        }
        .onChange(of: model.selectedID) { _, selected in
            if handledDrag { cancelledDrag = true; lastSpatialDragEnd = Date() }
            handledDrag = false; dragFixtureID = nil
            if selected == nil {
                dismissWindow(id: "fixture-editor")
            }
        }
        .task(id: model.toolboxRequestID) {
            guard let request = model.toolboxRequestID else { return }
            // A new window value recalls the toolbox near the viewer instead of
            // refocusing an existing window at its old, possibly distant position.
            if model.toolboxVisible {
                dismissWindow(id: "toolbox")
                for _ in 0..<30 where model.toolboxVisible {
                    do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                }
            }
            guard !Task.isCancelled else { return }
            openWindow(id: "toolbox", value: request)
        }
        .task(id: model.roomLoadToken) {
            model.canPlace = false
            let loaded = await scene.load(model: model)
            if !Task.isCancelled && (loaded || model.environment != nil) {
                await scene.runTracking(model: model)
            }
        }
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            if model.isDemoMode && arguments.contains("--transform-gizmo") {
                while !model.canPlace {
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                }
                if let id = model.selectedID { model.beginTransform(id); model.transformMode = .rotate }
            }
            if model.isDemoMode && (arguments.contains("--show-preset-editor") || arguments.contains("--position-tab") || arguments.contains("--show-item-editor")) {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                if arguments.contains("--position-tab") {
                    if let id = model.selectedID { model.beginTransform(id) }
                    openWindow(id: "fixture-editor")
                } else if arguments.contains("--show-item-editor") {
                    openWindow(id: "fixture-editor")
                } else if !model.presetWindowVisible { openWindow(id: "presets") }
            }
        }
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            guard model.isDemoMode,
                  arguments.contains("--targeting") || arguments.contains("--retarget-head") else { return }
            // Reproducible presentation states exercise the same model commands
            // as the UI, after the room has loaded and aligned. They are not gesture tests.
            while !model.canPlace {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            }
            guard let id = model.selectedID else { return }
            model.beginRetarget(id)
            if !arguments.contains("--targeting") {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                _ = model.acceptTarget(.init(x: 2.9, y: 1.8, z: -7.67))
            }
        }
        .onAppear {
            model.isImmersed = true
            dismissWindow(id: "launch")
            let arguments = ProcessInfo.processInfo.arguments
            if model.isDemoMode && !arguments.contains("--show-preset-editor") && !arguments.contains("--position-tab") {
                dismissWindow(id: "presets")
            }
            if model.isDemoMode && !arguments.contains("--position-tab") && !arguments.contains("--show-item-editor") {
                dismissWindow(id: "fixture-editor")
            }
        }
        .task {
            #if DEBUG
            await runToolboxWindowSmoke()
            await scene.runInputSmoke(model: model)
            await RoomLibrarySmoke.run(model: model)
            #endif
        }
        .onDisappear {
            model.finishHistoryGesture()
            model.flushHistoryEdits()
            model.isImmersed = false
            model.cancelPicking()
            model.canPlace = false
            model.expandedID = nil
            model.gizmoVisible = false
            dismissWindow(id: "fixture-editor")
            dismissWindow(id: "toolbox")
            model.resetToolboxActivation()
            model.endPresetDrag()
            model.previewDraft = false
            scene.clearAttachments()
            openWindow(id: "launch")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() }
        }
    }

    #if DEBUG
    private func runToolboxWindowSmoke() async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--input-smoke") else { return }
        do {
            while !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            model.requestToolbox()
            try await waitForToolbox(model.toolboxRequestID)
            let heldRequest = model.toolboxRequestID
            dismissWindow(id: "toolbox")
            try await waitForToolbox(nil)
            try await Task.sleep(for: .milliseconds(300))
            guard !model.toolboxVisible, model.toolboxRequestID == heldRequest else {
                throw CancellationError()
            }
            model.updateToolboxActivation(raised: false)
            model.updateToolboxActivation(raised: true)
            try await waitForToolbox(model.toolboxRequestID)
            let reopened = model.toolboxPresentedID
            model.requestToolbox()
            try await waitForToolbox(model.toolboxRequestID)
            guard model.toolboxPresentedID != reopened else { throw CancellationError() }
            print("TOOLBOX_WINDOW_SMOKE_PASS")
        } catch { print("TOOLBOX_WINDOW_SMOKE_FAIL: \(error)") }
    }

    private func waitForToolbox(_ identity: UUID?) async throws {
        for _ in 0..<100 {
            if model.toolboxPresentedID == identity && model.toolboxVisible == (identity != nil) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw CancellationError()
    }
    #endif

}
