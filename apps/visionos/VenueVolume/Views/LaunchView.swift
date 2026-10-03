import SwiftUI
import VenueVolumeCore

struct LaunchView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace

    @ScaledMetric(relativeTo: .body) private var pickerHeight = 340.0

    var body: some View {
        @Bindable var model = model
        ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("VENUE VOLUME").font(.caption.weight(.bold)).tracking(3).foregroundStyle(.cyan)
                    Text("Your venues").font(.largeTitle.bold())
                }
                Spacer()
                Image(systemName: "cube.transparent").font(.system(size: 48, weight: .light)).foregroundStyle(.cyan).accessibilityHidden(true)
            }
            Text("Open a recent save, load a shared save, or start with a blank venue.")
                .foregroundStyle(.secondary)
            VenueLibraryPicker(showsNewVenues: false).frame(height: pickerHeight)
            if model.canResumeVenue {
                Button {
                    Task { if model.isImmersed { await dismissSpace(); model.isImmersed = false } else { await enter() } }
                } label: {
                    Label(model.isImmersed ? "Leave venue" : "Resume current venue", systemImage: model.isImmersed ? "arrow.down.right.and.arrow.up.left" : "viewfinder")
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                }.disabled(model.isTransitioning || model.libraryBusy)
            }
            Text("Turn your left hand toward you to open the wrist menu. Placements stay on this device until you export a save.")
                .font(.caption).foregroundStyle(.secondary)
            Text("Estimated venue dimensions · No physical DMX output").font(.caption).foregroundStyle(.secondary)
        }
        .padding(32)
        }.frame(minWidth: 680, minHeight: 700)
        .sheet(isPresented: Binding(get: { model.newVenuePresented && !model.isImmersed }, set: { model.newVenuePresented = $0 })) { NewVenueSheet() }
        .presetEditorPresenter(when: !model.isImmersed)
        .task {
            await model.prepareLibrary()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--show-new-venue") { model.requestNewVenue() }
            #endif
            if model.consumeDemoAutoEntry() { await enter() }
        }
    }
    private func enter() async {
        guard !model.isImmersed, !model.isTransitioning else { return }
        model.isTransitioning = true
        defer { model.isTransitioning = false }
        switch await openSpace(id: "VenueSpace") {
        case .opened: model.isImmersed = true
        case .userCancelled: break
        case .error: model.message = "The venue could not open. Try again."
        @unknown default: model.message = "The system could not open the venue."
        }
    }
}

/// A companion window may be restored without the launch window after a relaunch.
/// Keep room entry reachable from those windows and let the demo resume there too.
struct VenueEntryButton: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button(model.isDemoMode ? "Enter venue" : "Choose venue", systemImage: "viewfinder") {
            if model.isDemoMode { Task { await enter() } }
            else { openWindow(id: "launch") }
        }
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
