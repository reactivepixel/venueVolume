import Foundation

/// Deliberately synthetic visualizer personality, never a manufacturer's wire protocol.
public struct LightingPreview: Equatable, Sendable {
    public static let assetID = "chauvet-professional/rogue-r1x-spot"
    public static let profileName = "VV Preview 16 · simulation"
    public static let channelNames = ["Dimmer", "Red", "Green", "Blue", "Pan", "Tilt", "Beam width"]
    public static let footprintRadius: Float = 0.23 // conservative envelope at any base yaw
    public static let height: Float = 0.447
    public let intensity: Float
    public let rgb: [Float]
    public let panDegrees: Float
    public let tiltDegrees: Float
    public let outerAngle: Float

    public init(channels: [Int], blackout: Bool = false) {
        func value(_ index: Int, fallback: Int = 0) -> Float {
            Float(min(255, max(0, channels.indices.contains(index) ? channels[index] : fallback))) / 255
        }
        intensity = blackout ? 0 : value(0) * 35_000
        rgb = [value(1), value(2), value(3)]
        panDegrees = (value(4, fallback: 128) - 128 / 255) * 270
        tiltDegrees = (value(5, fallback: 128) - 128 / 255) * 120
        outerAngle = 10 + value(6, fallback: 128) * 50
    }

    public static let presets = [
        DMXPreset(id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, name: "Warm room wash",
                  channels: [210, 255, 170, 95, 128, 145, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        DMXPreset(id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!, name: "Blue focus",
                  channels: [255, 45, 115, 255, 128, 145, 125, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        DMXPreset(id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!, name: "White work light",
                  channels: [180, 255, 255, 255, 128, 128, 240, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    ]

    public static func placementIssue(_ position: Position3D, in room: EnvironmentManifest) -> String? {
        let values = [position.x, position.y, position.z]
        guard values.allSatisfy(\.isFinite) else { return "Position must contain finite numbers." }
        guard position.x >= room.bounds.min[0] + footprintRadius,
              position.x <= room.bounds.max[0] - footprintRadius,
              position.z >= room.bounds.min[2] + footprintRadius,
              position.z <= room.bounds.max[2] - footprintRadius,
              position.y >= 0, position.y + height <= room.bounds.max[1] else {
            return "Keep the fixture inside the room, above the floor and below the ceiling."
        }
        return nil
    }
}
