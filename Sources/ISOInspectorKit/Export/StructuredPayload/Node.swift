import Foundation

extension StructuredPayload {
    struct Node: Encodable {
        let fourcc: String
        let uuid: UUID?
        let offsets: Offsets
        let sizes: Sizes
        let metadata: Metadata?
        let payload: [PayloadField]?
        let structured: StructuredPayload?
        let validationIssues: [Issue]
        let status: String
        let issues: [ParseIssuePayload]
        let children: [Node]
        let compatibilityName: String
        let compatibilityHeaderSize: Int
        let compatibilityTotalSize: Int

        init(node: ParseTreeNode) {
            self.fourcc = node.header.type.rawValue
            self.uuid = node.header.uuid
            self.offsets = Offsets(header: node.header)
            self.sizes = Sizes(header: node.header)
            self.metadata = node.metadata.map(Metadata.init)
            if let payload = node.payload {
                let fields = payload.fields.map(PayloadField.init)
                self.payload = fields.isEmpty ? nil : fields
                self.structured = payload.detail.map(StructuredPayload.init)
            } else {
                self.payload = nil
                self.structured = nil
            }
            self.validationIssues = node.validationIssues.map(Issue.init)
            self.status = node.status.rawValue
            self.issues = node.issues.map(ParseIssuePayload.init)
            self.children = node.children.map(Node.init)
            self.compatibilityName = node.header.type.rawValue
            self.compatibilityHeaderSize = Int(clamping: node.header.headerSize)
            self.compatibilityTotalSize = Int(clamping: node.header.totalSize)
        }

        private enum CodingKeys: String, CodingKey {
            case fourcc
            case uuid
            case offsets
            case sizes
            case metadata
            case payload
            case structured
            case validationIssues
            case status
            case issues
            case children
            case compatibilityName = "name"
            case compatibilityHeaderSize = "header_size"
            case compatibilityTotalSize = "size"
        }
    }
}
