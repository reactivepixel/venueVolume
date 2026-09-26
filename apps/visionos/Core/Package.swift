// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VenueVolumeCore",
    platforms: [.macOS(.v14), .visionOS(.v2)],
    products: [.library(name: "VenueVolumeCore", targets: ["VenueVolumeCore"])],
    targets: [
        .target(name: "VenueVolumeCore"),
        .testTarget(name: "VenueVolumeCoreTests", dependencies: ["VenueVolumeCore"])
    ]
)
