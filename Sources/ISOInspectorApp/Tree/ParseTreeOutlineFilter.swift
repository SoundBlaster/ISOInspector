#if canImport(Combine)
import Foundation
import ISOInspectorKit

struct ParseTreeOutlineFilter: Equatable {
    var focusedSeverities: Set<ValidationIssue.Severity>
    var focusedCategories: Set<BoxCategory>
    var showsStreamingIndicators: Bool

    init(
        focusedSeverities: Set<ValidationIssue.Severity> = [],
        focusedCategories: Set<BoxCategory> = [],
        showsStreamingIndicators: Bool = true
    ) {
        self.focusedSeverities = focusedSeverities
        self.focusedCategories = focusedCategories
        self.showsStreamingIndicators = showsStreamingIndicators
    }

    static let all = ParseTreeOutlineFilter()

    var isFocused: Bool {
        !focusedSeverities.isEmpty || !focusedCategories.isEmpty || !showsStreamingIndicators
    }

    func matches(node: ParseTreeNode) -> Bool {
        if !focusedSeverities.isEmpty {
            let hasMatchingSeverity = node.validationIssues.contains { focusedSeverities.contains($0.severity) }
            if !hasMatchingSeverity {
                return false
            }
        }
        if !focusedCategories.isEmpty {
            if !focusedCategories.contains(node.category) {
                return false
            }
        }
        if !showsStreamingIndicators && node.isStreamingIndicator {
            return false
        }
        return true
    }
}
#endif
