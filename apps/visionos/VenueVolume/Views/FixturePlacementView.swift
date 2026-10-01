import SwiftUI
import VenueVolumeCore

struct FixturePlacementView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    var body: some View {
        if let id = model.selectedID, let fixture = model.fixture(id), let room = model.environment {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(fixture.name).font(.title2.weight(.semibold))
                    HStack {
                        Button("Reposition") { model.beginReposition(id); dismissWindow(id: "presets") }
                        Menu("Retarget", systemImage: "scope") {
                            Button("Aim head (preview)") { model.beginRetarget(id, method: .head); dismissWindow(id: "presets") }
                            Button("Aim mount") { model.beginRetarget(id, method: .mount); dismissWindow(id: "presets") }
                        }.disabled(fixture.assetID == nil)
                    }.disabled(!model.canPlace)
                    Text("Position · room meters").font(.caption).foregroundStyle(.secondary)
                    axis("X · left / right", value: fixture.position.x, range: bounded(room.bounds.min[0]+0.23, room.bounds.max[0]-0.23), fixture: fixture) { $0.x = $1 }
                    axis("Y · base height", value: fixture.position.y, range: bounded(0, room.bounds.max[1]-LightingPreview.height), fixture: fixture) { $0.y = $1 }
                    axis("Z · front / back", value: fixture.position.z, range: bounded(room.bounds.min[2]+0.23, room.bounds.max[2]-0.23), fixture: fixture) { $0.z = $1 }
                    if fixture.assetID == LightingPreview.assetID && fixture.channels.count >= 6 {
                        Divider()
                        Text("MOVING HEAD PILOT · ROGUE R1X SPOT")
                            .font(.caption.weight(.semibold)).foregroundStyle(.cyan)
                        Text("Aim this fixture's head. These VV Preview 16 controls animate the model and beam; they are not the manufacturer's DMX channels.")
                            .font(.caption).foregroundStyle(.secondary)
                        headAxis("Pan", axis: 0, fixture: fixture)
                        headAxis("Tilt", axis: 1, fixture: fixture)
                        Button("Use preset aim") { model.resetAim(id) }
                            .disabled(fixture.aimOverride == nil)
                    }
                    Divider()
                    Text("Mount orientation").font(.caption).foregroundStyle(.secondary)
                    rotation("Yaw", axis: 0, fixture: fixture)
                    rotation("Pitch", axis: 1, fixture: fixture)
                    rotation("Roll", axis: 2, fixture: fixture)
                    HStack {
                        Button("Move to floor") {
                            var position = fixture.position; position.y = 0
                            model.moveFixture(id, position: position, yawDegrees: model.yawDegrees(for: fixture))
                        }
                        Button("Upright mount") { model.transformFixture(id, position: fixture.position, yaw: 0, pitch: 0, roll: 0) }
                    }
                    Text("Aim head changes this fixture's pan/tilt override. Aim mount rotates the whole asset and preserves its DMX values.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let message = model.message { Text(message).font(.caption).foregroundStyle(.orange) }
                }
            }
        } else {
            ContentUnavailableView("Select a fixture", systemImage: "light.beacon.max", description: Text("Select an object in the room to change its transform or target."))
        }
    }

    private func headAxis(_ title: String, axis: Int, fixture: Fixture) -> some View {
        let preview = LightingPreview(channels: fixture.channels)
        let value = axis == 0 ? preview.panDegrees : preview.tiltDegrees
        let range = axis == 0 ? FixtureAiming.panRange : FixtureAiming.tiltRange
        return VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.1f°", value)).monospacedDigit()
            }
            Slider(value: Binding(get: { Double(value) }, set: { next in
                if axis == 0 { model.setHeadAim(fixture.id, panDegrees: Float(next)) }
                else { model.setHeadAim(fixture.id, tiltDegrees: Float(next)) }
            }), in: Double(range.lowerBound)...Double(range.upperBound), step: 1, onEditingChanged: { editing in
                if editing { model.beginHistoryAction("Aim moving head · \(title)") }
                else { model.endHistoryAction() }
            })
                .accessibilityLabel("Pilot head \(title)")
        }
    }

    private func rotation(_ title: String, axis: Int, fixture: Fixture) -> some View {
        let angles = FixtureAiming.angles(fixture.orientation)
        let value = [angles.yaw, angles.pitch, angles.roll][axis]
        return VStack(spacing: 4) {
            HStack { Text(title); Spacer(); Text(String(format: "%.0f°", value)).monospacedDigit() }
            Slider(value: Binding(get: { value }, set: { next in
                guard let current = model.fixture(fixture.id) else { return }
                let a = FixtureAiming.angles(current.orientation)
                model.transformFixture(fixture.id, position: current.position,
                                       yaw: axis == 0 ? next : a.yaw, pitch: axis == 1 ? next : a.pitch, roll: axis == 2 ? next : a.roll)
            }), in: axis == 1 ? -89...89 : -180...180, step: 1, onEditingChanged: { editing in
                if editing { model.beginHistoryAction("Rotate fixture · \(title)") } else { model.endHistoryAction() }
            }).accessibilityLabel("Mount \(title)")
        }
    }

    private func bounded(_ lower: Float, _ upper: Float) -> ClosedRange<Float> { lower...max(lower, upper) }

    private func axis(_ name: String, value: Float, range: ClosedRange<Float>, fixture: Fixture,
                      set: @escaping (inout Position3D, Float) -> Void) -> some View {
        VStack(spacing: 4) {
            HStack { Text(name); Spacer(); Text(String(format: "%.2f m", value)).monospacedDigit() }
            Slider(value: Binding(get: { value }, set: { next in
                guard let current = model.fixture(fixture.id) else { return }
                var position = current.position; set(&position, next)
                model.moveFixture(fixture.id, position: position, yawDegrees: model.yawDegrees(for: current))
            }), in: range, step: 0.01, onEditingChanged: { editing in
                if editing { model.beginHistoryAction("Move fixture · \(name)") } else { model.endHistoryAction() }
            }).accessibilityLabel(name)
        }
    }
}
