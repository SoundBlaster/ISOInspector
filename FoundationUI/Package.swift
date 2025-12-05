// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationUI", platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FoundationUI", targets: ["FoundationUI"])],
    dependencies: [
        // NOTE: swift-snapshot-testing removed from SPM dependencies
        // Snapshot tests are only run via Tuist + xcodebuild (not SPM)
        // See FoundationUI/Project.swift for Tuist configuration
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "FoundationUI", dependencies: [.product(name: "Yams", package: "Yams")],
            exclude: [
                "README.md", "AgentSupport/ComponentSchema.yaml", "AgentSupport/Examples/README.md",
                "AgentSupport/Examples/badge_examples.yaml",
                "AgentSupport/Examples/inspector_pattern_examples.yaml",
                "AgentSupport/Examples/complete_ui_example.yaml"
            ],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))]),

        // MARK: - Test Targets

        .testTarget(
            name: "FoundationUITests", dependencies: ["FoundationUI"],
            path: "Tests/FoundationUITests",
            exclude: [
                // Exclude any non-test files
            ]
            // NOTE: StrictConcurrency is enabled by default in Swift 6.0
            // No need for .enableUpcomingFeature("StrictConcurrency")
        )
        // NOTE: FoundationUISnapshotTests removed from SPM configuration
        // Snapshot tests are only run via Tuist + xcodebuild in CI
        // SPM validation job runs only unit tests (FoundationUITests)
        // Reason: SnapshotTesting API incompatibility with SPM on macOS
        // See: .github/workflows/foundationui.yml (validate-spm-package job)
    ])
