// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
    targets: [
        .target(
            name: "FoundationUI",
            dependencies: []
        ),
        .testTarget(
            name: "FoundationUITests",
            dependencies: ["FoundationUI"]
        ),
    ]
)
