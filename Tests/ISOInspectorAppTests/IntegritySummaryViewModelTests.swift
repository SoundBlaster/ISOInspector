#if canImport(Combine)
  import Combine
  import XCTest
  @testable import ISOInspectorApp
  @testable import ISOInspectorKit

  @MainActor
  final class IntegritySummaryViewModelTests: XCTestCase {

    // MARK: - Offset-Based Sorting Tests (#T36-001)

    func testOffsetSorting_PrimarySortByByteOffset() {
      // Arrange: Create issues with different byte offsets
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Error at offset 300",
          byteRange: 300..<400,
          affectedNodeIDs: [3]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error at offset 200",
          byteRange: 200..<300,
          affectedNodeIDs: [2]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by offset
      viewModel.sortOrder = .offset

      // Assert: Issues should be sorted by byte offset (100, 200, 300)
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].byteRange?.lowerBound, 100)
      XCTAssertEqual(sortedIssues[1].byteRange?.lowerBound, 200)
      XCTAssertEqual(sortedIssues[2].byteRange?.lowerBound, 300)
    }

    func testOffsetSorting_SecondaryTieBreakerBySeverity() {
      // Arrange: Create multiple issues at the same byte offset with different severities
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .info,
          code: "INFO-001",
          message: "Info at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [2]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .warning,
          code: "WARN-001",
          message: "Warning at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [3]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by offset
      viewModel.sortOrder = .offset

      // Assert: At same offset, should sort by severity (Error > Warning > Info)
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].severity, .error, "Error should be first")
      XCTAssertEqual(sortedIssues[1].severity, .warning, "Warning should be second")
      XCTAssertEqual(sortedIssues[2].severity, .info, "Info should be last")
    }

    func testOffsetSorting_TertiaryTieBreakerByCode() {
      // Arrange: Create multiple issues at same offset with same severity but different codes
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Error C at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [3]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error A at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error B at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [2]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by offset
      viewModel.sortOrder = .offset

      // Assert: At same offset and severity, should sort by code lexicographically
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].code, "ERR-001", "ERR-001 should be first")
      XCTAssertEqual(sortedIssues[1].code, "ERR-002", "ERR-002 should be second")
      XCTAssertEqual(sortedIssues[2].code, "ERR-003", "ERR-003 should be last")
    }

    func testOffsetSorting_IssuesWithoutByteRangeSortToEnd() {
      // Arrange: Create issues with and without byte ranges
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error with offset",
          byteRange: 100..<200,
          affectedNodeIDs: [2]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error without offset",
          byteRange: nil,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Another error with offset",
          byteRange: 300..<400,
          affectedNodeIDs: [3]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by offset
      viewModel.sortOrder = .offset

      // Assert: Issues without byte ranges should sort to end
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].byteRange?.lowerBound, 100)
      XCTAssertEqual(sortedIssues[1].byteRange?.lowerBound, 300)
      XCTAssertNil(sortedIssues[2].byteRange, "Issue without byte range should be last")
    }

    // MARK: - Affected Node Sorting Tests (#T36-002)

    func testAffectedNodeSorting_PrimarySortByFirstNodeID() {
      // Arrange: Create issues affecting different nodes
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Error affecting node 30",
          byteRange: 300..<400,
          affectedNodeIDs: [30]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error affecting node 10",
          byteRange: 100..<200,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error affecting node 20",
          byteRange: 200..<300,
          affectedNodeIDs: [20]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by affected node
      viewModel.sortOrder = .affectedNode

      // Assert: Issues should be sorted by first affected node ID (10, 20, 30)
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].affectedNodeIDs.first, 10)
      XCTAssertEqual(sortedIssues[1].affectedNodeIDs.first, 20)
      XCTAssertEqual(sortedIssues[2].affectedNodeIDs.first, 30)
    }

    func testAffectedNodeSorting_SecondaryTieBreakerBySeverity() {
      // Arrange: Create multiple issues affecting the same node with different severities
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .info,
          code: "INFO-001",
          message: "Info affecting node 10",
          byteRange: 100..<200,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error affecting node 10",
          byteRange: 300..<400,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .warning,
          code: "WARN-001",
          message: "Warning affecting node 10",
          byteRange: 200..<300,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by affected node
      viewModel.sortOrder = .affectedNode

      // Assert: For same node, should sort by severity (Error > Warning > Info)
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].severity, .error, "Error should be first")
      XCTAssertEqual(sortedIssues[1].severity, .warning, "Warning should be second")
      XCTAssertEqual(sortedIssues[2].severity, .info, "Info should be last")
    }

    func testAffectedNodeSorting_TertiaryTieBreakerByOffset() {
      // Arrange: Create multiple issues affecting same node with same severity but different offsets
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Error at offset 300",
          byteRange: 300..<400,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error at offset 100",
          byteRange: 100..<200,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error at offset 200",
          byteRange: 200..<300,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by affected node
      viewModel.sortOrder = .affectedNode

      // Assert: For same node and severity, should sort by offset
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].byteRange?.lowerBound, 100, "Offset 100 should be first")
      XCTAssertEqual(sortedIssues[1].byteRange?.lowerBound, 200, "Offset 200 should be second")
      XCTAssertEqual(sortedIssues[2].byteRange?.lowerBound, 300, "Offset 300 should be last")
    }

    func testAffectedNodeSorting_IssuesWithEmptyNodesSortToEnd() {
      // Arrange: Create issues with and without affected nodes
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-002",
          message: "Error with node",
          byteRange: 100..<200,
          affectedNodeIDs: [10]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error without node",
          byteRange: 300..<400,
          affectedNodeIDs: []
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Another error with node",
          byteRange: 200..<300,
          affectedNodeIDs: [20]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Sort by affected node
      viewModel.sortOrder = .affectedNode

      // Assert: Issues without affected nodes should sort to end
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].affectedNodeIDs.first, 10)
      XCTAssertEqual(sortedIssues[1].affectedNodeIDs.first, 20)
      XCTAssertTrue(
        sortedIssues[2].affectedNodeIDs.isEmpty, "Issue without affected nodes should be last")
    }

    // MARK: - Severity Sorting Tests (Existing Behavior)

    func testSeveritySorting_RemainsDeterministic() {
      // Arrange: Create issues with same severity but different codes
      let store = ParseTreeStore()
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-003",
          message: "Error C",
          byteRange: 300..<400,
          affectedNodeIDs: [3]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .error,
          code: "ERR-001",
          message: "Error A",
          byteRange: 100..<200,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )
      store.issueStore.record(
        ParseIssue(
          severity: .warning,
          code: "WARN-001",
          message: "Warning",
          byteRange: 200..<300,
          affectedNodeIDs: [2]
        ),
        depth: 1
      )

      let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

      // Act: Default sort by severity
      viewModel.sortOrder = .severity

      // Assert: Should sort by severity (errors first, then warnings)
      let sortedIssues = viewModel.displayedIssues
      XCTAssertEqual(sortedIssues.count, 3)
      XCTAssertEqual(sortedIssues[0].severity, .error)
      XCTAssertEqual(sortedIssues[1].severity, .error)
      XCTAssertEqual(sortedIssues[2].severity, .warning)
    }
  }
#endif
