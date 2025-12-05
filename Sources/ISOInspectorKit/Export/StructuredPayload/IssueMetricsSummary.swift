import Foundation

extension StructuredPayload {
    struct IssueMetricsSummary: Encodable {
        let errorCount: Int
        let warningCount: Int
        let infoCount: Int
        let deepestAffectedDepth: Int

        var totalCount: Int { errorCount + warningCount + infoCount }

        init(tree: ParseTree) {
            var counter = IssueMetricsCounter()
            counter.accumulate(nodes: tree.nodes, depth: 0)
            self.errorCount = counter.errorCount
            self.warningCount = counter.warningCount
            self.infoCount = counter.infoCount
            self.deepestAffectedDepth = counter.deepestDepth
        }

        private enum CodingKeys: String, CodingKey {
            case errorCount = "error_count"
            case warningCount = "warning_count"
            case infoCount = "info_count"
            case deepestAffectedDepth = "deepest_affected_depth"
        }

        private struct IssueMetricsCounter {
            var errorCount: Int = 0
            var warningCount: Int = 0
            var infoCount: Int = 0
            var deepestDepth: Int = 0

            private var trackedIssues: [IssueIdentifier: Int] = [:]

            mutating func accumulate(nodes: [ParseTreeNode], depth: Int) {
                for node in nodes {
                    if !node.issues.isEmpty {
                        for issue in node.issues {
                            let identifier = IssueIdentifier(issue: issue)
                            let previousDepth = trackedIssues[identifier]
                            if previousDepth == nil {
                                switch issue.severity {
                                case .error: errorCount += 1
                                case .warning: warningCount += 1
                                case .info: infoCount += 1
                                }
                            }
                            let resolvedDepth = max(previousDepth ?? depth, depth)
                            trackedIssues[identifier] = resolvedDepth
                            deepestDepth = max(deepestDepth, resolvedDepth)
                        }
                    }
                    accumulate(nodes: node.children, depth: depth + 1)
                }
            }

            private struct IssueIdentifier: Hashable {
                let severity: String
                let code: String
                let message: String
                let byteRangeLowerBound: Int64?
                let byteRangeUpperBound: Int64?
                let affectedNodeIDs: [Int64]

                init(issue: ParseIssue) {
                    self.severity = issue.severity.rawValue
                    self.code = issue.code
                    self.message = issue.message
                    self.byteRangeLowerBound = issue.byteRange?.lowerBound
                    self.byteRangeUpperBound = issue.byteRange?.upperBound
                    self.affectedNodeIDs = issue.affectedNodeIDs
                }
            }
        }
    }
}
