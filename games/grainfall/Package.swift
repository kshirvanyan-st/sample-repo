// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Grainfall",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GrainfallCore", targets: ["GrainfallCore"]),
        .executable(name: "grainfall-sim", targets: ["grainfall-sim"]),
    ],
    targets: [
        .target(
            name: "GrainfallCore",
            resources: [.copy("Resources/levels")]
        ),
        .executableTarget(name: "grainfall-sim", dependencies: ["GrainfallCore"]),
        .testTarget(name: "GrainfallCoreTests", dependencies: ["GrainfallCore"]),
    ]
)
