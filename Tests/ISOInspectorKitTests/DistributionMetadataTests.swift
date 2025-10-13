import XCTest
@testable import ISOInspectorKit

final class DistributionMetadataTests: XCTestCase {
    func testLoadsDefaultMetadataFromResourceBundle() throws {
        let metadata = try DistributionMetadataLoader.defaultMetadata()

        XCTAssertEqual(metadata.marketingVersion, "0.1.0")
        XCTAssertEqual(metadata.buildNumber, "1")
        XCTAssertEqual(metadata.teamIdentifier, "DEVELOPMENT_TEAM")
        XCTAssertEqual(metadata.targets.count, 3)

        XCTAssertEqual(
            metadata.targets.first { $0.platform == .macOS },
            DistributionMetadata.Target(
                platform: .macOS,
                productName: "ISOInspector",
                bundleIdentifier: "com.isoinspector.app.mac",
                entitlementsPath: "Distribution/Entitlements/ISOInspectorApp.macOS.entitlements"
            )
        )
        XCTAssertEqual(
            metadata.targets.first { $0.platform == .iOS },
            DistributionMetadata.Target(
                platform: .iOS,
                productName: "ISOInspector",
                bundleIdentifier: "com.isoinspector.app.ios",
                entitlementsPath: "Distribution/Entitlements/ISOInspectorApp.iOS.entitlements"
            )
        )
        XCTAssertEqual(
            metadata.targets.first { $0.platform == .iPadOS },
            DistributionMetadata.Target(
                platform: .iPadOS,
                productName: "ISOInspector",
                bundleIdentifier: "com.isoinspector.app.ipados",
                entitlementsPath: "Distribution/Entitlements/ISOInspectorApp.iPadOS.entitlements"
            )
        )
    }
}
