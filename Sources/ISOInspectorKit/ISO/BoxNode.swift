import Foundation

/// Immutable aggregate describing a parsed ISO BMFF box and its subtree.
///
/// ``BoxNode`` snapshots capture the header offsets, catalog metadata,
/// parsed payload details, validation issues, and nested children produced by
/// the streaming ``ParsePipeline``. The type is ``Sendable`` so callers can
/// freely share snapshots across concurrency domains (CLI formatting,
/// SwiftUI stores, exporters).
public struct BoxNode: Equatable, Sendable {
    public enum Status: String, Equatable, Sendable, Codable {
        case valid
        case partial
        case corrupt
        case skipped
        case invalid
        case empty
        case trimmed
    }

    public let header: BoxHeader
    public var metadata: BoxDescriptor?
    public var payload: ParsedBoxPayload?
    public var validationIssues: [ValidationIssue]
    public var issues: [ParseIssue]
    public var status: Status
    public var children: [BoxNode]

    public init(
        header: BoxHeader,
        metadata: BoxDescriptor? = nil,
        payload: ParsedBoxPayload? = nil,
        validationIssues: [ValidationIssue] = [],
        issues: [ParseIssue] = [],
        status: Status = .valid,
        children: [BoxNode] = []
    ) {
        self.header = header
        self.metadata = metadata
        self.payload = payload
        self.validationIssues = validationIssues
        self.issues = issues
        self.status = status
        self.children = children
    }
}

extension BoxNode: Identifiable {
    public var id: Int64 { header.startOffset }

    public var category: BoxCategory {
        BoxClassifier.category(for: header, metadata: metadata)
    }

    public var isStreamingIndicator: Bool {
        BoxClassifier.isStreamingIndicator(header: header)
    }
}
