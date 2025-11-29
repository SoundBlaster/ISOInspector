import Foundation

extension StructuredPayload {
    struct Metadata: Encodable {
        let name: String
        let summary: String
        let category: String?
        let specification: String?
        let version: Int?
        let flags: UInt32?

        init(descriptor: BoxDescriptor) {
            self.name = descriptor.name
            self.summary = descriptor.summary
            self.category = descriptor.category
            self.specification = descriptor.specification
            self.version = descriptor.version
            self.flags = descriptor.flags
        }
    }
}
