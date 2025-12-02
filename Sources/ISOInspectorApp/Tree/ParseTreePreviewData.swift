#if canImport(Combine)
    import Foundation
    import ISOInspectorKit

    enum ParseTreePreviewData {
        @MainActor static let sampleSnapshot: ParseTreeSnapshot = {
            let ftyp = makeNode(type: "ftyp", start: 0)
            let moov = makeNode(
                type: "moov", start: 200,
                issues: [
                    ValidationIssue(ruleID: "VR-INFO", message: "Movie metadata", severity: .info)
                ],
                children: [
                    makeNode(
                        type: "trak", start: 400,
                        issues: [
                            ValidationIssue(
                                ruleID: "VR-TRAK", message: "Track missing language",
                                severity: .warning)
                        ],
                        children: [
                            makeNode(
                                type: "mdia", start: 600,
                                children: [
                                    makeNode(
                                        type: "minf", start: 800,
                                        children: [
                                            makeNode(
                                                type: "stbl", start: 1000,
                                                issues: [
                                                    ValidationIssue(
                                                        ruleID: "VR-STBL", message: "Index error",
                                                        severity: .error)
                                                ])
                                        ])
                                ])
                        ]), makeNode(type: "mvex", start: 1200),
                ])
            let mdat = makeNode(type: "mdat", start: 1600)
            let free = makeNode(type: "free", start: 2000)
            let nodes = [ftyp, moov, mdat, free]
            let issues = nodes.flatMap { collectIssues(from: $0) }
            return ParseTreeSnapshot(nodes: nodes, validationIssues: issues, lastUpdatedAt: Date())
        }()

        private static func makeNode(
            type: String, start: Int64, issues: [ValidationIssue] = [],
            children: [ParseTreeNode] = []
        ) -> ParseTreeNode {
            let header = makeHeader(type: type, start: start, size: 180)
            let metadata = BoxCatalog.shared.descriptor(for: header)
            let parseIssues = issues.map { issue -> ParseIssue in
                ParseIssue(
                    severity: ParseIssue.Severity(validationSeverity: issue.severity),
                    code: issue.ruleID, message: issue.message, byteRange: header.range,
                    affectedNodeIDs: [header.startOffset])
            }
            return ParseTreeNode(
                header: header, metadata: metadata, payload: nil, validationIssues: issues,
                issues: parseIssues, children: children)
        }

        private static func makeHeader(type: String, start: Int64, size: Int64) -> BoxHeader {
            let fourCC = try! FourCharCode(type)
            let headerSize: Int64 = 8
            let payload = (start + headerSize)..<(start + size)
            return BoxHeader(
                type: fourCC, totalSize: size, headerSize: headerSize, payloadRange: payload,
                range: start..<(start + size), uuid: nil)
        }

        private static func collectIssues(from node: ParseTreeNode) -> [ValidationIssue] {
            node.validationIssues + node.children.flatMap(collectIssues)
        }
    }

#endif
