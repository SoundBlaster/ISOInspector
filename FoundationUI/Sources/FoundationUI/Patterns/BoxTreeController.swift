// swift-tools-version: 6.0
import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Controller responsible for managing selection and expansion state for ``BoxTreePattern``.
public final class BoxTreeController<ID: Hashable>: FoundationUIObservableObject {
    /// Metadata describing a node visible within the flattened tree representation.
    public struct VisibleNode: Identifiable, Equatable {
        /// Underlying tree node.
        public let node: BoxTreeNode<ID>

        /// Hierarchy depth used for indentation.
        public let depth: Int

        /// Indicates whether the node is currently expanded.
        public let isExpanded: Bool

        /// Stable identifier forwarding to the underlying node identifier.
        public var id: ID { node.id }

        /// Convenience flag denoting whether the node has children.
        public var isLeaf: Bool { node.isLeaf }
    }

    @FoundationUIPublished
    public private(set) var visibleNodes: [VisibleNode]

    @FoundationUIPublished
    public private(set) var selection: Set<ID>

    private(set) var lastAccessibilityAnnouncement: String?

    private var expanded: Set<ID>
    private let allowsMultipleSelection: Bool
    private let nodes: [BoxTreeNode<ID>]
    private let titleLookup: [ID: String]

    /// Creates a controller for the provided hierarchy.
    /// - Parameters:
    ///   - nodes: Root nodes of the tree to manage.
    ///   - allowsMultipleSelection: Controls whether the tree supports multi-select interactions.
    ///   - initialSelection: Pre-selected node identifiers.
    ///   - initialExpansion: Node identifiers that should start in an expanded state.
    public init(
        nodes: [BoxTreeNode<ID>],
        allowsMultipleSelection: Bool,
        initialSelection: Set<ID> = [],
        initialExpansion: Set<ID> = []
    ) {
        self.nodes = nodes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.selection = initialSelection
        self.expanded = initialExpansion
        self.titleLookup = Self.buildTitleLookup(from: nodes)
        self.visibleNodes = Self.flatten(nodes: nodes, expanded: initialExpansion)
    }

    /// Toggles the expansion state for the node with the provided identifier.
    /// Updates ``visibleNodes`` and emits accessibility announcements describing the change.
    public func toggleExpansion(for id: ID) {
        if expanded.contains(id) {
            expanded.remove(id)
            lastAccessibilityAnnouncement = "Collapsed \(title(for: id))"
        } else {
            expanded.insert(id)
            lastAccessibilityAnnouncement = "Expanded \(title(for: id))"
        }
        visibleNodes = Self.flatten(nodes: nodes, expanded: expanded)
    }

    /// Returns whether the node with the provided identifier is currently expanded.
    public func isExpanded(_ id: ID) -> Bool {
        expanded.contains(id)
    }

    /// Selects the node matching the identifier using the configured selection policy.
    public func select(_ id: ID) {
        if allowsMultipleSelection {
            if selection.contains(id) {
                selection.remove(id)
            } else {
                selection.insert(id)
            }
        } else {
            selection = [id]
        }
    }

    /// Replaces the selection set, enforcing single-selection mode when required.
    public func setSelection(_ newValue: Set<ID>) {
        selection = allowsMultipleSelection ? newValue : Set(newValue.prefix(1))
    }

    /// Computes indentation for a hierarchy depth using design system spacing tokens.
    /// - Parameter depth: Depth within the tree (root starts at zero).
    /// - Returns: Calculated indentation.
    public func indentation(forDepth depth: Int) -> CGFloat {
        DS.Spacing.indentation(forDepth: depth)
    }

    /// Last accessibility announcement generated from expansion changes.
    public var lastAccessibilityAnnouncementText: String? {
        lastAccessibilityAnnouncement
    }

    private func title(for id: ID) -> String {
        titleLookup[id] ?? "Item"
    }

    private static func flatten(
        nodes: [BoxTreeNode<ID>],
        expanded: Set<ID>,
        depth: Int = 0
    ) -> [VisibleNode] {
        nodes.flatMap { node -> [VisibleNode] in
            var rows: [VisibleNode] = [VisibleNode(
                node: node,
                depth: depth,
                isExpanded: expanded.contains(node.id)
            )]

            if expanded.contains(node.id), !node.children.isEmpty {
                rows.append(contentsOf: flatten(
                    nodes: node.children,
                    expanded: expanded,
                    depth: depth + 1
                ))
            }

            return rows
        }
    }

    private static func buildTitleLookup(from nodes: [BoxTreeNode<ID>]) -> [ID: String] {
        var lookup: [ID: String] = [:]

        func visit(_ node: BoxTreeNode<ID>) {
            lookup[node.id] = node.title
            node.children.forEach(visit)
        }

        nodes.forEach(visit)
        return lookup
    }
}
