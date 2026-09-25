import SwiftUI

@main
struct VenueVolumeApp: App {
    @State private var model = VenueModel()

    var body: some Scene {
        WindowGroup(id: "launch") {
            LaunchView()
                .environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 620)

        WindowGroup(id: "presets") {
            PresetEditorView().environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1040, height: 740)
        .defaultWindowPlacement { _, _ in WindowPlacement(.utilityPanel) }

        WindowGroup(id: "diagnostics") {
            DebugPanel().environment(model)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .environment(model)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
