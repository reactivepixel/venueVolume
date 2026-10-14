import SwiftUI

@main struct PaletteProposalsApp: App {
    var body: some Scene {
        WindowGroup { ProposalView() }
            .windowStyle(.plain)
            .windowResizability(.contentSize)
            .defaultSize(width: 1380, height: 860)
    }
}

struct ProposalView: View {
    @State private var selected: Int? = 3
    @State private var steps = 8.0
    @State private var bpm = 120
    @State private var pattern = "Wave"
    @State private var source = "Full"
    @State private var playing = false
    @State private var taps: [Double] = []
    @State private var phase = 0.16
    @State private var showPool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let variant: Int = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--proposal"), args.indices.contains(i + 1) { return Int(args[i+1]) ?? 11 }
        return 11
    }()
    var accent: Color { variant == 12 ? .yellow : variant == 15 ? .mint : .white }
    var body: some View {
        Group {
            switch variant {
            case 12: console
            case 13: stage
            case 14: studio
            case 15: score
            default: composer
            }
        }
        .frame(width: 1380, height: 860)
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            HStack(spacing: 24) {
                Label("4 wash fixtures", systemImage: "light.beacon.max")
                    .font(.headline)
                Divider().frame(height: 30)
                Text("Dimmer wave").foregroundStyle(.secondary)
                Button("Update palette") { }.fixedSize()
                Button("Apply to 4") { }.buttonStyle(.borderedProminent)
            }
            .controlSize(.large).padding(16).glassBackgroundEffect(in: .capsule)
            .padding(.top, 22)
        }
        .sheet(isPresented: $showPool) {
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text("Preset pool").font(.largeTitle); Spacer(); Button("Done") { showPool = false } }
                ForEach(["Wave", "Breathe", "Pulse", "Red / blue", "Warm wash"], id: \.self) { name in poolRow(name) }
            }.padding(32).frame(width: 540)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(40))
                if playing && !reduceMotion { phase = (phase + 0.04 / (60.0 / Double(bpm) * steps)).truncatingRemainder(dividingBy: 1) }
            }
        }
    }

    func glass<Content: View>(width: CGFloat? = nil, height: CGFloat? = nil, @ViewBuilder content: () -> Content) -> some View {
        content().padding(26).frame(width: width, height: height, alignment: .topLeading)
            .glassBackgroundEffect(in: .rect(cornerRadius: 32))
    }
    var title: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Palettes & phasers").font(.title.weight(.bold))
                Text("Dimmer wave · 4 fixtures selected").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showPool = true } label: { Label("Presets", systemImage: "square.grid.2x2") }.controlSize(.large)
        }
    }
    var composer: some View {
        HStack(alignment: .center, spacing: 24) {
            glass(width: 970, height: 836) {
                VStack(spacing: 20) {
                    title
                    HStack(alignment: .top, spacing: 28) {
                        tempo.frame(width: 408)
                        VStack(spacing: 22) { preview(height: 164); graph(height: 140); patterns; phaseControl }
                            .frame(maxWidth: .infinity)
                    }
                    shelf
                }
            }
            if selected != nil { glass(width: 370, height: 836) { inspector }.transition(.move(edge: .trailing).combined(with: .opacity)) }
        }
    }
    var console: some View {
        glass(width: 1360, height: 836) {
            VStack(spacing: 20) {
                title
                HStack(alignment: .top, spacing: 32) {
                    tempo.frame(width: 408)
                    VStack(spacing: 12) {
                        HStack { Swatch(kind: 0, phase: phase).frame(width: 64, height: 48).clipShape(.rect(cornerRadius: 10)); Text("1.4  Dimmer wave").font(.title2.bold()); Spacer(); Text("Programmer").foregroundStyle(.secondary) }
                        preview(height: 110)
                        graph(height: 82)
                        patterns
                        HStack { Label("Phase  0° → 360°", systemImage: "arrow.trianglehead.2.clockwise.rotate.90"); Spacer(); Text("Relative  0%").foregroundStyle(.secondary) }.font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                }
                Divider()
                if let selected {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Step \(selected)", systemImage: "circle.inset.filled").font(.title2.bold())
                            Button { source = source == "Full" ? "Blackout" : "Full" } label: { Text("Source · \(source)").frame(width: 180, height: 36) }
                            Text("1 beat · 100% transition").font(.subheadline).foregroundStyle(.secondary)
                        }.frame(width: 225, alignment: .leading)
                        Divider().frame(height: 148)
                        VStack(alignment: .leading, spacing: 12) { Text("Presaved steps").font(.headline); savedSteps(horizontal: true) }
                        VStack(alignment: .leading, spacing: 12) { Text("Recent").font(.headline); recentRow("Soft rise", kind: 1); recentRow("Snap to full", kind: 2) }.frame(width: 265)
                    }
                }
            }
        }
    }
    var stage: some View {
        HStack(spacing: 24) {
            glass(width: 300, height: 776) { library }
            glass(width: 1040, height: 836) {
                VStack(spacing: 18) {
                    title
                    preview(height: 112)
                    HStack(alignment: .top, spacing: 28) {
                        tempo.frame(width: 408)
                        VStack(alignment: .leading, spacing: 18) {
                            patterns
                            graph(height: 103)
                            if let selected {
                                HStack { Text("Step \(selected)").font(.title2.bold()); Spacer(); Button("Source: \(source)") { source = "Full" } }
                                HStack { Text("Dimmer  100%"); Spacer(); Text("Fade  100%").foregroundStyle(.secondary) }.font(.headline)
                                Text("Presaved steps").font(.headline)
                                savedSteps(horizontal: true)
                                HStack { Text("Recent").foregroundStyle(.secondary); recentRow("Soft rise", kind: 1) }
                            }
                        }.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    var studio: some View {
        HStack(spacing: 24) {
            glass(width: 470, height: 836) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Rhythm").font(.title.bold())
                    tempo
                    HStack { Swatch(kind: 0, phase: phase).frame(width: 76, height: 56).clipShape(.rect(cornerRadius: 12)); VStack(alignment: .leading) { Text("Dimmer wave").font(.headline); Text("Saved phaser").foregroundStyle(.secondary) }; Spacer() }
                    Button { showPool = true } label: { Label("Choose palette", systemImage: "square.grid.2x2").frame(maxWidth: .infinity, minHeight: 36) }.controlSize(.large)
                }
            }
            glass(width: 870, height: 836) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { VStack(alignment: .leading, spacing: 6) { Text("Step \(selected ?? 3)").font(.largeTitle.bold()); Text("Dimmer wave · 4 selected fixtures").foregroundStyle(.secondary) }; Spacer(); Text("3 of \(Int(steps))").font(.title3).foregroundStyle(.secondary) }
                    HStack(alignment: .top, spacing: 26) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("1  Choose a source").font(.headline)
                            sourceButton
                            valueControls
                            Text("2  Set the transition").font(.headline).padding(.top, 6)
                            HStack { Text("Smooth fade"); Spacer(); Text("100%").bold() }.padding(16).background(.white.opacity(0.08), in: .rect(cornerRadius: 16))
                            Text("Presaved steps").font(.headline)
                            savedSteps(horizontal: false)
                        }.frame(width: 340)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("3  Preview the result").font(.headline)
                            preview(height: 128)
                            graph(height: 108)
                            Text("Recently used").font(.headline)
                            recentRow("Soft rise", kind: 1)
                            recentRow("Snap to full", kind: 2)
                        }.frame(maxWidth: .infinity)
                    }
                    Divider()
                    patterns
                }
            }
        }
    }
    var score: some View {
        HStack(spacing: 24) {
            glass(width: 970, height: 836) {
                VStack(spacing: 18) {
                    title
                    HStack(alignment: .top, spacing: 26) {
                        tempo.frame(width: 408)
                        VStack(alignment: .leading, spacing: 20) {
                            preview(height: 154)
                            Text("Fixture score").font(.title2.bold())
                            graph(height: 185, multi: true)
                            patterns
                        }.frame(maxWidth: .infinity)
                    }
                    shelf
                }
            }
            glass(width: 370, height: 720) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack { Image(systemName: "scope").font(.title2); Text("Step \(selected ?? 3)").font(.title.bold()); Spacer(); Text("1 beat").foregroundStyle(.secondary) }
                    sourceButton
                    valueControls
                    Text("Presaved steps").font(.headline)
                    savedSteps(horizontal: false)
                    Text("Recently used").font(.headline)
                    recentRow("Soft rise", kind: 1)
                    Text("Step and score stay linked.").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }
    var ringRadius: Double { steps > 12 ? 158 : 124 }
    var ringSize: Double { steps > 12 ? 380 : 312 }
    var tempo: some View {
        VStack(spacing: 10) {
            HStack { Text("Tempo & steps").font(.headline); Spacer(); Text("4/4").foregroundStyle(.secondary) }
            ZStack {
                Circle().stroke(.white.opacity(0.18), lineWidth: 2).frame(width: ringRadius * 2, height: ringRadius * 2)
                Circle().trim(from: 0, to: 0.25).stroke(accent.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: ringRadius * 2, height: ringRadius * 2).rotationEffect(.degrees(-90))
                Button(action: tapTempo) {
                    VStack(spacing: 4) {
                        Text("\(bpm)").font(.system(size: 64, weight: .medium, design: .rounded)).monospacedDigit()
                        Text("BPM").font(.headline).tracking(2)
                        Text("Tap tempo").font(.subheadline).foregroundStyle(.secondary).padding(.top, 6)
                    }.frame(width: 180, height: 180).contentShape(.circle)
                }.buttonStyle(.plain).background(.white.opacity(0.08), in: .circle).hoverEffect(.highlight)
                ForEach(1...Int(steps), id: \.self) { step in
                    let a = Double(step - 1) / steps * 2 * .pi - .pi / 2
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selected = step } } label: {
                        Text("\(step)").font(.title3.bold()).frame(width: 52, height: 52)
                            .background(selected == step ? accent : .white.opacity(0.10), in: .circle)
                            .foregroundStyle(selected == step ? Color.black : Color.white)
                            .frame(width: 60, height: 60).contentShape(.circle)
                    }.buttonStyle(.plain).hoverEffect(.highlight).accessibilityLabel("Configure step \(step)")
                        .offset(x: cos(a) * ringRadius, y: sin(a) * ringRadius)
                }
            }.frame(height: ringSize)
            HStack { Text("Steps"); Spacer(); Text("\(Int(steps))").monospacedDigit().bold() }.font(.headline)
            Slider(value: $steps, in: 1...16, step: 1).accessibilityLabel("Step count")
                .onChange(of: steps) { _, value in if let s = selected, s > Int(value) { selected = Int(value) } }
            HStack(spacing: 12) {
                ForEach([1,2,4,8,16], id: \.self) { count in
                    Button { steps = Double(count); if let s = selected, s > count { selected = count } } label: {
                        Text([1:"¼",2:"½",4:"1",8:"2",16:"4"][count]!).font(.headline).foregroundStyle(Int(steps) == count ? Color.black : Color.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.bordered).tint(Int(steps) == count ? accent : .white.opacity(0.15))
                }
            }
            HStack { Text("Bars · 4/4"); Spacer(); Text("\(60 / Double(bpm) * steps, specifier: "%.1f") s per loop") }.font(.subheadline).foregroundStyle(.secondary)
        }
    }
    func tapTempo() {
        let now = Date.timeIntervalSinceReferenceDate
        if let last = taps.last, now - last > 2 { taps = [] }
        taps.append(now); taps = Array(taps.suffix(6))
        if taps.count > 1 { bpm = max(20, min(300, Int((60 * Double(taps.count - 1) / (now - taps[0])).rounded()))) }
    }
    var patterns: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phaser pattern").font(.headline)
            HStack(spacing: 16) {
                ForEach(["Wave","Breathe","Pulse"], id: \.self) { name in
                    Button { pattern = name } label: {
                        VStack(spacing: 8) { PatternLine(pattern: name).stroke(.primary, lineWidth: 2).frame(width: 42, height: 17); Text(name).font(.subheadline.bold()) }.frame(maxWidth: .infinity, minHeight: 62)
                    }.buttonStyle(.bordered).tint(pattern == name ? accent.opacity(0.3) : .white.opacity(0.07))
                }
            }
        }
    }
    var phaseControl: some View {
        HStack { Text("Phase spread"); Spacer(); Button("360°") { } }.font(.headline)
    }
    func preview(height: CGFloat) -> some View {
        VStack(spacing: 6) {
            HStack { Text("Live preview").font(.headline); Spacer(); Button { playing.toggle() } label: { Image(systemName: playing ? "pause.fill" : "play.fill").frame(width: 36, height: 32) }.accessibilityLabel(playing ? "Pause preview" : "Play preview") }
            BeamPreview(phase: phase, pattern: pattern).frame(height: height)
        }.padding(16).background(.black.opacity(0.16), in: .rect(cornerRadius: 22))
    }
    func graph(height: CGFloat, multi: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !multi { HStack { Text("Dimmer over time").font(.headline); Spacer(); Text("\(Int(steps)) beats").font(.subheadline).foregroundStyle(.secondary) } }
            CurveGraph(pattern: pattern, phase: phase, multi: multi, accent: accent).frame(height: height)
            HStack { Text("0"); Spacer(); Text("\(Int(steps / 2)) beats"); Spacer(); Text("\(Int(steps)) beats") }.font(.caption).foregroundStyle(.secondary)
        }
    }
    var sourceButton: some View {
        Button { source = source == "Full" ? "Blackout" : "Full" } label: {
            HStack { VStack(alignment: .leading, spacing: 5) { Text("Palette source").font(.subheadline).foregroundStyle(.secondary); Text(source).font(.title3.bold()) }; Spacer(); Image(systemName: "chevron.up.chevron.down") }.frame(maxWidth: .infinity, minHeight: 52)
        }.buttonStyle(.bordered)
    }
    var valueControls: some View {
        HStack(spacing: 16) {
            ForEach(["Dimmer", "Transition"], id: \.self) { label in
                VStack(alignment: .leading, spacing: 8) { Text(label).font(.subheadline).foregroundStyle(.secondary); Text(source == "Blackout" && label == "Dimmer" ? "0%" : "100%").font(.title2.bold()) }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(.vertical, 8)
    }
    var inspector: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("Step \(selected ?? 3)").font(.title.bold()); Spacer(); Button { withAnimation { selected = nil } } label: { Image(systemName: "xmark") }.accessibilityLabel("Close step") }
            Text("1 beat · linked palette values").font(.subheadline).foregroundStyle(.secondary)
            sourceButton
            valueControls
            Divider()
            Text("Presaved steps").font(.headline)
            savedSteps(horizontal: false)
            Text("Recently used").font(.headline)
            recentRow("Soft rise", kind: 1)
            recentRow("Snap to full", kind: 2)
        }
    }
    func savedSteps(horizontal: Bool) -> some View {
        let layout = horizontal ? AnyLayout(HStackLayout(spacing: 16)) : AnyLayout(VStackLayout(spacing: 16))
        return layout {
            ForEach(["Full hold", "Fade down", "Blackout"], id: \.self) { name in
                Button { source = name == "Blackout" ? "Blackout" : "Full" } label: {
                    if horizontal {
                        VStack(spacing: 12) { PresetLine(name: name).stroke(.white.opacity(0.85), lineWidth: 2).frame(width: 48, height: 22); Text(name).font(.subheadline) }.frame(maxWidth: .infinity, minHeight: 68)
                    } else {
                        HStack { PresetLine(name: name).stroke(.white.opacity(0.85), lineWidth: 2).frame(width: 46, height: 20); Text(name).font(.headline); Spacer() }.frame(maxWidth: .infinity, minHeight: 40)
                    }
                }.buttonStyle(.bordered)
            }
        }
    }
    func recentRow(_ name: String, kind: Int) -> some View {
        Button { source = "Full" } label: {
            HStack(spacing: 14) { Swatch(kind: kind, phase: phase).frame(width: 52, height: 40).clipShape(.rect(cornerRadius: 10)); Text(name).font(.subheadline.bold()); Spacer(minLength: 0) }.frame(minHeight: 40)
        }.buttonStyle(.bordered)
    }
    var shelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Preset pool").font(.headline); Spacer(); Button("All 15", systemImage: "chevron.right") { showPool = true }.buttonStyle(.plain) }
            HStack(spacing: 16) { poolRow("Wave"); poolRow("Breathe"); poolRow("Pulse") }
        }
    }
    func poolRow(_ name: String) -> some View {
        let index = ["Wave", "Breathe", "Pulse", "Red / blue", "Warm wash"].firstIndex(of: name) ?? 0
        return Button { pattern = ["Wave","Breathe","Pulse"].contains(name) ? name : "Wave" } label: {
            HStack(spacing: 14) { Swatch(kind: index, phase: phase).frame(width: 64, height: 48).clipShape(.rect(cornerRadius: 12)); VStack(alignment: .leading, spacing: 5) { Text(name).font(.headline); Text(index > 2 ? "Color" : "Dimmer phaser").font(.caption).foregroundStyle(.secondary) }; Spacer(minLength: 0) }.frame(maxWidth: .infinity, minHeight: 52)
        }.buttonStyle(.bordered)
    }
    var library: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("Presets").font(.title.bold()); Spacer(); Image(systemName: "square.grid.2x2") }
            Text("15 saved palettes").foregroundStyle(.secondary)
            ForEach(["Wave","Breathe","Pulse","Red / blue","Warm wash"], id: \.self) { name in poolRow(name) }
            Spacer(minLength: 0)
            Button { showPool = true } label: { Label("Browse all", systemImage: "magnifyingglass").frame(maxWidth: .infinity, minHeight: 40) }
        }
    }
}

