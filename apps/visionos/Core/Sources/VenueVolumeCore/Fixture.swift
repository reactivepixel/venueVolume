import Foundation

public struct Position3D: Codable, Equatable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// A generic, unverified DMX fixture. Addresses are one-based logical addresses.
public struct Fixture: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var universe: Int
    public var startAddress: Int
    public var channels: [Int]
    public var position: Position3D

    public init(id: UUID = UUID(), name: String, universe: Int = 1,
                startAddress: Int = 1, channels: [Int] = Array(repeating: 0, count: 8),
                position: Position3D = .init(x: 0, y: 1.4, z: -2)) {
        self.id = id
        self.name = name
        self.universe = universe
        self.startAddress = startAddress
        self.channels = channels
        self.position = position
    }

    public var endAddress: Int { startAddress + channels.count - 1 }

    public func validationIssue(among fixtures: [Fixture]) -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Give this fixture a name." }
        if !(1...63999).contains(universe) { return "Universe must be between 1 and 63999." }
        if !(1...16).contains(channels.count) { return "Choose between 1 and 16 channels." }
        if !(1...512).contains(startAddress) || endAddress > 512 { return "The full footprint must fit within addresses 1–512." }
        if channels.contains(where: { !(0...255).contains($0) }) { return "Channel values must be between 0 and 255." }
        if !position.x.isFinite || !position.y.isFinite || !position.z.isFinite { return "The fixture position is invalid." }
        if let other = fixtures.first(where: {
            $0.id != id && $0.universe == universe && startAddress <= $0.endAddress && $0.startAddress <= endAddress
        }) { return "Addresses overlap with \(other.name) in universe \(universe)." }
        return nil
    }

    public static func nextAvailablePatch(in fixtures: [Fixture], footprint: Int) -> (universe: Int, address: Int)? {
        guard (1...16).contains(footprint) else { return nil }
        for universe in 1...63999 {
            let occupied = fixtures.filter { $0.universe == universe }
            for address in 1...(513 - footprint) {
                let end = address + footprint - 1
                if !occupied.contains(where: { address <= $0.endAddress && $0.startAddress <= end }) {
                    return (universe, address)
                }
            }
        }
        return nil
    }
}
