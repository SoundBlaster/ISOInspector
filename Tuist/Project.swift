import ProjectDescription
import Foundation

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
            return "com.isoinspector.app"
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

func loadDistributionMetadata() -> DistributionMetadata {
    let projectDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let metadataURL = projectDirectory
        .appendingPathComponent("Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json")
    let data = try! Data(contentsOf: metadataURL)
    return try! JSONDecoder().decode(DistributionMetadata.self, from: data)
}

let metadata = loadDistributionMetadata()

let baseSettings: SettingsDictionary = [
    "MARKETING_VERSION": .string(metadata.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(metadata.buildNumber)
]

func kitTarget(for platform: DistributionPlatform) -> Target {
    let name = platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"
    let platformValue: Platform = platform == .macOS ? .macOS : .iOS
    let deploymentTarget: DeploymentTarget = platform == .macOS
        ? .macOS(targetVersion: "14.0")
        : .iOS(targetVersion: "16.0", devices: [.iphone, .ipad])
    return Target(
        name: name,
        platform: platformValue,
        product: .framework,
        bundleId: "com.isoinspector.kit.\(platform.rawValue.lowercased())",
        deploymentTarget: deploymentTarget,
        infoPlist: .default,
        sources: ["Sources/ISOInspectorKit/**"],
        resources: ["Sources/ISOInspectorKit/Resources/**"],
        settings: .settings(base: baseSettings)
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

    let platformValue: Platform = platform == .macOS ? .macOS : .iOS

    let deploymentTarget: DeploymentTarget
    switch platform {
    case .macOS:
        deploymentTarget = .macOS(targetVersion: "14.0")
    case .iPadOS:
        deploymentTarget = .iOS(targetVersion: "16.0", devices: [.ipad])
    case .iOS:
        deploymentTarget = .iOS(targetVersion: "16.0", devices: [.iphone, .ipad])
    }

    let entitlements = metadata.entitlementsPath(for: platform).map { Path.relativeToRoot($0) }
    let dependencies: [TargetDependency] = [
        .target(name: platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"),
        .product(name: "NestedA11yIDs", package: "NestedA11yIDs")
    ]
    return Target(
        name: targetName,
        platform: platformValue,
        product: .app,
        bundleId: metadata.bundleIdentifier(for: platform),
        deploymentTarget: deploymentTarget,
        infoPlist: .default,
        sources: ["Sources/ISOInspectorApp/**"],
        resources: ["Sources/ISOInspectorApp/Resources/**"],
        entitlements: entitlements,
        settings: .settings(base: baseSettings),
        dependencies: dependencies
    )
}

let cliTarget = Target(
    name: "ISOInspectorCLI",
    platform: .macOS,
    product: .commandLineTool,
    bundleId: "com.isoinspector.cli",
    infoPlist: .default,
    sources: ["Sources/ISOInspectorCLI/**", "Sources/ISOInspectorCLIRunner/**"],
    settings: .settings(base: baseSettings),
    dependencies: [
        .target(name: "ISOInspectorKit-macOS"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
)

let project = Project(
    name: "ISOInspector",
    organizationName: "ISOInspector",
    options: .options(),
    packages: [
        .remote(url: "https://github.com/SoundBlaster/NestedA11yIDs", requirement: .upToNextMajor(from: "1.0.0")),
        .remote(url: "https://github.com/apple/swift-argument-parser", requirement: .upToNextMajor(from: "1.3.0"))
    ],
    targets: [
        kitTarget(for: .macOS),
        kitTarget(for: .iOS),
        appTarget(for: .macOS),
        appTarget(for: .iOS),
        appTarget(for: .iPadOS),
        cliTarget
    ]
)
