import Foundation
import XCTest
@testable import ISOInspectorKit

final class ParseExportTests: XCTestCase {
    func testBuilderConstructsTreeWithMetadataAndChildren() throws {
        let header = try makeHeader(type: "ftyp", size: 32)
        let childHeader = try makeHeader(type: "moov", size: 24, offset: 32)
        let metadata = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil),
            name: "File Type",
            summary: "File type and compatibility",
            category: "File",
            specification: "ISO",
            version: 1,
            flags: 0
        )
        let issue = ValidationIssue(ruleID: "VR-001", message: "Test", severity: .error)

        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: metadata,
                validationIssues: [issue]
            )
        )
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: childHeader, depth: 1),
                offset: childHeader.startOffset
            )
        )
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: childHeader, depth: 1),
                offset: childHeader.endOffset
            )
        )
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset
            )
        )

        let tree = builder.makeTree()
        XCTAssertEqual(tree.validationIssues, [issue])
        XCTAssertEqual(tree.nodes.count, 1)
        let root = try XCTUnwrap(tree.nodes.first)
        XCTAssertEqual(root.header, header)
        XCTAssertEqual(root.metadata, metadata)
        XCTAssertEqual(root.validationIssues, [issue])
        XCTAssertEqual(root.children.count, 1)
        let child = try XCTUnwrap(root.children.first)
        XCTAssertEqual(child.header, childHeader)
        XCTAssertNil(child.metadata)
        XCTAssertTrue(child.validationIssues.isEmpty)
        XCTAssertTrue(child.children.isEmpty)
    }

    func testJSONExporterProducesDeterministicStructure() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: BoxCatalog.shared.descriptor(for: header)
            )
        )
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset
            )
        )

        let tree = builder.makeTree()
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 1)
        let node = try XCTUnwrap(nodes.first)
        XCTAssertEqual(node["fourcc"] as? String, "ftyp")
        let offsets = try XCTUnwrap(node["offsets"] as? [String: Any])
        XCTAssertEqual(offsets["start"] as? Int, 0)
        XCTAssertEqual(offsets["end"] as? Int, Int(header.endOffset))
        let sizes = try XCTUnwrap(node["sizes"] as? [String: Any])
        XCTAssertEqual(sizes["total"] as? Int, Int(header.totalSize))
        XCTAssertEqual(sizes["header"] as? Int, Int(header.headerSize))
        let metadata = try XCTUnwrap(node["metadata"] as? [String: Any])
        XCTAssertEqual(metadata["name"] as? String, "File Type And Compatibility")
        let issues = try XCTUnwrap(json["validationIssues"] as? [[String: Any]])
        XCTAssertTrue(issues.isEmpty)
    }

    func testBinaryCaptureRoundTripPreservesEvents() throws {
        let header = try makeHeader(type: "trak", size: 40)
        let metadata = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil),
            name: "Track Box",
            summary: "Track container",
            category: nil,
            specification: nil,
            version: nil,
            flags: nil
        )
        let issue = ValidationIssue(ruleID: "VR-002", message: "Mismatch", severity: .warning)
        let events = [
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: metadata,
                validationIssues: [issue]
            ),
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset,
                metadata: metadata,
                validationIssues: []
            )
        ]

        let encoded = try ParseEventCaptureEncoder().encode(events: events)
        let decoded = try ParseEventCaptureDecoder().decode(data: encoded)
        XCTAssertEqual(decoded, events)
    }

    private func makeHeader(type: String, size: Int64, offset: Int64 = 0) throws -> BoxHeader {
        let fourcc = try FourCharCode(type)
        return BoxHeader(
            type: fourcc,
            totalSize: size,
            headerSize: 8,
            payloadRange: (offset + 8)..<(offset + size),
            range: offset..<(offset + size),
            uuid: nil
        )
    }
}
