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

        ImmersiveSpace(id: "VenueSpace") {
            VenueSpaceView()
                .environment(model)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
