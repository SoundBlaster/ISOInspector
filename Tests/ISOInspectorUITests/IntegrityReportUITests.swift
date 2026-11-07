import Foundation
import XCTest

@MainActor
final class IntegrityReportUITests: XCTestCase {
    func testOpeningIntegrityReportKeepsDocumentUsable() throws {
        continueAfterFailure = false
        let fixture = FileManager.default.temporaryDirectory
            .appendingPathComponent("integrity-\(UUID().uuidString).mp4")
        // A valid ftyp followed by an unregistered box gives the report an issue.
        let bytes: [UInt8] = [
            0, 0, 0, 24, 102, 116, 121, 112, 105, 115, 111, 109,
            0, 0, 0, 0, 105, 115, 111, 109, 109, 112, 52, 49,
            0, 0, 0, 8, 122, 122, 122, 122,
        ]
        try Data(bytes).write(to: fixture)
        addTeardownBlock { try FileManager.default.removeItem(at: fixture) }

        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 60))
        app.buttons["Open File…"].firstMatch.click()
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText(fixture.path)
        app.typeKey(.return, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])

        let showReport = app.buttons["Show Integrity"]
        XCTAssertTrue(showReport.waitForExistence(timeout: 20))
        showReport.click()
        let summary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Integrity Summary")).firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Hide Integrity"].exists)
        let issue = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "VR-006")).firstMatch
        XCTAssertTrue(issue.waitForExistence(timeout: 10))

        app.buttons["Hide Integrity"].click()
        XCTAssertTrue(showReport.waitForExistence(timeout: 5))
        showReport.click()
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
    }
}
