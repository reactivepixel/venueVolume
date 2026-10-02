import Foundation

/// Runtime geometry and simulation controls generated from the authored library.
/// These channels describe VV Preview 16, not a manufacturer's DMX personality.
public struct FixtureAsset: Codable, Identifiable, Sendable {
    public struct Joint: Codable, Identifiable, Sendable {
        public let id: String
        public let label: String
        public let parent: String?
        public let members: [String]
        public let pivot: [Float]
        public let axis: [Float]
        public let channel: Int // zero based
        public let travel: Float
        public let continuous: Bool
        public let mode: String
        public var range: ClosedRange<Float> { (-128 * travel / 255)...(127 * travel / 255) }
        public func value(channels: [Int]) -> Float {
            let byte = channels.indices.contains(channel) ? channels[channel] : (continuous ? 0 : 128)
            return continuous ? Float(max(0, min(255, byte))) / 255 * travel : (Float(max(0, min(255, byte))) - 128) / 255 * travel
        }
        public func byte(for value: Float) -> Int {
            guard value.isFinite, travel > 0 else { return continuous ? 0 : 128 }
            return max(0, min(255, Int((value / travel * 255 + (continuous ? 0 : 128)).rounded())))
        }
    }
    public struct Emitter: Codable, Sendable {
        public let parent: String?
        public let position: [Float]
        public let axis: [Float]
    }
    public let id: String
    public let name: String
    public let manufacturer: String
    public let family: String
    public let resource: String
    public let sha256: String
    public let boundsMin: [Float]
    public let boundsMax: [Float]
    public let joints: [Joint]
    public let emitters: [Emitter]
    public let headAim: Bool
    public let notes: String
    public var pan: Joint? { joints.first { $0.id == "pan" } }
    public var tilt: Joint? { joints.first { $0.id == "tilt" } }
    public var height: Float { boundsMax[1] - boundsMin[1] }
    public var radius: Float {
        let x = max(abs(boundsMin[0]), abs(boundsMax[0]))
        let z = max(abs(boundsMin[2]), abs(boundsMax[2]))
        return sqrt(x*x + z*z)
    }
    public var neutralChannels: [Int] {
        var values = Array(repeating: 0, count: 16)
        values[4] = 128; values[5] = 128; values[6] = 128
        for joint in joints { values[joint.channel] = joint.continuous ? 0 : 128 }
        return values
    }
    public var motionLabel: String {
        if joints.isEmpty { return "Static model" }
        if headAim { return "Pan / tilt" }
        return joints.map(\.label).joined(separator: " · ")
    }
    public func channelName(_ index: Int) -> String {
        let names = joints.filter { $0.channel == index }.map(\.label)
        if !names.isEmpty { return names.joined(separator: " / ") }
        if emitters.isEmpty { return "Unused" }
        return [0: "Dimmer", 1: "Red", 2: "Green", 3: "Blue", 6: "Beam width"][index] ?? "Unused"
    }
}

public enum FixtureCatalog {
    public static let all: [FixtureAsset] = {
        do { return try JSONDecoder().decode([FixtureAsset].self, from: Data(generatedFixtureCatalog.utf8)) }
        catch { preconditionFailure("Invalid generated fixture catalog: \(error)") }
    }()
    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    public static func asset(_ id: String?) -> FixtureAsset? { id.flatMap { byID[$0] } }
}

extension Fixture {
    public var asset: FixtureAsset? { FixtureCatalog.asset(assetID) }
    public var footprintRadius: Float { (asset?.radius ?? 0.12) * max(scale.x, scale.z) }
    public var visualHeight: Float { (asset?.height ?? 0.24) * scale.y }
    public func placementIssue(in room: EnvironmentManifest) -> String? {
        let low = asset?.boundsMin ?? [-0.12,-0.12,-0.12]
        let high = asset?.boundsMax ?? [0.12,0.12,0.12]
        for x in [low[0], high[0]] {
            for y in [low[1], high[1]] {
                for z in [low[2], high[2]] {
                    let point = FixtureAiming.vector(position) + FixtureAiming.rotate(orientation, SIMD3<Float>(x,y,z) * FixtureAiming.vector(scale))
                    guard (0..<3).allSatisfy({ point[$0].isFinite && point[$0] >= room.bounds.min[$0]-0.002 && point[$0] <= room.bounds.max[$0]+0.002 }) else {
                        return "Keep the model's dimensions inside the room bounds."
                    }
                }
            }
        }
        return nil
    }
}
