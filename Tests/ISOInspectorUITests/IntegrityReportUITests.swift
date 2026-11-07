import AppKit
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
        let pathField = app.textFields["PathTextField"]
        XCTAssertTrue(pathField.waitForExistence(timeout: 10))
        paste(fixture.path, into: app)
        app.typeKey(.return, modifierFlags: [])
        let openButton = app.sheets["open-panel"].buttons["OKButton"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 10))
        openButton.click()

        let showReport = app.buttons["Show Integrity"]
        XCTAssertTrue(showReport.waitForExistence(timeout: 20))
        showReport.click()
        let summary = app.descendants(matching: .any)["parseTree.integritySummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons["Hide Integrity"].exists)
        let issue = summary.staticTexts.matching(NSPredicate(format: "value == %@", "VR-006")).firstMatch
        XCTAssertTrue(issue.waitForExistence(timeout: 10), app.debugDescription)

        app.buttons["Hide Integrity"].click()
        XCTAssertTrue(showReport.waitForExistence(timeout: 5))
        showReport.click()
        XCTAssertTrue(summary.waitForExistence(timeout: 10), app.debugDescription)
    }

    private func paste(_ text: String, into app: XCUIApplication) {
        let pasteboard = NSPasteboard.general
        let savedItems = (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let changeCount = pasteboard.changeCount
        app.typeKey("v", modifierFlags: .command)
        if pasteboard.changeCount == changeCount {
            pasteboard.clearContents()
            if !savedItems.isEmpty { pasteboard.writeObjects(savedItems) }
        }
    }
}
