import Foundation

public struct ParseTree: Equatable, Sendable {
    public var nodes: [ParseTreeNode]
    public var validationIssues: [ValidationIssue]
    public var validationMetadata: ValidationMetadata?

    public init(
        nodes: [ParseTreeNode] = [],
        validationIssues: [ValidationIssue] = [],
        validationMetadata: ValidationMetadata? = nil
    ) {
        self.nodes = nodes
        self.validationIssues = validationIssues
        self.validationMetadata = validationMetadata
    }
}
