import XCTest
@testable import ISOInspectorKit

final class ParseIssueStoreTests: XCTestCase {
    func testRecordAppendsIssuesAndUpdatesMetrics() {
        let store = ParseIssueStore()
        let first = ParseIssue(
            severity: .error,
            code: "walker.error",
            message: "Encountered unrecoverable header",
            byteRange: 10..<20,
            affectedNodeIDs: [1, 2]
        )
        let second = ParseIssue(
            severity: .warning,
            code: "walker.warning",
            message: "Truncated payload",
            byteRange: 30..<50,
            affectedNodeIDs: [42]
        )

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
            severity: .info,
            code: "walker.info",
            message: "Advisory",
            affectedNodeIDs: [111]
        )
        let nonMatching = ParseIssue(
            severity: .warning,
            code: "walker.warning",
            message: "Different node",
            affectedNodeIDs: [222]
        )

        store.record(matching)
        store.record(nonMatching)

        XCTAssertEqual(store.issues(forNodeID: 111), [matching])
        XCTAssertTrue(store.issues(forNodeID: 333).isEmpty)
    }

    func testIssuesInRangeFiltersByByteRange() {
        let store = ParseIssueStore()
        let inside = ParseIssue(
            severity: .error,
            code: "walker.range",
            message: "Inside",
            byteRange: 100..<200
        )
        let overlapping = ParseIssue(
            severity: .warning,
            code: "walker.overlap",
            message: "Overlap",
            byteRange: 50..<120
        )
        let outside = ParseIssue(
            severity: .info,
            code: "walker.outside",
            message: "Outside",
            byteRange: 300..<400
        )
        let missing = ParseIssue(
            severity: .info,
            code: "walker.nil",
            message: "Nil range"
        )

        store.record(inside)
        store.record(overlapping)
        store.record(outside)
        store.record(missing)

        let results = store.issues(in: 90..<210)
        XCTAssertEqual(results, [inside, overlapping])
    }

    func testResetClearsIssuesAndMetrics() {
        let store = ParseIssueStore()
        let issue = ParseIssue(
            severity: .error,
            code: "walker.error",
            message: "Failure"
        )

        store.record(issue)
        store.reset()

        XCTAssertTrue(store.issues.isEmpty)
        let metrics = store.metrics
        XCTAssertEqual(metrics.errorCount, 0)
        XCTAssertEqual(metrics.warningCount, 0)
        XCTAssertEqual(metrics.infoCount, 0)
        XCTAssertEqual(metrics.deepestAffectedDepth, 0)
    }
}
