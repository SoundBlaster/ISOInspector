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

        let parsedPayload = ParsedBoxPayload(fields: [
            ParsedBoxPayload.Field(
                name: "major_brand",
                value: "isom",
                description: "Primary brand identifying the file",
                byteRange: 8..<12
            )
        ])

        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: metadata,
                payload: parsedPayload,
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
        XCTAssertEqual(root.payload, parsedPayload)
        XCTAssertEqual(root.validationIssues, [issue])
        XCTAssertEqual(root.children.count, 1)
        let child = try XCTUnwrap(root.children.first)
        XCTAssertEqual(child.header, childHeader)
        XCTAssertNil(child.metadata)
        XCTAssertNil(child.payload)
        XCTAssertTrue(child.validationIssues.isEmpty)
        XCTAssertTrue(child.children.isEmpty)
    }

    func testJSONExporterProducesDeterministicStructure() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        var builder = ParseTreeBuilder()
        let payload = try ParsedBoxPayload(
            fields: [
                ParsedBoxPayload.Field(
                    name: "major_brand",
                    value: "isom",
                    description: nil,
                    byteRange: 8..<12
                )
            ],
            detail: .fileType(
                ParsedBoxPayload.FileTypeBox(
                    majorBrand: FourCharCode("isom"),
                    minorVersion: 1,
                    compatibleBrands: []
                )
            )
        )
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: BoxCatalog.shared.descriptor(for: header),
                payload: payload
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
        let payloadFields = try XCTUnwrap(node["payload"] as? [[String: Any]])
        XCTAssertEqual(payloadFields.count, 1)
        let field = try XCTUnwrap(payloadFields.first)
        XCTAssertEqual(field["name"] as? String, "major_brand")
        XCTAssertEqual(field["value"] as? String, "isom")
        let range = try XCTUnwrap(field["byteRange"] as? [String: Any])
        XCTAssertEqual(range["start"] as? Int, 8)
        XCTAssertEqual(range["end"] as? Int, 12)
        let structured = try XCTUnwrap(node["structured"] as? [String: Any])
        let fileTypeDetail = try XCTUnwrap(structured["file_type"] as? [String: Any])
        XCTAssertEqual(fileTypeDetail["major_brand"] as? String, "isom")
        XCTAssertEqual(fileTypeDetail["minor_version"] as? Int, 1)
        let compatible = try XCTUnwrap(fileTypeDetail["compatible_brands"] as? [String])
        XCTAssertTrue(compatible.isEmpty)
        let issues = try XCTUnwrap(json["validationIssues"] as? [[String: Any]])
        XCTAssertTrue(issues.isEmpty)
    }

    func testJSONExporterIncludesValidationMetadata() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: nil,
                payload: nil,
                validationIssues: [
                    ValidationIssue(ruleID: "VR-006", message: "suppressed", severity: .info)
                ]
            )
        )
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset,
                validationIssues: [
                    ValidationIssue(ruleID: "VR-006", message: "suppressed", severity: .info)
                ]
            )
        )

        var tree = builder.makeTree()
        tree.validationMetadata = ValidationMetadata(
            activePresetID: "structural",
            disabledRuleIDs: ["VR-006"]
        )

        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let validation = try XCTUnwrap(json["validation"] as? [String: Any])
        XCTAssertEqual(validation["activePresetID"] as? String, "structural")
        let disabled = try XCTUnwrap(validation["disabledRules"] as? [String])
        XCTAssertEqual(disabled, ["VR-006"])
    }

    func testJSONExporterIncludesPaddingBoxes() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let freePayload = Data(count: 12)
        let free = makeBox(type: "free", payload: freePayload)
        let skip = makeBox(type: "skip", payload: Data())
        let moov = makeBox(type: "moov", payload: Data())
        let mdat = makeBox(type: "mdat", payload: Data(count: 4))
        let data = ftyp + free + moov + skip + mdat

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()
        var builder = ParseTreeBuilder()
        for try await event in pipeline.events(for: reader) {
            builder.consume(event)
        }

        let tree = builder.makeTree()
        let exporter = JSONParseTreeExporter()
        let jsonData = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: jsonData) as? [String: Any])

        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 5)
        XCTAssertEqual(nodes.compactMap { $0["fourcc"] as? String }, ["ftyp", "free", "moov", "skip", "mdat"])

        let freeNode = try XCTUnwrap(nodes.first(where: { $0["fourcc"] as? String == "free" }))
        let freeStructured = try XCTUnwrap(freeNode["structured"] as? [String: Any])
        let freePadding = try XCTUnwrap(freeStructured["padding"] as? [String: Any])
        XCTAssertEqual(freePadding["type"] as? String, "free")
        XCTAssertEqual(freePadding["headerStartOffset"] as? Int, 24)
        XCTAssertEqual(freePadding["headerEndOffset"] as? Int, 32)
        XCTAssertEqual(freePadding["payloadStartOffset"] as? Int, 32)
        XCTAssertEqual(freePadding["payloadEndOffset"] as? Int, 44)
        XCTAssertEqual(freePadding["payloadLength"] as? Int, freePayload.count)
        XCTAssertEqual(freePadding["totalSize"] as? Int, 20)

        let skipNode = try XCTUnwrap(nodes.first(where: { $0["fourcc"] as? String == "skip" }))
        let skipStructured = try XCTUnwrap(skipNode["structured"] as? [String: Any])
        let skipPadding = try XCTUnwrap(skipStructured["padding"] as? [String: Any])
        XCTAssertEqual(skipPadding["type"] as? String, "skip")
        XCTAssertEqual(skipPadding["headerStartOffset"] as? Int, 52)
        XCTAssertEqual(skipPadding["headerEndOffset"] as? Int, 60)
        XCTAssertEqual(skipPadding["payloadStartOffset"] as? Int, 60)
        XCTAssertEqual(skipPadding["payloadEndOffset"] as? Int, 60)
        XCTAssertEqual(skipPadding["payloadLength"] as? Int, 0)
        XCTAssertEqual(skipPadding["totalSize"] as? Int, 8)

        let validationIssues = try XCTUnwrap(json["validationIssues"] as? [[String: Any]])
        XCTAssertTrue(validationIssues.isEmpty, "Validation issues present: \(validationIssues)")
    }

    func testJSONExporterIncludesRandomAccessDetails() throws {
        let tfraHeader = try makeHeader(type: "tfra", size: 32, offset: 16)
        let mfraHeader = try makeHeader(type: "mfra", size: 48, offset: 0)

        let entry = ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry(
            index: 1,
            time: 12_000,
            moofOffset: 0,
            trafNumber: 1,
            trunNumber: 1,
            sampleNumber: 2,
            fragmentSequenceNumber: 9,
            trackID: 1,
            sampleDescriptionIndex: 1,
            runIndex: 0,
            firstSampleGlobalIndex: 1,
            resolvedDecodeTime: 12_000,
            resolvedPresentationTime: 12_000,
            resolvedDataOffset: 5_360,
            resolvedSampleSize: 1_500,
            resolvedSampleFlags: nil
        )

        let tfraDetail = ParsedBoxPayload.TrackFragmentRandomAccessBox(
            version: 1,
            flags: 0,
            trackID: 1,
            trafNumberLength: 4,
            trunNumberLength: 4,
            sampleNumberLength: 4,
            entryCount: 1,
            entries: [entry]
        )

        let mfraDetail = ParsedBoxPayload.MovieFragmentRandomAccessBox(
            tracks: [
                ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary(
                    trackID: 1,
                    entryCount: 1,
                    earliestTime: 12_000,
                    latestTime: 12_000,
                    referencedFragmentSequenceNumbers: [9]
                )
            ],
            totalEntryCount: 1,
            offset: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox(mfraSize: 128)
        )

        let tfraNode = ParseTreeNode(
            header: tfraHeader,
            payload: ParsedBoxPayload(detail: .trackFragmentRandomAccess(tfraDetail))
        )

        let mfraNode = ParseTreeNode(
            header: mfraHeader,
            payload: ParsedBoxPayload(detail: .movieFragmentRandomAccess(mfraDetail)),
            children: [tfraNode]
        )

        let tree = ParseTree(nodes: [mfraNode])
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 1)
        let root = try XCTUnwrap(nodes.first)
        XCTAssertEqual(root["fourcc"] as? String, "mfra")
        let structured = try XCTUnwrap(root["structured"] as? [String: Any])
        let mfraJSON = try XCTUnwrap(structured["movie_fragment_random_access"] as? [String: Any])
        XCTAssertEqual(mfraJSON["total_entry_count"] as? Int, 1)
        XCTAssertEqual((mfraJSON["tracks"] as? [[String: Any]])?.count, 1)
        let trackJSON = try XCTUnwrap((mfraJSON["tracks"] as? [[String: Any]])?.first)
        XCTAssertEqual(trackJSON["track_ID"] as? Int, 1)
        XCTAssertEqual(trackJSON["entry_count"] as? Int, 1)
        XCTAssertEqual(trackJSON["earliest_time"] as? Int, 12_000)
        XCTAssertEqual(trackJSON["fragments"] as? [Int], [9])
        let offsetJSON = try XCTUnwrap(mfraJSON["offset"] as? [String: Any])
        XCTAssertEqual(offsetJSON["mfra_size"] as? Int, 128)

        let children = try XCTUnwrap(root["children"] as? [[String: Any]])
        XCTAssertEqual(children.count, 1)
        let tfraJSON = try XCTUnwrap(children.first)
        XCTAssertEqual(tfraJSON["fourcc"] as? String, "tfra")
        let tfraStructured = try XCTUnwrap(tfraJSON["structured"] as? [String: Any])
        let tableJSON = try XCTUnwrap(tfraStructured["track_fragment_random_access"] as? [String: Any])
        XCTAssertEqual(tableJSON["track_ID"] as? Int, 1)
        XCTAssertEqual(tableJSON["entry_count"] as? Int, 1)
        let entriesJSON = try XCTUnwrap(tableJSON["entries"] as? [[String: Any]])
        XCTAssertEqual(entriesJSON.count, 1)
        let entryJSON = try XCTUnwrap(entriesJSON.first)
        XCTAssertEqual(entryJSON["fragment_sequence_number"] as? Int, 9)
        XCTAssertEqual(entryJSON["traf_number"] as? Int, 1)
        XCTAssertEqual(entryJSON["trun_number"] as? Int, 1)
        XCTAssertEqual(entryJSON["sample_number"] as? Int, 2)
        XCTAssertEqual(entryJSON["resolved_decode_time"] as? Int, 12_000)
        XCTAssertEqual(entryJSON["resolved_data_offset"] as? Int, 5_360)
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
        let payload = ParsedBoxPayload(fields: [
            ParsedBoxPayload.Field(
                name: "dummy",
                value: "value",
                description: nil,
                byteRange: header.payloadRange
            )
        ])
        let events = [
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: metadata,
                payload: payload,
                validationIssues: [issue]
            ),
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset,
                metadata: metadata,
                payload: payload,
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

    private func makeBox(type: String, payload: Data) -> Data {
        precondition(type.utf8.count == 4, "Box type must be four characters")
        var data = Data()
        let size = UInt32(8 + payload.count).bigEndian
        withUnsafeBytes(of: size) { buffer in
            data.append(contentsOf: buffer)
        }
        data.append(contentsOf: type.utf8)
        data.append(payload)
        return data
    }
}
