import SwiftUI

struct HistoryControls: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            Button("Undo", systemImage: "arrow.uturn.backward") { model.undo() }
                .disabled(!model.canUndo).keyboardShortcut("z", modifiers: .command)
                .help(model.history?.current.title ?? "Undo the previous change")
            Button("Redo", systemImage: "arrow.uturn.forward") { model.redo() }
                .disabled(!model.canRedo).keyboardShortcut("z", modifiers: [.command, .shift])
        }.font(.callout)
    }
}

struct AuditHistoryView: View {
    @Environment(VenueModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Audit history").font(.title3.weight(.semibold))
                Spacer()
                Text("\(model.history?.entries.count ?? 0) events").font(.caption).foregroundStyle(.secondary)
            }
            Text("Restore the state after an event. Editing after Undo creates a new branch; earlier events stay available.")
                .font(.caption).foregroundStyle(.secondary)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array((model.history?.entries ?? []).reversed())) { entry in
                        let current = model.history?.cursor == entry.nodeID
                        HStack(spacing: 12) {
                            Image(systemName: entry.kind == .external ? "arrow.up.right.square" : "clock.arrow.circlepath")
                                .foregroundStyle(current ? .cyan : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title).font(.callout.weight(.medium))
                                HStack {
                                    Text(entry.date, format: .dateTime.month().day().hour().minute().second())
                                    Text(entry.kind == .external ? "Logged action · no automatic replay" : (current ? "Current state" : "Saved state"))
                                }.font(.caption2).foregroundStyle(.secondary)
                                if entry.kind == .change, let state = model.history?.node(entry.nodeID)?.state {
                                    Text("\(state.rooms.first { $0.id == state.roomID }?.manifest.title ?? "Room") · \(state.fixtures.count) fixtures")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if entry.kind != .external {
                                Button("Restore") { model.restoreHistory(entry.nodeID) }
                                    .disabled(current || model.libraryBusy)
                                    .accessibilityLabel("Restore state after \(entry.title)")
                            }
                        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(current && entry.kind == .change ? Color.cyan.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            Text(model.historyMessage ?? "History is stored on this device. Restoring never resends a sync request.")
                .font(.caption).foregroundStyle(.secondary).lineLimit(3)
        }.frame(height: 410)
        .onAppear { model.flushHistoryEdits() }
    }
}
