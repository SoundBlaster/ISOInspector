// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FoundationUI",
            targets: ["FoundationUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
    ],
    targets: [
        .target(
            name: "FoundationUI",
            dependencies: [],
            exclude: ["README.md"],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        // MARK: - Test Targets
        .testTarget(
            name: "FoundationUITests",
            dependencies: [
                "FoundationUI"
            ],
            path: "Tests/FoundationUITests",
            exclude: [
                // Exclude any non-test files
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FoundationUISnapshotTests",
            dependencies: [
                "FoundationUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/SnapshotTests",
            exclude: [
                // Exclude any non-test files if needed
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
    ]
)
