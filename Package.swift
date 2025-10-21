// swift-tools-version: 6.0
import PackageDescription

// Conditional products and targets based on platform
// FoundationUI requires SwiftUI which is only available on Apple platforms
#if os(macOS) || os(iOS)
let foundationUIProducts: [Product] = [
    .library(
        name: "FoundationUI",
        targets: ["FoundationUI"]
    )
]

let conditionalTargets: [Target] = [
    .target(
        name: "FoundationUI",
        dependencies: []
    ),
    .testTarget(
        name: "FoundationUITests",
        dependencies: ["FoundationUI"]
    )
]
#else
let foundationUIProducts: [Product] = []
let conditionalTargets: [Target] = []
#endif

let package = Package(
    name: "ISOInspector",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
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
        )
    ] + foundationUIProducts,
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/SoundBlaster/NestedA11yIDs", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: conditionalTargets + [
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
                )
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
