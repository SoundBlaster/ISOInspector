#if canImport(AppKit) && canImport(Combine) && canImport(SwiftUI)
    import AppKit
    import Combine
    import SwiftUI
    import XCTest
    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    @MainActor final class IntegritySummaryViewTests: XCTestCase {

        func testIntegritySummaryViewDisplaysIssues() async throws {
            // Arrange: Create a store with sample issues
            let store = ParseTreeStore()
            store.issueStore.record(
                ParseIssue(
                    severity: .error, code: "ERR-001", message: "Critical error in box",
                    byteRange: 100..<200, affectedNodeIDs: [1]), depth: 1)
            store.issueStore.record(
                ParseIssue(
                    severity: .warning, code: "WARN-001", message: "Warning: potential issue",
                    byteRange: 300..<400, affectedNodeIDs: [2]), depth: 2)

            let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)
            await viewModel.waitForPendingUpdates()

            XCTAssertEqual(viewModel.displayedIssues.count, 2)
            XCTAssertTrue(viewModel.displayedIssues.contains { $0.code == "ERR-001" })
            XCTAssertTrue(viewModel.displayedIssues.contains { $0.code == "WARN-001" })
            XCTAssertTrue(
                viewModel.displayedIssues.contains { $0.message.contains("Critical error") })
        }

        func testIntegritySummaryViewSortsBySeverity() async throws {
            // Arrange: Create issues with different severities
            let store = ParseTreeStore()
            store.issueStore.record(
                ParseIssue(
                    severity: .info, code: "INFO-001", message: "Info message",
                    byteRange: 100..<200, affectedNodeIDs: [1]), depth: 1)
            store.issueStore.record(
                ParseIssue(
                    severity: .error, code: "ERR-001", message: "Error message",
                    byteRange: 300..<400, affectedNodeIDs: [2]), depth: 1)

            let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)
            await viewModel.waitForPendingUpdates()

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
            XCTAssertTrue(viewModel.displayedIssues.isEmpty)
        }

        func testToolbarPolicyDisablesExportToolbarOnMacOS() {
            XCTAssertFalse(
                IntegritySummaryToolbarPolicy.shouldShowToolbar(
                    platform: .macOS, hasJSONExport: true, hasIssueSummaryExport: true))
        }

        func testToolbarPolicyRequiresBothExportActions() {
            XCTAssertFalse(
                IntegritySummaryToolbarPolicy.shouldShowToolbar(
                    platform: .iOSLike, hasJSONExport: true, hasIssueSummaryExport: false))
            XCTAssertFalse(
                IntegritySummaryToolbarPolicy.shouldShowToolbar(
                    platform: .iOSLike, hasJSONExport: false, hasIssueSummaryExport: true))
            XCTAssertTrue(
                IntegritySummaryToolbarPolicy.shouldShowToolbar(
                    platform: .iOSLike, hasJSONExport: true, hasIssueSummaryExport: true))
        }
    }
#endif
