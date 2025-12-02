import Foundation

public struct ParseTree: Equatable, Sendable {
    public var nodes: [BoxNode]
    public var validationIssues: [ValidationIssue]
    public var validationMetadata: ValidationMetadata?

    public init(
        nodes: [BoxNode] = [], validationIssues: [ValidationIssue] = [],
        validationMetadata: ValidationMetadata? = nil
    ) {
        self.nodes = nodes
        self.validationIssues = validationIssues
        self.validationMetadata = validationMetadata
    }
}
