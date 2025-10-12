// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ISOInspector",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "ISOInspectorKit",
            targets: ["ISOInspectorKit"]
        ),
        .executable(
            name: "isoinspect",
            targets: ["ISOInspectorCLI"]
        ),
        .executable(
            name: "ISOInspectorApp",
            targets: ["ISOInspectorApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/SoundBlaster/NestedA11yIDs", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "ISOInspectorKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ISOInspectorCLI",
            dependencies: [
                "ISOInspectorKit",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .executableTarget(
            name: "ISOInspectorApp",
            dependencies: [
                "ISOInspectorKit",
                .product(
                    name: "NestedA11yIDs",
                    package: "NestedA11yIDs",
                    condition: .when(platforms: [.iOS, .macOS])
                )
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ISOInspectorKitTests",
            dependencies: ["ISOInspectorKit"],
            resources: [
                .process("Fixtures")
            ]
        ),
        .testTarget(
            name: "ISOInspectorCLITests",
            dependencies: [
                "ISOInspectorCLI",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .testTarget(
            name: "ISOInspectorAppTests",
            dependencies: [
                "ISOInspectorApp",
                "ISOInspectorKit"
            ]
        ),
        .testTarget(
            name: "ISOInspectorPerformanceTests",
            dependencies: [
                "ISOInspectorCLI",
                "ISOInspectorApp",
                "ISOInspectorKit"
            ]
        )
    ]
)
