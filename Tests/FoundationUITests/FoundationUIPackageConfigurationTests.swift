import XCTest
@testable import FoundationUI

final class FoundationUIPackageConfigurationTests: XCTestCase {
    func testModuleIdentifierMatchesExpectedName() {
        XCTAssertEqual(FoundationUI.moduleIdentifier, "FoundationUI")
    }
}
