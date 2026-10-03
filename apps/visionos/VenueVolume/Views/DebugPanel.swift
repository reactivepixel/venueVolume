import SwiftUI
import VenueVolumeCore

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
            if !model.isImmersed { VenueEntryButton() }
            Text(model.environmentStatus).font(.headline)
            Text(model.fixtureAssetStatus).font(.caption).foregroundStyle(.secondary)
            Text(model.persistenceStatus).font(.caption).foregroundStyle(.secondary)
            Picker("Shadow beam budget", selection: $model.requestedLightLimit) {
                ForEach(LightingBudget.options, id: \.self) { count in Text("\(count)").tag(count) }
            }.disabled(model.lightingBenchmark != nil)
            Text("Active budget: \(model.effectiveLightLimit) · \(model.lightingThermal.rawValue)")
                .font(.caption)
            Text("Above 8 is experimental; profile on your headset. All active beams cast shadows.")
                .font(.caption2).foregroundStyle(.secondary)
            if model.lightingBenchmark != nil {
                Text(model.lightingBenchmarkStatus.isEmpty ? "Benchmark warms for 5 seconds after entering, then records update cadence." : model.lightingBenchmarkStatus)
                    .font(.caption)
                if !model.lightingBenchmarkJSON.isEmpty {
                    ShareLink("Share benchmark JSON", item: model.lightingBenchmarkJSON)
                }
            }
            Text(model.trackingStatus).font(.caption).foregroundStyle(.secondary)
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
