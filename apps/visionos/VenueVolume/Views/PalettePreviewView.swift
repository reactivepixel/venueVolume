import SwiftUI
import VenueVolumeCore

/// Flat output preview uses the same palette sampler as the immersive fixtures.
struct PalettePreviewView: View {
    var palette: DMXPreset
    @Environment(VenueModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live preview", systemImage: "light.beacon.max").font(.headline)
                Spacer()
                Text(model.selectedFixtures.isEmpty ? "4 sample fixtures" : "\(model.selectedFixtures.count) selected fixtures").font(.caption).foregroundStyle(.secondary)
                Button { model.setPalettePlaying(!model.palettePlayback.isPlaying) } label: {
                    Image(systemName: model.palettePlayback.isPlaying ? "pause.fill" : "play.fill").frame(width: 60, height: 60)
                }.accessibilityLabel(model.palettePlayback.isPlaying ? "Pause diagram and fixtures" : "Play diagram and fixtures")
            }
            TimelineView(.animation(minimumInterval: 1 / 30, paused: !model.palettePlayback.isPlaying)) { timeline in
                let _ = timeline.date
                let seconds = model.paletteSeconds()
                Canvas { context, size in
                    let count = min(8, max(1, model.selectedFixtures.isEmpty ? 4 : model.selectedFixtures.count))
                    for index in 0..<count {
                        let channels = model.selectedFixtures.indices.contains(index)
                            ? model.renderedChannels(for: model.selectedFixtures[index], at: seconds)
                            : palette.sampledChannels(at: seconds, fixtureIndex: index, fixtureCount: count, palettes: model.presets)
                        let light = LightingPreview(channels: channels)
                        let color = Color(red: Double(light.rgb[0]), green: Double(light.rgb[1]), blue: Double(light.rgb[2]))
                        let x = size.width * (Double(index) + 0.5) / Double(count)
                        let half = min(55, size.width / Double(count) * 0.42)
                        let brightness = Double(channels.first ?? 0) / 255
                        var beam = Path(); beam.move(to: .init(x: x - 5, y: 12)); beam.addLine(to: .init(x: x + 5, y: 12)); beam.addLine(to: .init(x: x + half, y: size.height - 18)); beam.addLine(to: .init(x: x - half, y: size.height - 18)); beam.closeSubpath()
                        context.fill(beam, with: .linearGradient(.init(colors: [color.opacity(brightness * 0.15), color.opacity(brightness * 0.6)]), startPoint: .init(x: x, y: 12), endPoint: .init(x: x, y: size.height)))
                        context.fill(Path(ellipseIn: .init(x: x - half, y: size.height - 26, width: half * 2, height: 16)), with: .color(color.opacity(max(0.04, brightness))))
                        context.fill(Path(roundedRect: .init(x: x - 8, y: 0, width: 16, height: 8), cornerRadius: 3), with: .color(.white.opacity(0.4 + brightness * 0.6)))
                    }
                }.frame(height: 86).accessibilityLabel("Animated fixture output preview")
            }
        }.padding(18).background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 22))
            .onChange(of: reduceMotion, initial: true) { _, reduce in if reduce { model.setPalettePlaying(false) } }
    }
}

struct PaletteSwatch: View {
    let palette: DMXPreset
    @Environment(VenueModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: reduceMotion || palette.phaser == nil)) { time in
            Canvas { context, size in
                for index in 0..<12 {
                    let seconds = reduceMotion ? 0 : time.date.timeIntervalSinceReferenceDate
                    let channels = palette.sampledChannels(at: seconds, fixtureIndex: index, fixtureCount: 12, palettes: model.presets)
                    let light = LightingPreview(channels: channels)
                    let value = palette.channelMask.contains(0) ? Double(channels[0]) / 255 : 1
                    let color = Color(red: Double(light.rgb[0]), green: Double(light.rgb[1]), blue: Double(light.rgb[2]))
                    context.fill(Path(.init(x: Double(index) * size.width / 12, y: 0, width: size.width / 12 + 1, height: size.height)), with: .color(color.opacity(max(0.08, value))))
                }
            }
        }.frame(width: 56, height: 48).clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityHidden(true)
    }
}

struct PhaserCurveView: View {
    let palette: DMXPreset
    @Environment(VenueModel.self) private var model
    var body: some View {
        if let phaser = palette.phaser {
            let channel = palette.channelMask.sorted().first ?? 0
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text(LightingPreview.channelNames[channel]); Spacer(); Text("\(phaser.measure, specifier: "%.1f") beats · \(60 * phaser.measure / phaser.beatsPerMinute, specifier: "%.2f") s") }.font(.caption).foregroundStyle(.secondary)
                Canvas { context, size in
                    for i in 0...4 {
                        var grid = Path(); let y = size.height * Double(i) / 4
                        grid.move(to: .init(x: 0, y: y)); grid.addLine(to: .init(x: size.width, y: y)); context.stroke(grid, with: .color(.white.opacity(0.1)))
                    }
                    var curve = Path()
                    for i in 0...120 {
                        let seconds = Double(i) / 120 * 60 * phaser.measure / phaser.beatsPerMinute
                        let value = palette.sampledChannels(at: seconds, palettes: model.presets)[channel]
                        let point = CGPoint(x: Double(i) / 120 * size.width, y: (1 - Double(value) / 255) * (size.height - 4) + 2)
                        if i == 0 { curve.move(to: point) } else { curve.addLine(to: point) }
                    }
                    context.stroke(curve, with: .color(.white), lineWidth: 2)
                }.frame(height: 86).accessibilityLabel("\(LightingPreview.channelNames[channel]) curve over one phaser cycle")
            }
        }
    }
}
