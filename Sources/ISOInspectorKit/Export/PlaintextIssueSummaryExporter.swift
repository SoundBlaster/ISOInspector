import Foundation

public struct PlaintextIssueSummaryExporter {
    public struct Metadata: Equatable, Sendable {
        public var filePath: String
        public var fileSize: Int64?
        public var analyzedAt: Date
        public var sha256: String?

        public init(filePath: String, fileSize: Int64?, analyzedAt: Date, sha256: String?) {
            self.filePath = filePath
            self.fileSize = fileSize
            self.analyzedAt = analyzedAt
            self.sha256 = sha256
        }
    }

    private let dateFormatter: ISO8601DateFormatter

    public init(dateFormatter: ISO8601DateFormatter? = nil) {
        if let dateFormatter {
            self.dateFormatter = dateFormatter
        } else {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.formatOptions = [.withInternetDateTime]
            self.dateFormatter = formatter
        }
    }

    public func export(
        tree: ParseTree, metadata: Metadata, summary: ParseIssueStore.IssueSummary,
        issues: [ParseIssue]
    ) throws -> Data {
        var lines: [String] = []
        lines.append("ISOInspector Issue Summary")
        lines.append(String(repeating: "=", count: "ISOInspector Issue Summary".count))
        lines.append("")

        let fileURL = URL(fileURLWithPath: metadata.filePath)
        let fileName =
            fileURL.lastPathComponent.isEmpty ? metadata.filePath : fileURL.lastPathComponent
        lines.append("File: \(fileName)")
        lines.append("Path: \(metadata.filePath)")
        if let size = metadata.fileSize {
            lines.append("Size: \(size) bytes")
        } else {
            lines.append("Size: unknown")
        }
        lines.append("Analyzed: \(dateFormatter.string(from: metadata.analyzedAt))")
        if let hash = metadata.sha256, !hash.isEmpty {
            lines.append("SHA256: \(hash)")
        } else {
            lines.append("SHA256: (pending)")
        }
        lines.append("")

        lines.append("Totals:")
        for severity in severityOrder {
            let label = severityLabel(for: severity)
            lines.append("- \(label): \(summary.count(for: severity))")
        }
        lines.append("- Total Issues: \(summary.totalCount)")
        if summary.deepestAffectedDepth > 0 {
            lines.append("- Deepest Affected Depth: \(summary.deepestAffectedDepth)")
        }
        lines.append("")

        if issues.isEmpty {
            lines.append("No issues recorded.")
        } else {
            let nodePaths = makeNodePathIndex(from: tree.nodes)
            let grouped = Dictionary(grouping: issues, by: { $0.severity })
            for severity in severityOrder {
                guard let bucket = grouped[severity], !bucket.isEmpty else { continue }
                let header = "\(sectionTitle(for: severity)) (\(bucket.count))"
                lines.append(header)
                lines.append(String(repeating: "-", count: header.count))

                for issue in sortIssues(bucket) {
                    lines.append(formatHeadline(for: issue))
                    lines.append("  Severity: \(issue.severity.rawValue)")
                    lines.append("  Byte Range: \(format(range: issue.byteRange))")
                    let paths = issue.affectedNodeIDs.compactMap { nodePaths[$0] }
                    if paths.isEmpty {
                        lines.append("  Node Path: unavailable")
                    } else {
                        lines.append("  Node Path: \(paths.joined(separator: ", "))")
                    }
                    lines.append("")
                }
            }
            if lines.last == "" { _ = lines.popLast() }
        }

        let joined = lines.joined(separator: "\n") + "\n"
        return Data(joined.utf8)
    }

    private var severityOrder: [ParseIssue.Severity] { [.error, .warning, .info] }

    private func severityLabel(for severity: ParseIssue.Severity) -> String {
        switch severity {
        case .error: return "Errors"
        case .warning: return "Warnings"
        case .info: return "Info"
        }
    }

    private func sectionTitle(for severity: ParseIssue.Severity) -> String {
        switch severity {
        case .error: return "ERRORS"
        case .warning: return "WARNINGS"
        case .info: return "INFO"
        }
    }

    private func makeNodePathIndex(from nodes: [ParseTreeNode]) -> [Int64: String] {
        var index: [Int64: String] = [:]
        func traverse(_ current: [String], nodes: [ParseTreeNode]) {
            for node in nodes {
                let component = "\(node.header.type.description)@\(node.header.startOffset)"
                let path: [String]
                if current.isEmpty { path = [component] } else { path = current + [component] }
                index[node.id] = path.joined(separator: " > ")
                if !node.children.isEmpty { traverse(path, nodes: node.children) }
            }
        }
        traverse([], nodes: nodes)
        return index
    }

    private func formatHeadline(for issue: ParseIssue) -> String {
        let code = issue.code.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = issue.message.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (code.isEmpty, message.isEmpty) {
        case (true, true): return "• Issue"
        case (true, false): return "• \(message)"
        case (false, true): return "• \(code)"
        case (false, false): return "• \(code) — \(message)"
        }
    }

    private func format(range: Range<Int64>?) -> String {
        guard let range else { return "unavailable" }
        return "\(range.lowerBound)-\(range.upperBound)"
    }

    private func sortIssues(_ issues: [ParseIssue]) -> [ParseIssue] {
        issues.sorted { lhs, rhs in
            let lhsLower = lhs.byteRange?.lowerBound ?? .max
            let rhsLower = rhs.byteRange?.lowerBound ?? .max
            if lhsLower != rhsLower { return lhsLower < rhsLower }
            let lhsCode = lhs.code
            let rhsCode = rhs.code
            if lhsCode != rhsCode { return lhsCode < rhsCode }
            let lhsMessage = lhs.message
            let rhsMessage = rhs.message
            if lhsMessage != rhsMessage { return lhsMessage < rhsMessage }
            let lhsIDs = lhs.affectedNodeIDs
            let rhsIDs = rhs.affectedNodeIDs
            return lhsIDs.lexicographicallyPrecedes(rhsIDs)
        }
    }
}
