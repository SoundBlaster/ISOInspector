// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ISOInspector",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "FoundationUI",
            targets: ["FoundationUI"]
        ),
        .library(
            name: "ISOInspectorKit",
            targets: ["ISOInspectorKit"]
        ),
        .executable(
            name: "isoinspect",
            targets: ["ISOInspectorCLIRunner"]
        ),
        .executable(
            name: "ISOInspectorApp",
            targets: ["ISOInspectorApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/SoundBlaster/NestedA11yIDs", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "ISOInspectorKit",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "ISOInspectorCLI",
            dependencies: [
                "ISOInspectorKit",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
        .executableTarget(
            name: "ISOInspectorCLIRunner",
            dependencies: ["ISOInspectorCLI"]
        ),
        .executableTarget(
            name: "ISOInspectorApp",
            dependencies: [
                "ISOInspectorKit",
                .product(
                    name: "NestedA11yIDs",
                    package: "NestedA11yIDs",
                    condition: .when(platforms: [.iOS, .macOS])
                ),
                .target(name: "FoundationUI", condition: .when(platforms: [.iOS, .macOS])),
            ],
            resources: [
                .process("Resources")
            ],
            platforms: [.iOS, .macOS]
        ),
        .target(
            name: "FoundationUI",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ],
            path: "FoundationUI/Sources/FoundationUI",
            exclude: [
                "README.md",
                ".swiftlint.yml",
                "AgentSupport/ComponentSchema.yaml",
                "AgentSupport/Examples/README.md",
                "AgentSupport/Examples/badge_examples.yaml",
                "AgentSupport/Examples/inspector_pattern_examples.yaml",
                "AgentSupport/Examples/complete_ui_example.yaml",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release)),
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
                ),
            ]
        ),
        .testTarget(
            name: "ISOInspectorAppTests",
            dependencies: [
                "ISOInspectorApp",
                "ISOInspectorKit",
                .target(name: "FoundationUI", condition: .when(platforms: [.iOS, .macOS])),
            ],
            platforms: [.iOS, .macOS]
        ),
        .testTarget(
            name: "ISOInspectorPerformanceTests",
            dependencies: [
                "ISOInspectorCLI",
                "ISOInspectorApp",
                "ISOInspectorKit",
            ]
        ),
    ]
)
