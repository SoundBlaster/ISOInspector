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
                makeNode(identifier: 1, type: "moov", children: [
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
                makeNode(identifier: 1, type: "root", children: [
                    makeNode(identifier: 2, type: "trak"),
                    makeNode(identifier: 3, type: "mdia")
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
                makeNode(identifier: 1, type: "moov", children: [
                    makeNode(identifier: 2, type: "trak", children: [
                        makeNode(identifier: 3, type: "mdia")
                    ])
                ])
            ],
            validationIssues: []
        )
        let viewModel = ParseTreeOutlineViewModel()
        viewModel.apply(snapshot: snapshot)
        viewModel.toggleExpansion(for: 1) // collapse root

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
                makeNode(identifier: 1, type: "moov", issues: [warningIssue], children: [
                    makeNode(identifier: 2, type: "trak", children: [
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
        let root = makeNode(identifier: 1, type: "moov", children: [metadataNode, mediaNode, indexNode])
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

    func testAvailableCategoriesReflectsSnapshotContents() throws {
        let metadataNode = makeNode(identifier: 2, type: "meta")
        let mediaNode = makeNode(identifier: 3, type: "mdat")
        let indexNode = makeNode(identifier: 4, type: "sidx")
        let otherNode = makeNode(identifier: 5, type: "free")
        let root = makeNode(identifier: 1, type: "moov", children: [metadataNode, mediaNode, indexNode, otherNode])
        let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
        let viewModel = ParseTreeOutlineViewModel()

        viewModel.apply(snapshot: snapshot)

        XCTAssertEqual(viewModel.availableCategories, [.metadata, .media, .index, .container, .other])
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

    func testNavigationMovesBetweenVisibleRows() throws {
        let root = makeNode(identifier: 1, type: "root", children: [
            makeNode(identifier: 2, type: "trak"),
            makeNode(identifier: 3, type: "mdia"),
            makeNode(identifier: 4, type: "minf")
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
        let child = makeNode(identifier: 2, type: "trak", children: [
            makeNode(identifier: 3, type: "mdia")
        ])
        let root = makeNode(identifier: 1, type: "root", children: [child])
        let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [])
        let viewModel = ParseTreeOutlineViewModel()

        viewModel.apply(snapshot: snapshot)

        let rootID = viewModel.rows[0].id
        let childID = viewModel.rows[1].id
        let grandchildID = viewModel.rows[2].id

        XCTAssertEqual(viewModel.rowID(after: rootID, direction: .child), childID)
        XCTAssertEqual(viewModel.rowID(after: childID, direction: .child), grandchildID)
        XCTAssertEqual(viewModel.rowID(after: childID, direction: .parent), rootID)
        XCTAssertEqual(viewModel.rowID(after: grandchildID, direction: .parent), childID)
    }

    // MARK: - Helpers

    private func makeNode(
        identifier: Int64,
        type: String,
        issues: [ValidationIssue] = [],
        children: [ParseTreeNode] = []
    ) -> ParseTreeNode {
        let start = identifier * 100
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
            children: children
        )
    }
}
#endif
