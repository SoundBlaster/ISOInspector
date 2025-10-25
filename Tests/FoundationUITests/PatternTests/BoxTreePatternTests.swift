import XCTest
@testable import FoundationUI

final class BoxTreePatternTests: XCTestCase {
    func testToggleExpansionUpdatesExpandedState() {
        let controller = BoxTreeController(
            nodes: TestFixtures.makeLinearTree(depth: 3),
            allowsMultipleSelection: false
        )

        let rootID = TestFixtures.rootID
        XCTAssertFalse(controller.isExpanded(rootID))

        controller.toggleExpansion(for: rootID)
        XCTAssertTrue(controller.isExpanded(rootID))

        controller.toggleExpansion(for: rootID)
        XCTAssertFalse(controller.isExpanded(rootID))
    }

    func testSelectionSingleSelectionReplacesPrevious() {
        let controller = BoxTreeController(
            nodes: TestFixtures.makeLinearTree(depth: 3),
            allowsMultipleSelection: false
        )

        let firstChildID = TestFixtures.childID(index: 0)
        let secondChildID = TestFixtures.childID(index: 1)

        controller.select(firstChildID)
        XCTAssertEqual(controller.selection, [firstChildID])

        controller.select(secondChildID)
        XCTAssertEqual(controller.selection, [secondChildID])
    }

    func testIndentationSpacingAlignsWithDesignTokens() {
        let controller = BoxTreeController(
            nodes: TestFixtures.makeLinearTree(depth: 2),
            allowsMultipleSelection: false
        )

        let depth = 3
        let indentation = controller.indentation(forDepth: depth)
        XCTAssertEqual(
            indentation,
            DS.Spacing.levelIndentation * CGFloat(depth),
            accuracy: 0.0001
        )
    }

    func testAccessibilityAnnouncementsReflectExpansionState() {
        let controller = BoxTreeController(
            nodes: TestFixtures.makeLinearTree(depth: 2),
            allowsMultipleSelection: true
        )

        let rootID = TestFixtures.rootID
        controller.toggleExpansion(for: rootID)
        XCTAssertEqual(
            controller.lastAccessibilityAnnouncementText,
            "Expanded Root"
        )

        controller.toggleExpansion(for: rootID)
        XCTAssertEqual(
            controller.lastAccessibilityAnnouncementText,
            "Collapsed Root"
        )
    }

    func testVisibleNodesHandlesLargeDataSets() {
        let controller = BoxTreeController(
            nodes: TestFixtures.makeWideTree(childCount: 1_000),
            allowsMultipleSelection: false
        )

        controller.toggleExpansion(for: TestFixtures.rootID)
        XCTAssertEqual(controller.visibleNodes.count, 1_001)
    }
}

private enum TestFixtures {
    static let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    static func makeLinearTree(depth: Int) -> [BoxTreeNode<UUID>] {
        var current = BoxTreeNode(id: rootID, title: "Root", children: [])
        var parent = current
        for index in 0..<depth {
            let child = BoxTreeNode(id: childID(index: index), title: "Child \(index)")
            parent.children.append(child)
        }
        current.children = parent.children
        return [current]
    }

    static func makeWideTree(childCount: Int) -> [BoxTreeNode<UUID>] {
        var children: [BoxTreeNode<UUID>] = []
        children.reserveCapacity(childCount)
        for index in 0..<childCount {
            children.append(BoxTreeNode(id: childID(index: index), title: "Child \(index)"))
        }
        let root = BoxTreeNode(id: rootID, title: "Root", children: children)
        return [root]
    }

    static func childID(index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
    }
}
