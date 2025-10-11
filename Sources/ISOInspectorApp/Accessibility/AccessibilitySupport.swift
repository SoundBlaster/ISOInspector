#if canImport(Combine)
import Foundation
import ISOInspectorKit

struct AccessibilityDescriptor: Equatable {
    let label: String
    let value: String?
    let hint: String?
}

extension AccessibilityDescriptor {
    static func outlineRow(
        _ row: ParseTreeOutlineRow,
        isBookmarked: Bool
    ) -> AccessibilityDescriptor {
        var components: [String] = []

        if let displayName = row.node.metadata?.name, !displayName.isEmpty {
            components.append(displayName)
        } else {
            components.append(row.displayName)
        }

        components.append(row.typeDescription)

        if let summary = row.summary, !summary.isEmpty {
            components.append(summary)
        }

        if let severity = row.dominantSeverity {
            components.append(severity.accessibilityDescription)
        } else if row.hasValidationIssues {
            components.append("Additional validation notes available")
        }

        let childCount = row.node.children.count
        if childCount > 0 {
            let label = childCount == 1 ? "1 child" : "\(childCount) children"
            components.append(label)
        }

        if row.isSearchMatch {
            components.append("Matches current search")
        } else if row.hasMatchingDescendant {
            components.append("Contains matching descendant")
        }

        let label = components.joined(separator: ". ")
        let value = isBookmarked ? "Bookmarked" : nil
        let hint = "Press Return to expand or collapse. Press Space to toggle bookmark."

        return AccessibilityDescriptor(label: label, value: value, hint: hint)
    }
}

extension ParseTreeOutlineRow {
    func accessibilityDescriptor(isBookmarked: Bool) -> AccessibilityDescriptor {
        AccessibilityDescriptor.outlineRow(self, isBookmarked: isBookmarked)
    }
}

extension ParseTreeNodeDetail {
    var accessibilitySummary: String {
        var components: [String] = []
        components.append(header.type.description)
        if let name = metadata?.name, !name.isEmpty {
            components.append(name)
        }
        if let summary = metadata?.summary, !summary.isEmpty {
            components.append(summary)
        }

        let rangeDescription = "Range \(header.range.lowerBound) – \(header.range.upperBound)"
        let payloadDescription = "Payload \(header.payloadRange.lowerBound) – \(header.payloadRange.upperBound)"
        components.append(rangeDescription)
        components.append(payloadDescription)

        if let version = metadata?.version {
            components.append("Version \(version)")
        }
        if let flags = metadata?.flags {
            components.append("Flags 0x\(String(flags, radix: 16, uppercase: true))")
        }

        if validationIssues.isEmpty {
            components.append("No validation issues")
        } else {
            let issueSummaries = validationIssues.map { issue in
                "\(issue.severity.accessibilityDescription): \(issue.message)"
            }
            components.append(issueSummaries.joined(separator: ". "))
        }

        return components.joined(separator: ". ")
    }
}

extension ValidationIssue.Severity {
    var accessibilityDescription: String {
        switch self {
        case .info:
            return "Informational issue"
        case .warning:
            return "Warning issue"
        case .error:
            return "Error issue"
        }
    }
}
#endif
