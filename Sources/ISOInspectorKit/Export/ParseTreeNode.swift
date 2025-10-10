import Foundation

public struct ParseTreeNode: Equatable, Sendable {
    public let header: BoxHeader
    public var metadata: BoxDescriptor?
    public var validationIssues: [ValidationIssue]
    public var children: [ParseTreeNode]

    public init(
        header: BoxHeader,
        metadata: BoxDescriptor? = nil,
        validationIssues: [ValidationIssue] = [],
        children: [ParseTreeNode] = []
    ) {
        self.header = header
        self.metadata = metadata
        self.validationIssues = validationIssues
        self.children = children
    }
}
