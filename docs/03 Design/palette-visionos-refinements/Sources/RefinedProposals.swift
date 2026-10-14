import SwiftUI

// Throwaway native layout study. Ten variants share values and controls, not layout.
struct RefinedProposals: View {
    let variant: Int
    @State private var count = 8.0
    @State private var selected = 3
    @State private var bpm = 120
    @State private var pattern = "Wave"
    @State private var source = "Full"
    @State private var library = false
    @State private var advanced = false
    @State private var playback = false
    @State private var phase = 0.16
    @State private var taps: [Double] = []
    @State private var tab = "Steps"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var compact: Bool { variant == 24 }
    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 32).padding(.vertical, 24).fixedSize(horizontal: false, vertical: true)
            Divider()
            layout.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: compact ? 1080 : 1320, height: 900, alignment: .top)
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            HStack(spacing: 24) {
                Label("4 fixtures selected", systemImage: "light.beacon.max").font(.headline)
                Divider().frame(height: 28)
                Button("Update palette") { }.buttonStyle(.borderless)
                Button("Apply to fixtures") { }.buttonStyle(.borderedProminent).tint(.blue)
            }.controlSize(.large).padding(18).glassBackgroundEffect(in: .capsule).padding(.top, 16)
        }
        .sheet(isPresented: $library) {
            VStack(alignment: .leading, spacing: 22) {
                HStack { Text("Palettes").font(.largeTitle.bold()); Spacer(); Button("Done") { library = false } }
                ForEach(["Wave", "Breathe", "Pulse", "Red / blue", "Warm wash"], id: \.self) { name in paletteRow(name) }
            }.padding(32).frame(width: 600)
        }
        .task {
            print("Palette prototype \(variant): 8 steps, step 3, 120 BPM, Wave, four selected fixtures")
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                if playback && !reduceMotion { phase = (phase + 0.05/(60/Double(bpm)*count)).truncatingRemainder(dividingBy: 1) }
            }
        }
    }
    var header: some View {
        HStack(spacing: 24) {
            Button { library = true } label: { Image(systemName: "square.grid.2x2").font(.title3).frame(width: 36, height: 36) }.accessibilityLabel("Open palettes")
            VStack(alignment: .leading, spacing: 5) {
                Text("Dimmer wave").font(.largeTitle.weight(.bold))
                Text("Dimmer palette  ·  Phaser").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { advanced.toggle() } label: { Label("Timing", systemImage: "slider.horizontal.3").frame(minHeight: 36) }
                .popover(isPresented: $advanced) { VStack(alignment: .leading, spacing: 24) { Text("Timing").font(.title2.bold()); Text("4/4 · one step per beat"); Text("Phase spread 0° → 360°"); Text("Transition 100%"); Text("Speed \(bpm) BPM") }.padding(32) }
        }
    }
    @ViewBuilder var layout: some View {
        switch variant {
        case 17: outputFirst
        case 18: libraryFirst
        case 19: drawer
        case 20: focusedTabs
        case 21: sourceShelf
        case 22: stepFocus
        case 23: twoModes
        case 24: compactLayout
        case 25: lightScore
        default: balanced
        }
    }
    var balanced: some View {
        HStack(alignment: .top, spacing: 36) {
            VStack(spacing: 28) { tempo; patterns }.frame(width: 410)
            Divider()
            VStack(alignment: .leading, spacing: 26) {
                liveGraph(height: 116)
                stepHeader
                HStack(alignment: .top, spacing: 28) { stepValues.frame(maxWidth: .infinity); presets.frame(maxWidth: .infinity) }
                Divider()
                paletteShelf
            }.frame(maxWidth: .infinity)
        }
    }
    var outputFirst: some View {
        VStack(spacing: 24) {
            liveGraph(height: 114)
            HStack(alignment: .top, spacing: 40) {
                tempo.frame(width: 410)
                Divider()
                VStack(alignment: .leading, spacing: 22) { stepHeader; HStack(alignment: .top, spacing: 28) { stepValues; presets }; patterns }.frame(maxWidth: .infinity)
            }
        }
    }
    var libraryFirst: some View {
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Palettes").font(.title2.bold())
                Text("15 saved").foregroundStyle(.secondary)
                ForEach(["Wave", "Breathe", "Pulse", "Warm wash"], id: \.self) { name in paletteRow(name) }
                Button("Browse all", systemImage: "magnifyingglass") { library = true }.controlSize(.large)
            }.frame(width: 248)
            Divider()
            VStack(spacing: 24) { tempo; graph(height: 82) }.frame(width: 380)
            Divider()
            VStack(alignment: .leading, spacing: 22) { preview(height: 106); stepHeader; stepValues; quickPresets; recent }.frame(maxWidth: .infinity)
        }
    }
    var drawer: some View {
        VStack(spacing: 26) {
            HStack(alignment: .top, spacing: 44) {
                tempo.frame(width: 410)
                VStack(alignment: .leading, spacing: 26) { preview(height: 110); graph(height: 90); patternCompact }.frame(maxWidth: .infinity)
            }
            Divider()
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 14) { stepHeader; sourceControl }.frame(width: 290)
                VStack(alignment: .leading, spacing: 18) { Text("Step values").font(.headline); valuesRow; Text("1 beat · smooth transition").foregroundStyle(.secondary) }.frame(width: 280)
                HStack(alignment: .top, spacing: 24) { quickPresets; recent }.frame(maxWidth: .infinity)
            }
        }
    }
    var focusedTabs: some View {
        VStack(spacing: 30) {
            Picker("Editor", selection: $tab) { Text("Palette").tag("Palette"); Text("Rhythm").tag("Rhythm"); Text("Steps").tag("Steps") }.pickerStyle(.segmented).frame(width: 600)
            HStack(alignment: .top, spacing: 36) {
                VStack(alignment: .leading, spacing: 24) { preview(height: 146); graph(height: 134); paletteShelf }.frame(width: 510)
                Divider()
                VStack(alignment: .leading, spacing: 26) {
                    if tab == "Steps" { stepHeader; stepValues; presets; patternCompact }
                    else if tab == "Rhythm" { tempo }
                    else { ForEach(["Wave","Breathe","Pulse"],id: \.self) { paletteRow($0) } }
                }.frame(maxWidth: .infinity)
            }
            HStack { Image(systemName: "metronome"); Text("\(bpm) BPM · \(Int(count)) steps · 2 bars"); Spacer(); Button("Edit rhythm") { tab = "Rhythm" } }.foregroundStyle(.secondary)
        }
    }
    var sourceShelf: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack { Text("Preset pool").font(.headline); Spacer(); Button("All palettes", systemImage: "chevron.right") { library = true }.buttonStyle(.borderless) }
            HStack(spacing: 20) { paletteRow("Wave"); paletteRow("Breathe"); paletteRow("Pulse"); paletteRow("Warm wash") }
            Divider()
            HStack(alignment: .top, spacing: 32) {
                tempo.frame(width: 388)
                Divider()
                VStack(alignment: .leading, spacing: 24) { stepHeader; stepValues; quickPresets; recent }.frame(width: 355)
                VStack(alignment: .leading, spacing: 24) { preview(height: 138); graph(height: 104); patternCompact }.frame(maxWidth: .infinity)
            }
        }
    }
    var stepFocus: some View {
        HStack(alignment: .top, spacing: 36) {
            VStack(spacing: 28) { tempo; patternCompact }.frame(width: 398)
            Divider()
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text("Step \(selected)").font(.largeTitle.bold()); Spacer(); Text("1 beat").foregroundStyle(.secondary) }
                HStack(alignment: .top, spacing: 30) { stepValues; presets }
                Divider()
                liveGraph(height: 125)
                HStack { Text("Palette source").foregroundStyle(.secondary); Spacer(); Text("Changes follow the Full palette.").foregroundStyle(.secondary) }.font(.subheadline)
            }.frame(maxWidth: .infinity)
        }
    }
    var twoModes: some View {
        HStack(alignment: .top, spacing: 32) {
            VStack(alignment: .leading, spacing: 26) {
                preview(height: 118)
                graph(height: 124)
                patternCompact
                paletteShelf
            }.frame(width: 460)
            Divider()
            VStack(alignment: .leading, spacing: 26) {
                tempo

            }.frame(width: 380)
            VStack(alignment: .leading, spacing: 24) {
                Text("Step \(selected)").font(.title2.bold())
                sourceControl
                VStack(alignment: .leading, spacing: 20) { metric("Dimmer", "100%"); metric("Transition", "100%"); metric("Length", "1 beat") }
                Divider()
                quickPresets
                recent
            }.frame(maxWidth: .infinity)
        }
    }
    var compactLayout: some View {
        VStack(spacing: 24) {
            liveGraph(height: 70)
            HStack(alignment: .top, spacing: 34) {
                tempo.frame(width: 398)
                Divider()
                VStack(alignment: .leading, spacing: 22) { stepHeader; sourceControl; valuesRow; quickPresets; recent; patternCompact }.frame(maxWidth: .infinity)
            }
        }
    }
    var lightScore: some View {
        VStack(spacing: 26) {
            HStack(alignment: .top, spacing: 38) {
                tempo.frame(width: 410)
                VStack(alignment: .leading, spacing: 24) { preview(height: 108); HStack { Text("Fixture score").font(.headline); Spacer(); Text("4 selected fixtures").foregroundStyle(.secondary) }; graph(height: 132, multi: true); patternCompact }.frame(maxWidth: .infinity)
            }
            Divider()
            HStack(alignment: .top, spacing: 30) { VStack(alignment: .leading, spacing: 16) { stepHeader; sourceControl }.frame(width: 310); HStack(alignment: .top, spacing: 24) { quickPresets; recent }; VStack(alignment: .leading, spacing: 18) { Text("Preset pool").font(.headline); paletteRow("Wave") }.frame(width: 265) }
        }
    }
    var tempo: some View {
        VStack(spacing: 14) {
            HStack { Text("Rhythm").font(.title2.bold()); Spacer(); Text("4/4").foregroundStyle(.secondary) }
            ZStack {
                Circle().stroke(.white.opacity(0.20),lineWidth:1.5).frame(width: radius*2,height:radius*2)
                Button(action: tap) {
                    VStack(spacing: 5) { Text("\(bpm)").font(.system(size:56,weight:.medium,design:.rounded)).monospacedDigit(); Text("BPM").font(.headline); Text("Tap tempo").font(.subheadline).foregroundStyle(.secondary).padding(.top,6) }.frame(width:166,height:166).contentShape(.circle)
                }.buttonStyle(.plain).background(.white.opacity(0.07),in:.circle).hoverEffect(.highlight)
                ForEach(1...Int(count),id: \.self) { n in
                    let a = Double(n-1)/count*2*Double.pi-Double.pi/2
                    Button { selected=n } label: { Text("\(n)").font(.title3.bold()).frame(width:44,height:44).background(selected == n ? Color.blue : .white.opacity(0.10),in:.circle).frame(width:60,height:60).contentShape(.circle) }.buttonStyle(.plain).hoverEffect(.highlight).accessibilityLabel("Step \(n)").offset(x:cos(a)*radius,y:sin(a)*radius)
                }
            }.frame(height:count > 12 ? 380 : 310)
            HStack { Text("Steps").font(.headline); Spacer(); Text("\(Int(count))").font(.headline).monospacedDigit() }
            Slider(value:$count,in:1...16,step:1).accessibilityLabel("Number of steps").onChange(of:count) { _,v in selected=min(selected,Int(v)) }
            HStack(spacing:16) { ForEach([2,4,8,16],id: \.self) { n in Button { count=Double(n);selected=min(selected,n) } label:{ Text([2:"½ bar",4:"1 bar",8:"2 bars",16:"4 bars"][n]!).font(.subheadline.weight(.semibold)).frame(maxWidth:.infinity,minHeight:40).foregroundStyle(count == Double(n) ? .black : .white) }.tint(count == Double(n) ? .white : .white.opacity(0.1)) } }
            HStack { Text("One step per beat");Spacer();Text("\(60/Double(bpm)*count,specifier:"%.1f") s") }.font(.subheadline).foregroundStyle(.secondary)
        }
    }
    var radius:Double { count > 12 ? 158 : 124 }
    func tap(){let now=Date.timeIntervalSinceReferenceDate;if let last=taps.last,now-last>2{taps=[]};taps.append(now);taps=Array(taps.suffix(6));if taps.count>1{bpm=max(20,min(300,Int((60*Double(taps.count-1)/(now-taps[0])).rounded())))}}
    var stepHeader:some View { HStack { Text("Step \(selected)").font(.title2.bold());Spacer();Text("1 beat").foregroundStyle(.secondary) } }
    var sourceControl:some View {
        Button { source=source == "Full" ? "Blackout" : "Full" } label:{ HStack(spacing:14){RoundedRectangle(cornerRadius:8).fill(source == "Full" ? .white : .black).frame(width:32,height:32);VStack(alignment:.leading,spacing:4){Text("Palette source").font(.subheadline).foregroundStyle(.secondary);Text(source).font(.headline)};Spacer();Image(systemName:"chevron.up.chevron.down")}.frame(minHeight:50) }
    }
    var valuesRow:some View { HStack(spacing:24){metric("Dimmer",source == "Full" ? "100%" : "0%");Spacer();metric("Transition","100%")} }
    func metric(_ name:String,_ value:String)->some View{VStack(alignment:.leading,spacing:8){Text(name).font(.subheadline).foregroundStyle(.secondary);Text(value).font(.title2.weight(.semibold))}}
    var stepValues:some View { VStack(alignment:.leading,spacing:24){sourceControl;valuesRow;HStack{Text("Interpolation").font(.headline);Spacer();Button("Smooth",systemImage:"chevron.down") { }};Text("Uses the saved palette values.").font(.subheadline).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading) }
    var quickPresets:some View { VStack(alignment:.leading,spacing:14){Text("Saved steps").font(.headline);HStack(spacing:16){ForEach(["Full hold","Fade down"],id: \.self){name in Button{source="Full"}label:{VStack(spacing:10){PresetLine(name:name).stroke(.primary,lineWidth:2).frame(width:52,height:18);Text(name).font(.subheadline)}.frame(maxWidth:.infinity,minHeight:58)}}}} }
    var recent:some View { VStack(alignment:.leading,spacing:14){Text("Recently used").font(.headline);Button{source="Full"}label:{HStack(spacing:14){Swatch(kind:1,phase:phase).frame(width:52,height:40).clipShape(.rect(cornerRadius:10));Text("Soft rise").font(.headline);Spacer()}.frame(minHeight:44)}} }
    var presets:some View { VStack(alignment:.leading,spacing:24){quickPresets;recent}.frame(maxWidth:.infinity,alignment:.leading) }
    var patterns:some View { VStack(alignment:.leading,spacing:16){Text("Phaser pattern").font(.headline);HStack(spacing:16){ForEach(["Wave","Breathe","Pulse"],id: \.self){name in Button{pattern=name}label:{VStack(spacing:10){PatternLine(pattern:name).stroke(.primary,lineWidth:2).frame(width:44,height:20);Text(name).font(.subheadline.bold())}.frame(maxWidth:.infinity,minHeight:62)}.tint(pattern == name ? .blue.opacity(0.45) : .white.opacity(0.08))}}} }
    var patternCompact:some View { VStack(alignment:.leading,spacing:14){Text("Phaser pattern").font(.headline);Picker("Phaser pattern",selection:$pattern){ForEach(["Wave","Breathe","Pulse"],id: \.self){Text($0)}}.pickerStyle(.segmented)} }
    func preview(height:CGFloat)->some View {
        VStack(spacing:12){HStack{Text("Live preview").font(.headline);Spacer();Button{playback.toggle()}label:{Image(systemName:playback ? "pause.fill":"play.fill").frame(width:36,height:32)}.accessibilityLabel(playback ? "Pause":"Play")};BeamPreview(phase:phase,pattern:pattern).frame(height:height)}.padding(20).background(.black.opacity(0.18),in:.rect(cornerRadius:24))
    }
    func graph(height:CGFloat,multi:Bool=false)->some View {
        VStack(alignment:.leading,spacing:12){if !multi{HStack{Text("Dimmer").font(.headline);Spacer();Text("0–100%").foregroundStyle(.secondary)}};CurveGraph(pattern:pattern,phase:phase,multi:multi,accent:.white).frame(height:height);HStack{Text("0");Spacer();Text("\(Int(count/2)) beats");Spacer();Text("\(Int(count)) beats")}.font(.subheadline).foregroundStyle(.secondary)}
    }
    func liveGraph(height:CGFloat)->some View {HStack(alignment:.top,spacing:28){preview(height:height).frame(maxWidth:.infinity);graph(height:height+38).frame(maxWidth:.infinity)}}
    func paletteRow(_ name:String)->some View {
        let index=["Wave","Breathe","Pulse","Red / blue","Warm wash"].firstIndex(of:name) ?? 0
        return Button{pattern=["Wave","Breathe","Pulse"].contains(name) ? name:"Wave"}label:{HStack(spacing:14){Swatch(kind:index,phase:phase).frame(width:60,height:52).clipShape(.rect(cornerRadius:12));VStack(alignment:.leading,spacing:5){Text(name).font(.headline);Text(index>2 ? "Color":"Dimmer phaser").font(.subheadline).foregroundStyle(.secondary)};Spacer(minLength:0)}.frame(maxWidth:.infinity,minHeight:62)}.buttonStyle(.plain).padding(10).background(pattern==name ? .white.opacity(0.12):.clear,in:.rect(cornerRadius:18)).hoverEffect(.highlight)
    }
    var paletteShelf:some View { VStack(alignment:.leading,spacing:14){HStack{Text("Preset pool").font(.headline);Spacer();Button("Browse",systemImage:"chevron.right"){library=true}.buttonStyle(.borderless)};HStack(spacing:16){paletteRow("Wave");paletteRow("Breathe")}} }
}
