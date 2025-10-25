// swift-tools-version: 6.0
import Foundation

/// Represents an item in the ISO box hierarchy rendered by ``BoxTreePattern``.
public struct BoxTreeNode<ID: Hashable>: Identifiable, Equatable {
    /// Stable identifier for the node.
    public let id: ID

    /// Primary title displayed for the node.
    public var title: String

    /// Optional subtitle providing supplemental context such as size or offsets.
    public var subtitle: String?

    /// Child nodes representing nested structure.
    public var children: [BoxTreeNode]

    /// Creates a node with the provided metadata and child hierarchy.
    /// - Parameters:
    ///   - id: Stable identifier used for selection and accessibility.
    ///   - title: Primary title displayed to the user.
    ///   - subtitle: Optional subtitle with secondary information.
    ///   - children: Nested nodes representing the tree below this node.
    public init(id: ID, title: String, subtitle: String? = nil, children: [BoxTreeNode] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.children = children
    }

    /// Indicates whether the node has child content.
    public var isLeaf: Bool { children.isEmpty }
}
