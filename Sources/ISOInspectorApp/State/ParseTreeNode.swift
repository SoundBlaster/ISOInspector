#if canImport(Combine)
import Foundation
import ISOInspectorKit

public struct ParseTreeNode: Equatable, Identifiable, Sendable {
    public let header: BoxHeader
    public var metadata: BoxDescriptor?
    public var payload: ParsedBoxPayload?
    public var validationIssues: [ValidationIssue]
    public var children: [ParseTreeNode]

    public var id: Int64 { header.startOffset }

    public var category: BoxCategory {
        BoxClassifier.category(for: header, metadata: metadata)
    }

    public var isStreamingIndicator: Bool {
        BoxClassifier.isStreamingIndicator(header: header)
    }
}
#endif
