import ProjectDescription

// MARK: - ComponentTestApp Project Configuration

/// ComponentTestApp - Demo Application for FoundationUI Components
///
/// A minimal demo application showcasing all implemented FoundationUI components
/// with interactive examples, live preview capabilities, and comprehensive documentation.
///
/// Supports: iOS 17+, macOS 14+
/// Architecture: SwiftUI universal app

let baseSettings: SettingsDictionary = [
    "MARKETING_VERSION": "1.0.0",
    "CURRENT_PROJECT_VERSION": "1",
    "SWIFT_VERSION": "6.0",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MACOSX_DEPLOYMENT_TARGET": "14.0"
]

// MARK: - App Target (iOS)

func componentTestAppIOS() -> Target {
    Target.target(
        name: "ComponentTestApp-iOS",
        destinations: [.iPhone, .iPad],
        product: .app,
        bundleId: "ru.egormerkushev.componenttestapp.ios",
        deploymentTargets: .iOS("17.0"),
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "ComponentTest",
            "UILaunchScreen": .dictionary([
                "UIImageName": .string(""),
                "UIColorName": .string("")
            ])
        ]),
        sources: ["ComponentTestApp/**"],
        dependencies: [
            .project(
                target: "FoundationUI",
                path: .relativeToRoot("FoundationUI")
            ),
            .project(
                target: "ISOInspectorApp",
                path: .relativeToRoot(".")
            )
        ],
        settings: .settings(base: baseSettings)
    )
}

// MARK: - App Target (macOS)

func componentTestAppMacOS() -> Target {
    Target.target(
        name: "ComponentTestApp-macOS",
        destinations: [.mac],
        product: .app,
        bundleId: "ru.egormerkushev.componenttestapp.macos",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .extendingDefault(with: [
            "CFBundleDisplayName": "ComponentTest",
            "NSHumanReadableCopyright": "© 2025 ISOInspector Project"
        ]),
        sources: ["ComponentTestApp/**"],
        dependencies: [
            .project(
                target: "FoundationUI",
                path: .relativeToRoot("FoundationUI")
            ),
            .project(
                target: "ISOInspectorApp",
                path: .relativeToRoot(".")
            )
        ],
        settings: .settings(base: baseSettings)
    )
}

// MARK: - Project

let project = Project(
    name: "ComponentTestApp",
    organizationName: "ISOInspector",
    options: .options(),
    targets: [
        componentTestAppIOS(),
        componentTestAppMacOS()
    ]
)
