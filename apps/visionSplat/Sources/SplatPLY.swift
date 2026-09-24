import Foundation
import simd

struct SplatCloud: Sendable {
    var positions: [Float] = []
    var logScales: [Float] = []
    var rotations: [Float] = []
    var logitOpacities: [Float] = []
    var dc: [Float] = []
    var count: Int { logitOpacities.count }
    var center: SIMD3<Float> {
        guard count > 0 else { return .zero }
        var low = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var high = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for i in 0..<count {
            let p = SIMD3<Float>(positions[i*3], positions[i*3+1], positions[i*3+2])
            low = simd_min(low, p)
            high = simd_max(high, p)
        }
        return low + (high - low) / 2
    }

    func subset(_ indices: [Int]) -> SplatCloud {
        var result = SplatCloud()
        result.positions.reserveCapacity(indices.count * 3)
        result.logScales.reserveCapacity(indices.count * 3)
        result.rotations.reserveCapacity(indices.count * 4)
        result.logitOpacities.reserveCapacity(indices.count)
        result.dc.reserveCapacity(indices.count * 3)
        for i in indices {
            result.positions.append(contentsOf: positions[(i * 3)..<(i * 3 + 3)])
            result.logScales.append(contentsOf: logScales[(i * 3)..<(i * 3 + 3)])
            result.rotations.append(contentsOf: rotations[(i * 4)..<(i * 4 + 4)])
            result.logitOpacities.append(logitOpacities[i])
            result.dc.append(contentsOf: dc[(i * 3)..<(i * 3 + 3)])
        }
        return result
    }
}

enum PLYError: LocalizedError {
    case invalidHeader, unsupportedFormat, missingProperty(String), truncated, invalidValue, tooLarge
    var errorDescription: String? {
        switch self {
        case .invalidHeader: "Invalid PLY header or vertex layout."
        case .unsupportedFormat: "Only ASCII and binary little-endian PLY are supported."
        case .missingProperty(let name): "Required Gaussian property is missing: \(name)."
        case .truncated: "PLY vertex data is truncated."
        case .invalidValue: "PLY contains a non-finite or malformed Gaussian value."
        case .tooLarge: "PLY exceeds the demo limit of 250,000 splats or 96 MiB."
        }
    }
}

enum SplatPLY {
    private struct Property {
        let name: String
        let type: String
        let byteSize: Int
    }
    private static let required = ["x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"]

    static func read(url: URL) throws -> SplatCloud {
        guard let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              bytes <= 96 * 1024 * 1024 else { throw PLYError.tooLarge }
        return try parse(Data(contentsOf: url, options: .mappedIfSafe))
    }

