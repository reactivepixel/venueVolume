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
        var offset = SIMD3<Float>.zero
        var dragged = false
        var fixtureID: UUID?
    }
    @State private var activeSpatialEvents: [SpatialEventCollection.Event.ID: SpatialInput] = [:]

    var body: some View {
        RealityView { content, attachments in
            scene.startAnimation(in: content)
            content.add(scene.root)
            content.add(scene.overlayRoot)
            content.add(scene.headAnchor)
            scene.update(model: model, attachments: attachments)
            scene.updateAccessibility(reduceMotion: reduceMotion)
        } update: { content, attachments in
            scene.update(model: model, attachments: attachments)
            scene.updateAccessibility(reduceMotion: reduceMotion)
        } attachments: {
            Attachment(id: "context-bar") { VenueContextBar().environment(model).controlSize(.large).navigationInputShield(model: model) }
            ForEach(model.environment?.surfaces ?? [], id: \.id) { surface in
                Attachment(id: "surface-drop-\(surface.id)") { FixtureSurfaceDrop(surface: surface).environment(model) }
            }
            ForEach(model.sceneFixtures) { fixture in
                Attachment(id: "label-\(fixture.id)") {
                    FixtureLabel(fixture: fixture).environment(model).navigationInputShield(model: model).disabled(model.palmMapVisible)
                }

            }
        }
        .gesture(SpatialEventGesture().targetedToAnyEntity()
            .onChanged { value in routeSpatialEvents(value) }
            .onEnded { value in
                routeSpatialEvents(value)
                model.endTransformDrag(); activeSpatialEvents.removeAll()
            })
        .onChange(of: model.selectedID) { _, selected in
            activeSpatialEvents.removeAll(); model.endTransformDrag()
        }
        .onChange(of: model.transformMode) { _, _ in
            activeSpatialEvents.removeAll(); model.endTransformDrag()
        }
        .onChange(of: model.canPlace, initial: true) { _, ready in
            if !ready { model.closePalmMap() }
            model.finishPlacementHandoffIfReady()
        }
        .onChange(of: model.palmMapRequestID) { _, _ in
            scene.cancelSpatialDrag(model: model)
            activeSpatialEvents.removeAll()
        }
        .onChange(of: model.isImmersed) { _, _ in model.finishPlacementHandoffIfReady() }
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
            model.closePalmMap()
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
                    model.requestToolbox()
                } else if arguments.contains("--show-item-editor") {
                    model.requestToolbox()
                } else {
                    let phaserID = arguments.contains("--phaser-editor") ? model.presets.first(where: { $0.phaser != nil })?.id : nil
                    model.presetEditor.request(presetID: phaserID)
                }
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
            if !model.toolboxVisible { model.requestToolbox() }
            dismissWindow(id: "launch")
            let arguments = ProcessInfo.processInfo.arguments
            if model.isDemoMode && !arguments.contains("--show-preset-editor") && !arguments.contains("--position-tab") {
                dismissWindow(id: "presets")
            }
        }
        .onDisappear {
            model.closePalmMap()
            model.cancelPlacementHandoff()
            model.finishHistoryGesture()
            model.flushHistoryEdits()
            model.isImmersed = false
            model.cancelPicking()
            model.canPlace = false
            model.gizmoVisible = false
            dismissWindow(id: "room-placement")
            for identity in model.toolboxWindowIDs { dismissWindow(id: "toolbox", value: identity) }
            if model.unvaluedToolboxVisible { dismissWindow(id: "toolbox") }
            model.resetToolboxActivation()
            model.previewDraft = false
            scene.clearAttachments()
            openWindow(id: "launch")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                model.closePalmMap(); scene.cancelSpatialDrag(model: model)
                model.finishHistoryGesture(); model.flushHistoryEdits()
            }
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
            let entity = event.targetedEntity ?? value.entity
            let point = value.convert(event.location3D, from: .local, to: scene.root)
            switch event.phase {
            case .active:
                var initial = SpatialInput(entity: entity,start: point,point: point,fixtureID: model.selectedID)
                // Keep SwiftUI controls on their own input route. Only redirect
                // room/fixture hits to the visible transformation overlay.
                if activeSpatialEvents[event.id] == nil,
                   entity.name.hasPrefix("aim-surface:") || entity.name.hasPrefix("room-collider:") || UUID(uuidString: entity.name) != nil,
                   let ray = event.selectionRay {
                    let origin = value.convert(ray.origin, from: .local, to: scene.root)
                    let end = value.convert(ray.origin + ray.direction, from: .local, to: scene.root)
                    if let hit = scene.transformHandle(origin: origin, direction: end-origin, model: model) {
                        initial.entity = hit.entity; initial.start = hit.position
                        initial.offset = hit.position-point
                    }
                }
                var input = activeSpatialEvents[event.id] ?? initial
                let point = point + input.offset
                input.point = point
                if input.fixtureID == model.selectedID, FixtureTransformGizmo.handle(input.entity) != nil || FixtureAiming.length(point-input.start) > 0.015 || input.dragged {
                    if input.entity.components.has(SpatialDragTarget.self),
                       scene.handleDrag(entity: input.entity,position: point,start: input.start,model: model) { input.dragged = true }
                }
                activeSpatialEvents[event.id] = input
            case .ended:
                guard let input = activeSpatialEvents.removeValue(forKey: event.id) else { continue }
                if input.dragged {
                    if input.fixtureID == model.selectedID { _ = scene.handleDrag(entity: input.entity,position: point + input.offset,start: input.start,model: model) }
                    scene.endSpatialDrag(model: model)
                } else { scene.handleTap(entity: input.entity,position: point,model: model) }
            case .cancelled:
                if activeSpatialEvents.removeValue(forKey: event.id)?.dragged == true { scene.cancelSpatialDrag(model: model) }
            @unknown default: break
            }
        }
    }


}