struct PatternLine: Shape {
    var pattern: String
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for i in 0...80 {
            let t = Double(i) / 80
            let v = pattern == "Pulse" ? (t < 0.3 || t > 0.7 ? 0.2 : 0.9) : pattern == "Breathe" ? pow(sin(t * .pi), 2) : 0.5 + sin(t * .pi * 2) * 0.4
            let point = CGPoint(x: t * rect.width, y: (1-v) * rect.height)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        return p
    }
}
struct PresetLine: Shape {
    var name: String
    func path(in r: CGRect) -> Path { var p=Path(); p.move(to: CGPoint(x: 0,y: name == "Blackout" ? r.maxY : 2)); p.addLine(to: CGPoint(x: r.maxX, y: name == "Full hold" ? 2 : r.maxY)); return p }
}
func intensity(_ t: Double, index: Int, pattern: String) -> Double {
    let p = (t + (pattern == "Breathe" ? 0 : Double(index) / 4)).truncatingRemainder(dividingBy: 1)
    return pattern == "Pulse" ? (p < 0.5 ? 1 : 0.05) : 0.5 + 0.5 * cos(p * 2 * .pi)
}
struct BeamPreview: View {
    var phase: Double
    var pattern: String
    var body: some View {
        GeometryReader { g in
            HStack(spacing: 0) {
                ForEach(0..<4) { i in
                    VStack(spacing: 6) {
                        Canvas { c,s in
                            let a = 0.13 + 0.87 * intensity(phase, index: i, pattern: pattern)
                            let cx = s.width / 2
                            c.fill(Path(roundedRect: CGRect(x: cx-8,y: 2,width: 16,height: 9),cornerRadius: 3), with: .color(.white.opacity(a)))
                            var beam=Path(); beam.move(to: CGPoint(x:cx-6,y:14)); beam.addLine(to:CGPoint(x:8,y:s.height-12)); beam.addQuadCurve(to:CGPoint(x:s.width-8,y:s.height-12),control:CGPoint(x:cx,y:s.height+10)); beam.addLine(to:CGPoint(x:cx+6,y:14)); beam.closeSubpath()
                            c.fill(beam,with:.linearGradient(Gradient(colors:[.white.opacity(a*0.06),.white.opacity(a*0.35)]),startPoint:CGPoint(x:cx,y:14),endPoint:CGPoint(x:cx,y:s.height)))
                            c.fill(Path(ellipseIn:CGRect(x:8,y:s.height-22,width:s.width-16,height:18)),with:.color(.white.opacity(a*0.9)))
                        }
                        Text("Wash 0\(i+1)").font(.caption).foregroundStyle(.secondary)
                    }.frame(width:g.size.width/4)
                }
            }
        }
    }
}
struct CurveGraph: View {
    var pattern: String; var phase: Double; var multi: Bool; var accent: Color
    var body: some View {
        Canvas { c,s in
            for i in 0...4 { var p=Path(); p.move(to:CGPoint(x:Double(i)*s.width/4,y:0));p.addLine(to:CGPoint(x:Double(i)*s.width/4,y:s.height));c.stroke(p,with:.color(.white.opacity(0.10)),lineWidth:1) }
            for i in 0...4 { var p=Path(); p.move(to:CGPoint(x:0,y:Double(i)*s.height/4));p.addLine(to:CGPoint(x:s.width,y:Double(i)*s.height/4));c.stroke(p,with:.color(.white.opacity(0.10)),lineWidth:1) }
            for row in 0..<(multi ? 4 : 1) {
                var p=Path()
                for i in 0...100 { let v=intensity(Double(i)/100,index:row,pattern:pattern);let y=multi ? Double(row)*s.height/4+(1-v)*s.height/5+4 : (1-v)*(s.height-12)+6;let point=CGPoint(x:Double(i)*s.width/100,y:y);if i==0 {p.move(to:point)}else{p.addLine(to:point)} }
                c.stroke(p,with:.color(accent.opacity(1-Double(row)*0.15)),lineWidth:2.5)
            }
            var p=Path(); p.move(to:CGPoint(x:phase*s.width,y:0));p.addLine(to:CGPoint(x:phase*s.width,y:s.height));c.stroke(p,with:.color(.white.opacity(0.6)),style:StrokeStyle(lineWidth:1,dash:[4,5]))
        }
    }
}
struct Swatch: View {
    var kind: Int; var phase: Double
    var body: some View {
        Canvas { context, size in
            for y in 0..<24 { for x in 0..<40 {
                let u = Double(x)/40, v = Double(y)/24
                let energy: Double
                var base = (0.08,0.15,0.16), light = (0.68,0.9,0.77)
                switch kind {
                case 0: energy = pow(0.5+0.5*sin(u*14-phase*6.283),2)*(0.35+0.65*exp(-pow((v-0.5)*3,2)))
                case 1: energy = exp(-(pow(u-0.5,2)+pow((v-0.5)*1.5,2))*7)*(0.5+0.4*sin(phase*6.283));light=(0.55,0.8,0.82)
                case 2: energy = (u*5-phase+1).truncatingRemainder(dividingBy:1) > 0.5 ? 0.85 : 0
                case 3: let q=0.5+0.5*sin(u*5+phase*6.283);base=(0.16+q*0.49,0.13-q*0.03,0.55-q*0.35);light=(0.3+q*0.7,0.4-q*0.15,1-q*0.7);energy=0.6
                default: base=(0.3,0.2,0.1);light=(1,0.78,0.44);energy=0.3+0.6*exp(-hypot(u-0.5,v-0.5)*3)
                }
                let color = Color(red:base.0+(light.0-base.0)*energy,green:base.1+(light.1-base.1)*energy,blue:base.2+(light.2-base.2)*energy)
                context.fill(Path(CGRect(x:Double(x)*size.width/40,y:Double(y)*size.height/24,width:size.width/40+0.5,height:size.height/24+0.5)),with:.color(color))
            }}
        }
    }
}
