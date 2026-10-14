import SwiftUI

/// Room tools live off the context bar; wrist recall always returns to the Toolbox.
struct RoomPlacementView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Room placement").font(.largeTitle.bold())
                    Spacer()
                    Button("Done") { dismissWindow(id: "room-placement") }
                }
                HStack(spacing: 20) {
                    Button("Palm Map", systemImage: "map") { model.togglePalmMap() }
                        .disabled(!model.canPlace || !model.isImmersed)
                    Button("Return to spawn", systemImage: "location") { model.resetViewerToSpawn() }
                }
                Text("Use Palm Map to choose your position in the room.").foregroundStyle(.secondary)
                DisclosureGroup("Viewpoint controls") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                        Button("Forward") { model.stepViewer(offset: [0,0,-0.5]) }
                        Button("Backward") { model.stepViewer(offset: [0,0,0.5]) }
                        Button("Left") { model.stepViewer(offset: [-0.5,0,0]) }
                        Button("Right") { model.stepViewer(offset: [0.5,0,0]) }
                        Button("Up") { model.stepViewer(offset: [0,0.5,0]) }
                        Button("Down") { model.stepViewer(offset: [0,-0.5,0]) }
                        Button("Turn left") { model.stepViewer(yaw: 15) }
                        Button("Turn right") { model.stepViewer(yaw: -15) }
                    }.padding(.top, 16)
                }
                HStack(spacing: 20) {
                    Toggle("White model", isOn: $model.whiteRoom).toggleStyle(.button)
                    Toggle("Blackout", isOn: $model.blackout).toggleStyle(.button)
                    VStack(alignment: .leading) {
                        Text("Room light")
                        Slider(value: $model.houseLight, in: 0...1, onEditingChanged: { editing in
                            if editing { model.beginHistoryAction("Adjust room light") } else { model.endHistoryAction() }
                        }).accessibilityLabel("Room light")
                    }
                }
                Divider()
                RoomLibraryView()
            }.padding(28)
        }.frame(minWidth: 680, minHeight: 600)
        .sheet(isPresented: $model.newVenuePresented) { NewVenueSheet().environment(model) }
        .onChange(of: model.isImmersed) { _, immersed in if !immersed { dismissWindow(id: "room-placement") } }
    }
}
