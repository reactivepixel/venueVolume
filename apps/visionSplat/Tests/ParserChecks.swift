// Run from apps/visionSplat on macOS:
// swiftc Sources/SplatPLY.swift Tests/ParserChecks.swift -o /tmp/visionsplat-parser-checks
// /tmp/visionsplat-parser-checks ../../assets/splats
import Foundation

@main
struct ParserChecks {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Pass the shared assets/splats directory")
        }
        let fixtures = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let asciiData = try Data(contentsOf: fixtures.appendingPathComponent("tiny-ascii.ply"))
        let ascii = try SplatPLY.parse(asciiData)
        let binary = try SplatPLY.read(url: fixtures.appendingPathComponent("tiny-binary.ply"))
        let reordered = try SplatPLY.read(url: fixtures.appendingPathComponent("tiny-reordered-binary.ply"))
        precondition(ascii.count == 3 && binary.count == 3 && reordered.count == 3)
        precondition(ascii.center == SIMD3<Float>(0, 1.5, 0))
        for other in [binary, reordered] {
            precondition(close(other.positions, ascii.positions))
            precondition(close(other.logScales, ascii.logScales))
            precondition(close(other.rotations, ascii.rotations))
            precondition(close(other.logitOpacities, ascii.logitOpacities))
            precondition(close(other.dc, ascii.dc))
        }

        let asciiText = String(decoding: asciiData, as: UTF8.self)
        let crlf = Data(asciiText.replacingOccurrences(of: "\n", with: "\r\n").utf8)
        let parsedCRLF = try SplatPLY.parse(crlf)
        precondition(parsedCRLF.count == 3)

        let duplicate = Data(asciiText.replacingOccurrences(of: "property float x\n", with: "property float x\nproperty float x\n").utf8)
        try expectError(duplicate) { error in
            guard let value = error as? PLYError else { return false }
            if case .invalidHeader = value { return true }
            return false
        }

        let binaryData = try Data(contentsOf: fixtures.appendingPathComponent("tiny-binary.ply"))
        try expectError(Data(binaryData.dropLast())) { error in
            guard let value = error as? PLYError else { return false }
            if case .truncated = value { return true }
            return false
        }

        let tooMany = Data(asciiText.replacingOccurrences(of: "element vertex 3", with: "element vertex 250001").utf8)
        try expectError(tooMany) { error in
            guard let value = error as? PLYError else { return false }
            if case .tooLarge = value { return true }
            return false
        }

        let zeroQuaternion = Data(asciiText.replacingOccurrences(of: " 1 0 0 0\n", with: " 0 0 0 0\n").utf8)
        try expectError(zeroQuaternion) { error in
            guard let value = error as? PLYError else { return false }
            if case .invalidValue = value { return true }
            return false
        }
        print("visionSplat parser checks passed")
    }

    static func expectError(_ data: Data, matching: (Error) -> Bool) throws {
        do {
            _ = try SplatPLY.parse(data)
            fatalError("Expected parser rejection")
        } catch {
            precondition(matching(error), "Unexpected error: \(error)")
        }
    }

    static func close(_ a: [Float], _ b: [Float]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { pair in abs(pair.0 - pair.1) < 0.00001 }
    }
}
