import SwiftUI
import VenueVolumeCore

/// Transform controls live on the object; DMX sliders stay in the preset editor.
struct FixturePlacementView: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        if let id = model.selectedID, let fixture = model.fixture(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(fixture.name).font(.title2.weight(.semibold))
                    Text("Transform in the scene").font(.headline)
                    @Bindable var model = model
                    Picker("Axis control", selection: $model.transformMode) {
                        ForEach(FixtureTransformMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                    }.pickerStyle(.segmented).disabled(model.isTransformDragging)
                    HStack(spacing: 24) {
                        Label("X", systemImage: "circle.fill").foregroundStyle(.red)
                        Label("Y", systemImage: "circle.fill").foregroundStyle(.green)
                        Label("Z", systemImage: "circle.fill").foregroundStyle(.blue)
                    }.font(.headline)
                    Text(model.transformMode == .rotate
                         ? "Look at a colored ring, then hold and drag around it to rotate the mount on that axis."
                         : "Look at a colored arrow handle, then hold and drag to move along that axis.")
                    Button(model.gizmoVisible ? "Hide axis controls" : "Show axis controls", systemImage: "rotate.3d") {
                        if model.gizmoVisible { model.endTransformDrag(); model.gizmoVisible = false }
                        else { model.beginTransform(id) }
                    }.disabled(!model.canPlace)
                    Text("Release to finish. Each gesture is one Undo step. Mount transforms preserve the fixture's DMX values.")
                        .font(.caption).foregroundStyle(.secondary)
                    Divider()
                    LabeledContent("Position · meters", value: String(format: "%.2f, %.2f, %.2f", fixture.position.x, fixture.position.y, fixture.position.z))
                    let angles = FixtureAiming.angles(fixture.orientation)
                    LabeledContent("Yaw / pitch / roll", value: String(format: "%.0f° / %.0f° / %.0f°", angles.yaw, angles.pitch, angles.roll))
                    HStack {
                        Button("Reposition on surface") { model.beginReposition(id) }
                        Button("Upright mount") { model.transformFixture(id, position: fixture.position, yaw: 0, pitch: 0, roll: 0) }
                    }.disabled(!model.canPlace)
                    if let asset = fixture.asset, !asset.joints.isEmpty {
                        Divider()
                        Text("Moving parts").font(.headline)
                        ForEach(asset.joints) { joint in
                            VStack(alignment: .leading, spacing: 6) {
                                let current = joint.value(channels: model.fixture(id)?.channels ?? fixture.channels)
                                LabeledContent(joint.label, value: String(format: joint.continuous ? "%.0f°/s" : "%.0f°", current))
                                Slider(value: Binding(get: {
                                    Double(joint.value(channels: model.fixture(id)?.channels ?? fixture.channels))
                                }, set: { model.setJoint(id, jointID: joint.id, value: Float($0)) }),
                                    in: joint.continuous ? 0...Double(joint.travel) : Double(joint.range.lowerBound)...Double(joint.range.upperBound),
                                    onEditingChanged: { editing in
                                        if editing { model.beginHistoryAction("Adjust \(joint.label)") } else { model.endHistoryAction() }
                                    }).accessibilityLabel(joint.label)
                            }
                        }
                        Button("Use preset motion") { model.resetAim(id) }
                            .disabled(fixture.aimOverride == nil && fixture.jointOverrides == nil)
                    }
                    if let asset = fixture.asset, !asset.emitters.isEmpty {
                        Divider()
                        Text("Light targeting").font(.headline)
                        Text("Retarget saves Pan/Tilt into the assigned preset and updates its fixtures. Cancel restores the previous look.")
                        Button("Retarget DMX", systemImage: "scope") { model.beginRetarget(id) }
                            .disabled(!model.canPlace || !asset.headAim)
                    }
                    if let message = model.message { Text(message).font(.caption).foregroundStyle(.orange) }
                }.padding(.trailing, 4)
            }
        } else {
            ContentUnavailableView("Select a fixture", systemImage: "rotate.3d",
                description: Text("Select an object in the scene or wrist toolbox to show its axes."))
        }
    }
}
