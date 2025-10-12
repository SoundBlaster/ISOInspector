import Foundation

public struct ParseTreeNode: Equatable, Sendable {
    public let header: BoxHeader
    public var metadata: BoxDescriptor?
    public var payload: ParsedBoxPayload?
    public var validationIssues: [ValidationIssue]
    public var children: [ParseTreeNode]

    public init(
        header: BoxHeader,
        metadata: BoxDescriptor? = nil,
        payload: ParsedBoxPayload? = nil,
        validationIssues: [ValidationIssue] = [],
        children: [ParseTreeNode] = []
    ) {
        self.header = header
        self.metadata = metadata
        self.payload = payload
        self.validationIssues = validationIssues
        self.children = children
    }
}
