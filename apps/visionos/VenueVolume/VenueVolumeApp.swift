import SwiftUI

@main
struct VenueVolumeApp: App {
    @State private var model = VenueModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "launch") {
            LaunchView()
                .environment(model)
                .onChange(of: scenePhase) { _, phase in if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() } }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 620)

        WindowGroup(id: "toolbox", for: UUID.self) { identity in
            ToolboxView(instanceID: identity.wrappedValue).environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 650)

        WindowGroup(id: "presets") {
            PresetEditorView().environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1040, height: 740)

        WindowGroup(id: "fixture-editor") { FixtureEditorView().environment(model) }
            .windowResizability(.contentSize)
            .defaultSize(width: 620, height: 760)

        WindowGroup(id: "diagnostics") {
            DebugPanel().environment(model)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .environment(model)
        }
        .immersionStyle(selection: .constant(.full), in: .full)

        ImmersiveSpace(id: "RoomScan") { RoomScanView().environment(model) }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
