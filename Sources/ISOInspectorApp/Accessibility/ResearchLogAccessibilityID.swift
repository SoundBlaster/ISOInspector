#if canImport(Combine)
import Foundation

enum ResearchLogAccessibilityID {
    static let root = "researchLogPreview"

    enum Header {
        static let root = "header"
        static let title = "title"

        enum Status {
            static let ready = "status.ready"
            static let missingFixture = "status.missingFixture"
            static let schemaMismatch = "status.schemaMismatch"
            static let loadFailure = "status.loadFailure"
        }

        enum Metadata {
            static let root = "metadata"
            static let schemaVersion = "schemaVersion"
            static let entryCount = "entryCount"
            static let fieldNames = "fieldNames"
        }

        enum SchemaMismatch {
            static let expected = "schemaMismatch.expected"
            static let actual = "schemaMismatch.actual"
        }

        enum MissingFixture {
            static let details = "missingFixture.details"
        }

        enum LoadFailure {
            static let message = "loadFailure.message"
        }
    }

    enum Diagnostics {
        static let root = "diagnostics"

        static func row(_ index: Int) -> String {
            "row.\(index)"
        }
    }

    static func path(_ components: String...) -> String {
        components.joined(separator: ".")
    }
}
#endif
