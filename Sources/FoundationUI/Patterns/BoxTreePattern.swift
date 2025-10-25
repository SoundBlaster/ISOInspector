import Foundation

/// Represents a node in the BoxTree hierarchy.
public struct BoxTreeNode<ID: Hashable>: Identifiable, Equatable {
    public let id: ID
    public var title: String
    public var subtitle: String?
    public var children: [BoxTreeNode]

    /// Creates a node with the provided metadata and children.
    /// - Parameters:
    ///   - id: Stable identifier for the node.
    ///   - title: Primary label to render for the node.
    ///   - subtitle: Optional secondary label.
    ///   - children: Child nodes representing the hierarchy beneath this node.
    public init(id: ID, title: String, subtitle: String? = nil, children: [BoxTreeNode] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.children = children
    }

    /// Indicates whether the node has any children.
    public var isLeaf: Bool { children.isEmpty }
}

/// Controller responsible for managing selection, expansion, and flattening logic for ``BoxTreePattern``.
public final class BoxTreeController<ID: Hashable>: FoundationUIObservableObject {
    /// Visible node metadata containing hierarchy depth information.
    public struct VisibleNode: Identifiable, Equatable {
        public let node: BoxTreeNode<ID>
        public let depth: Int
        public let isExpanded: Bool

        public var id: ID { node.id }
        public var isLeaf: Bool { node.isLeaf }
    }

    @FoundationUIPublished public private(set) var visibleNodes: [VisibleNode]
    @FoundationUIPublished public private(set) var selection: Set<ID>

    private(set) var lastAccessibilityAnnouncement: String?

    private var expanded: Set<ID>
    private let allowsMultipleSelection: Bool
    private let nodes: [BoxTreeNode<ID>]
    private let titleLookup: [ID: String]

    /// Creates the controller with the provided nodes and configuration.
    /// - Parameters:
    ///   - nodes: Root nodes of the tree.
    ///   - allowsMultipleSelection: Flag describing whether multiple nodes can be selected simultaneously.
    ///   - initialSelection: Initial selection applied to the controller.
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
    /// Updates ``visibleNodes`` and accessibility announcement metadata.
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

    /// Returns whether the node matching the identifier is currently expanded.
    public func isExpanded(_ id: ID) -> Bool {
        expanded.contains(id)
    }

    /// Selects the node matching the identifier according to the selection policy.
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

    /// Replaces the selection with the provided value.
    public func setSelection(_ newValue: Set<ID>) {
        selection = allowsMultipleSelection ? newValue : Set(newValue.prefix(1))
    }

    /// Computes indentation for a hierarchical depth using design system spacing tokens.
    public func indentation(forDepth depth: Int) -> CGFloat {
        DS.Spacing.indentation(forDepth: depth)
    }

    /// Provides the last accessibility announcement emitted after expansion changes.
    public var lastAccessibilityAnnouncementText: String? {
        lastAccessibilityAnnouncement
    }

    private func title(for id: ID) -> String {
        titleLookup[id] ?? "Item"
    }

    private static func flatten(nodes: [BoxTreeNode<ID>], expanded: Set<ID>, depth: Int = 0) -> [VisibleNode] {
        nodes.flatMap { node -> [VisibleNode] in
            var rows: [VisibleNode] = [VisibleNode(node: node, depth: depth, isExpanded: expanded.contains(node.id))]
            if expanded.contains(node.id), !node.children.isEmpty {
                rows.append(contentsOf: flatten(nodes: node.children, expanded: expanded, depth: depth + 1))
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

#if canImport(SwiftUI)
import SwiftUI

/// BoxTreePattern renders hierarchical box structures with expand/collapse, selection, and accessibility support.
public struct BoxTreePattern<ID: Hashable>: View {
    @Binding private var selection: Set<ID>
    @StateObject private var controller: BoxTreeController<ID>

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Creates the pattern with the specified tree nodes and selection binding.
    /// - Parameters:
    ///   - nodes: Root nodes to render.
    ///   - selection: Binding to the set of selected identifiers.
    ///   - allowsMultipleSelection: When `true`, permits multi-select interactions.
    public init(
        nodes: [BoxTreeNode<ID>],
        selection: Binding<Set<ID>>,
        allowsMultipleSelection: Bool = true
    ) {
        _selection = selection
        _controller = StateObject(
            wrappedValue: BoxTreeController(
                nodes: nodes,
                allowsMultipleSelection: allowsMultipleSelection,
                initialSelection: selection.wrappedValue
            )
        )
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.s) {
                ForEach(controller.visibleNodes) { visibleNode in
                    row(for: visibleNode)
                }
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Colors.surfaceBackground)
        .onChange(of: controller.selection) { newValue in
            if selection != newValue {
                selection = newValue
            }
        }
        .onChange(of: selection) { newValue in
            if controller.selection != newValue {
                controller.setSelection(newValue)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Box Tree")
    }

    @ViewBuilder
    private func row(for visibleNode: BoxTreeController<ID>.VisibleNode) -> some View {
        let node = visibleNode.node
        let isSelected = controller.selection.contains(node.id)
        let indentation = controller.indentation(forDepth: visibleNode.depth)

        HStack(spacing: DS.Spacing.s) {
            if !node.isLeaf {
                Button {
                    performAnimatedToggle(for: node.id)
                } label: {
                    Image(systemName: visibleNode.isExpanded ? "chevron.down" : "chevron.right")
                        .font(DS.Typography.icon)
                        .foregroundStyle(DS.Colors.primaryText)
                        .accessibilityLabel(visibleNode.isExpanded ? "Collapse" : "Expand")
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: DS.Spacing.s)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(node.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.primaryText)
                if let subtitle = node.subtitle {
                    Text(subtitle)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.primaryText.opacity(DS.Opacity.subtleText))
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, indentation)
        .padding(.horizontal, DS.Spacing.s)
        .padding(.vertical, DS.Spacing.xs)
        .background(isSelected ? DS.Colors.selectionBackground : Color.clear)
        .cornerRadius(DS.Radius.small)
        .contentShape(Rectangle())
        .onTapGesture {
            performSelection(for: node.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func performAnimatedToggle(for id: ID) {
        if let animation = DS.Animation.resolvedQuick(prefersReducedMotion: reduceMotion) {
            withAnimation(animation) {
                controller.toggleExpansion(for: id)
            }
        } else {
            controller.toggleExpansion(for: id)
        }
    }

    private func performSelection(for id: ID) {
        controller.select(id)
        selection = controller.selection
    }
}

#Preview("BoxTreePattern Light") {
    BoxTreePattern(
        nodes: SampleData.nodes,
        selection: .constant([])
    )
}

#Preview("BoxTreePattern Dark") {
    BoxTreePattern(
        nodes: SampleData.nodes,
        selection: .constant([])
    )
    .environment(\.colorScheme, .dark)
}

private enum SampleData {
    static var nodes: [BoxTreeNode<UUID>] {
        let childA = BoxTreeNode(id: UUID(), title: "ftyp", subtitle: "File Type Box")
        let childB = BoxTreeNode(id: UUID(), title: "moov", subtitle: "Movie Box", children: [
            BoxTreeNode(id: UUID(), title: "mvhd", subtitle: "Movie Header Box"),
            BoxTreeNode(id: UUID(), title: "trak", subtitle: "Track Box")
        ])
        let root = BoxTreeNode(id: UUID(), title: "ISO File", subtitle: "1.2 MB", children: [childA, childB])
        return [root]
    }
}
#endif
