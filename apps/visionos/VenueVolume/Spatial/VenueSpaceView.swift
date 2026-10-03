import RealityKit
import SwiftUI
import VenueVolumeCore

struct VenueSpaceView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            scene.updatePresetDrag(model: model, content: content, reduceMotion: reduceMotion)
        } update: { content, attachments in
            scene.update(model: model, attachments: attachments)
            scene.updatePresetDrag(model: model, content: content, reduceMotion: reduceMotion)
        } attachments: {
            ForEach(model.environment?.surfaces ?? [], id: \.id) { surface in
                Attachment(id: "surface-drop-\(surface.id)") { FixtureSurfaceDrop(surface: surface).environment(model) }
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
        .onChange(of: model.canSimulatePalm || model.needsManualToolbox, initial: true) { _, needed in
            if needed { openWindow(id: "venue-controls", value: "controls") }
        }
        .onChange(of: model.isPickingRoom || model.gizmoVisible) { _, active in
            if active { openWindow(id: "venue-controls", value: "controls") }
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
                    openWindow(id: "fixture-editor", value: "selection")
                } else if arguments.contains("--show-item-editor") {
                    openWindow(id: "fixture-editor", value: "selection")
                } else { model.presetEditor.request() }
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
            await scene.runPresetDragSmoke(model: model)
            await runStationaryControlsSmoke()
            await runEditorRecallSmoke()
            await runToolboxWindowSmoke()
            await scene.runInputSmoke(model: model)
            await RoomLibrarySmoke.run(model: model)
            await RoomLibrarySmoke.catalog(model: model)
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
            dismissWindow(id: "venue-controls")
            model.resetToolboxActivation()
            model.endPresetDrag()
            model.previewDraft = false
            scene.clearAttachments()
            openWindow(id: "launch")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits(); model.endPresetDrag() }
        }
        .presetEditorPresenter()
    }

    #if DEBUG
    private func runStationaryControlsSmoke() async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--audit-controls-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            guard let fixture = model.fixtures.first else { throw EnvironmentError.invalid("Missing fixture") }
            model.beginRetarget(fixture.id)
            for _ in 0..<100 where !model.venueControlsVisible { try await Task.sleep(for: .milliseconds(50)) }
            guard model.venueControlsVisible, scene.headAnchor.children.isEmpty else {
                throw EnvironmentError.invalid("Targeting did not use the stationary control window")
            }
            guard model.acceptTarget(.init(x: 2.9, y: 1.8, z: -7.67)) else { throw EnvironmentError.invalid("Preview failed") }
            model.cancelPicking()
            guard model.fixture(fixture.id)?.channels == fixture.channels else { throw EnvironmentError.invalid("Cancel changed saved channels") }
            model.beginRetarget(fixture.id)
            guard model.acceptTarget(.init(x: 2.9, y: 1.8, z: -7.67)), model.saveTarget() else { throw EnvironmentError.invalid("Save target failed") }
            model.undo()
            guard model.fixture(fixture.id)?.channels == fixture.channels else { throw EnvironmentError.invalid("Target undo failed") }
            model.beginRetarget(fixture.id)
            _ = model.acceptTarget(.init(x: 2.9, y: 1.8, z: -7.67))
            print("STATIONARY_CONTROLS_SMOKE_PASS normalWindow=true headControls=0 cancel=true save=true undo=true")
        } catch { print("STATIONARY_CONTROLS_SMOKE_FAIL \(error)") }
    }

    private func runEditorRecallSmoke() async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--editor-recall-smoke") else { return }
        func waitForEditor(_ id: UUID) async throws {
            for _ in 0..<200 {
                try await Task.sleep(for: .milliseconds(50))
                if model.presetEditor.windowIDs == [id] { return }
            }
            throw EnvironmentError.invalid("Editor window did not settle to the requested identity")
        }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(50)) }
            guard model.presets.count >= 2 else { throw EnvironmentError.invalid("Missing demo presets") }
            model.presetEditor.request(presetID: model.presets[0].id)
            try await waitForEditor(model.presetEditor.latestRequest!.id)
            model.presetDraft.name = "Unsaved recall check"
            let draft = model.presetDraft
            model.presetEditor.request(presetID: model.presets[0].id)
            model.presetEditor.request(presetID: model.presets[1].id)
            try await waitForEditor(model.presetEditor.latestRequest!.id)
            guard model.presetDraft == draft, model.presetWindowVisible else {
                throw EnvironmentError.invalid("Recall lost the unsaved draft")
            }
            print("EDITOR_RECALL_SMOKE_PASS oneWindow=true latestRequest=true dirtyDraftPreserved=true")
        } catch { print("EDITOR_RECALL_SMOKE_FAIL \(error)") }
    }

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
