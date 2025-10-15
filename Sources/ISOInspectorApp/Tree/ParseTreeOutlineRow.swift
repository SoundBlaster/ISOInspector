#if canImport(Combine)
import Foundation
import ISOInspectorKit

struct ParseTreeOutlineRow: Identifiable, Equatable {
    let node: ParseTreeNode
    let depth: Int
    let isExpanded: Bool
    let isSearchMatch: Bool
    let hasMatchingDescendant: Bool
    let hasValidationIssues: Bool

    var id: ParseTreeNode.ID { node.id }
    var typeDescription: String { node.header.type.description }
    var displayName: String { node.metadata?.name ?? typeDescription }
    var summary: String? { node.metadata?.summary }
    var dominantSeverity: ValidationIssue.Severity? {
        node.validationIssues
            .map(\.severity)
            .max(by: { priority(for: $0) < priority(for: $1) })
    }

    private func priority(for severity: ValidationIssue.Severity) -> Int {
        switch severity {
        case .info: return 0
        case .warning: return 1
        case .error: return 2
        }
    }
}
#endif
