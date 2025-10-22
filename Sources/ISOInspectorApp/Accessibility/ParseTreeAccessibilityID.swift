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
                ParseTreeAccessibilityID.path("severity", severity.rawValue)
            }

            static func categoryToggle(_ category: BoxCategory) -> String {
                ParseTreeAccessibilityID.path("category", category.rawValue)
            }

            static let streamingToggle = "streaming"
            static let clearButton = "clear"
        }

        enum List {
            static let root = "list"
            static let emptyState = "empty"

            static func row(_ nodeID: ParseTreeNode.ID) -> String {
                ParseTreeAccessibilityID.path("row", String(describing: nodeID))
            }

            static func rowBookmark(_ nodeID: ParseTreeNode.ID) -> String {
                ParseTreeAccessibilityID.path("row", String(describing: nodeID), "bookmark")
            }
        }
    }

    enum Detail {
        static let root = "detail"
        static let metadata = "metadata"
        static let encryption = "encryption"
        static let notes = "notes"
        static let fieldAnnotations = "fieldAnnotations"
        static let validation = "validation"
        static let hexView = "hexView"
        static let bookmarkButton = "bookmarkButton"

        enum Notes {
            static func row(_ annotationID: UUID) -> String {
                ParseTreeAccessibilityID.path("row", annotationID.uuidString.lowercased())
            }

            enum Controls {
                static let root = "controls"
                static let edit = "edit"
                static let save = "save"
                static let cancel = "cancel"
                static let delete = "delete"
            }
        }
    }

    static func path(_ components: String...) -> String {
        components.joined(separator: ".")
    }
}
#endif
