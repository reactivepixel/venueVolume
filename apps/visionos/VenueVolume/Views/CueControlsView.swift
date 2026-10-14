import SwiftUI
import VenueVolumeCore

struct CueControlsView: View {
    @Environment(VenueModel.self) private var model
    @State private var showingCues = false
    var body: some View {
        HStack(spacing: 10) {
            Button { model.stepCue(-1) } label: { Image(systemName: "backward.end.fill").frame(width: 60, height: 60) }
                .accessibilityLabel("Previous cue").disabled(model.currentCue == 1 || model.isRetargeting)
            Button { showingCues = true } label: {
                VStack(spacing: 2) { Text("Cue").font(.caption); Text(model.currentCueLabel).font(.title2.monospacedDigit().bold()) }.frame(minWidth: 72, minHeight: 60)
            }.accessibilityLabel("Cue \(model.currentCueLabel), choose cue")
                .popover(isPresented: $showingCues) {
                    CueList(current: model.currentCue, selected: model.currentCue) { number in model.selectCue(number); showingCues = false }
                        .frame(width: 370, height: 540)
                }
            Button { model.stepCue(1) } label: { Image(systemName: "forward.end.fill").frame(width: 60, height: 60) }
                .accessibilityLabel("Next cue").disabled(model.currentCue == 255 || model.isRetargeting)
        }.disabled(model.libraryBusy || model.tourPreview != nil)
    }
}

private struct CueList: View {
    @Environment(VenueModel.self) private var model
    let current: Int
    let selected: Int
    let select: (Int) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cues 01–255").font(.title2.bold()).padding(.horizontal, 22).padding(.top, 22)
            Text("Current cue \(CueSheet.label(current))").foregroundStyle(.secondary).padding(.horizontal, 22)
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(CueSheet.numbers), id: \.self) { number in
                            Button { select(number) } label: {
                                HStack(spacing: 16) {
                                    Text(CueSheet.label(number)).font(.headline.monospacedDigit()).frame(width: 48)
                                    Text(number == current ? "Current" : model.cueSheet.hasChanges(at: number) ? "Recorded" : "Tracking")
                                        .font(.callout).foregroundStyle(.secondary)
                                    Spacer()
                                    if number == selected { Image(systemName: "checkmark") }
                                }.padding(.horizontal, 16).frame(minHeight: 60).contentShape(.rect)
                            }.buttonStyle(.plain)
                                .background(number == current ? Color.accentColor.opacity(0.24) : number == selected ? Color.white.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 14))
                                .hoverEffect(.highlight)
                                .accessibilityLabel("Cue \(CueSheet.label(number))\(number == current ? ", current" : "")")
                                .accessibilityAddTraits(number == current ? .isSelected : [])
                                .id(number)
                        }
                    }.padding(.horizontal, 14)
                }.onAppear { reader.scrollTo(selected, anchor: .center) }
            }
        }
    }
}

struct SaveCueSheet: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var destination: Int
    init(current: Int) { _destination = State(initialValue: current) }
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text("Save to a specific cue").font(.title2.bold()); Spacer(); Button("Cancel") { dismiss() } }.padding([.top, .horizontal], 24)
            Text("\(model.selectedFixtures.count) fixtures · \(model.presetDraft.name)").foregroundStyle(.secondary)
            CueList(current: model.currentCue, selected: destination) { destination = $0 }
            Button("Save to cue \(CueSheet.label(destination))") { if model.saveCue(number: destination) { dismiss() } }
                .buttonStyle(.borderedProminent).frame(minHeight: 60).padding(.bottom, 24)
        }.frame(width: 500, height: 680)
    }
}
