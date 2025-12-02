#if canImport(Combine)
    import Foundation
    import ISOInspectorKit

    struct ParseTreeOutlineFilter: Equatable {
        var focusedSeverities: Set<ValidationIssue.Severity>
        var focusedCategories: Set<BoxCategory>
        var showsStreamingIndicators: Bool
        var showsOnlyIssues: Bool

        init(
            focusedSeverities: Set<ValidationIssue.Severity> = [],
            focusedCategories: Set<BoxCategory> = [], showsStreamingIndicators: Bool = true,
            showsOnlyIssues: Bool = false
        ) {
            self.focusedSeverities = focusedSeverities
            self.focusedCategories = focusedCategories
            self.showsStreamingIndicators = showsStreamingIndicators
            self.showsOnlyIssues = showsOnlyIssues
        }

        static let all = ParseTreeOutlineFilter()

        var isFocused: Bool {
            !focusedSeverities.isEmpty || !focusedCategories.isEmpty || !showsStreamingIndicators
                || showsOnlyIssues
        }

        func matches(node: ParseTreeNode) -> Bool {
            if !focusedSeverities.isEmpty {
                let hasMatchingValidationSeverity = node.validationIssues.contains {
                    focusedSeverities.contains($0.severity)
                }
                let hasMatchingParseSeverity = node.issues.contains { issue in
                    switch issue.severity {
                    case .error: return focusedSeverities.contains(.error)
                    case .warning: return focusedSeverities.contains(.warning)
                    case .info: return focusedSeverities.contains(.info)
                    }
                }
                if !(hasMatchingValidationSeverity || hasMatchingParseSeverity) { return false }
            }
            if !focusedCategories.isEmpty {
                if !focusedCategories.contains(node.category) { return false }
            }
            if !showsStreamingIndicators && node.isStreamingIndicator { return false }
            if showsOnlyIssues {
                let hasParseIssues = !node.issues.isEmpty
                let hasValidationIssues = !node.validationIssues.isEmpty
                if !(hasParseIssues || hasValidationIssues) { return false }
            }
            return true
        }
    }
#endif
