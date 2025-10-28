// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var foundationUISwiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
]

var foundationUITestSwiftSettings: [SwiftSetting] = []

#if compiler(<6.0)
foundationUISwiftSettings.insert(.enableUpcomingFeature("StrictConcurrency"), at: 0)
foundationUITestSwiftSettings.insert(.enableUpcomingFeature("StrictConcurrency"), at: 0)
#endif

let package = Package(
    name: "FoundationUI",
    platforms: [
        .iOS(.v16),
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
            swiftSettings: foundationUISwiftSettings
        ),
        .testTarget(
            name: "FoundationUITests",
            dependencies: [
                "FoundationUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            swiftSettings: foundationUITestSwiftSettings
        ),
    ]
)
