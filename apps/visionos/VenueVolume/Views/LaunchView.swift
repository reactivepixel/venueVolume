import SwiftUI
import VenueVolumeCore

struct LaunchView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var placementDecisionID: UUID?
    @State private var confirmingPlacement = false

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
            if let message = model.placementLinkMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Fixture placement handoff", systemImage: "visionpro").font(.headline)
                    Text(message).fixedSize(horizontal: false, vertical: true)
                    if let request = model.pendingFixturePlacement {
                        if !request.prepared {
                            Button("Continue placement handoff") { Task { await openPlacement(request.id) } }
                                .disabled(model.libraryBusy || model.isTransitioning)
                        }
                        Button("Cancel placement handoff", role: .cancel) {
                            if let token = request.roomToken { model.cancelRequestedRoom(token) }
                            model.cancelPlacementHandoff(request.id, message: "Placement handoff cancelled.")
                        }
                    }
                }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        .task(id: model.pendingFixturePlacement?.id) {
            guard let id = model.pendingFixturePlacement?.id else { return }
            await model.prepareLibrary()
            guard !Task.isCancelled, model.pendingFixturePlacement?.id == id else { return }
            await openPlacement(id)
        }
        .confirmationDialog("Save changes before opening this Load Out?", isPresented: $confirmingPlacement, titleVisibility: .visible) {
            Button("Save and open Load Out") {
                guard let id = placementDecisionID, model.pendingFixturePlacement?.id == id else { return }
                if model.saveSetup() { Task { await openPlacement(id, discardChanges: true) } }
            }
            Button("Discard changes and open Load Out", role: .destructive) {
                guard let id = placementDecisionID else { return }
                Task { await openPlacement(id, discardChanges: true) }
            }
            Button("Cancel", role: .cancel) {
                if let id = placementDecisionID { model.cancelPlacementHandoff(id, message: "Placement handoff cancelled.") }
            }
        } message: { Text("Your current fixture arrangement has unsaved changes.") }
        .task {
            await model.prepareLibrary()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--show-new-venue") { model.requestNewVenue() }
            #endif
            if model.consumeDemoAutoEntry() { await enter() }
        }
    }
    private func openPlacement(_ id: UUID, discardChanges: Bool = false) async {
        guard model.pendingFixturePlacement?.id == id else { return }
        confirmingPlacement = false
        switch model.preparePlacementHandoff(id, discardChanges: discardChanges) {
        case .failed: return
        case .needsSaveDecision: placementDecisionID = id; confirmingPlacement = true; return
        case .ready: break
        }
        if model.isImmersed { model.finishPlacementHandoffIfReady(); dismissWindow(id: "launch"); return }
        model.isTransitioning = true
        let roomToken = model.roomLoadToken
        defer { model.isTransitioning = false }
        switch await openSpace(id: "VenueSpace") {
        case .opened: model.isImmersed = true; model.finishPlacementHandoffIfReady()
        case .userCancelled:
            model.cancelRequestedRoom(roomToken)
            model.cancelPlacementHandoff(id, message: "Opening the Load Out was cancelled. Open the link to try again.")
        case .error:
            model.cancelRequestedRoom(roomToken)
            model.cancelPlacementHandoff(id, message: "Vision Pro could not open the Load Out. Open the link to try again.")
        @unknown default:
            model.cancelRequestedRoom(roomToken)
            model.cancelPlacementHandoff(id, message: "Vision Pro could not open the Load Out.")
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
