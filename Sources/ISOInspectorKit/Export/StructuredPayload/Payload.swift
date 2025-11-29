import Foundation

extension StructuredPayload {
    struct Payload: Encodable {
        let schema: SchemaDescriptor?
        let nodes: [Node]
        let validationIssues: [Issue]
        let validation: ValidationMetadataPayload?
        let format: FormatSummary?
        let issueMetrics: IssueMetricsSummary

        init(tree: ParseTree) {
            self.nodes = tree.nodes.map(Node.init)
            self.validationIssues = tree.validationIssues.map(Issue.init)
            if let metadata = tree.validationMetadata {
                self.validation = ValidationMetadataPayload(metadata: metadata)
            } else {
                self.validation = nil
            }
            self.format = FormatSummary(tree: tree)
            let metrics = IssueMetricsSummary(tree: tree)
            self.issueMetrics = metrics
            if metrics.totalCount > 0 {
                self.schema = .tolerantIssuesV2
            } else {
                self.schema = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case schema
            case nodes
            case validationIssues
            case validation
            case format
            case issueMetrics = "issue_metrics"
        }
    }
}
