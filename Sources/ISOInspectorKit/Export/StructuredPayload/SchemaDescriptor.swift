import Foundation

extension StructuredPayload {
    struct SchemaDescriptor: Encodable {
        let version: Int

        static let tolerantIssuesV2 = SchemaDescriptor(version: 2)
    }
}
