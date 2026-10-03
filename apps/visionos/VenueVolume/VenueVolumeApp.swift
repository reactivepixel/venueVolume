import SwiftUI

@main
struct VenueVolumeApp: App {
    @State private var model = VenueModel()
    @State private var venueImmersion: ImmersionStyle = .progressive(0...1, initialAmount: 1)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "launch") {
            LaunchView()
                .environment(model)
                .onChange(of: scenePhase) { _, phase in if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() } }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 700)

        WindowGroup(id: "toolbox", for: UUID.self) { identity in
            ToolboxView(instanceID: identity.wrappedValue).environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 820, height: 650)

        WindowGroup(id: "presets", for: UUID.self) { identity in
            PresetEditorView(instanceID: identity.wrappedValue).environment(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1040, height: 820)

        WindowGroup(id: "fixture-editor", for: String.self) { _ in FixtureEditorView().environment(model) } defaultValue: { "selection" }
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
        // visionOS owns Digital Crown input and smoothly reveals passthrough.
        .immersionStyle(selection: $venueImmersion, in: .progressive(0...1, initialAmount: 1))

        ImmersiveSpace(id: "RoomScan") { RoomScanView().environment(model) }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
