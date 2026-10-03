import SwiftUI

@main
struct VenueVolumeApp: App {
    @State private var model = VenueModel()
    @State private var venueImmersion: ImmersionStyle = .progressive(0...1, initialAmount: 1)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "launch") {
            LaunchView()
                .environment(model).auditTextSize().controlSize(.large)
                .onChange(of: scenePhase) { _, phase in if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() } }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 680, height: 700)

        WindowGroup(id: "toolbox", for: UUID.self) { identity in
            ToolboxView(instanceID: identity.wrappedValue).environment(model).auditTextSize().controlSize(.large)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 860)

        WindowGroup(id: "presets", for: UUID.self) { identity in
            PresetEditorView(instanceID: identity.wrappedValue).environment(model).auditTextSize().controlSize(.large)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 820)

        WindowGroup(id: "fixture-editor", for: String.self) { _ in FixtureEditorView().environment(model).auditTextSize().controlSize(.large) } defaultValue: { "selection" }
            .windowResizability(.contentMinSize)
            .defaultSize(width: 620, height: 760)

        WindowGroup(id: "venue-controls", for: String.self) { _ in
            VenueControlsView().environment(model).auditTextSize().controlSize(.large)
        } defaultValue: { "controls" }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 620, height: 480)

        WindowGroup(id: "diagnostics") {
            DebugPanel().environment(model).auditTextSize().controlSize(.large)
        }
        .windowResizability(.contentMinSize)

        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .environment(model).auditTextSize().controlSize(.large)
        }
        // visionOS owns Digital Crown input and smoothly reveals passthrough.
        .immersionStyle(selection: $venueImmersion, in: .progressive(0...1, initialAmount: 1))

        ImmersiveSpace(id: "RoomScan") { RoomScanView().environment(model).auditTextSize().controlSize(.large) }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
