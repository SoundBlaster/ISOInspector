import Foundation
import ProjectDescription

public struct DistributionMetadata: Decodable {
    public struct DistributionTarget: Decodable {
        public let platform: String
        public let productName: String
        public let bundleIdentifier: String
        public let entitlementsPath: String
    }

    public let marketingVersion: String
    public let buildNumber: String
    public let teamIdentifier: String
    public let targets: [DistributionTarget]

    public func bundleIdentifier(for platform: DistributionPlatform) -> String {
        guard let match = targets.first(where: { $0.platform == platform.rawValue }) else {
            return "com.isoinspector.app"
        }
        return match.bundleIdentifier
    }

    public func entitlementsPath(for platform: DistributionPlatform) -> String? {
        targets.first(where: { $0.platform == platform.rawValue })?.entitlementsPath
    }
}

public enum DistributionPlatform: String {
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

public func makeISOInspectorProject(manifestPath: String = #filePath) -> Project {
    let metadata = loadDistributionMetadata(from: manifestPath)

    let baseSettings: SettingsDictionary = [
        "MARKETING_VERSION": .string(metadata.marketingVersion),
        "CURRENT_PROJECT_VERSION": .string(metadata.buildNumber)
    ]

    let defaultConfigurations: [Configuration] = [
        .debug(name: .debug),
        .release(name: .release)
    ]

    let projectSettings = Settings.settings(
        base: baseSettings,
        configurations: defaultConfigurations,
        defaultSettings: .recommended,
        defaultConfiguration: "Debug"
    )

    let targetSettings = Settings.settings(
        base: baseSettings,
        configurations: defaultConfigurations,
        defaultSettings: .recommended,
        defaultConfiguration: "Debug"
    )

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
            return .iOS("16.0")
        }
    }

    func kitTarget(for platform: DistributionPlatform) -> Target {
        let name = platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"
        return Target.target(
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

        let entitlements = metadata.entitlementsPath(for: platform).map { Entitlements.file(path: .relativeToRoot($0)) }
        let dependencies: [TargetDependency] = [
            .target(name: platform == .macOS ? "ISOInspectorKit-macOS" : "ISOInspectorKit-iOS"),
            .external(name: "NestedA11yIDs")
        ]
        return Target.target(
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

    let cliTarget = Target.target(
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

    func schemeName(for platform: DistributionPlatform) -> String {
        switch platform {
        case .macOS:
            return "ISOInspectorApp-macOS"
        case .iOS:
            return "ISOInspectorApp-iOS"
        case .iPadOS:
            return "ISOInspectorApp-iPadOS"
        }
    }

    func appScheme(for platform: DistributionPlatform) -> Scheme {
        let name = schemeName(for: platform)
        return Scheme.scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: [.target(name)]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    }

    let cliScheme = Scheme.scheme(
        name: "ISOInspectorCLI",
        shared: true,
        buildAction: .buildAction(targets: [.target("ISOInspectorCLI")]),
        runAction: .runAction(configuration: "Debug"),
        archiveAction: .archiveAction(configuration: "Release"),
        analyzeAction: .analyzeAction(configuration: "Debug")
    )

    return Project(
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
}
