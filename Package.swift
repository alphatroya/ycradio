// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ycradio",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "YcradioCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Ycradio",
            dependencies: ["YcradioCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "YcradioCoreTests",
            dependencies: ["YcradioCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
