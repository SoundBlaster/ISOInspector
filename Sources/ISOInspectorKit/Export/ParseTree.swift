import Foundation

public struct ParseTree: Equatable, Sendable {
    public var nodes: [ParseTreeNode]
    public var validationIssues: [ValidationIssue]

    public init(nodes: [ParseTreeNode] = [], validationIssues: [ValidationIssue] = []) {
        self.nodes = nodes
        self.validationIssues = validationIssues
    }
}
