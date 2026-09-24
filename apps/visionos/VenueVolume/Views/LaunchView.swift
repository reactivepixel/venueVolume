import SwiftUI

struct LaunchView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VENUE VOLUME").font(.caption.weight(.bold)).tracking(3).foregroundStyle(.cyan)
                    Text("Your space.\nYour fixtures.").font(.system(size: 44, weight: .semibold, design: .rounded))
                }
                Spacer()
                Image(systemName: "cube.transparent").font(.system(size: 76, weight: .ultraLight)).foregroundStyle(.cyan)
                    .accessibilityHidden(true)
            }
            Text("Place virtual DMX fixtures in the room, shape their channels, and sync a complete mock configuration.")
                .foregroundStyle(.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                Label("Place fixture → look at the grid → pinch", systemImage: "scope")
                Label("Select a cube to highlight its fixture", systemImage: "cube")
                Label("Double-select its name to open DMX controls", systemImage: "slider.horizontal.3")
            }
            HStack {
                Text("\(model.fixtures.count) fixtures · \(model.totalChannels) channels").monospacedDigit()
                Spacer()
                Text("MOCK OUTPUT").font(.caption.weight(.semibold)).foregroundStyle(.cyan)
            }
            Spacer(minLength: 0)
            if let message = model.message {
                Text(message).font(.callout).foregroundStyle(.orange)
            }
            Button {
                Task { await toggleSpace() }
            } label: {
                Label(model.isImmersed ? "Leave venue" : "Enter venue", systemImage: model.isImmersed ? "arrow.down.right.and.arrow.up.left" : "viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isTransitioning)
            Text("Session-only prototype · Generic 8-bit channels · No physical lighting output")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(36)
        .frame(width: 620, height: 620)
        .task {
            if model.consumeDemoAutoEntry() {
                await toggleSpace()
            }
        }
    }

    @MainActor private func toggleSpace() async {
        model.isTransitioning = true
        model.message = nil
        defer { model.isTransitioning = false }
        if model.isImmersed {
            await dismissSpace()
            model.isImmersed = false
        } else {
            switch await openSpace(id: "VenueSpace") {
            case .opened: model.isImmersed = true
            case .userCancelled: break
            case .error: model.message = "The venue could not open. Try entering again."
            @unknown default: model.message = "The system could not open the venue."
            }
        }
    }
}
