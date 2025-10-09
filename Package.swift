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
                "ISOInspectorKit"
            ]
        ),
        .executableTarget(
            name: "ISOInspectorApp",
            dependencies: [
                "ISOInspectorKit"
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
            dependencies: ["ISOInspectorCLI"]
        ),
        .testTarget(
            name: "ISOInspectorAppTests",
            dependencies: ["ISOInspectorApp"]
        )
    ]
)
