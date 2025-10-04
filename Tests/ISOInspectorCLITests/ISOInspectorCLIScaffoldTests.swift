import XCTest
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class ISOInspectorCLIScaffoldTests: XCTestCase {
    func testWelcomeSummaryIncludesProjectNameAndFocus() {
        let summary = ISOInspectorCLIIO.welcomeSummary()
        XCTAssertTrue(summary.contains(ISOInspectorKit.projectName))
        XCTAssertTrue(summary.contains("Phase A"))
    }
}
