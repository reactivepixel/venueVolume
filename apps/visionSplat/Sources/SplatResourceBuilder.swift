#if !targetEnvironment(simulator)
import CoreGraphics
import Metal
import RealityKit
import simd

@MainActor
enum SplatResourceBuilder {
    static func makeEntity(_ cloud: SplatCloud) throws -> Entity {
        let root = Entity()
        guard cloud.count > 0 else { return root }
        // Keep resources local. A single room-wide resource is culled when the
        // wearer enters its bounds on current visionOS 27 device builds.
        var low = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var high = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for i in 0..<cloud.count {
            let p = SIMD3<Float>(cloud.positions[i*3], cloud.positions[i*3+1], cloud.positions[i*3+2])
            low = simd_min(low, p)
            high = simd_max(high, p)
        }
        let span = simd_max(high - low, SIMD3<Float>(repeating: 0.001))
        func key(_ i: Int) -> Int {
            let p = SIMD3<Float>(cloud.positions[i*3], cloud.positions[i*3+1], cloud.positions[i*3+2])
            let cell = simd_clamp((p - low) / span * 4, SIMD3<Float>(repeating: 0), SIMD3<Float>(repeating: 3))
            return (Int(cell.x) * 4 + Int(cell.y)) * 4 + Int(cell.z)
        }
        var cells: [Int: [Int]] = [:]
        for i in 0..<cloud.count { cells[key(i), default: []].append(i) }
        for cellKey in cells.keys.sorted() {
            guard let indices = cells[cellKey] else { continue }
            var start = 0
            while start < indices.count {
                let end = min(start + 4096, indices.count)
                var subset = cloud.subset(Array(indices[start..<end]))
                // Keep small cells local. Padded copies have effectively zero
                // opacity and meet the device renderer's minimum buffer count.
                let ghostPosition = Array(subset.positions[0..<3])
                let ghostScale = Array(subset.logScales[0..<3])
                let ghostRotation = Array(subset.rotations[0..<4])
                let ghostColor = Array(subset.dc[0..<3])
                while subset.count < 256 {
                    subset.positions.append(contentsOf: ghostPosition)
                    subset.logScales.append(contentsOf: ghostScale)
                    subset.rotations.append(contentsOf: ghostRotation)
                    subset.dc.append(contentsOf: ghostColor)
                    subset.logitOpacities.append(-30)
                }
                let resource = try makeResource(subset)
                let entity = Entity()
                entity.components.set(GaussianSplatComponent(resource))
                root.addChild(entity)
                start = end
            }
        }
        return root
    }

    private static func makeResource(_ cloud: SplatCloud) throws -> GaussianSplatResource {
        let position = try descriptor(cloud.positions, components: 3, format: .float3)
        let scale = try descriptor(cloud.logScales, components: 3, format: .float3)
        let rotation = try descriptor(cloud.rotations, components: 4, format: .float4)
        let opacity = try descriptor(cloud.logitOpacities, components: 1, format: .float)
        let harmonics = try descriptor(cloud.dc, components: 3, format: .float3)
        let buffers = try GaussianSplatResource.BufferResource(
            count: cloud.count,
            position: position,
            scale: scale,
            rotation: rotation,
            opacity: opacity,
            sphericalHarmonics: (harmonics, .zero)
        )
        let resource = GaussianSplatResource(buffers)
        resource.scaleActivation = .exponential
        resource.opacityActivation = .sigmoid
        resource.colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        return resource
    }

    private static func descriptor(_ values: [Float], components: Int, format: MTLAttributeFormat) throws -> GaussianSplatResource.BufferDescriptor {
        let used = values.count * MemoryLayout<Float>.stride
        let buffer = try LowLevelBuffer(descriptor: .init(capacity: (used + 255) & ~255))
        buffer.withUnsafeMutableBytes { destination in
            values.withUnsafeBytes { source in destination.copyMemory(from: source) }
        }
        buffer.bytesUsed = used
        return .init(buffer: buffer, format: format, stride: components * MemoryLayout<Float>.stride, offset: 0)
    }
}
#endif
