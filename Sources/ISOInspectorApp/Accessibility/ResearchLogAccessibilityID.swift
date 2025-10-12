#if canImport(Combine)
import Foundation

enum ResearchLogAccessibilityID {
    static let root = "researchLogPreview"

    enum Header {
        static let root = "header"
        static let title = "title"

        enum Status {
            static let root = "status"
            static let ready = "ready"
            static let missingFixture = "missingFixture"
            static let schemaMismatch = "schemaMismatch"
            static let loadFailure = "loadFailure"
        }

        enum Metadata {
            static let root = "metadata"
            static let schemaVersion = "schemaVersion"
            static let entryCount = "entryCount"
            static let fieldNames = "fieldNames"
        }

        enum SchemaMismatch {
            static let expected = "expected"
            static let actual = "actual"
        }

        enum MissingFixture {
            static let details = "details"
        }

        enum LoadFailure {
            static let message = "message"
        }
    }

    enum Diagnostics {
        static let root = "diagnostics"

        static func row(_ index: Int) -> String {
            ResearchLogAccessibilityID.path("row", String(index))
        }
    }

    static func path(_ components: String...) -> String {
        components.joined(separator: ".")
    }
}
#endif
