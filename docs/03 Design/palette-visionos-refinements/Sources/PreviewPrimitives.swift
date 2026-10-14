import SwiftUI

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
