import SwiftUI

@main
struct VenueVolumeApp: App {
    @State private var model = VenueModel()
    @State private var venueImmersion: ImmersionStyle = .progressive(0...1, initialAmount: 1)
    @State private var immersionBeforeNavigation: ImmersionStyle?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "launch") {
            LaunchView()
                .placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
                .onChange(of: scenePhase) { _, phase in if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() } }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 680, height: 700)

        WindowGroup(id: "toolbox", for: UUID.self) { identity in
            ToolboxView(instanceID: identity.wrappedValue).placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 860)

        WindowGroup(id: "presets", for: UUID.self) { identity in
            PresetEditorView(instanceID: identity.wrappedValue).placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
                .frame(minWidth: 680, minHeight: 500)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 820)

        WindowGroup(id: "fixture-editor", for: String.self) { _ in FixtureEditorView().placementLinkReceiver().environment(model).auditTextSize().controlSize(.large) } defaultValue: { "selection" }
            .windowResizability(.contentMinSize)
            .defaultSize(width: 620, height: 760)

        WindowGroup(id: "venue-controls", for: String.self) { _ in
            VenueControlsView().placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
        } defaultValue: { "controls" }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 620, height: 480)

        WindowGroup(id: "diagnostics") {
            DebugPanel().placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
        }
        .windowResizability(.contentMinSize)

        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .placementLinkReceiver().environment(model).auditTextSize().controlSize(.large)
                .onChange(of: model.navigationBlackoutActive) { _, active in
                    if active {
                        immersionBeforeNavigation = venueImmersion
                        venueImmersion = .full
                    } else if let previous = immersionBeforeNavigation {
                        venueImmersion = previous
                        immersionBeforeNavigation = nil
                    }
                }
                .onDisappear {
                    if let previous = immersionBeforeNavigation { venueImmersion = previous }
                    immersionBeforeNavigation = nil
                }
        }
        // Full immersion lets the head-anchored cover mask a navigation change even
        // when the user has reduced the progressive portal using the Digital Crown.
        // Restore their selected style after the fade completes.
        .immersionStyle(selection: $venueImmersion, in: .progressive(0...1, initialAmount: 1), .full)

        ImmersiveSpace(id: "RoomScan") { RoomScanView().placementLinkReceiver().environment(model).auditTextSize().controlSize(.large) }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
