import SwiftUI
import VenueVolumeCore

struct FixturePlacementView: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        if let id = model.selectedID, let fixture = model.fixture(id), let room = model.environment {
            VStack(alignment: .leading, spacing: 18) {
                Text(fixture.name).font(.title2.weight(.semibold))
                Text("Position in the white room").foregroundStyle(.secondary)
                axis("X · left / right", value: fixture.position.x, range: 0.23...(room.bounds.max[0]-0.23), fixture: fixture) { $0.x = $1 }
                axis("Y · base height", value: fixture.position.y, range: 0...(room.bounds.max[1]-LightingPreview.height), fixture: fixture) { $0.y = $1 }
                axis("Z · front / back", value: fixture.position.z, range: (room.bounds.min[2]+0.23)...(-0.23), fixture: fixture) { $0.z = $1 }
                HStack {
                    Text("Base rotation")
                    Spacer()
                    Text(String(format: "%.0f°", model.yawDegrees(for: fixture))).monospacedDigit()
                }
                Slider(value: Binding(get: { model.yawDegrees(for: model.fixture(id) ?? fixture) },
                                      set: { value in
                                          if let current = model.fixture(id) { model.moveFixture(id, position: current.position, yawDegrees: value) }
                                      }),
                       in: -180...180, step: 1).accessibilityLabel("Base rotation")
                HStack {
                    Button("Move to floor") {
                        var position = fixture.position; position.y = 0
                        model.moveFixture(id, position: position, yawDegrees: model.yawDegrees(for: fixture))
                    }
                    Spacer()
                    Text("Room meters · saved locally").font(.caption).foregroundStyle(.secondary)
                }
                Text("Pan and tilt aim the moving head in the DMX preset. Position and base rotation belong to this fixture.")
                    .font(.caption).foregroundStyle(.secondary)
                if let message = model.message { Text(message).font(.caption).foregroundStyle(.orange) }
                Spacer()
            }
        } else {
            ContentUnavailableView("Select a fixture", systemImage: "light.beacon.max", description: Text("Place a fixture from the toolbox, then select it to change its position."))
        }
    }

    private func axis(_ name: String, value: Float, range: ClosedRange<Float>, fixture: Fixture,
                      set: @escaping (inout Position3D, Float) -> Void) -> some View {
        VStack(spacing: 6) {
            HStack { Text(name); Spacer(); Text(String(format: "%.2f m", value)).monospacedDigit() }
            Slider(value: Binding(get: { value }, set: { next in
                guard let current = model.fixture(fixture.id) else { return }
                var position = current.position; set(&position, next)
                model.moveFixture(fixture.id, position: position, yawDegrees: model.yawDegrees(for: current))
            }), in: range, step: 0.01).accessibilityLabel(name)
        }
    }
}
