#if canImport(Combine)
import Foundation
import ISOInspectorKit

enum ParseTreeAccessibilityID {
    static let root = "parseTree"

    enum Header {
        static let root = "header"
        static let title = "title"
        static let subtitle = "subtitle"
        static let parseState = "parseState"
    }

    enum Outline {
        static let root = "outline"

        enum Filters {
            static let root = "filters"
            static let searchField = "searchField"
            static func severityToggle(_ severity: ValidationIssue.Severity) -> String {
                "severity.\(severity.rawValue)"
            }

            static func categoryToggle(_ category: BoxCategory) -> String {
                "category.\(category.rawValue)"
            }

            static let streamingToggle = "streaming"
            static let clearButton = "clear"
        }

        enum List {
            static let root = "list"
            static let emptyState = "empty"

            static func row(_ nodeID: ParseTreeNode.ID) -> String {
                "row.\(nodeID)"
            }

            static func rowBookmark(_ nodeID: ParseTreeNode.ID) -> String {
                "row.\(nodeID).bookmark"
            }
        }
    }

    enum Detail {
        static let root = "detail"
        static let metadata = "metadata"
        static let notes = "notes"
        static let fieldAnnotations = "fieldAnnotations"
        static let validation = "validation"
        static let hexView = "hexView"
        static let bookmarkButton = "bookmarkButton"
    }

    static func path(_ components: String...) -> String {
        components.joined(separator: ".")
    }
}
#endif
