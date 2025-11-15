#if canImport(Combine)
  import Combine
  import XCTest
  @testable import ISOInspectorApp
  import ISOInspectorKit

  @MainActor
  final class ParseTreeOutlineViewModelTests: XCTestCase {
    func testApplyingSnapshotExpandsRootNodes() throws {
      let snapshot = ParseTreeSnapshot(
        nodes: [
          makeNode(
            identifier: 1, type: "moov",
            children: [
              makeNode(identifier: 2, type: "trak")
            ])
        ],
        validationIssues: []
      )
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2])
      XCTAssertTrue(viewModel.rows.first?.isExpanded ?? false)
    }

    func testToggleExpansionCollapsesChildren() throws {
      let snapshot = ParseTreeSnapshot(
        nodes: [
          makeNode(
            identifier: 1, type: "root",
            children: [
              makeNode(identifier: 2, type: "trak"),
              makeNode(identifier: 3, type: "mdia"),
            ])
        ],
        validationIssues: []
      )
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)

      viewModel.toggleExpansion(for: 1)

      XCTAssertEqual(viewModel.rows.map(\.id), [1])
      XCTAssertFalse(viewModel.rows.first?.isExpanded ?? true)

      viewModel.toggleExpansion(for: 1)

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])
      XCTAssertTrue(viewModel.rows.first?.isExpanded ?? false)
    }

    func testSearchNarrowsResultsAndExpandsAncestors() throws {
      let snapshot = ParseTreeSnapshot(
        nodes: [
          makeNode(
            identifier: 1, type: "moov",
            children: [
              makeNode(
                identifier: 2, type: "trak",
                children: [
                  makeNode(identifier: 3, type: "mdia")
                ])
            ])
        ],
        validationIssues: []
      )
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)
      viewModel.toggleExpansion(for: 1)  // collapse root

      XCTAssertEqual(viewModel.rows.map(\.id), [1])

      viewModel.searchText = "mdia"

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])
      XCTAssertTrue(viewModel.rows.allSatisfy { $0.isExpanded })
      XCTAssertEqual(viewModel.rows.last?.isSearchMatch, true)
    }

    func testSeverityFilterShowsMatchingIssuesAndContext() throws {
      let errorIssue = ValidationIssue(ruleID: "VR-001", message: "error", severity: .error)
      let warningIssue = ValidationIssue(ruleID: "VR-002", message: "warning", severity: .warning)
      let snapshot = ParseTreeSnapshot(
        nodes: [
          makeNode(
            identifier: 1, type: "moov", issues: [warningIssue],
            children: [
              makeNode(
                identifier: 2, type: "trak",
                children: [
                  makeNode(identifier: 3, type: "mdia", issues: [errorIssue])
                ])
            ])
        ],
        validationIssues: [warningIssue, errorIssue]
      )
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)

      viewModel.filter = ParseTreeOutlineFilter(focusedSeverities: [.error])

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])
      XCTAssertTrue(viewModel.rows.first?.isExpanded ?? false)
      XCTAssertEqual(viewModel.rows.last?.hasValidationIssues, true)
      XCTAssertEqual(viewModel.rows.last?.isSearchMatch, false)
    }

    @MainActor
    func testBindingToSnapshotPublisherStreamsUpdates() async throws {
      let viewModel = ParseTreeOutlineViewModel()
      let subject = PassthroughSubject<ParseTreeSnapshot, Never>()

      viewModel.bind(to: subject.eraseToAnyPublisher())

      let root = makeNode(identifier: 1, type: "moov")
      let initial = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      subject.send(initial)
      await Task.yield()

      XCTAssertEqual(viewModel.rows.map(\.id), [1])

      let child = makeNode(identifier: 2, type: "trak")
      let updatedRoot = makeNode(identifier: 1, type: "moov", children: [child])
      let updated = ParseTreeSnapshot(nodes: [updatedRoot], validationIssues: [])
      subject.send(updated)
      await Task.yield()

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2])
      XCTAssertTrue(viewModel.rows.first?.isExpanded ?? false)
    }

    func testCategoryFilterFocusesOnSelectedCategories() throws {
      let metadataNode = makeNode(identifier: 2, type: "meta")
      let mediaNode = makeNode(identifier: 3, type: "mdat")
      let indexNode = makeNode(identifier: 4, type: "sidx")
      let root = makeNode(
        identifier: 1, type: "moov", children: [metadataNode, mediaNode, indexNode])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)

      viewModel.filter = ParseTreeOutlineFilter(focusedCategories: [.metadata, .media])

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])
      XCTAssertTrue(viewModel.rows.contains { $0.id == 2 })
      XCTAssertTrue(viewModel.rows.contains { $0.id == 3 })
      XCTAssertFalse(viewModel.rows.contains { $0.id == 4 })
    }

    func testStreamingFilterHidesIndicatorBoxesWhenDisabled() throws {
      let streamingNode = makeNode(identifier: 2, type: "sidx")
      let otherNode = makeNode(identifier: 3, type: "free")
      let root = makeNode(identifier: 1, type: "moov", children: [streamingNode, otherNode])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)

      viewModel.filter = ParseTreeOutlineFilter(showsStreamingIndicators: false)

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 3])
      XCTAssertFalse(viewModel.rows.contains { $0.id == 2 })
    }

    func testIssueOnlyFilterHidesHealthyBranchesButKeepsAncestors() throws {
      let corruptLeaf = makeNode(
        identifier: 3,
        type: "leaf",
        parseIssues: [
          ParseIssue(
            severity: .error,
            code: "VR-999",
            message: "Corrupt",
            byteRange: 0..<8,
            affectedNodeIDs: [3]
          )
        ]
      )
      let healthySibling = makeNode(identifier: 4, type: "clen")
      let intermediate = makeNode(
        identifier: 2, type: "trak", children: [corruptLeaf, healthySibling])
      let healthyBranch = makeNode(identifier: 5, type: "mdia")
      let root = makeNode(identifier: 1, type: "moov", children: [intermediate, healthyBranch])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()
      viewModel.apply(snapshot: snapshot)

      viewModel.filter = ParseTreeOutlineFilter(showsOnlyIssues: true)

      let visibleIDs = viewModel.rows.map(\.id)
      XCTAssertTrue(visibleIDs.contains(1))
      XCTAssertTrue(visibleIDs.contains(2))
      XCTAssertTrue(visibleIDs.contains(3))
      XCTAssertFalse(visibleIDs.contains(4))
      XCTAssertFalse(visibleIDs.contains(5))
    }

    func testAvailableCategoriesReflectsSnapshotContents() throws {
      let metadataNode = makeNode(identifier: 2, type: "meta")
      let mediaNode = makeNode(identifier: 3, type: "mdat")
      let indexNode = makeNode(identifier: 4, type: "sidx")
      let otherNode = makeNode(identifier: 5, type: "free")
      let root = makeNode(
        identifier: 1, type: "moov", children: [metadataNode, mediaNode, indexNode, otherNode])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      XCTAssertEqual(
        viewModel.availableCategories, [.metadata, .media, .index, .container, .other])
    }

    func testContainsStreamingIndicatorsIsTrueWhenNodesPresent() throws {
      let streamingNode = makeNode(identifier: 2, type: "sidx")
      let root = makeNode(identifier: 1, type: "moov", children: [streamingNode])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      XCTAssertTrue(viewModel.containsStreamingIndicators)
    }

    func testContainsStreamingIndicatorsIsFalseWhenAbsent() throws {
      let root = makeNode(identifier: 1, type: "moov")
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      XCTAssertFalse(viewModel.containsStreamingIndicators)
    }

    func testRowsExposeCorruptionSummaryFromParseIssues() throws {
      let parseIssues = [
        ParseIssue(
          severity: .error,
          code: "VR-900",
          message: "Stub error",
          byteRange: 0..<8,
          affectedNodeIDs: [1]
        ),
        ParseIssue(
          severity: .warning,
          code: "VR-901",
          message: "Stub warning",
          byteRange: 8..<16,
          affectedNodeIDs: [1]
        ),
      ]
      let node = makeNode(identifier: 1, type: "trak", parseIssues: parseIssues)
      let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      let row = try XCTUnwrap(viewModel.rows.first)
      let summary = try XCTUnwrap(row.corruptionSummary)
      XCTAssertEqual(summary.totalCount, 2)
      XCTAssertEqual(summary.count(for: .error), 1)
      XCTAssertEqual(summary.count(for: .warning), 1)
      XCTAssertEqual(summary.dominantSeverity, .error)
      XCTAssertEqual(summary.primaryIssue?.code, "VR-900")
    }

    func testRowsIncludeStatusDescriptorForPartialNodes() throws {
      let node = makeNode(identifier: 1, type: "trak", status: .partial)
      let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      let descriptor = try XCTUnwrap(viewModel.rows.first?.statusDescriptor)
      XCTAssertEqual(descriptor.text, "Partial")
      XCTAssertEqual(descriptor.level, .warning)
    }

    func testFirstVisibleNodeIDDefaultsToRoot() throws {
      let child = makeNode(identifier: 2, type: "trak")
      let root = makeNode(identifier: 1, type: "moov", children: [child])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      XCTAssertEqual(viewModel.firstVisibleNodeID(), root.id)
    }

    func testContainsNodeReflectsLatestSnapshot() throws {
      let rootWithChild = makeNode(
        identifier: 1, type: "moov",
        children: [
          makeNode(identifier: 2, type: "trak")
        ])
      let initial = ParseTreeSnapshot(nodes: [rootWithChild], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: initial)

      XCTAssertTrue(viewModel.containsNode(with: rootWithChild.id))
      let childID = try XCTUnwrap(viewModel.rows.last?.id)
      XCTAssertTrue(viewModel.containsNode(with: childID))

      let updatedRoot = makeNode(identifier: 1, type: "moov")
      let updated = ParseTreeSnapshot(nodes: [updatedRoot], validationIssues: [])
      viewModel.apply(snapshot: updated)

      XCTAssertTrue(viewModel.containsNode(with: updatedRoot.id))
      XCTAssertFalse(viewModel.containsNode(with: childID))
    }

    func testNavigationMovesBetweenVisibleRows() throws {
      let root = makeNode(
        identifier: 1, type: "root",
        children: [
          makeNode(identifier: 2, type: "trak"),
          makeNode(identifier: 3, type: "mdia"),
          makeNode(identifier: 4, type: "minf"),
        ])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      let first = viewModel.rows[0].id
      let second = viewModel.rows[1].id
      let third = viewModel.rows[2].id

      XCTAssertEqual(viewModel.rowID(after: first, direction: .down), second)
      XCTAssertEqual(viewModel.rowID(after: second, direction: .down), third)
      XCTAssertEqual(viewModel.rowID(after: second, direction: .up), first)
    }

    func testNavigationMovesToParentOrChildRows() throws {
      let child = makeNode(
        identifier: 2, type: "trak",
        children: [
          makeNode(identifier: 3, type: "mdia")
        ])
      let root = makeNode(identifier: 1, type: "root", children: [child])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      let rootID = viewModel.rows[0].id
      let childID = viewModel.rows[1].id
      viewModel.toggleExpansion(for: childID)
      XCTAssertGreaterThanOrEqual(viewModel.rows.count, 3)
      let grandchildID = viewModel.rows[2].id

      XCTAssertEqual(viewModel.rowID(after: rootID, direction: .child), childID)
      XCTAssertEqual(viewModel.rowID(after: childID, direction: .child), grandchildID)
      XCTAssertEqual(viewModel.rowID(after: childID, direction: .parent), rootID)
      XCTAssertEqual(viewModel.rowID(after: grandchildID, direction: .parent), childID)
    }

    func testIssueNavigationSkipsHealthyNodes() throws {
      let corruptA = makeNode(
        identifier: 2,
        type: "trak",
        parseIssues: [
          ParseIssue(
            severity: .warning,
            code: "VR-100",
            message: "Warning",
            byteRange: 0..<4,
            affectedNodeIDs: [2]
          )
        ]
      )
      let healthy = makeNode(identifier: 3, type: "mdia")
      let corruptB = makeNode(
        identifier: 4,
        type: "minf",
        issues: [ValidationIssue(ruleID: "VR-002", message: "Error", severity: .error)]
      )
      let root = makeNode(identifier: 1, type: "root", children: [corruptA, healthy, corruptB])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      let nextFromRoot = viewModel.issueRowID(after: 1, direction: .down)
      XCTAssertEqual(nextFromRoot, 2)

      let nextFromFirstIssue = viewModel.issueRowID(after: 2, direction: .down)
      XCTAssertEqual(nextFromFirstIssue, 4)

      let previousFromLast = viewModel.issueRowID(after: 4, direction: .up)
      XCTAssertEqual(previousFromLast, 2)
    }

    func testRevealNodeExpandsAncestorsForIssueSelection() throws {
      let leaf = makeNode(identifier: 3, type: "leaf")
      let parent = makeNode(identifier: 2, type: "trak", children: [leaf])
      let root = makeNode(identifier: 1, type: "moov", children: [parent])
      let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
      let viewModel = ParseTreeOutlineViewModel()

      viewModel.apply(snapshot: snapshot)

      // Expand the parent first so the child is visible, mirroring a user that
      // previously drilled into the branch before collapsing it.
      viewModel.toggleExpansion(for: 2)
      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])

      viewModel.toggleExpansion(for: 2)
      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2])

      viewModel.revealNode(withID: 3)

      XCTAssertEqual(viewModel.rows.map(\.id), [1, 2, 3])
    }

    // MARK: - Helpers

    private func makeNode(
      identifier: Int64,
      type: String,
      issues: [ValidationIssue] = [],
      parseIssues: [ParseIssue] = [],
      status: ParseTreeNode.Status = .valid,
      children: [ParseTreeNode] = []
    ) -> ParseTreeNode {
      let start = identifier
      let totalSize: Int64 = 32
      let headerSize: Int64 = 8
      let header = BoxHeader(
        type: try! FourCharCode(type),
        totalSize: totalSize,
        headerSize: headerSize,
        payloadRange: (start + headerSize)..<(start + totalSize),
        range: start..<(start + totalSize),
        uuid: nil
      )
      return ParseTreeNode(
        header: header,
        metadata: nil,
        payload: nil,
        validationIssues: issues,
        issues: parseIssues,
        status: status,
        children: children
      )
    }
  }
#endif
