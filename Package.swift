// swift-tools-version: 6.0
import PackageDescription

// Platform-independent products
var products: [Product] = [
    .library(
        name: "ISOInspectorKit",
        targets: ["ISOInspectorKit"]
    ),
    .executable(
        name: "isoinspect",
        targets: ["ISOInspectorCLIRunner"]
    ),
]

// Add iOS/macOS-only products
#if os(macOS) || os(iOS)
    products.append(
        .library(
            name: "FoundationUI",
            targets: ["FoundationUI"]
        ))
    products.append(
        .executable(
            name: "ISOInspectorApp",
            targets: ["ISOInspectorApp"]
        ))
#endif

// Platform-independent targets
var targets: [Target] = [
    .target(
        name: "ISOInspectorKit",
        resources: [
            .process("Resources")
        ],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
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
        ],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    ),
    .executableTarget(
        name: "ISOInspectorCLIRunner",
        dependencies: ["ISOInspectorCLI"],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    ),
    .testTarget(
        name: "ISOInspectorKitTests",
        dependencies: ["ISOInspectorKit"],
        resources: [
            .process("Fixtures")
        ],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
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
        ],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    ),
]

// Add iOS/macOS-only targets
#if os(macOS) || os(iOS)
    targets.append(
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
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ))

    targets.append(
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
        ))

    targets.append(
        .testTarget(
            name: "ISOInspectorAppTests",
            dependencies: [
                "ISOInspectorApp",
                "ISOInspectorKit",
                .target(name: "FoundationUI", condition: .when(platforms: [.iOS, .macOS])),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ))

    targets.append(
        .testTarget(
            name: "ISOInspectorPerformanceTests",
            dependencies: [
                "ISOInspectorCLI",
                "ISOInspectorApp",
                "ISOInspectorKit",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ))
#endif

// Platform-independent dependencies
var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
]

// Add iOS/macOS-only dependencies
#if os(macOS) || os(iOS)
    dependencies.append(
        .package(url: "https://github.com/SoundBlaster/NestedA11yIDs", from: "1.0.0"))
    dependencies.append(.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"))
#endif

let package = Package(
    name: "ISOInspector",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
