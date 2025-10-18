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

extension ParseTreeNode: Identifiable {
    public var id: Int64 { header.startOffset }

    public var category: BoxCategory {
        BoxClassifier.category(for: header, metadata: metadata)
    }

    public var isStreamingIndicator: Bool {
        BoxClassifier.isStreamingIndicator(header: header)
    }
}
