#if canImport(Combine)
import Foundation
import ISOInspectorKit

public struct ParseTreeSnapshot: Equatable, Sendable {
    public var nodes: [ParseTreeNode]
    public var validationIssues: [ValidationIssue]
    public var lastUpdatedAt: Date

    public init(
        nodes: [ParseTreeNode],
        validationIssues: [ValidationIssue],
        lastUpdatedAt: Date = Date.distantPast
    ) {
        self.nodes = nodes
        self.validationIssues = validationIssues
        self.lastUpdatedAt = lastUpdatedAt
    }

    public static let empty = ParseTreeSnapshot(
        nodes: [],
        validationIssues: [],
        lastUpdatedAt: Date.distantPast
    )
}
#endif
