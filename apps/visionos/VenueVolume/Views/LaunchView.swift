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
                    Text("White room.\nLive light.").font(.system(size: 44, weight: .semibold, design: .rounded))
                }
                Spacer()
                Image(systemName: "cube.transparent").font(.system(size: 76, weight: .ultraLight)).foregroundStyle(.cyan)
                    .accessibilityHidden(true)
            }
            Text("Start in the white classroom, import a room, or scan with Vision Pro. Save independent fixture setups and reopen them from the wrist toolbox.")
                .foregroundStyle(.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                Label("Raise your left palm to reveal the toolbox", systemImage: "hand.raised")
                Label("Drag fixtures into the room and presets onto fixtures", systemImage: "cube")
                Label("Open Rooms & saved setups to import, scan, save and load", systemImage: "square.stack.3d.up")
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
            Text("Classroom dimensions are estimated · Placements saved locally · No physical DMX output")
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

/// A companion window may be restored without the launch window after a relaunch.
/// Keep room entry reachable from those windows and let the demo resume there too.
struct VenueEntryButton: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    var body: some View {
        Button("Enter venue", systemImage: "viewfinder") { Task { await enter() } }
            .disabled(model.isTransitioning)
            .task { if model.consumeDemoAutoEntry() { await enter() } }
    }
    private func enter() async {
        guard !model.isImmersed, !model.isTransitioning else { return }
        model.isTransitioning = true
        defer { model.isTransitioning = false }
        switch await openSpace(id: "VenueSpace") {
        case .opened: model.isImmersed = true
        case .userCancelled: break
        case .error: model.message = "The room could not open. Choose Enter venue to retry."
        @unknown default: model.message = "The system could not open the room."
        }
    }
}
