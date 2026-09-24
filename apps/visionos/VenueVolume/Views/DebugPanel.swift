import SwiftUI

struct DebugPanel: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @State private var showRequest = false

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("VENUE VOLUME").font(.caption.weight(.bold)).tracking(2)
                Spacer()
                Text("DEBUG").font(.caption2.weight(.bold)).foregroundStyle(.cyan)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(model.fixtures.count)").font(.system(size: 38, weight: .medium, design: .rounded)).monospacedDigit()
                Text("fixtures").foregroundStyle(.secondary)
                Spacer()
                Text("\(model.totalChannels) channels").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
            }
            Text(model.trackingStatus).font(.caption).foregroundStyle(.secondary)
            Button {
                model.isPlacing.toggle()
                model.expandedID = nil
            } label: {
                Label(model.isPlacing ? "Cancel placement" : "Place fixture", systemImage: model.isPlacing ? "xmark" : "plus")
                    .frame(maxWidth: .infinity)
            }.disabled(!model.canPlace && !model.isPlacing)
            if model.isPlacing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Look at the grid and pinch.").font(.callout)
                    HStack {
                        Text("Distance").font(.caption)
                        Slider(value: $model.placementDistance, in: 0.75...4, step: 0.25)
                            .accessibilityLabel("Placement distance in meters")
                        Text(String(format: "%.2f m", model.placementDistance)).font(.caption.monospacedDigit()).frame(width: 60)
                    }
                }
            }
            if let selectedID = model.selectedID, let fixture = model.fixture(selectedID) {
                Button {
                    model.expandedID = selectedID
                    model.isPlacing = false
                } label: { Label("Configure \(fixture.name)", systemImage: "slider.horizontal.3").lineLimit(1) }
            }
            if let message = model.message {
                Text(message).font(.caption).foregroundStyle(.orange)
            }
            Divider()
            HStack {
                Text("Mock API").font(.headline)
                Spacer()
                Text(model.hasUnsyncedChanges ? "Unsynced" : "Synced")
                    .font(.caption).foregroundStyle(model.hasUnsyncedChanges ? Color.secondary : Color.cyan)
            }
            Button {
                Task { await model.sync() }
            } label: {
                HStack {
                    if model.isSyncing { ProgressView().controlSize(.small) }
                    Label(model.isSyncing ? "Syncing…" : "Sync all configurations", systemImage: "arrow.triangle.2.circlepath")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).disabled(model.isSyncing)
            Text(model.syncStatus).font(.caption).foregroundStyle(model.syncFailed ? Color.orange : Color.secondary)
            Toggle("Simulate API failure", isOn: $model.simulateSyncFailure).font(.caption).disabled(model.isSyncing)
            DisclosureGroup("Last request · POST", isExpanded: $showRequest) {
                ScrollView {
                    Text(model.lastRequestJSON.isEmpty ? "Sync to inspect the full request." : model.lastRequestJSON)
                        .font(.system(size: 11, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }.frame(height: 130)
            }.font(.caption)
            HStack {
                Text("Local mock · no DMX output").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button("Leave") { Task { await dismissSpace() } }.font(.caption)
            }
        }
        .padding(24).frame(width: 360)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
        .animation(.easeInOut(duration: 0.2), value: model.isPlacing)
    }
}
