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
                .placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model)
                .onChange(of: scenePhase) { _, phase in if phase != .active { model.finishHistoryGesture(); model.flushHistoryEdits() } }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 680, height: 700)

        WindowGroup(id: "toolbox", for: UUID.self) { identity in
            ToolboxView(instanceID: identity.wrappedValue).placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 860)

        WindowGroup(id: "room-placement") {
            RoomPlacementView().placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 760)

        WindowGroup(id: "presets", for: UUID.self) { identity in
            PresetEditorView(instanceID: identity.wrappedValue).placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model)
                .frame(minWidth: 680, minHeight: 500)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1320, height: 1000)



        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model)
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

        ImmersiveSpace(id: "RoomScan") { RoomScanView().placementLinkReceiver().environment(model).controlSize(.large).navigationInputShield(model: model) }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
