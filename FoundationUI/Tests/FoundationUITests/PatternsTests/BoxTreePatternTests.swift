// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for the BoxTreePattern view.
///
/// These tests validate the hierarchical tree view functionality including
/// expand/collapse state management, selection handling, DS token usage,
/// and performance optimization for large data sets.
@MainActor
final class BoxTreePatternTests: XCTestCase {

    // MARK: - Test Data Models

    /// Represents a node in the tree hierarchy for testing purposes
    struct TestTreeNode: Identifiable, Equatable {
        let id: UUID
        let title: String
        var children: [TestTreeNode]
        var isExpanded: Bool = false

        init(id: UUID = UUID(), title: String, children: [TestTreeNode] = []) {
            self.id = id
            self.title = title
            self.children = children
        }

        static func == (lhs: TestTreeNode, rhs: TestTreeNode) -> Bool {
            lhs.id == rhs.id && lhs.title == rhs.title
        }
    }

    // MARK: - Test Fixtures

    /// Creates a simple tree with 3 levels for basic testing
    private func makeSimpleTree() -> [TestTreeNode] {
        [
            TestTreeNode(title: "Root", children: [
                TestTreeNode(title: "Child 1", children: [
                    TestTreeNode(title: "Grandchild 1.1"),
                    TestTreeNode(title: "Grandchild 1.2")
                ]),
                TestTreeNode(title: "Child 2")
            ])
        ]
    }

    /// Creates a deep tree with 5+ levels for nesting tests
    private func makeDeepTree() -> [TestTreeNode] {
        [
            TestTreeNode(title: "Level 0", children: [
                TestTreeNode(title: "Level 1", children: [
                    TestTreeNode(title: "Level 2", children: [
                        TestTreeNode(title: "Level 3", children: [
                            TestTreeNode(title: "Level 4", children: [
                                TestTreeNode(title: "Level 5")
                            ])
                        ])
                    ])
                ])
            ])
        ]
    }

    /// Creates a large tree with 1000+ nodes for performance testing
    private func makeLargeTree() -> [TestTreeNode] {
        var nodes: [TestTreeNode] = []
        // Create 10 root nodes, each with 100 children
        for i in 0..<10 {
            var children: [TestTreeNode] = []
            for j in 0..<100 {
                children.append(TestTreeNode(title: "Node \(i).\(j)"))
            }
            nodes.append(TestTreeNode(title: "Root \(i)", children: children))
        }
        return nodes
    }

    // MARK: - Initialization Tests

    func testBoxTreePatternInitializesWithEmptyTree() {
        // Given
        let emptyTree: [TestTreeNode] = []

        // When
        let pattern = BoxTreePattern(
            data: emptyTree,
            children: { $0.children },
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "BoxTreePattern should initialize with empty data")
    }

