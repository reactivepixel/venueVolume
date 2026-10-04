import RealityKit
import SwiftUI
import VenueVolumeCore

struct VenueSpaceView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene = VenueScene()
    private struct SpatialInput {
        var entity: Entity
        var start: SIMD3<Float>
        var point: SIMD3<Float>
        var dragged = false
        var fixtureID: UUID?
    }
    @State private var presetSpatialEvents: Set<SpatialEventCollection.Event.ID> = []
    @State private var activeSpatialEvents: [SpatialEventCollection.Event.ID: SpatialInput] = [:]

    var body: some View {
        RealityView { content, attachments in
            scene.startAnimation(in: content)
            content.add(scene.root)
            content.add(scene.overlayRoot)
            content.add(scene.headAnchor)
            scene.update(model: model, attachments: attachments)
            scene.updatePresetDrag(model: model, reduceMotion: reduceMotion)
        } update: { content, attachments in
            scene.update(model: model, attachments: attachments)
            scene.updatePresetDrag(model: model, reduceMotion: reduceMotion)
        } attachments: {
            Attachment(id: "venue-controls-dock") { VenueControlsView().environment(model).auditTextSize().controlSize(.large).navigationInputShield(model: model) }
            ForEach(model.environment?.surfaces ?? [], id: \.id) { surface in
                Attachment(id: "surface-drop-\(surface.id)") { FixtureSurfaceDrop(surface: surface).environment(model) }
            }
            ForEach(model.sceneFixtures) { fixture in
                Attachment(id: "label-\(fixture.id)") {
                    FixtureLabel(fixture: fixture).environment(model).navigationInputShield(model: model)
                }
                Attachment(id: "drop-\(fixture.id)") {
                    FixtureDropTarget(fixture: fixture).environment(model).navigationInputShield(model: model)
                }
            }
        }
        .gesture(SpatialEventGesture().targetedToAnyEntity()
            .onChanged { value in routeSpatialEvents(value) }
            .onEnded { value in
                routeSpatialEvents(value)
                model.endTransformDrag(); activeSpatialEvents.removeAll(); presetSpatialEvents.removeAll()
            })
        .onChange(of: model.selectedID) { _, selected in
            activeSpatialEvents.removeAll(); model.endTransformDrag()
            if selected == nil {
                dismissWindow(id: "fixture-editor")
            }
        }
        .task(id: model.toolboxRequestID) {
            guard let request = model.toolboxRequestID, model.isImmersed else { return }
            // A new window value recalls the toolbox near the viewer instead of
            // refocusing an existing window at its old, possibly distant position.
            if model.toolboxVisible {
                for identity in model.toolboxWindowIDs { dismissWindow(id: "toolbox", value: identity) }
                if model.unvaluedToolboxVisible { dismissWindow(id: "toolbox") }
                for _ in 0..<30 where model.toolboxVisible {
                    do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                }
            }
            guard !Task.isCancelled, model.isImmersed, !model.toolboxVisible,
                  model.toolboxRequestID == request else { return }
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
            model.showVenueControls()
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
            await scene.runPresetDragSmoke(model: model) { dismissWindow(id: "toolbox") }
            await runBottomControlsSmoke()
            await runEditorRecallSmoke()
            await runToolboxWindowSmoke()
            await scene.runInputSmoke(model: model)
            await scene.runFixtureMovementSmoke(model: model)
            await scene.runNavigationSmoke(model: model)
            await RoomLibrarySmoke.run(model: model)
            await RoomLibrarySmoke.catalog(model: model)
            await RoomLibrarySmoke.touring(model: model)
            runVenueExitSmoke()
            if model.isDemoMode && ProcessInfo.processInfo.arguments.contains("--movement-screenshot") {
                for identity in model.toolboxWindowIDs { dismissWindow(id: "toolbox", value: identity) }
            }
            if model.isDemoMode && ProcessInfo.processInfo.arguments.contains("--touring-editor") {
                // Presentation-only capture: expose the editor instead of leaving
                // it behind the automatically recalled wrist/controls windows.
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled { dismissWindow(id: "toolbox") }
            }
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
            for identity in model.toolboxWindowIDs { dismissWindow(id: "toolbox", value: identity) }
            if model.unvaluedToolboxVisible { dismissWindow(id: "toolbox") }
            model.venueControlsVisible = false
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

    private func routeSpatialEvents(_ value: EntityTargetValue<SpatialEventCollection>) {
        for event in value.gestureValue {
            // ARKit handles left navigation even when looking at empty space.
            // Never route a left-hand system pinch into fixture editing.
            if event.chirality == .left {
                model.reserveLeftHandInput(); activeSpatialEvents[event.id] = nil; continue
            }
            if model.navigationInputReserved { continue }
            if model.presetDrag.session == nil, presetSpatialEvents.contains(event.id) {
                if event.phase != .active { presetSpatialEvents.remove(event.id) }
                continue
            }
            if let session = model.presetDrag.session {
                presetSpatialEvents.insert(event.id)
                func world(_ point: Point3D) -> SIMD3<Float> {
                    scene.root.convert(position: value.convert(point, from: .local, to: scene.root), to: nil)
                }
                let sample = PresetDragState.Sample(cursor: world(event.location3D),
                    hand: event.inputDevicePose.map { world($0.pose3D.position) },
                    rayOrigin: event.selectionRay.map { world($0.origin) },
                    rayPoint: event.selectionRay.map { world($0.origin + $0.direction) })
                switch event.phase {
                case .active: model.presetDrag.update(session.id, sample: sample, armed: true)
                case .ended:
                    model.presetDrag.update(session.id, sample: sample, armed: true)
                    model.presetDrag.release(session.id)
                case .cancelled: model.presetDrag.clearPointer()
                @unknown default: model.presetDrag.clearPointer()
                }
                activeSpatialEvents.removeAll()
                continue
            }
            let entity = event.targetedEntity ?? value.entity
            let point = value.convert(event.location3D, from: .local, to: scene.root)
            switch event.phase {
            case .active:
                var input = activeSpatialEvents[event.id] ?? SpatialInput(entity: entity,start: point,point: point,fixtureID: model.selectedID)
                input.point = point
                if input.fixtureID == model.selectedID, FixtureAiming.length(point-input.start) > 0.015 || input.dragged {
                    if input.entity.components.has(SpatialDragTarget.self),
                       scene.handleDrag(entity: input.entity,position: point,start: input.start,model: model) { input.dragged = true }
                }
                activeSpatialEvents[event.id] = input
            case .ended:
                guard let input = activeSpatialEvents.removeValue(forKey: event.id) else { continue }
                if input.dragged {
                    if input.fixtureID == model.selectedID { _ = scene.handleDrag(entity: input.entity,position: point,start: input.start,model: model) }
                    model.endTransformDrag()
                } else { scene.handleTap(entity: input.entity,position: point,model: model) }
            case .cancelled:
                if activeSpatialEvents.removeValue(forKey: event.id)?.dragged == true { model.endTransformDrag() }
            @unknown default: break
            }
        }
    }

    #if DEBUG
    private func runVenueExitSmoke() {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--venue-exit-smoke") else { return }
        // Outlive this view's task cancellation when the immersive space closes.
        Task { @MainActor in
            do {
                model.requestToolbox()
                try await waitForToolbox(model.toolboxRequestID)
                await dismissSpace()
                for _ in 0..<100 where model.isImmersed || model.toolboxVisible {
                    try await Task.sleep(for: .milliseconds(50))
                }
                guard !model.isImmersed, !model.toolboxVisible, model.toolboxWindowIDs.isEmpty,
                      !model.unvaluedToolboxVisible, model.toolboxRequestID == nil else {
                    throw EnvironmentError.invalid("Venue exit left wrist window or recall active")
                }
                print("VENUE_EXIT_SMOKE_PASS immersed=false toolboxWindows=0 pendingRecall=false")
            } catch { print("VENUE_EXIT_SMOKE_FAIL \(error)") }
        }
    }

    private func runBottomControlsSmoke() async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--audit-controls-smoke") else { return }
        do {
            for _ in 0..<200 where !model.canPlace { try await Task.sleep(for: .milliseconds(100)) }
            guard let fixture = model.fixtures.first else { throw EnvironmentError.invalid("Missing fixture") }
            model.beginRetarget(fixture.id)
            for _ in 0..<100 where !model.venueControlsVisible { try await Task.sleep(for: .milliseconds(50)) }
            guard model.venueControlsVisible, scene.headAnchor.children.contains(where: { $0.name == "venue-controls-dock" }) else {
                throw EnvironmentError.invalid("Targeting did not use the bottom controls attachment")
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
            print("VENUE_CONTROLS_DOCK_SMOKE_PASS bottomAttachment=true wristReveal=true cancel=true save=true undo=true")
        } catch { print("VENUE_CONTROLS_DOCK_SMOKE_FAIL \(error)") }
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
            if let identity = model.toolboxPresentedID { dismissWindow(id: "toolbox", value: identity) }
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
