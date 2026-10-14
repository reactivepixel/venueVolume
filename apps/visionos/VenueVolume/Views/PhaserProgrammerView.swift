import SwiftUI
import VenueVolumeCore

struct PhaserProgrammerView: View {
    @Environment(VenueModel.self) private var model
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selectedStep = 0
    @State private var tapTempo = TapTempo()
    @State private var pendingPattern: DimmerPattern?
    @State private var replacingPattern = false
    private var phaser: Phaser? { model.presetDraft.phaser }
    private var compatibleSources: [DMXPreset] {
        model.presets.filter { $0.phaser == nil && $0.id != model.presetDraft.id && model.presetDraft.channelMask.isSubset(of: $0.channelMask) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                modeButton("Static", enabled: false)
                modeButton("Dynamic · Phaser", enabled: true)
            }.accessibilityElement(children: .contain).accessibilityLabel("Value mode")
            if let phaser {
                if model.presetDraft.channelMask == Set([0]) {
                    HStack(spacing: 16) {
                        Text("Pattern").font(.headline)
                        ForEach(DimmerPattern.allCases, id: \.self) { pattern in
                            Button(pattern.rawValue) { pendingPattern = pattern; replacingPattern = true }
                        }
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 28) { rhythm(phaser).frame(width: 330); Divider(); stepEditor(phaser).frame(minWidth: 300) }
                    VStack(alignment: .leading, spacing: 28) { rhythm(phaser); Divider(); stepEditor(phaser) }
                }
                DisclosureGroup("Timing & fixture distribution") {
                    VStack(alignment: .leading, spacing: 18) {
                        number("Speed (BPM)", value: phaser.beatsPerMinute, range: 1...600) { model.presetDraft.phaser?.beatsPerMinute = $0 }
                        number("Cycle length (beats)", value: phaser.measure, range: 0.25...64) { model.presetDraft.phaser?.measure = $0 }
                        number("Phase offset (°)", value: phaser.phaseDegrees, range: -360...360) { model.presetDraft.phaser?.phaseDegrees = $0 }
                        number("Fixture phase spread (°)", value: phaser.phaseSpreadDegrees, range: -360...360) { model.presetDraft.phaser?.phaseSpreadDegrees = $0 }
                        HStack {
                            Button("Together") { model.presetDraft.phaser?.phaseSpreadDegrees = 0 }
                            Button("Wave") { model.presetDraft.phaser?.phaseSpreadDegrees = 360 }
                            Button("Reverse") { model.presetDraft.phaser?.phaseSpreadDegrees = -360 }
                        }
                        Text("Fixtures follow their order in the room list. Step widths divide the chosen cycle length proportionally.").font(.caption).foregroundStyle(.secondary)
                    }.padding(.top, 16)
                }
            }
        }
        .onChange(of: model.presetDraft.id) { _, _ in selectedStep = 0 }
        .onChange(of: phaser?.steps.count) { _, count in selectedStep = min(selectedStep, max(0, (count ?? 1) - 1)) }
        .confirmationDialog("Replace the phaser steps?", isPresented: $replacingPattern, titleVisibility: .visible) {
            Button("Use \(pendingPattern?.rawValue ?? "pattern")") {
                if let pattern = pendingPattern { model.presetDraft.phaser = pattern.make(beatsPerMinute: phaser?.beatsPerMinute ?? 120, measure: phaser?.measure ?? 4); selectedStep = 0 }
            }
            Button("Cancel", role: .cancel) { pendingPattern = nil }
        } message: { Text("The pattern replaces step sources and distribution. Your tempo and cycle length are kept.") }
    }
    private func modeButton(_ title: String, enabled: Bool) -> some View {
        Button { model.setPhaserMode(enabled); selectedStep = 0 } label: {
            HStack { Image(systemName: enabled ? "waveform.path" : "line.diagonal"); Text(title) }
                .frame(maxWidth: .infinity, minHeight: 60).contentShape(.rect)
        }
        .buttonStyle(.bordered)
        .tint((phaser != nil) == enabled ? .accentColor : .gray)
        .accessibilityIdentifier(enabled ? "palette-mode-dynamic" : "palette-mode-static")
        .accessibilityAddTraits((phaser != nil) == enabled ? .isSelected : [])
    }
    private func rhythm(_ phaser: Phaser) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("Rhythm").font(.title2.bold()); Spacer(); Text("4/4").foregroundStyle(.secondary) }
            if textSize.isAccessibilitySize {
                Button("\(Int(phaser.beatsPerMinute)) BPM · Tap tempo", action: tap)
                Picker("Selected step", selection: $selectedStep) { ForEach(phaser.steps.indices, id: \.self) { Text("Step \($0 + 1)").tag($0) } }
            } else {
                ZStack {
                    Circle().stroke(.white.opacity(0.15), lineWidth: 1).frame(width: 260, height: 260)
                    Button(action: tap) {
                        VStack(spacing: 4) {
                            Text("\(Int(phaser.beatsPerMinute.rounded()))").font(.system(size: 48, weight: .semibold, design: .rounded)).monospacedDigit()
                            Text("BPM").font(.headline); Text("Tap tempo").font(.caption).foregroundStyle(.secondary)
                        }.frame(width: 160, height: 160).contentShape(Circle())
                    }.buttonStyle(.borderless).background(.white.opacity(0.07), in: Circle()).accessibilityLabel("Tap tempo, \(Int(phaser.beatsPerMinute)) BPM")
                    let first = selectedStep / 8 * 8
                    let count = min(8, phaser.steps.count - first)
                    ForEach(first..<(first + count), id: \.self) { index in
                        let angle = Double(index - first) / Double(count) * 2 * Double.pi - Double.pi / 2
                        Button { selectedStep = index } label: { Text("\(index + 1)").font(.headline).frame(width: 54, height: 54) }
                            .buttonStyle(.borderless)
                            .background(index == selectedStep ? Color.accentColor : .white.opacity(0.12), in: Circle())
                            .offset(x: cos(angle) * 130, y: sin(angle) * 130)
                            .accessibilityLabel("Step \(index + 1)").accessibilityAddTraits(index == selectedStep ? .isSelected : [])
                    }
                }.frame(width: 330, height: 330)
                if phaser.steps.count > 8 {
                    Picker("Step bank", selection: Binding(get: { selectedStep / 8 }, set: { selectedStep = $0 * 8 })) {
                        ForEach(0..<Int(ceil(Double(phaser.steps.count) / 8)), id: \.self) { bank in Text("\(bank * 8 + 1)–\(min(phaser.steps.count, bank * 8 + 8))").tag(bank) }
                    }.pickerStyle(.segmented)
                }
            }
            HStack { Text("Steps"); Spacer(); Text("\(phaser.steps.count)").monospacedDigit() }
            Slider(value: Binding(get: { Double(phaser.steps.count) }, set: { model.presetDraft.phaser?.resizeSteps(to: Int($0)) }), in: 2...32, step: 1).accessibilityLabel("Step count")
            HStack(spacing: 10) {
                ForEach([2.0, 4, 8, 16], id: \.self) { beats in
                    Button(beats == 2 ? "½ bar" : beats == 4 ? "1 bar" : "\(Int(beats / 4)) bars") { model.presetDraft.phaser?.measure = beats }
                        .tint(phaser.measure == beats ? .accentColor : .gray)
                }
            }
            Text("Bar shortcuts change loop length; steps keep their sources.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func stepEditor(_ phaser: Phaser) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if phaser.steps.indices.contains(selectedStep) {
                let step = phaser.steps[selectedStep]
                HStack { Text("Step \(selectedStep + 1)").font(.title2.bold()); Spacer(); Button("Next", systemImage: "chevron.right") { selectedStep = (selectedStep + 1) % phaser.steps.count } }
                Picker("Palette source", selection: Binding(get: { step.paletteID }, set: { id in
                    if id == nil, let previous = compatibleSources.first(where: { $0.id == step.paletteID }) {
                        model.presetDraft.phaser?.steps[selectedStep].values = Dictionary(uniqueKeysWithValues: model.presetDraft.channelMask.map { ($0, previous.channels[$0]) })
                    }
                    model.presetDraft.phaser?.steps[selectedStep].paletteID = id
                    remember()
                })) {
                    Text("Custom values").tag(nil as UUID?)
                    ForEach(compatibleSources) { Text($0.name).tag(Optional($0.id)) }
                    if let id = step.paletteID, !compatibleSources.contains(where: { $0.id == id }) { Text("Missing or incompatible source").tag(Optional(id)) }
                }
                if step.paletteID != nil { Text("Linked source · updates to this palette follow through to the phaser.").font(.caption).foregroundStyle(.secondary) }
                else {
                    ForEach(model.presetDraft.channelMask.sorted(), id: \.self) { channel in
                        number(LightingPreview.channelNames[channel] + " (%)", value: Double(step.values[channel] ?? model.presetDraft.channels[channel]) / 255 * 100, range: 0...100) { model.presetDraft.phaser?.steps[selectedStep].values[channel] = Int(($0 * 255 / 100).rounded()) }
                    }
                }
                number("Relative step width", value: step.width, range: 0.1...8) { model.presetDraft.phaser?.steps[selectedStep].width = $0 }
                number("Transition (%)", value: (step.transition ?? phaser.transition) * 100, range: 0...100) { model.presetDraft.phaser?.steps[selectedStep].transition = $0 / 100 }
                Picker("Curve", selection: Binding(get: { step.curve ?? .linear }, set: { model.presetDraft.phaser?.steps[selectedStep].curve = $0 })) {
                    Text("Linear").tag(PhaserCurve.linear); Text("Sine").tag(PhaserCurve.sine)
                }
                Text("Transition reaches this step’s value first, then holds it.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Hold") { model.presetDraft.phaser?.steps[selectedStep].transition = 0; remember() }
                    Button("Fade") { model.presetDraft.phaser?.steps[selectedStep].transition = 1; remember() }
                    Button("Remember step") { remember() }
                }
                if model.presetDraft.channelMask == Set([0]) {
                    Menu("Saved step configurations") {
                        Button("Full hold") { use(.init(values: [0: 255], transition: 0)) }
                        Button("Fade up") { use(.init(values: [0: 255], transition: 1, curve: .sine)) }
                        Button("Fade down") { use(.init(values: [0: 0], transition: 1, curve: .sine)) }
                        Button("Low hold") { use(.init(values: [0: 0], transition: 0)) }
                    }
                }
                let recent = model.recentPhaserSteps.filter { saved in
                    if let id = saved.paletteID { return compatibleSources.contains { $0.id == id } }
                    return Set(saved.values.keys).isSubset(of: model.presetDraft.channelMask)
                }
                if !recent.isEmpty {
                    Menu("Recently used steps") {
                        ForEach(recent.indices, id: \.self) { index in
                            let saved = recent[index]
                            Button(saved.paletteID.flatMap { id in compatibleSources.first { $0.id == id }?.name } ?? "Custom · width \(saved.width.formatted()) · \(Int((saved.transition ?? phaser.transition) * 100))% fade") { model.presetDraft.phaser?.steps[selectedStep] = saved }
                        }
                    }
                }
                HStack {
                    Button("Add step", systemImage: "plus") { model.presetDraft.phaser?.steps.append(step); selectedStep = phaser.steps.count }.disabled(phaser.steps.count >= 32)
                    Button("Remove", role: .destructive) { model.presetDraft.phaser?.steps.remove(at: selectedStep); selectedStep = max(0, selectedStep - 1) }.disabled(phaser.steps.count <= 2)
                }
            }
        }
    }
    private func use(_ step: PhaserStep) { model.presetDraft.phaser?.steps[selectedStep] = step; remember() }
    private func tap() { if let bpm = tapTempo.tap(at: ProcessInfo.processInfo.systemUptime) { model.presetDraft.phaser?.beatsPerMinute = bpm } }
    private func remember() { if let step = phaser?.steps[safe: selectedStep] { model.rememberPhaserStep(step) } }
    private func number(_ label: String, value: Double, range: ClosedRange<Double>, set: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(label); Spacer(); TextField(label, value: Binding(get: { value }, set: { if $0.isFinite { set(min(range.upperBound, max(range.lowerBound, $0))) } }), format: .number.precision(.fractionLength(0...2))).multilineTextAlignment(.trailing).frame(width: 90) }
            Slider(value: Binding(get: { value }, set: set), in: range).accessibilityLabel(label)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
