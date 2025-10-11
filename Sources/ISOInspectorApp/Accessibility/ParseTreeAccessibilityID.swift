#if canImport(Combine)
import Foundation
import ISOInspectorKit

enum ParseTreeAccessibilityID {
    static let root = "parseTree"

    enum Header {
        static let root = "header"
        static let title = "header.title"
        static let subtitle = "header.subtitle"
        static let parseState = "header.parseState"
    }

    enum Outline {
        static let root = "outline"

        enum Filters {
            static let root = "filters"
            static let searchField = "filters.searchField"
            static func severityToggle(_ severity: ValidationIssue.Severity) -> String {
                "filters.severity.\(severity.rawValue)"
            }

            static func categoryToggle(_ category: BoxCategory) -> String {
                "filters.category.\(category.rawValue)"
            }

            static let streamingToggle = "filters.streaming"
            static let clearButton = "filters.clear"
        }

        enum List {
            static let root = "list"
            static let emptyState = "list.empty"

            static func row(_ nodeID: ParseTreeNode.ID) -> String {
                "list.row.\(nodeID)"
            }

            static func rowBookmark(_ nodeID: ParseTreeNode.ID) -> String {
                "list.row.\(nodeID).bookmark"
            }
        }
    }

    enum Detail {
        static let root = "detail"
        static let metadata = "detail.metadata"
        static let notes = "detail.notes"
        static let fieldAnnotations = "detail.fieldAnnotations"
        static let validation = "detail.validation"
        static let hexView = "detail.hexView"
        static let bookmarkButton = "detail.metadata.bookmark"
    }
}
#endif
