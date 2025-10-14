import ProjectDescription
import Foundation

private struct DistributionMetadata: Decodable {
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

private enum DistributionPlatform: String {
    case macOS
    case iOS
    case iPadOS
}

private func projectRootDirectory(from manifestPath: String) -> URL {
    var directory = URL(fileURLWithPath: manifestPath).deletingLastPathComponent()
    let fileManager = FileManager.default

    while directory.path != "/" {
        let packagePath = directory.appendingPathComponent("Package.swift").path
        if fileManager.fileExists(atPath: packagePath) {
            return directory
        }

        directory.deleteLastPathComponent()
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}

private func loadDistributionMetadata(from manifestPath: String) -> DistributionMetadata {
    let projectDirectory = projectRootDirectory(from: manifestPath)
    let metadataURL = projectDirectory
        .appendingPathComponent("Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json")
    let data = try! Data(contentsOf: metadataURL)
    return try! JSONDecoder().decode(DistributionMetadata.self, from: data)
}

private let metadata = loadDistributionMetadata(from: #filePath)

private let baseSettings: SettingsDictionary = [
    "MARKETING_VERSION": .string(metadata.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(metadata.buildNumber)
]

private let configurations: [Configuration] = [
    .debug(name: .debug),
    .release(name: .release)
]

private let projectSettings = Settings.settings(
    base: baseSettings,
    configurations: configurations,
    defaultSettings: .recommended,
    defaultConfiguration: "Debug"
)

private let targetSettings = Settings.settings(
    base: baseSettings,
    configurations: configurations,
    defaultSettings: .recommended,
    defaultConfiguration: "Debug"
)

private func destinations(for platform: DistributionPlatform) -> Destinations {
    switch platform {
    case .macOS:
        return [.mac]
    case .iPadOS:
        return [.iPad]
    case .iOS:
        return [.iPhone, .iPad]
    }
}

private func deploymentTargets(for platform: DistributionPlatform) -> DeploymentTargets {
    switch platform {
    case .macOS:
        return .macOS("14.0")
    case .iPadOS, .iOS:
        return .iOS("16.0")
    }
}

private func kitTarget(for platform: DistributionPlatform) -> Target {
    let name = platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"
    return Target(
        name: name,
        destinations: destinations(for: platform),
        product: .framework,
        bundleId: "com.isoinspector.kit.\(platform.rawValue.lowercased())",
        deploymentTargets: deploymentTargets(for: platform),
        infoPlist: .default,
        sources: ["../Sources/ISOInspectorKit/**"],
        resources: ["../Sources/ISOInspectorKit/Resources/**"],
        settings: targetSettings
    )
}

private func appTarget(for platform: DistributionPlatform) -> Target {
    let targetName: String
    switch platform {
    case .macOS:
        targetName = "ISOInspectorApp-macOS"
    case .iPadOS:
        targetName = "ISOInspectorApp-iPadOS"
    case .iOS:
        targetName = "ISOInspectorApp-iOS"
    }

    let entitlements = metadata.entitlementsPath(for: platform).map { Entitlements.file(path: .relativeToRoot($0)) }
    let dependencies: [TargetDependency] = [
        .target(name: platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"),
        .external(name: "NestedA11yIDs")
    ]

    return Target(
        name: targetName,
        destinations: destinations(for: platform),
        product: .app,
        bundleId: metadata.bundleIdentifier(for: platform),
        deploymentTargets: deploymentTargets(for: platform),
        infoPlist: .default,
        sources: ["../Sources/ISOInspectorApp/**"],
        resources: ["../Sources/ISOInspectorApp/Resources/**"],
        entitlements: entitlements,
        dependencies: dependencies,
        settings: targetSettings
    )
}

private let cliTarget = Target(
    name: "ISOInspectorCLI",
    destinations: [.mac],
    product: .commandLineTool,
    bundleId: "com.isoinspector.cli",
    deploymentTargets: .macOS("14.0"),
    infoPlist: .default,
    sources: ["../Sources/ISOInspectorCLI/**", "../Sources/ISOInspectorCLIRunner/**"],
    dependencies: [
        .target(name: "ISOInspectorKit-macOS"),
        .external(name: "ArgumentParser")
    ],
    settings: targetSettings
)

private func schemeName(for platform: DistributionPlatform) -> String {
    switch platform {
    case .macOS:
        return "ISOInspectorApp-macOS"
    case .iOS:
        return "ISOInspectorApp-iOS"
    case .iPadOS:
        return "ISOInspectorApp-iPadOS"
    }
}

private func appScheme(for platform: DistributionPlatform) -> Scheme {
    let name = schemeName(for: platform)
    return Scheme(
        name: name,
        shared: true,
        buildAction: .buildAction(targets: [.target(name)]),
        runAction: .runAction(configuration: "Debug"),
        archiveAction: .archiveAction(configuration: "Release"),
        analyzeAction: .analyzeAction(configuration: "Debug")
    )
}

private let cliScheme = Scheme(
    name: "ISOInspectorCLI",
    shared: true,
    buildAction: .buildAction(targets: [.target("ISOInspectorCLI")]),
    runAction: .runAction(configuration: "Debug"),
    archiveAction: .archiveAction(configuration: "Release"),
    analyzeAction: .analyzeAction(configuration: "Debug")
)

let project = Project(
    name: "ISOInspector",
    organizationName: "ISOInspector",
    options: .options(),
    packages: [
        .remote(url: "https://github.com/SoundBlaster/NestedA11yIDs", requirement: .upToNextMajor(from: "1.0.0")),
        .remote(url: "https://github.com/apple/swift-argument-parser", requirement: .upToNextMajor(from: "1.3.0"))
    ],
    settings: projectSettings,
    targets: [
        kitTarget(for: .macOS),
        kitTarget(for: .iOS),
        appTarget(for: .macOS),
        appTarget(for: .iOS),
        appTarget(for: .iPadOS),
        cliTarget
    ],
    schemes: [
        appScheme(for: .macOS),
        appScheme(for: .iOS),
        appScheme(for: .iPadOS),
        cliScheme
    ]
)
