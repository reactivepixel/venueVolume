import SwiftUI
import UIKit
import RealityKit
import VenueVolumeCore

/// A self-contained sample room; never depends on fixture selection or venue state.
struct PalettePreviewView: View {
    let palette: DMXPreset
    @State private var position = SIMD3<Float>(0, 1, 0)
    @State private var selected = false
    @State private var dragStart: SIMD3<Float>?
    private let scale: Float = 0.12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live sample · cube 1 m above the floor").font(.headline)
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let channels = palette.sampledChannels(at: timeline.date.timeIntervalSinceReferenceDate)
                RealityView { content in
                    let root = Entity(); root.name = "sampleRoom"; root.scale = SIMD3(repeating: scale)
                    func box(_ size: SIMD3<Float>, _ point: SIMD3<Float>, _ color: UIColor, name: String = "") -> ModelEntity {
                        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, isMetallic: false)])
                        entity.name = name; entity.position = point; root.addChild(entity); return entity
                    }
                    _ = box([4, 0.025, 4], [0, 0, 0], .white)
                    _ = box([4, 3, 0.025], [0, 1.5, -2], .white)
                    _ = box([0.025, 3, 4], [-2, 1.5, 0], .white)
                    for index in -4...4 {
                        let coordinate = Float(index) * 0.5
                        _ = box([0.012, 0.012, 4], [coordinate, 0.02, 0], .lightGray)
                        _ = box([4, 0.012, 0.012], [0, 0.02, coordinate], .lightGray)
                        _ = box([4, 0.012, 0.012], [0, coordinate + 2, -1.975], .lightGray)
                        _ = box([0.012, 3, 0.012], [coordinate, 1.5, -1.975], .lightGray)
                    }
                    let cube = box([0.3, 0.3, 0.3], position, .white, name: "sampleCube")
                    cube.components.set(InputTargetComponent()); cube.generateCollisionShapes(recursive: false)
                    for (axis, color) in [(0, UIColor.systemRed), (1, UIColor.systemGreen), (2, UIColor.systemBlue)] {
                        var offset = SIMD3<Float>.zero; offset[axis] = 0.45
                        let handle = box([0.13, 0.13, 0.13], position + offset, color, name: "axis\(axis)")
                        handle.components.set(InputTargetComponent()); handle.generateCollisionShapes(recursive: false)
                    }
                    let light = SpotLight(); light.name = "sampleLight"; light.position = position
                    root.addChild(light); content.add(root)
                } update: { content in
                    guard let root = content.entities.first,
                          let cube = root.findEntity(named: "sampleCube") as? ModelEntity,
                          let light = root.findEntity(named: "sampleLight") as? SpotLight else { return }
                    let preview = LightingPreview(channels: channels)
                    cube.position = position
                    cube.model?.materials = [SimpleMaterial(color: selected ? .lightGray : .white, isMetallic: false)]
                    light.light.intensity = preview.intensity
                    light.light.color = UIColor(red: CGFloat(preview.rgb[0]), green: CGFloat(preview.rgb[1]), blue: CGFloat(preview.rgb[2]), alpha: 1)
                    light.light.outerAngleInDegrees = preview.outerAngle
                    let pan = preview.panDegrees * .pi / 180, tilt = preview.tiltDegrees * .pi / 180
                    // Neutral aim faces down. Pan sweeps horizontally; tilt moves the beam off vertical.
                    let direction = SIMD3<Float>(sin(pan) * sin(tilt), -cos(tilt), -cos(pan) * sin(tilt))
                    light.light.attenuationRadius = 8
                    light.light.innerAngleInDegrees = preview.outerAngle * 0.7
                    light.look(at: position + direction, from: position, relativeTo: root)
                    for axis in 0...2 {
                        var offset = SIMD3<Float>.zero; offset[axis] = 0.45
                        root.findEntity(named: "axis\(axis)")?.position = position + offset
                        root.findEntity(named: "axis\(axis)")?.isEnabled = selected
                    }
                }
                .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
                    if value.entity.name == "sampleCube" { selected.toggle() }
                })
                .simultaneousGesture(DragGesture().targetedToAnyEntity().onChanged { value in
                    guard let axis = Int(value.entity.name.replacingOccurrences(of: "axis", with: "")) else { return }
                    if dragStart == nil { dragStart = position }
                    let translation = value.convert(value.translation3D, from: .global, to: .scene)
                    position[axis] = min(axis == 1 ? 2.7 : 1.7, max(axis == 1 ? 0.2 : -1.7, (dragStart ?? position)[axis] + translation[axis] / scale))
                }.onEnded { _ in dragStart = nil })
            }.frame(height: 250)
            Text("Select the cube, then drag a red X, green Y or blue Z handle. Preview uses the VV simulation profile.").font(.caption).foregroundStyle(.secondary)
        }.padding(16).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
