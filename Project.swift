import Foundation
import ProjectDescription

struct DistributionMetadata: Decodable {
    struct DistributionTarget: Decodable {
        let platform: String
        let productName: String
        let bundleIdentifier: String
        let entitlementsPath: String
    }

    let marketingVersion: String
    let buildNumber: String
    let teamIdentifier: String
    let targets: [DistributionTarget]

    func bundleIdentifier(for platform: DistributionPlatform) -> String {
        guard let match = targets.first(where: { $0.platform == platform.rawValue }) else {
            return "ru.egormerkushev.isoinspector.app"
        }
        return match.bundleIdentifier
    }

    func entitlementsPath(for platform: DistributionPlatform) -> String? {
        targets.first(where: { $0.platform == platform.rawValue })?.entitlementsPath
    }
}

enum DistributionPlatform: String {
    case macOS
    case iOS
    case iPadOS
}

func projectDirectory() -> URL {
    let fileManager = FileManager.default
    let metadataRelativePath =
        "Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json"
    let candidates = [
        URL(fileURLWithPath: fileManager.currentDirectoryPath),
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent(),
    ]

    // Tuist compiles manifests in a cache directory, so fall back to the process
    // working directory if #filePath no longer lives at the repository root.
    if let match = candidates.first(where: {
        fileManager.fileExists(atPath: $0.appendingPathComponent(metadataRelativePath).path)
    }) {
        return match
    }

    fatalError("Unable to locate project directory containing \(metadataRelativePath)")
}

func loadDistributionMetadata() -> DistributionMetadata {
    let metadataURL = projectDirectory()
        .appendingPathComponent(
            "Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json")
    let data = try! Data(contentsOf: metadataURL)
    return try! JSONDecoder().decode(DistributionMetadata.self, from: data)
}

let metadata = loadDistributionMetadata()

