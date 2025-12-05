import XCTest

@testable import ISOInspectorKit

final class ParseIssueStoreTests: XCTestCase {
    func testRecordAppendsIssuesAndUpdatesMetrics() {
        let store = ParseIssueStore()
        let first = ParseIssue(
            severity: .error, code: "walker.error", message: "Encountered unrecoverable header",
            byteRange: 10..<20, affectedNodeIDs: [1, 2])
        let second = ParseIssue(
            severity: .warning, code: "walker.warning", message: "Truncated payload",
            byteRange: 30..<50, affectedNodeIDs: [42])

        store.record(first)
        store.record(second)

        XCTAssertEqual(store.issues, [first, second])

        let metrics = store.metrics
        XCTAssertEqual(metrics.errorCount, 1)
        XCTAssertEqual(metrics.warningCount, 1)
        XCTAssertEqual(metrics.infoCount, 0)
        XCTAssertEqual(metrics.deepestAffectedDepth, 2)
    }

    func testIssuesForNodeIDFiltersRecordedIssues() {
        let store = ParseIssueStore()
        let matching = ParseIssue(
            severity: .info, code: "walker.info", message: "Advisory", affectedNodeIDs: [111])
        let nonMatching = ParseIssue(
            severity: .warning, code: "walker.warning", message: "Different node",
            affectedNodeIDs: [222])

        store.record(matching)
        store.record(nonMatching)

        XCTAssertEqual(store.issues(forNodeID: 111), [matching])
        XCTAssertTrue(store.issues(forNodeID: 333).isEmpty)
    }

    func testIssuesInRangeFiltersByByteRange() {
        let store = ParseIssueStore()
        let inside = ParseIssue(
            severity: .error, code: "walker.range", message: "Inside", byteRange: 100..<200)
        let overlapping = ParseIssue(
            severity: .warning, code: "walker.overlap", message: "Overlap", byteRange: 50..<120)
        let outside = ParseIssue(
            severity: .info, code: "walker.outside", message: "Outside", byteRange: 300..<400)
        let missing = ParseIssue(severity: .info, code: "walker.nil", message: "Nil range")

        store.record(inside)
        store.record(overlapping)
        store.record(outside)
        store.record(missing)

        let results = store.issues(in: 90..<210)
        XCTAssertEqual(results, [inside, overlapping])
    }

    func testResetClearsIssuesAndMetrics() {
        let store = ParseIssueStore()
        let issue = ParseIssue(severity: .error, code: "walker.error", message: "Failure")

        store.record(issue)
        store.reset()

        XCTAssertTrue(store.issues.isEmpty)
        let metrics = store.metrics
        XCTAssertEqual(metrics.errorCount, 0)
        XCTAssertEqual(metrics.warningCount, 0)
        XCTAssertEqual(metrics.infoCount, 0)
        XCTAssertEqual(metrics.deepestAffectedDepth, 0)
    }

    func testMetricsExposeCountsBySeverityAndTotal() {
        let store = ParseIssueStore()
        let error = ParseIssue(severity: .error, code: "walker.error", message: "Failure")
        let warning = ParseIssue(severity: .warning, code: "walker.warning", message: "Corruption")
        let info = ParseIssue(severity: .info, code: "walker.info", message: "Advisory")

        store.record(error)
        store.record(warning)
        store.record(info)

        let metrics = store.metrics
        XCTAssertEqual(metrics.count(for: .error), 1)
        XCTAssertEqual(metrics.count(for: .warning), 1)
        XCTAssertEqual(metrics.count(for: .info), 1)
        XCTAssertEqual(metrics.countsBySeverity[.error], 1)
        XCTAssertEqual(metrics.countsBySeverity[.warning], 1)
        XCTAssertEqual(metrics.countsBySeverity[.info], 1)
        XCTAssertEqual(metrics.totalCount, 3)
    }

    func testMetricsSnapshotReturnsLatestCountsFromBackgroundQueue() {
        let store = ParseIssueStore()
        let issue = ParseIssue(severity: .warning, code: "walker.warning", message: "Corruption")

        store.record(issue)

        let expectation = expectation(description: "Metrics snapshot resolved")

        DispatchQueue.global().async {
            let metrics = store.metricsSnapshot()
            XCTAssertEqual(metrics.count(for: .warning), 1)
            XCTAssertEqual(metrics.deepestAffectedDepth, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testIssueSummaryReturnsAggregatedCounts() {
        let store = ParseIssueStore()
        let issue = ParseIssue(
            severity: .error, code: "walker.error", message: "Failure", affectedNodeIDs: [1, 2, 3])

        store.record(issue, depth: 5)

        let summary = store.makeIssueSummary()
        XCTAssertEqual(summary.count(for: .error), 1)
        XCTAssertEqual(summary.totalCount, 1)
        XCTAssertEqual(summary.deepestAffectedDepth, 5)
    }
}
