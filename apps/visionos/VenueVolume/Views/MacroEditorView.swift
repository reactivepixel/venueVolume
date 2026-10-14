import SwiftUI
import VenueVolumeCore

struct MacroEditorView: View {
    var seed: ProgrammingMacro? = nil
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ProgrammingMacro(name: "New macro")
    @State private var stored: ProgrammingMacro?
    @State private var pending: ProgrammingMacro?
    @State private var confirmDiscard = false
    private var dirty: Bool { stored != draft }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Recall saved palettes in order. Each run uses one fixture target and can be undone in one action.").foregroundStyle(.secondary)
                    HStack {
                        Menu("Macro pool") {
                            ForEach(model.programmingMacros) { macro in Button(macro.name) { navigate(macro) } }
                        }
                        Button("New macro", systemImage: "plus") { navigate(ProgrammingMacro(name: "New macro")) }
                        Spacer()
                        Text(dirty ? "Unsaved changes" : "Stored").foregroundStyle(.secondary)
                    }
                    TextField("Macro name", text: $draft.name).textFieldStyle(.roundedBorder)
                    Picker("Target", selection: $draft.target) {
                        Text("Current selection · \(model.selectedFixtures.count) fixtures").tag(MacroTarget.currentSelection)
                        ForEach(model.macroGroups, id: \.id) { group in Text(group.name).tag(MacroTarget.group(group.id)) }
                        if case .group(let id) = draft.target, !model.macroGroups.contains(where: { $0.id == id }) {
                            Text("Missing group").tag(draft.target)
                        }
                    }
                    Text("Actions").font(.title2.bold())
                    ForEach(draft.lines.indices, id: \.self) { index in
                        HStack(spacing: 16) {
                            Toggle("Enable action \(index + 1)", isOn: $draft.lines[index].enabled).labelsHidden()
                            Text("\(index + 1)").monospacedDigit()
                            Picker("Apply palette", selection: $draft.lines[index].paletteID) {
                                Text("Choose palette").tag(nil as UUID?)
                                ForEach(model.presets) { palette in Text(palette.name).tag(Optional(palette.id)) }
                                if let id = draft.lines[index].paletteID, !model.presets.contains(where: { $0.id == id }) {
                                    Text("Missing palette").tag(Optional(id))
                                }
                            }
                            Spacer()
                            Button { draft.lines.swapAt(index, index - 1) } label: { Image(systemName: "arrow.up") }
                                .disabled(index == 0).accessibilityLabel("Move action \(index + 1) up")
                            Button { draft.lines.remove(at: index) } label: { Image(systemName: "minus.circle") }
                                .disabled(draft.lines.count == 1).accessibilityLabel("Remove action \(index + 1)")
                        }.frame(minHeight: 60)
                    }
                    Button("Add action", systemImage: "plus") { draft.lines.append(.init()) }.disabled(draft.lines.count >= 32)
                    Divider()
                    Text(model.inspectMacro(draft)).fixedSize(horizontal: false, vertical: true)
                    if let message = model.macroMessage { Text(message).foregroundStyle(.secondary) }
                    HStack {
                        Button("Validate") { model.macroMessage = model.inspectMacro(draft) }
                        Button("Store macro") { if model.storeMacro(draft) { stored = draft } }.disabled(draft.validationIssue != nil)
                        Spacer()
                        Button("Run macro") { _ = model.runMacro(draft) }
                            .buttonStyle(.borderedProminent).disabled(dirty || !model.canRunMacro(draft))
                    }
                }.padding(28)
            }
            .navigationTitle("Macros")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { if dirty { pending = nil; confirmDiscard = true } else { dismiss() } } } }
            .confirmationDialog("Store your macro changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Store and continue") { if model.storeMacro(draft) { finishNavigation() } }
                    .disabled(draft.validationIssue != nil)
                Button("Discard changes", role: .destructive) { finishNavigation() }
                Button("Keep editing", role: .cancel) { pending = nil }
            }
            .onAppear { if let seed { draft = seed; stored = nil } else if let first = model.programmingMacros.first { draft = first; stored = first } }
        }.frame(minWidth: 860, idealWidth: 960, minHeight: 650)
            .interactiveDismissDisabled(dirty)
    }
    private func navigate(_ macro: ProgrammingMacro) {
        if dirty { pending = macro; confirmDiscard = true }
        else { draft = macro; stored = model.programmingMacros.first { $0.id == macro.id } }
    }
    private func finishNavigation() {
        if let next = pending { draft = next; stored = model.programmingMacros.first { $0.id == next.id }; pending = nil }
        else { dismiss() }
    }
}