let baseSettings: SettingsDictionary = [
    "MARKETING_VERSION": .string(metadata.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(metadata.buildNumber),
]

let buildConfigurations: [Configuration] = [
    .debug(
        name: .debug,
        settings: [
            "SWIFT_OPTIMIZATION_LEVEL": .string("-Onone"),
            "SWIFT_COMPILATION_MODE": .string("singlefile"),
        ]
    ),
    .release(
        name: .release,
        settings: [
            "SWIFT_OPTIMIZATION_LEVEL": .string("-O"),
            "SWIFT_COMPILATION_MODE": .string("wholemodule"),
        ]
    ),
]

func destinations(for platform: DistributionPlatform) -> Destinations {
    switch platform {
    case .macOS:
        return [.mac]
    case .iPadOS:
        return [.iPad]
    case .iOS:
        return [.iPhone, .iPad]
    }
}

func deploymentTargets(for platform: DistributionPlatform) -> DeploymentTargets {
    switch platform {
    case .macOS:
        return .macOS("14.0")
    case .iPadOS, .iOS:
        return .iOS("17.0")
    }
}

func kitTarget() -> Target {
    Target.target(
        name: "ISOInspectorKit",
        destinations: [.mac, .iPad, .iPhone],
        product: .framework,
        bundleId: "ru.egormerkushev.isoinspector.kit",
        deploymentTargets: DeploymentTargets.multiplatform(iOS: "17.0", macOS: "14.0"),
        infoPlist: .default,
        sources: ["Sources/ISOInspectorKit/**"],
        resources: ["Sources/ISOInspectorKit/Resources/**"],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func appTarget(for platform: DistributionPlatform) -> Target {
    let targetName: String
    switch platform {
    case .macOS:
        targetName = "ISOInspectorApp-macOS"
    case .iPadOS:
        targetName = "ISOInspectorApp-iPadOS"
    case .iOS:
        targetName = "ISOInspectorApp-iOS"
    }

    let entitlements = metadata.entitlementsPath(for: platform).map {
        Entitlements.file(path: .relativeToRoot($0))
    }
    let dependencies: [TargetDependency] = [
        .target(name: "ISOInspectorKit"),
        .package(product: "NestedA11yIDs"),
        .project(target: "FoundationUI", path: .relativeToRoot("FoundationUI")),
    ]

    // Configure Info.plist with privacy descriptions and document types
    let infoPlist = infoPlistConfiguration(for: platform)

    // Set module name to "ISOInspectorApp" for all platforms to enable consistent imports
    var appSettings = baseSettings
    appSettings["PRODUCT_MODULE_NAME"] = .string("ISOInspectorApp")

    return Target.target(
        name: targetName,
        destinations: destinations(for: platform),
        product: .app,
        bundleId: metadata.bundleIdentifier(for: platform),
        deploymentTargets: deploymentTargets(for: platform),
        infoPlist: infoPlist,
        sources: ["Sources/ISOInspectorApp/**"],
        resources: ["Sources/ISOInspectorApp/Resources/**"],
        entitlements: entitlements,
        dependencies: dependencies,
        settings: .settings(base: appSettings, configurations: buildConfigurations)
    )
}

func infoPlistConfiguration(for platform: DistributionPlatform) -> InfoPlist {
    var infoPlistEntries: [String: Plist.Value] = [:]

    // Document type associations for MP4 and QuickTime files
    infoPlistEntries["CFBundleDocumentTypes"] = .array([
        .dictionary([
            "CFBundleTypeName": .string("Movie"),
            "CFBundleTypeRole": .string("Viewer"),
            "LSHandlerRank": .string("Default"),
            "LSItemContentTypes": .array([
                .string("public.mpeg-4"),
                .string("com.apple.quicktime-movie"),
            ]),
        ])
    ])

    // Privacy descriptions for folder access (macOS only, but safe to add for all platforms)
    // These enable permission dialogs when accessing files from protected folders
    infoPlistEntries["NSDocumentsFolderUsageDescription"] = .string(
        "ISO Inspector needs access to open and inspect MP4 and QuickTime files from your Documents folder."
    )
    infoPlistEntries["NSDownloadsFolderUsageDescription"] = .string(
        "ISO Inspector needs access to open and inspect MP4 and QuickTime files from your Downloads folder."
    )

    // Desktop folder access (macOS specific, but safe for all platforms)
    if platform == .macOS {
        infoPlistEntries["NSDesktopFolderUsageDescription"] = .string(
            "ISO Inspector needs access to open and inspect MP4 and QuickTime files from your Desktop."
        )
    }

    if platform == .iOS || platform == .iPadOS {
        infoPlistEntries["LSSupportsOpeningDocumentsInPlace"] = .boolean(true)
        // Launch screen configuration for iOS/iPadOS (iOS 14+)
        // Empty dictionary uses system-generated launch screen
        infoPlistEntries["UILaunchScreen"] = .dictionary([:])
    }

    return .extendingDefault(with: infoPlistEntries)
}

func cliLibraryTarget() -> Target {
    Target.target(
        name: "ISOInspectorCLI",
        destinations: [.mac],
        product: .staticLibrary,
        bundleId: "ru.egormerkushev.isoinspector.cli.library",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["Sources/ISOInspectorCLI/**"],
        dependencies: [
            .target(name: "ISOInspectorKit"),
            .package(product: "ArgumentParser"),
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func cliRunnerTarget() -> Target {
    Target.target(
        name: "ISOInspectorCLIRunner",
        destinations: [.mac],
        product: .commandLineTool,
        bundleId: "ru.egormerkushev.isoinspector.cli.runner",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["Sources/ISOInspectorCLIRunner/**"],
        dependencies: [
            .target(name: "ISOInspectorCLI"),
            .package(product: "ArgumentParser"),
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func kitTestsTarget() -> Target {
    Target.target(
        name: "ISOInspectorKitTests",
        destinations: [.mac],
        product: .unitTests,
        bundleId: "ru.egormerkushev.isoinspector.kit.tests",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["Tests/ISOInspectorKitTests/**"],
        resources: ["Tests/ISOInspectorKitTests/Fixtures/**"],
        dependencies: [
            .target(name: "ISOInspectorKit")
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func cliTestsTarget() -> Target {
    Target.target(
        name: "ISOInspectorCLITests",
        destinations: [.mac],
        product: .unitTests,
        bundleId: "ru.egormerkushev.isoinspector.cli.tests",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["Tests/ISOInspectorCLITests/**"],
        dependencies: [
            .target(name: "ISOInspectorCLI"),
            .target(name: "ISOInspectorKit"),
            .package(product: "ArgumentParser"),
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func performanceTestsTarget() -> Target {
    Target.target(
        name: "ISOInspectorPerformanceTests",
        destinations: [.mac],
        product: .unitTests,
        bundleId: "ru.egormerkushev.isoinspector.performance.tests",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["Tests/ISOInspectorPerformanceTests/**"],
        dependencies: [
            .target(name: "ISOInspectorCLI"),
            .target(name: "ISOInspectorKit"),
            .target(name: "ISOInspectorApp-macOS"),
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

func appTestsTarget(for platform: DistributionPlatform) -> Target {
    let targetName: String
    let appTargetName: String

    switch platform {
    case .macOS:
        targetName = "ISOInspectorAppTests-macOS"
        appTargetName = "ISOInspectorApp-macOS"
    case .iOS, .iPadOS:
        targetName = "ISOInspectorAppTests-iOS"
        appTargetName = "ISOInspectorApp-iOS"
    }

    return Target.target(
        name: targetName,
        destinations: destinations(for: platform),
        product: .unitTests,
        bundleId: "ru.egormerkushev.isoinspector.app.tests.\(platform.rawValue.lowercased())",
        deploymentTargets: deploymentTargets(for: platform),
        infoPlist: .default,
        sources: ["Tests/ISOInspectorAppTests/**"],
        dependencies: [
            .target(name: appTargetName),
            .target(name: "ISOInspectorKit"),
            .package(product: "NestedA11yIDs"),
            .project(target: "FoundationUI", path: .relativeToRoot("FoundationUI")),
        ],
        settings: .settings(base: baseSettings, configurations: buildConfigurations)
    )
}

let project = Project(
    name: "ISOInspector",
    organizationName: "ISOInspector",
    options: .options(),
    packages: [
        .remote(
            url: "https://github.com/SoundBlaster/NestedA11yIDs",
            requirement: .upToNextMajor(from: "1.0.0")),
        .remote(
            url: "https://github.com/apple/swift-argument-parser",
            requirement: .upToNextMajor(from: "1.3.0")),
    ],
    targets: [
        kitTarget(),
        appTarget(for: .macOS),
        appTarget(for: .iOS),
        appTarget(for: .iPadOS),
        cliLibraryTarget(),
        cliRunnerTarget(),
        kitTestsTarget(),
        cliTestsTarget(),
        performanceTestsTarget(),
        appTestsTarget(for: .macOS),
        appTestsTarget(for: .iOS),
    ]
)
