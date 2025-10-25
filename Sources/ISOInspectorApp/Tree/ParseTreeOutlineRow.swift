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
    let corruptionSummary: CorruptionSummary?

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

    struct CorruptionSummary: Equatable {
        private let counts: [ParseIssue.Severity: Int]
        let totalCount: Int
        let dominantSeverity: ParseIssue.Severity
        let primaryIssue: ParseIssue?

        init?(issues: [ParseIssue]) {
            guard !issues.isEmpty else { return nil }
            var resolvedCounts: [ParseIssue.Severity: Int] = [:]
            for severity in ParseIssue.Severity.allCases {
                resolvedCounts[severity] = 0
            }
            for issue in issues {
                resolvedCounts[issue.severity, default: 0] += 1
            }

            let sortedIssues = issues.sorted { lhs, rhs in
                priority(for: lhs.severity) > priority(for: rhs.severity)
            }

            self.counts = resolvedCounts
            self.totalCount = issues.count
            self.dominantSeverity = sortedIssues.first?.severity ?? .info
            self.primaryIssue = sortedIssues.first
        }

        func count(for severity: ParseIssue.Severity) -> Int {
            counts[severity, default: 0]
        }

        var badgeText: String {
            if totalCount == 1 {
                return "1 issue"
            }
            return "\(totalCount) issues"
        }

        var accessibilityLabel: String {
            var components: [String] = ["Corrupted", badgeText]
            components.append("Highest severity \(dominantSeverity.accessibilityDescription)")
            if let primaryIssue, !primaryIssue.message.isEmpty {
                components.append(primaryIssue.message)
            }
            return components.joined(separator: ". ")
        }

        var accessibilityHint: String? {
            guard let primaryIssue else { return nil }
            if primaryIssue.code.isEmpty {
                return nil
            }
            return "Primary issue: \(primaryIssue.code)"
        }

        var tooltipText: String? {
            guard let primaryIssue else { return nil }
            let code = primaryIssue.code.isEmpty ? nil : primaryIssue.code
            if let code, !primaryIssue.message.isEmpty {
                return "\(code) — \(primaryIssue.message)"
            }
            if !primaryIssue.message.isEmpty {
                return primaryIssue.message
            }
            return code
        }

        private static func priority(for severity: ParseIssue.Severity) -> Int {
            switch severity {
            case .error:
                return 2
            case .warning:
                return 1
            case .info:
                return 0
            }
        }
    }
}

private extension ParseIssue.Severity {
    var accessibilityDescription: String {
        switch self {
        case .info:
            return "informational issue"
        case .warning:
            return "warning issue"
        case .error:
            return "error issue"
        }
    }
}
#endif
