// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ComponentTestApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ComponentTestApp",
            targets: ["ComponentTestApp"]
        ),
    ],
    dependencies: [
        .package(path: "../../FoundationUI")
    ],
    targets: [
        .executableTarget(
            name: "ComponentTestApp",
            dependencies: [
                .product(name: "FoundationUI", package: "FoundationUI")
            ],
            path: "ComponentTestApp"
        ),
    ]
)
