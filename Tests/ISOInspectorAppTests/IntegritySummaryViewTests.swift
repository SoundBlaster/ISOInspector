#if canImport(AppKit) && canImport(Combine) && canImport(SwiftUI)
import AppKit
import Combine
import SwiftUI
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

@MainActor
final class IntegritySummaryViewTests: XCTestCase {

    func testIntegritySummaryViewDisplaysIssues() throws {
        // Arrange: Create a store with sample issues
        let store = ParseTreeStore()
        store.issueStore.record(
            ParseIssue(
                severity: .error,
                code: "ERR-001",
                message: "Critical error in box",
                byteRange: 100..<200,
                affectedNodeIDs: [1]
            ),
            depth: 1
        )
        store.issueStore.record(
            ParseIssue(
                severity: .warning,
                code: "WARN-001",
                message: "Warning: potential issue",
                byteRange: 300..<400,
                affectedNodeIDs: [2]
            ),
            depth: 2
        )

        let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)
        let view = IntegritySummaryView(viewModel: viewModel)

        // Act: Render the view
        let hostingView = NSHostingView(rootView: view.frame(width: 600, height: 400))

        // Assert: View should display both issues
        XCTAssertTrue(
            hostingView.containsText("ERR-001"),
            "View should display error code ERR-001"
        )
        XCTAssertTrue(
            hostingView.containsText("WARN-001"),
            "View should display warning code WARN-001"
        )
        XCTAssertTrue(
            hostingView.containsText("Critical error in box"),
            "View should display error message"
        )
    }

    func testIntegritySummaryViewSortsBySeverity() throws {
        // Arrange: Create issues with different severities
        let store = ParseTreeStore()
        store.issueStore.record(
            ParseIssue(
                severity: .info,
                code: "INFO-001",
                message: "Info message",
                byteRange: 100..<200,
                affectedNodeIDs: [1]
            ),
            depth: 1
        )
        store.issueStore.record(
            ParseIssue(
                severity: .error,
                code: "ERR-001",
                message: "Error message",
                byteRange: 300..<400,
                affectedNodeIDs: [2]
            ),
            depth: 1
        )

        let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

        // Act: Default sort should be by severity (error first)
        let sortedIssues = viewModel.displayedIssues

        // Assert: Error should be first
        XCTAssertEqual(sortedIssues.first?.severity, .error)
        XCTAssertEqual(sortedIssues.last?.severity, .info)
    }

    func testIntegritySummaryViewEmptyState() throws {
        // Arrange: Create empty store
        let store = ParseTreeStore()
        let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)
        let view = IntegritySummaryView(viewModel: viewModel)

        // Act: Render the view
        let hostingView = NSHostingView(rootView: view.frame(width: 600, height: 400))

        // Assert: Should show empty state message
        XCTAssertTrue(
            hostingView.containsText("No integrity issues"),
            "View should display empty state message"
        )
    }
}

// MARK: - Test Helper Extensions

extension NSHostingView {
    func containsText(_ text: String) -> Bool {
        containsTextRecursive(view: self, text: text)
    }

    private func containsTextRecursive(view: NSView, text: String) -> Bool {
        if let textField = view as? NSTextField,
           let content = textField.stringValue as String?,
           content.contains(text) {
            return true
        }

        if let textView = view as? NSTextView,
           let content = textView.string as String?,
           content.contains(text) {
            return true
        }

        for subview in view.subviews {
            if containsTextRecursive(view: subview, text: text) {
                return true
            }
        }

        return false
    }
}
#endif
