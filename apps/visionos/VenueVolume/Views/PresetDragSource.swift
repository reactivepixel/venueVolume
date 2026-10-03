import Spatial
import SwiftUI
import VenueVolumeCore

/// A separate handle keeps vertical scrolling and the editor button predictable.
/// The real window transform is required: an unavailable transform disables the
/// spatial path while the explicit Apply menu remains usable.
struct PresetDragSource: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    let preset: DMXPreset
    let openEditor: () -> Void
    @State private var windowTransform: AffineTransform3D?
    @State private var sourcePoint = Point3D.zero
    @State private var eventID: SpatialEventCollection.Event.ID?
    @State private var sessionID: UUID?
    @State private var cancelledEventID: SpatialEventCollection.Event.ID?
    @State private var initialCursor: SIMD3<Float>?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Button(action: openEditor) {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3").frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name).font(.headline)
                            Text("\(preset.channels.count) channels · Edit preset")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }.frame(minHeight: 60).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.title3)
                    .frame(width: 60, height: 60)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                    .hoverEffect()
                    .onGeometryChange3D(for: SourceGeometry.self) { proxy in
                        SourceGeometry(transform: proxy.transform(in: .immersiveSpace),
                                       center: Point3D(x: proxy.size.width/2, y: proxy.size.height/2, z: proxy.size.depth/2))
                    } action: { geometry in
                        windowTransform = geometry.transform; sourcePoint = geometry.center
                        let point = geometry.transform.map { geometry.center.applying($0) }
                        model.presetDrag.registerSource(presetID: preset.id, point: point.map { [Float($0.x), Float($0.y), Float($0.z)] })
                        if let id = sessionID, var sample = model.presetDrag.session?.sample, let point {
                            sample.source = [Float(point.x), Float(point.y), Float(point.z)]
                            model.presetDrag.update(id, sample: sample, armed: false)
                        }
                    }
                    .gesture(SpatialEventGesture(coordinateSpace: .local)
                        .onChanged { events in events.forEach(receive) }
                        .onEnded { events in events.forEach(receive); if sessionID != nil { cancel() } })
                    .accessibilityLabel("Drag \(preset.name) to a fixture")
                    .accessibilityHint("Pinch and move toward a fixture. A solid line confirms the target. Release to apply. Use the Apply menu as an alternative.")
                Menu {
                    if model.fixtures.isEmpty { Text("Add a fixture first") }
                    ForEach(model.fixtures) { fixture in
                        Button("Apply to \(fixture.name)") { apply(to: fixture.id) }
                    }
                } label: {
                    Image(systemName: "arrow.up.right.circle").frame(width: 60, height: 60)
                }
                .accessibilityLabel("Apply \(preset.name) to fixture")
            }
            if model.presetDrag.session?.presetID == preset.id {
                let target = model.presetDrag.proposedFixtureID.flatMap { model.fixture($0) }
                Label(target.map { "Release to apply to \($0.name)" } ?? "Drag toward a fixture · release away to cancel",
                      systemImage: target == nil ? "hand.draw" : "scope")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Cancel drag", role: .cancel) { cancel() }.controlSize(.small)
            } else if let feedback = model.presetDrag.feedback, feedback.presetID == preset.id {
                Label(feedback.succeeded ? "Preset applied" : "Could not apply preset · \(model.message ?? "Try again")",
                      systemImage: feedback.succeeded ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            cancel()
            if model.presetDrag.session?.presetID == preset.id { model.endPresetDrag() }
            model.presetDrag.registerSource(presetID: preset.id, point: nil)
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { cancel() } }
        .onChange(of: model.roomLoadToken) { _, _ in cancel() }
    }

    private struct SourceGeometry: Equatable {
        var transform: AffineTransform3D?
        var center: Point3D
    }

    private func receive(_ event: SpatialEventCollection.Event) {
        if cancelledEventID == event.id {
            if event.phase != .active { cancelledEventID = nil }
            return
        }
        guard model.isImmersed, !model.libraryBusy, !model.isPickingRoom, !model.isTransformDragging,
              let transform = windowTransform else { cancel(); return }
        guard eventID == nil || eventID == event.id else { return }
        func converted(_ point: Point3D) -> SIMD3<Float> {
            let value = point.applying(transform)
            return [Float(value.x), Float(value.y), Float(value.z)]
        }
        let cursor = converted(event.location3D)
        let sample = PresetDragState.Sample(
            source: converted(sourcePoint), cursor: cursor,
            hand: event.inputDevicePose.map { converted($0.pose3D.position) },
            rayOrigin: event.selectionRay.map { converted($0.origin) },
            rayPoint: event.selectionRay.map { converted($0.origin + $0.direction) })
        switch event.phase {
        case .active:
            if sessionID == nil {
                guard let id = model.presetDrag.begin(presetID: preset.id, sample: sample) else { return }
                sessionID = id; eventID = event.id; initialCursor = cursor
                model.beginPresetDrag(preset.id)
            }
            guard let id = sessionID else { return }
            // Twelve SwiftUI points is a movement threshold, not a guessed
            // physical coordinate conversion. The renderer works in meters.
            let delta = cursor - (initialCursor ?? cursor)
            let moved = sqrt(delta.x*delta.x + delta.y*delta.y + delta.z*delta.z) >= 12
            model.presetDrag.update(id, sample: sample, armed: moved)
        case .ended:
            if let id = sessionID {
                model.presetDrag.update(id, sample: sample, armed: false)
                model.presetDrag.release(id)
            }
            sessionID = nil; eventID = nil; initialCursor = nil
        case .cancelled:
            cancel()
        @unknown default:
            cancel()
        }
    }

    private func cancel() {
        if let eventID { cancelledEventID = eventID }
        if let id = sessionID, model.presetDrag.session?.id == id { model.endPresetDrag() }
        sessionID = nil; eventID = nil; initialCursor = nil
    }

    private func apply(to fixtureID: UUID) {
        let succeeded = model.applyPreset(preset.id, to: fixtureID)
        model.presetDrag.showFeedback(presetID: preset.id, fixtureID: fixtureID, succeeded: succeeded)
    }
}
