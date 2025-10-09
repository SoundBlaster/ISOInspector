// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ISOInspector",
    platforms: [
        .iOS(.v16), .macOS(.v13)
    ],
    products: [
        .library(name: "ISOInspectorKit", targets: ["ISOInspectorKit"]),
        .executable(name: "isoinspect", targets: ["ISOInspectorCLI"])
    ],
    targets: [
        .target(name: "ISOInspectorKit", path: "Sources/ISOInspectorKit"),
        .executableTarget(name: "ISOInspectorCLI", dependencies: ["ISOInspectorKit"], path: "Sources/ISOInspectorCLI"),
        .testTarget(name: "ISOInspectorKitTests", dependencies: ["ISOInspectorKit"], path: "Tests/ISOInspectorKitTests")
    ]
)
