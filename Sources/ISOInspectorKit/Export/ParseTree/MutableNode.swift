import Foundation

extension ParseTreeBuilder {
    final class MutableNode {
        let header: BoxHeader
        var metadata: BoxDescriptor?
        var payload: ParsedBoxPayload?
        var validationIssues: [ValidationIssue]
        var issues: [ParseIssue]
        var status: BoxNode.Status
        var children: [MutableNode]
        let depth: Int
        
        init(
            header: BoxHeader,
            metadata: BoxDescriptor?,
            payload: ParsedBoxPayload?,
            validationIssues: [ValidationIssue],
            depth: Int
        ) {
            self.header = header
            self.metadata = metadata
            self.payload = payload
            self.validationIssues = validationIssues
            self.issues = []
            self.status = .valid
            self.children = []
            self.depth = depth
        }
        
        func snapshot() -> ParseTreeNode {
            ParseTreeNode(
                header: header,
                metadata: metadata,
                payload: payload,
                validationIssues: validationIssues,
                issues: issues,
                status: status,
                children: children.map { $0.snapshot() }
            )
        }
    }
}
