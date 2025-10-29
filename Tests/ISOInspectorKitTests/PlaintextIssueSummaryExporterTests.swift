import Foundation
import XCTest
@testable import ISOInspectorKit

final class PlaintextIssueSummaryExporterTests: XCTestCase {
    func testExporterIncludesMetadataAndGroupedIssues() throws {
        let root = try makeNode(type: "moov", offset: 0, size: 128)
        let child = try makeNode(type: "trak", offset: 32, size: 64)
        let grandChild = try makeNode(type: "mdia", offset: 48, size: 32)

        let issues = [
            ParseIssue(
                severity: .error,
                code: "VR-001",
                message: "Truncated box",
                byteRange: 48..<60,
                affectedNodeIDs: [grandChild.header.startOffset]
            ),
            ParseIssue(
                severity: .warning,
                code: "VR-010",
                message: "Unexpected padding",
                byteRange: 32..<40,
                affectedNodeIDs: [child.header.startOffset]
            ),
        ]

        let tree = ParseTree(
            nodes: [
                BoxNode(
                    header: root.header,
                    metadata: nil,
                    payload: nil,
                    validationIssues: [],
                    issues: [issues[0], issues[1]],
                    status: .corrupt,
                    children: [
                        BoxNode(
                            header: child.header,
                            metadata: nil,
                            payload: nil,
                            validationIssues: [],
                            issues: [issues[1]],
                            status: .corrupt,
                            children: [
                                BoxNode(
                                    header: grandChild.header,
                                    metadata: nil,
                                    payload: nil,
                                    validationIssues: [],
                                    issues: [issues[0]],
                                    status: .corrupt,
                                    children: []
                                ),
                            ]
                        ),
                    ]
                ),
            ]
        )

        let metadata = PlaintextIssueSummaryExporter.Metadata(
            filePath: "/tmp/sample.mp4",
            fileSize: 1024,
            analyzedAt: Date(timeIntervalSince1970: 0),
            sha256: nil
        )

        let summary = ParseIssueStore.IssueSummary(
            metrics: .init(errorCount: 1, warningCount: 1, infoCount: 0, deepestAffectedDepth: 3),
            totalCount: issues.count
        )

        let exporter = PlaintextIssueSummaryExporter()
        let data = try exporter.export(
            tree: tree,
            metadata: metadata,
            summary: summary,
            issues: issues
        )

        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("File: sample.mp4"))
        XCTAssertTrue(text.contains("Path: /tmp/sample.mp4"))
        XCTAssertTrue(text.contains("Size: 1024 bytes"))
        XCTAssertTrue(text.contains("Analyzed: 1970-01-01T00:00:00Z"))
        XCTAssertTrue(text.contains("SHA256: (pending)"))
        XCTAssertTrue(text.contains("Total Issues: 2"))
        XCTAssertTrue(text.contains("ERRORS (1)"))
        XCTAssertTrue(text.contains("WARNINGS (1)"))
        XCTAssertTrue(text.contains("VR-001 — Truncated box"))
        XCTAssertTrue(text.contains("Node Path: moov@0 > trak@32 > mdia@48"))
        XCTAssertTrue(text.contains("Byte Range: 48-60"))
        XCTAssertTrue(text.contains("VR-010 — Unexpected padding"))
        XCTAssertTrue(text.contains("Node Path: moov@0 > trak@32"))
        XCTAssertTrue(text.contains("Byte Range: 32-40"))
    }

    func testExporterHandlesNoIssues() throws {
        let root = try makeNode(type: "ftyp", offset: 0, size: 24)
        let tree = ParseTree(nodes: [root])
        let metadata = PlaintextIssueSummaryExporter.Metadata(
            filePath: "/tmp/clean.mp4",
            fileSize: 2048,
            analyzedAt: Date(timeIntervalSince1970: 1_000),
            sha256: "abc123"
        )
        let summary = ParseIssueStore.IssueSummary(metrics: .init(), totalCount: 0)
        let exporter = PlaintextIssueSummaryExporter()
        let data = try exporter.export(
            tree: tree,
            metadata: metadata,
            summary: summary,
            issues: []
        )

        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("Total Issues: 0"))
        XCTAssertTrue(text.contains("No issues recorded."))
        XCTAssertFalse(text.contains("ERRORS"))
        XCTAssertTrue(text.contains("SHA256: abc123"))
    }

    private func makeNode(type: String, offset: Int64, size: Int64) throws -> BoxNode {
        let header = try makeHeader(type: type, size: size, offset: offset)
        return BoxNode(header: header)
    }

    private func makeHeader(type: String, size: Int64, offset: Int64) throws -> BoxHeader {
        let fourCC = try IIFourCharCode(type)
        return BoxHeader(
            type: fourCC,
            totalSize: size,
            headerSize: 8,
            payloadRange: (offset + 8)..<(offset + size),
            range: offset..<(offset + size),
            uuid: nil
        )
    }
}
