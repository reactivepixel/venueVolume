import SwiftUI

/// Attach to every window so warm links work even when the launch window closed.
private struct PlacementLinkReceiver: ViewModifier {
    @Environment(VenueModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    func body(content: Content) -> some View {
        content.onOpenURL { url in
            model.receivePlacementLink(url)
            openWindow(id: "launch")
        }
    }
}
extension View {
    func placementLinkReceiver() -> some View { modifier(PlacementLinkReceiver()) }
}
