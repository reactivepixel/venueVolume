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
                            Button("Aim head (DMX)") { model.beginRetarget(id, method: .head); dismissWindow(id: "presets") }
                            Button("Aim mount") { model.beginRetarget(id, method: .mount); dismissWindow(id: "presets") }
                        }.disabled(fixture.assetID == nil)
                    }.disabled(!model.canPlace)
                    Text("Position · room meters").font(.caption).foregroundStyle(.secondary)
                    axis("X · left / right", value: fixture.position.x, range: 0.23...(room.bounds.max[0]-0.23), fixture: fixture) { $0.x = $1 }
                    axis("Y · base height", value: fixture.position.y, range: 0...(room.bounds.max[1]-LightingPreview.height), fixture: fixture) { $0.y = $1 }
                    axis("Z · front / back", value: fixture.position.z, range: (room.bounds.min[2]+0.23)...(-0.23), fixture: fixture) { $0.z = $1 }
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
            }), in: axis == 1 ? -89...89 : -180...180, step: 1).accessibilityLabel("Mount \(title)")
        }
    }

    private func axis(_ name: String, value: Float, range: ClosedRange<Float>, fixture: Fixture,
                      set: @escaping (inout Position3D, Float) -> Void) -> some View {
        VStack(spacing: 4) {
            HStack { Text(name); Spacer(); Text(String(format: "%.2f m", value)).monospacedDigit() }
            Slider(value: Binding(get: { value }, set: { next in
                guard let current = model.fixture(fixture.id) else { return }
                var position = current.position; set(&position, next)
                model.moveFixture(fixture.id, position: position, yawDegrees: model.yawDegrees(for: current))
            }), in: range, step: 0.01).accessibilityLabel(name)
        }
    }
}
