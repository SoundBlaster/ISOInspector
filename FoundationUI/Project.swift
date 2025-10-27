import ProjectDescription

// MARK: - FoundationUI Project Configuration

/// FoundationUI - Composable Clarity Design System for ISO Inspector
///
/// A SwiftUI component library following TDD, XP, and Composable Clarity principles.
/// Supports iOS 16+, iPadOS 16+, macOS 14+.
///
/// ## Architecture
/// - Layer 0: Design Tokens (DS namespace)
/// - Layer 1: View Modifiers
/// - Layer 2: Components
/// - Layer 3: Patterns
/// - Layer 4: Contexts

let baseSettings: SettingsDictionary = [
    "MARKETING_VERSION": "0.1.0",
    "CURRENT_PROJECT_VERSION": "1",
    "SWIFT_VERSION": "6.0",
    "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
    "MACOSX_DEPLOYMENT_TARGET": "14.0"
]

// MARK: - Framework Target

func foundationUIFramework() -> Target {
    Target.target(
        name: "FoundationUI",
        destinations: [.iPhone, .iPad, .mac],
        product: .framework,
        bundleId: "ru.egormerkushev.foundationui",
        deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.0"),
        infoPlist: .default,
        sources: ["Sources/FoundationUI/**"],
        settings: .settings(base: baseSettings)
    )
}

// MARK: - Test Target

func foundationUITests() -> Target {
    Target.target(
        name: "FoundationUITests",
        destinations: [.iPhone, .iPad, .mac],
        product: .unitTests,
        bundleId: "ru.egormerkushev.foundationui.tests",
        deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.0"),
        infoPlist: .default,
        sources: ["Tests/FoundationUITests/**"],
        dependencies: [
            .target(name: "FoundationUI"),
            .package(product: "SnapshotTesting")
        ],
        settings: .settings(base: baseSettings)
    )
}

// MARK: - Project

let project = Project(
    name: "FoundationUI",
    organizationName: "ISOInspector",
    options: .options(),
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            requirement: .upToNextMajor(from: "1.15.0")
        )
    ],
    targets: [
        foundationUIFramework(),
        foundationUITests()
    ],
    schemes: [
        .scheme(
            name: "FoundationUI",
            shared: true,
            buildAction: .buildAction(targets: ["FoundationUI"]),
            testAction: .targets(["FoundationUITests"])
        )
    ]
)
