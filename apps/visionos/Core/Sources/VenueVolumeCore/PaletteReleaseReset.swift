import Foundation

/// Intentional release boundary: old placements, shows and undo journals can restore
/// incompatible preset definitions. Keep imported/scanned room geometry, clear user state
/// once per store, and allow new palette/phaser saves to persist normally afterwards.
public enum PaletteReleaseReset {
    public static func run(placements: URL, library: URL, defaults: UserDefaults) throws {
        let files = FileManager.default
        let marker = library.appendingPathComponent("palette-phaser-release-v2")
        if !files.fileExists(atPath: marker.path) {
            if files.fileExists(atPath: placements.path) {
                for file in try files.contentsOfDirectory(at: placements, includingPropertiesForKeys: nil)
                    where file.pathExtension == "json" {
                    try files.removeItem(at: file)
                }
            }
            for name in ["Setups", "audit-history.json", "touring-shows.json", "touring-history.json"] {
                let file = library.appendingPathComponent(name)
                if files.fileExists(atPath: file.path) { try files.removeItem(at: file) }
            }
            try files.createDirectory(at: library, withIntermediateDirectories: true)
            try Data("2".utf8).write(to: marker, options: .atomic)
        }
        if !defaults.bool(forKey: "venue.paletteRelease.v2") {
            let data = try JSONEncoder().encode(PaletteLibrary.baseline)
            defaults.set(data, forKey: "venue.presets.v1")
            defaults.removeObject(forKey: "venue.paletteBaseline.v1")
            defaults.set(true, forKey: "venue.paletteRelease.v2")
        }
    }
}