    static func parse(_ data: Data) throws -> SplatCloud {
        guard data.count <= 96 * 1024 * 1024 else { throw PLYError.tooLarge }
        var start: Int? = nil
        var cursor = 0
        while cursor < min(data.count, 1_048_576) {
            guard let newline = data[cursor...].firstIndex(of: 10) else { break }
            guard newline < 1_048_576 else { throw PLYError.invalidHeader }
            guard let line = String(data: data[cursor..<newline], encoding: .ascii) else { throw PLYError.invalidHeader }
            cursor = data.index(after: newline)
            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "end_header" {
                start = cursor
                break
            }
        }
        guard let start, let header = String(data: data[..<start], encoding: .ascii) else { throw PLYError.invalidHeader }
        let lines = header.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard lines.first == "ply" else { throw PLYError.invalidHeader }
        var format = ""
        var vertexCount = 0
        var properties: [Property] = []
        var currentElement = ""
        var sawOtherElementBeforeVertex = false
        for line in lines {
            let parts = line.split(separator: " ").map(String.init)
            guard !parts.isEmpty else { continue }
            if parts[0] == "format", parts.count == 3, parts[2] == "1.0" { format = parts[1] }
            if parts[0] == "element", parts.count == 3 {
                currentElement = parts[1]
                if currentElement == "vertex" { vertexCount = Int(parts[2]) ?? 0 }
                else if vertexCount == 0 { sawOtherElementBeforeVertex = true }
            }
            if parts[0] == "property", currentElement == "vertex" {
                guard parts.count == 3, let size = byteSize(parts[1]) else { throw PLYError.invalidHeader }
                properties.append(Property(name: parts[2], type: parts[1], byteSize: size))
            }
        }
        guard !sawOtherElementBeforeVertex, vertexCount > 0 else { throw PLYError.invalidHeader }
        guard vertexCount <= 250_000 else { throw PLYError.tooLarge }
        guard format == "ascii" || format == "binary_little_endian" else { throw PLYError.unsupportedFormat }
        let names = properties.map(\.name)
        guard Set(names).count == names.count else { throw PLYError.invalidHeader }
        for name in required where !names.contains(name) { throw PLYError.missingProperty(name) }
        var cloud = SplatCloud()
        cloud.positions.reserveCapacity(vertexCount * 3)
        cloud.logScales.reserveCapacity(vertexCount * 3)
        cloud.rotations.reserveCapacity(vertexCount * 4)
        cloud.logitOpacities.reserveCapacity(vertexCount)
        cloud.dc.reserveCapacity(vertexCount * 3)
        let index = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($0.element, $0.offset) })
        func append(_ values: [Float]) throws {
            func get(_ name: String) -> Float { values[index[name]!] }
            let p = [get("x"), get("y"), get("z")]
            guard p.allSatisfy({ abs($0) <= 1_000_000 }) else { throw PLYError.invalidValue }
            cloud.positions.append(contentsOf: p)
            cloud.logScales.append(contentsOf: [get("scale_0"), get("scale_1"), get("scale_2")].map { min(5, max(-12, $0)) })
            let q = SIMD4<Float>(get("rot_0"), get("rot_1"), get("rot_2"), get("rot_3"))
            let maximum = max(max(abs(q.x), abs(q.y)), max(abs(q.z), abs(q.w)))
            guard maximum > 0, maximum.isFinite else { throw PLYError.invalidValue }
            let scaled = q / maximum
            let length = simd_length(scaled)
            guard length > 0, length.isFinite else { throw PLYError.invalidValue }
            let normalized = scaled / length
            cloud.rotations.append(contentsOf: [normalized.x, normalized.y, normalized.z, normalized.w])
            cloud.logitOpacities.append(get("opacity"))
            cloud.dc.append(contentsOf: [get("f_dc_0"), get("f_dc_1"), get("f_dc_2")])
        }
        if format == "ascii" {
            guard let body = String(data: data[start...], encoding: .ascii) else { throw PLYError.invalidValue }
            let vertexLines = body.split(whereSeparator: \.isNewline)
            guard vertexLines.count >= vertexCount else { throw PLYError.truncated }
            for line in vertexLines.prefix(vertexCount) {
                let values = line.split(whereSeparator: \.isWhitespace)
                guard values.count >= properties.count else { throw PLYError.truncated }
                let parsed = try values.prefix(properties.count).map { token in
                    guard let value = Float(token), value.isFinite else { throw PLYError.invalidValue }
                    return value
                }
                try append(parsed)
            }
        } else {
            let stride = properties.reduce(0) { $0 + $1.byteSize }
            guard stride > 0, data.count - start >= vertexCount * stride else { throw PLYError.truncated }
            for i in 0..<vertexCount {
                var offset = start + i * stride
                var values: [Float] = []
                values.reserveCapacity(properties.count)
                for property in properties {
                    let value = try scalar(data, at: offset, type: property.type)
                    guard value.isFinite else { throw PLYError.invalidValue }
                    values.append(value)
                    offset += property.byteSize
                }
                try append(values)
            }
        }
        return cloud
    }

    private static func byteSize(_ type: String) -> Int? {
        switch type {
        case "char", "uchar", "int8", "uint8": 1
        case "short", "ushort", "int16", "uint16": 2
        case "int", "uint", "float", "int32", "uint32", "float32": 4
        case "double", "float64": 8
        default: nil
        }
    }

    private static func scalar(_ data: Data, at offset: Int, type: String) throws -> Float {
        guard let size = byteSize(type), offset + size <= data.count else { throw PLYError.truncated }
        func bits() -> UInt64 {
            var value: UInt64 = 0
            for i in 0..<size { value |= UInt64(data[offset + i]) << (i * 8) }
            return value
        }
        let value = bits()
        switch type {
        case "float", "float32": return Float(bitPattern: UInt32(value))
        case "double", "float64": return Float(Double(bitPattern: value))
        case "char", "int8": return Float(Int8(bitPattern: UInt8(value)))
        case "uchar", "uint8": return Float(value)
        case "short", "int16": return Float(Int16(bitPattern: UInt16(value)))
        case "ushort", "uint16": return Float(value)
        case "int", "int32": return Float(Int32(bitPattern: UInt32(value)))
        case "uint", "uint32": return Float(value)
        default: throw PLYError.invalidHeader
        }
    }
}