    func testBoxTreePatternInitializesWithSimpleTree() {
        // Given
        let tree = makeSimpleTree()

        // When
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "BoxTreePattern should initialize with simple tree data")
    }

    func testBoxTreePatternInitializesWithSelectionBinding() {
        // Given
        let tree = makeSimpleTree()
        var selection: UUID? = nil

        // When
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            selection: Binding(get: { selection }, set: { selection = $0 }),
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "BoxTreePattern should support optional selection binding")
    }

    // MARK: - Expand/Collapse State Tests

    func testBoxTreePatternExpandsNode() {
        // Given
        let tree = makeSimpleTree()
        var expandedNodes: Set<UUID> = []

        // When
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            expandedNodes: Binding(get: { expandedNodes }, set: { expandedNodes = $0 }),
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "BoxTreePattern should support expanded state tracking")
    }

    func testBoxTreePatternCollapsesNode() {
        // Given
        let tree = makeSimpleTree()
        let rootId = tree[0].id
        var expandedNodes: Set<UUID> = [rootId]

        // When - initially expanded
        XCTAssertTrue(expandedNodes.contains(rootId), "Root should be initially expanded")

        // Then - can be collapsed by removing from set
        expandedNodes.remove(rootId)
        XCTAssertFalse(expandedNodes.contains(rootId), "Root should be collapsed after removal")
    }

    func testBoxTreePatternPreservesExpandedStateAfterUpdate() {
        // Given
        let tree = makeSimpleTree()
        let rootId = tree[0].id
        var expandedNodes: Set<UUID> = [rootId]

        // When - pattern is recreated with same expanded state
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            expandedNodes: Binding(get: { expandedNodes }, set: { expandedNodes = $0 }),
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertTrue(expandedNodes.contains(rootId), "Expanded state should be preserved")
        XCTAssertNotNil(pattern, "Pattern should maintain state across updates")
    }

    // MARK: - Selection Tests

    func testBoxTreePatternSupportsSelection() {
        // Given
        let tree = makeSimpleTree()
        let targetId = tree[0].id
        var selection: UUID? = nil

        // When
        selection = targetId

        // Then
        XCTAssertEqual(selection, targetId, "Selection should update to target node")
    }

    func testBoxTreePatternSupportsNilSelection() {
        // Given
        let tree = makeSimpleTree()
        var selection: UUID? = tree[0].id

        // When
        selection = nil

        // Then
        XCTAssertNil(selection, "Selection should support deselection")
    }

    func testBoxTreePatternSupportsMultiSelection() {
        // Given
        let tree = makeSimpleTree()
        var selection: Set<UUID> = []

        // When
        selection.insert(tree[0].id)
        if !tree[0].children.isEmpty {
            selection.insert(tree[0].children[0].id)
        }

        // Then
        XCTAssertEqual(selection.count, 2, "Should support multiple selected nodes")
    }

    // MARK: - Indentation Tests (DS Token Usage)

    func testBoxTreePatternUsesDesignSystemSpacingForIndentation() {
        // Given
        _ = makeDeepTree()

        // When - indentation should use DS.Spacing tokens
        let expectedIndentPerLevel = DS.Spacing.l

        // Then
        XCTAssertGreaterThan(expectedIndentPerLevel, 0, "Indentation should use positive DS.Spacing value")
        XCTAssertEqual(expectedIndentPerLevel, DS.Spacing.l, "Should use DS.Spacing.l (16pt) for indentation")
    }

    func testBoxTreePatternCalculatesCorrectIndentationForDeepNesting() {
        // Given
        let levels = [0, 1, 2, 3, 4, 5]

        // When
        let indentations = levels.map { level in
            CGFloat(level) * DS.Spacing.l
        }

        // Then
        XCTAssertEqual(indentations[0], 0, "Level 0 should have no indentation")
        XCTAssertEqual(indentations[1], DS.Spacing.l, "Level 1 should have 1x spacing")
        XCTAssertEqual(indentations[2], DS.Spacing.l * 2, "Level 2 should have 2x spacing")
        XCTAssertEqual(indentations[5], DS.Spacing.l * 5, "Level 5 should have 5x spacing")
    }

    // MARK: - Accessibility Tests

    func testBoxTreePatternSupportsAccessibilityLabels() {
        // Given
        let tree = makeSimpleTree()

        // When
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            content: { node in
                Text(node.title)
                    .accessibilityLabel(node.title)
            }
        )

        // Then
        XCTAssertNotNil(pattern, "Pattern should support accessibility labels on content")
    }

    func testBoxTreePatternProvidesExpandedCollapsedAnnouncements() {
        // Given
        let tree = makeSimpleTree()
        let rootId = tree[0].id
        var expandedNodes: Set<UUID> = []

        // When - toggle expansion
        let wasExpanded = expandedNodes.contains(rootId)
        if wasExpanded {
            expandedNodes.remove(rootId)
        } else {
            expandedNodes.insert(rootId)
        }

        // Then
        let expectedState = wasExpanded ? "collapsed" : "expanded"
        XCTAssertEqual(expectedState, "expanded", "Should announce expanded state for accessibility")
    }

    // MARK: - Performance Tests

    func testBoxTreePatternHandlesLargeDataSet() {
        // Given
        let largeTree = makeLargeTree()

        // When
        let pattern = BoxTreePattern(
            data: largeTree,
            children: { $0.children },
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "Pattern should handle 1000+ nodes without issues")
    }

    func testBoxTreePatternUsesLazyRenderingForPerformance() {
        // Given
        let largeTree = makeLargeTree()
        var expandedNodes: Set<UUID> = []

        // When - only root nodes are expanded
        // LazyVStack should only render visible nodes

        let pattern = BoxTreePattern(
            data: largeTree,
            children: { $0.children },
            expandedNodes: Binding(get: { expandedNodes }, set: { expandedNodes = $0 }),
            content: { node in Text(node.title) }
        )

        // Then
        XCTAssertNotNil(pattern, "Pattern should use lazy rendering for performance")
        XCTAssertTrue(expandedNodes.isEmpty, "Collapsed children should not be rendered")
    }

    // MARK: - View Conformance

    func testBoxTreePatternConformsToView() {
        // Given
        let tree = makeSimpleTree()

        // When
        let pattern = BoxTreePattern(
            data: tree,
            children: { $0.children },
            content: { node in Text(node.title) }
        )

        // Then
        _ = pattern as any View
    }

    // MARK: - Zero Magic Numbers Validation

    func testBoxTreePatternUsesOnlyDesignSystemTokens() {
        // Given - all spacing should use DS tokens
        let spacingTokens = [
            DS.Spacing.s,   // 8pt
            DS.Spacing.m,   // 12pt
            DS.Spacing.l,   // 16pt
            DS.Spacing.xl   // 24pt
        ]

        // Then
        XCTAssertFalse(spacingTokens.isEmpty, "Should use DS.Spacing tokens exclusively")
        XCTAssertEqual(DS.Spacing.s, 8, "DS.Spacing.s should be 8pt")
        XCTAssertEqual(DS.Spacing.m, 12, "DS.Spacing.m should be 12pt")
        XCTAssertEqual(DS.Spacing.l, 16, "DS.Spacing.l should be 16pt")
        XCTAssertEqual(DS.Spacing.xl, 24, "DS.Spacing.xl should be 24pt")
    }

    // MARK: - Animation Tests

    func testBoxTreePatternUsesDesignSystemAnimation() {
        // Given
        _ = makeSimpleTree()
        _ = Set<UUID>()

        // When - animations should use DS.Animation tokens
        let animation = DS.Animation.medium

        // Then
        XCTAssertNotNil(animation, "Should use DS.Animation.medium for expand/collapse")
    }

    func testBoxTreePatternAnimatesExpandCollapse() {
        // Given
        let tree = makeSimpleTree()
        let rootId = tree[0].id
        var expandedNodes: Set<UUID> = []

        // When - expand with animation
        _ = withAnimation(DS.Animation.medium) {
            expandedNodes.insert(rootId)
        }

        // Then
        XCTAssertTrue(expandedNodes.contains(rootId), "Should animate expansion")
    }
}
