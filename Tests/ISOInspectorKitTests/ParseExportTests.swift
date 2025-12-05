import Foundation
import XCTest

@testable import ISOInspectorKit

final class ParseExportTests: XCTestCase {
    func testBuilderConstructsTreeWithMetadataAndChildren() throws {
        let header = try makeHeader(type: "ftyp", size: 32)
        let childHeader = try makeHeader(type: "moov", size: 24, offset: 32)
        let metadata = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil), name: "File Type",
            summary: "File type and compatibility", category: "File", specification: "ISO",
            version: 1, flags: 0)
        let issue = ValidationIssue(ruleID: "VR-001", message: "Test", severity: .error)

        let parsedPayload = ParsedBoxPayload(fields: [
            ParsedBoxPayload.Field(
                name: "major_brand", value: "isom",
                description: "Primary brand identifying the file", byteRange: 8..<12)
        ])

        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: metadata, payload: parsedPayload, validationIssues: [issue]))
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: childHeader, depth: 1), offset: childHeader.startOffset)
        )
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: childHeader, depth: 1), offset: childHeader.endOffset))
        builder.consume(
            ParseEvent(kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset))

        let tree = builder.makeTree()
        XCTAssertEqual(tree.validationIssues, [issue])
        XCTAssertEqual(tree.nodes.count, 1)
        let root = try XCTUnwrap(tree.nodes.first)
        XCTAssertEqual(root.header, header)
        XCTAssertEqual(root.metadata, metadata)
        XCTAssertEqual(root.payload, parsedPayload)
        XCTAssertEqual(root.validationIssues, [issue])
        XCTAssertEqual(root.issues, [])
        XCTAssertEqual(root.status, .valid)
        XCTAssertEqual(root.children.count, 1)
        let child = try XCTUnwrap(root.children.first)
        XCTAssertEqual(child.header, childHeader)
        XCTAssertNil(child.metadata)
        XCTAssertNil(child.payload)
        XCTAssertTrue(child.validationIssues.isEmpty)
        XCTAssertEqual(child.issues, [])
        XCTAssertEqual(child.status, .valid)
        XCTAssertTrue(child.children.isEmpty)
    }

    func testJSONExporterProducesDeterministicStructure() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        var builder = ParseTreeBuilder()
        let payload = try ParsedBoxPayload(
            fields: [
                ParsedBoxPayload.Field(
                    name: "major_brand", value: "isom", description: nil, byteRange: 8..<12)
            ],
            detail: .fileType(
                ParsedBoxPayload.FileTypeBox(
                    majorBrand: FourCharCode("isom"), minorVersion: 1, compatibleBrands: [])))
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: BoxCatalog.shared.descriptor(for: header), payload: payload))
        builder.consume(
            ParseEvent(kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset))

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
        XCTAssertEqual(node["status"] as? String, "valid")
        let parseIssues = try XCTUnwrap(node["issues"] as? [[String: Any]])
        XCTAssertTrue(parseIssues.isEmpty)
    }

    func testJSONExporterIncludesStatusAndIssues() throws {
        var node = ParseTreeNode(
            header: try makeHeader(type: "mdat", size: 32), validationIssues: [],
            issues: [
                ParseIssue(
                    severity: .error, code: "corrupt_payload", message: "Media data truncated",
                    byteRange: 24..<32, affectedNodeIDs: [])
            ], status: .corrupt, children: [])
        node.metadata = BoxDescriptor(
            identifier: .init(type: node.header.type, extendedType: nil), name: "Media Data",
            summary: "Raw media payload", category: "Media", specification: nil, version: nil,
            flags: nil)
        let tree = ParseTree(nodes: [node])
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let nodes = try XCTUnwrap(root["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 1)
        let exported = try XCTUnwrap(nodes.first)
        XCTAssertEqual(exported["status"] as? String, "corrupt")
        let exportedIssues = try XCTUnwrap(exported["issues"] as? [[String: Any]])
        XCTAssertEqual(exportedIssues.count, 1)
        let exportedIssue = try XCTUnwrap(exportedIssues.first)
        XCTAssertEqual(exportedIssue["severity"] as? String, "error")
        XCTAssertEqual(exportedIssue["code"] as? String, "corrupt_payload")
        XCTAssertEqual(exportedIssue["message"] as? String, "Media data truncated")
        let byteRange = try XCTUnwrap(exportedIssue["byteRange"] as? [String: Any])
        XCTAssertEqual(byteRange["start"] as? Int, 24)
        XCTAssertEqual(byteRange["end"] as? Int, 32)
    }

    func testJSONExporterIncludesValidationMetadata() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: nil, payload: nil,
                validationIssues: [
                    ValidationIssue(ruleID: "VR-006", message: "suppressed", severity: .info)
                ]))
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset,
                validationIssues: [
                    ValidationIssue(ruleID: "VR-006", message: "suppressed", severity: .info)
                ]))

        var tree = builder.makeTree()
        tree.validationMetadata = ValidationMetadata(
            activePresetID: "structural", disabledRuleIDs: ["VR-006"])

        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let validation = try XCTUnwrap(json["validation"] as? [String: Any])
        XCTAssertEqual(validation["activePresetID"] as? String, "structural")
        let disabled = try XCTUnwrap(validation["disabledRules"] as? [String])
        XCTAssertEqual(disabled, ["VR-006"])
    }

    func testJSONExporterRedactsMetadataBinaryValues() throws {
        let header = try makeHeader(type: "ilst", size: 64)
        var builder = ParseTreeBuilder()
        let metadataItems = ParsedBoxPayload.MetadataItemListBox(
            handlerType: nil,
            entries: [
                .init(
                    identifier: .fourCC(raw: 0x636F_7672, display: "covr"), namespace: "mdta",
                    name: "Cover Art",
                    values: [
                        .init(
                            kind: .data(format: .png, data: Data([0x00, 0x01, 0x02, 0x03])),
                            rawType: 0x6461_7461, locale: 0),
                        .init(
                            kind: .bytes(Data([0xAA, 0xBB, 0xCC])), rawType: 0x6269_6E61, locale: 0),
                    ])
            ])
        let payload = ParsedBoxPayload(fields: [], detail: .metadataItemList(metadataItems))
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: BoxCatalog.shared.descriptor(for: header), payload: payload))
        builder.consume(
            ParseEvent(kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset))

        let tree = builder.makeTree()
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let nodes = try XCTUnwrap(root["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 1)
        let node = try XCTUnwrap(nodes.first)
        let structured = try XCTUnwrap(node["structured"] as? [String: Any])
        let metadataJSON = try XCTUnwrap(structured["metadata_items"] as? [String: Any])
        let entries = try XCTUnwrap(metadataJSON["entries"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 1)
        let entry = try XCTUnwrap(entries.first)
        let values = try XCTUnwrap(entry["values"] as? [[String: Any]])
        XCTAssertEqual(values.count, 2)

        let dataValue = values[0]
        XCTAssertEqual(dataValue["kind"] as? String, "data")
        XCTAssertEqual(dataValue["data_format"] as? String, "png")
        XCTAssertEqual(dataValue["byte_length"] as? Int, 4)
        XCTAssertNil(dataValue["bytes_base64"])
        XCTAssertFalse(dataValue.keys.contains("bytes_base64"))

        let bytesValue = values[1]
        XCTAssertEqual(bytesValue["kind"] as? String, "bytes")
        XCTAssertEqual(bytesValue["byte_length"] as? Int, 3)
        XCTAssertNil(bytesValue["bytes_base64"])
        XCTAssertFalse(bytesValue.keys.contains("bytes_base64"))
    }

    func testJSONExporterRedactsDataReferencePayload() throws {
        let header = try makeHeader(type: "dref", size: 48)
        var builder = ParseTreeBuilder()
        let payloadRangeStart = header.payloadRange.lowerBound
        let payloadRange = payloadRangeStart..<(payloadRangeStart + 2)
        let dataReference = ParsedBoxPayload.DataReferenceBox(
            version: 0, flags: 0, entryCount: 1,
            entries: [
                .init(
                    index: 1, type: try FourCharCode("url "), version: 0, flags: 0,
                    location: .data(Data([0xDE, 0xAD])), byteRange: header.payloadRange,
                    payloadRange: payloadRange)
            ])
        let payload = ParsedBoxPayload(fields: [], detail: .dataReference(dataReference))
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: BoxCatalog.shared.descriptor(for: header), payload: payload))
        builder.consume(
            ParseEvent(kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset))

        let tree = builder.makeTree()
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let nodes = try XCTUnwrap(root["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 1)
        let node = try XCTUnwrap(nodes.first)
        let structured = try XCTUnwrap(node["structured"] as? [String: Any])
        let dataReferenceJSON = try XCTUnwrap(structured["data_reference"] as? [String: Any])
        let entries = try XCTUnwrap(dataReferenceJSON["entries"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 1)
        let entry = try XCTUnwrap(entries.first)
        XCTAssertEqual(entry["payload_length"] as? Int, 2)
        XCTAssertNil(entry["payload_base64"])
        XCTAssertFalse(entry.keys.contains("payload_base64"))
    }

    func testParseTreeBuilderCapturesParseIssues() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let issue = ParseIssue(
            severity: .error, code: "header.truncated_field", message: "Truncated header field",
            byteRange: 0..<8, affectedNodeIDs: [header.startOffset])

        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                issues: [issue]))
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset,
                issues: [issue]))

        let tree = builder.makeTree()
        let node = try XCTUnwrap(tree.nodes.first)
        XCTAssertEqual(node.issues, [issue])
    }

    func testParseTreeBuilderSynthesizesPlaceholderForMissingRequiredChild() throws {
        let parent = try makeHeader(type: "minf", size: 64)
        let presentChild = try makeHeader(
            type: "smhd", size: 16, offset: parent.payloadRange.lowerBound)

        var builder = ParseTreeBuilder()
        builder.consume(
            ParseEvent(kind: .willStartBox(header: parent, depth: 0), offset: parent.startOffset))
        builder.consume(
            ParseEvent(
                kind: .willStartBox(header: presentChild, depth: 1),
                offset: presentChild.startOffset))
        builder.consume(
            ParseEvent(
                kind: .didFinishBox(header: presentChild, depth: 1), offset: presentChild.endOffset)
        )
        builder.consume(
            ParseEvent(kind: .didFinishBox(header: parent, depth: 0), offset: parent.endOffset))

        let tree = builder.makeTree()
        let root = try XCTUnwrap(tree.nodes.first)
        XCTAssertEqual(root.header.type.rawValue, "minf")
        XCTAssertEqual(root.status, .partial)
        XCTAssertEqual(root.children.count, 2)

        let placeholder = try XCTUnwrap(
            root.children.first(where: { $0.header.type.rawValue == "stbl" }))
        XCTAssertLessThan(placeholder.header.startOffset, 0)
        XCTAssertEqual(placeholder.status, .corrupt)
        XCTAssertEqual(placeholder.children.count, 0)

        let placeholderIssue = try XCTUnwrap(placeholder.issues.first)
        XCTAssertEqual(placeholderIssue.code, "structure.missing_child")
        XCTAssertEqual(placeholderIssue.severity, .error)
        XCTAssertTrue(placeholderIssue.message.contains("minf"))
        XCTAssertTrue(placeholderIssue.message.contains("stbl"))
        XCTAssertEqual(
            Set(placeholderIssue.affectedNodeIDs),
            Set([parent.startOffset, placeholder.header.startOffset]))
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
        for try await event in pipeline.events(for: reader) { builder.consume(event) }

        let tree = builder.makeTree()
        let exporter = JSONParseTreeExporter()
        let jsonData = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: jsonData) as? [String: Any])

        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
        XCTAssertEqual(nodes.count, 5)
        XCTAssertEqual(
            nodes.compactMap { $0["fourcc"] as? String }, ["ftyp", "free", "moov", "skip", "mdat"])

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
            index: 1, time: 12_000, moofOffset: 0, trafNumber: 1, trunNumber: 1, sampleNumber: 2,
            fragmentSequenceNumber: 9, trackID: 1, sampleDescriptionIndex: 1, runIndex: 0,
            firstSampleGlobalIndex: 1, resolvedDecodeTime: 12_000, resolvedPresentationTime: 12_000,
            resolvedDataOffset: 5_360, resolvedSampleSize: 1_500, resolvedSampleFlags: nil)

        let tfraDetail = ParsedBoxPayload.TrackFragmentRandomAccessBox(
            version: 1, flags: 0, trackID: 1, trafNumberLength: 4, trunNumberLength: 4,
            sampleNumberLength: 4, entryCount: 1, entries: [entry])

        let mfraDetail = ParsedBoxPayload.MovieFragmentRandomAccessBox(
            tracks: [
                ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary(
                    trackID: 1, entryCount: 1, earliestTime: 12_000, latestTime: 12_000,
                    referencedFragmentSequenceNumbers: [9])
            ], totalEntryCount: 1,
            offset: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox(mfraSize: 128))

        let tfraNode = ParseTreeNode(
            header: tfraHeader,
            payload: ParsedBoxPayload(detail: .trackFragmentRandomAccess(tfraDetail)))

        let mfraNode = ParseTreeNode(
            header: mfraHeader,
            payload: ParsedBoxPayload(detail: .movieFragmentRandomAccess(mfraDetail)),
            children: [tfraNode])

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
        let tableJSON = try XCTUnwrap(
            tfraStructured["track_fragment_random_access"] as? [String: Any])
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

    func testJSONExporterIncludesSampleEncryptionMetadata() throws {
        let sampleEncryption = ParsedBoxPayload.SampleEncryptionBox(
            version: 0, flags: 0x000003, sampleCount: 2, algorithmIdentifier: 0x010203,
            perSampleIVSize: 8, keyIdentifierRange: 24..<40, sampleInfoRange: 40..<48,
            sampleInfoByteLength: 8, constantIVRange: nil, constantIVByteLength: nil)
        let sampleOffsets = ParsedBoxPayload.SampleAuxInfoOffsetsBox(
            version: 0, flags: 0x000001, entryCount: 3, auxInfoType: try FourCharCode("cenc"),
            auxInfoTypeParameter: 0x0000_0002, entrySize: .eightBytes, entriesRange: 80..<104,
            entriesByteLength: 24)
        let sampleSizes = ParsedBoxPayload.SampleAuxInfoSizesBox(
            version: 0, flags: 0x000001, defaultSampleInfoSize: 0, entryCount: 3,
            auxInfoType: try FourCharCode("cenc"), auxInfoTypeParameter: 0x0000_0002,
            variableEntriesRange: 120..<123, variableEntriesByteLength: 3)

        let sencHeader = try makeHeader(type: "senc", size: 80)
        let saioHeader = try makeHeader(type: "saio", size: 72, offset: 80)
        let saizHeader = try makeHeader(type: "saiz", size: 64, offset: 160)

        let sencNode = ParseTreeNode(
            header: sencHeader,
            payload: ParsedBoxPayload(detail: .sampleEncryption(sampleEncryption)))
        let saioNode = ParseTreeNode(
            header: saioHeader,
            payload: ParsedBoxPayload(detail: .sampleAuxInfoOffsets(sampleOffsets)))
        let saizNode = ParseTreeNode(
            header: saizHeader, payload: ParsedBoxPayload(detail: .sampleAuxInfoSizes(sampleSizes)))

        let tree = ParseTree(nodes: [sencNode, saioNode, saizNode])
        let exporter = JSONParseTreeExporter()
        let data = try exporter.export(tree: tree)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])

        let sencJSON = try XCTUnwrap(nodes.first { ($0["fourcc"] as? String) == "senc" })
        let sencStructured = try XCTUnwrap(sencJSON["structured"] as? [String: Any])
        let sampleEncryptionJSON = try XCTUnwrap(
            sencStructured["sample_encryption"] as? [String: Any])
        XCTAssertEqual(sampleEncryptionJSON["version"] as? Int, 0)
        XCTAssertEqual(sampleEncryptionJSON["flags"] as? Int, 3)
        XCTAssertEqual(sampleEncryptionJSON["sample_count"] as? Int, 2)
        XCTAssertEqual(sampleEncryptionJSON["override_track_encryption_defaults"] as? Bool, true)
        XCTAssertEqual(sampleEncryptionJSON["uses_subsample_encryption"] as? Bool, true)
        XCTAssertEqual(sampleEncryptionJSON["algorithm_identifier"] as? String, "0x010203")
        XCTAssertEqual(sampleEncryptionJSON["per_sample_iv_size"] as? Int, 8)
        let keyIdentifier = try XCTUnwrap(
            sampleEncryptionJSON["key_identifier_range"] as? [String: Any])
        XCTAssertEqual(keyIdentifier["start"] as? Int, 24)
        XCTAssertEqual(keyIdentifier["end"] as? Int, 40)
        let sampleInfo = try XCTUnwrap(sampleEncryptionJSON["sample_info"] as? [String: Any])
        XCTAssertEqual(sampleInfo["length"] as? Int, 8)
        let sampleInfoRange = try XCTUnwrap(sampleInfo["range"] as? [String: Any])
        XCTAssertEqual(sampleInfoRange["start"] as? Int, 40)
        XCTAssertEqual(sampleInfoRange["end"] as? Int, 48)

        let saioJSON = try XCTUnwrap(nodes.first { ($0["fourcc"] as? String) == "saio" })
        let saioStructured = try XCTUnwrap(saioJSON["structured"] as? [String: Any])
        let offsetsJSON = try XCTUnwrap(saioStructured["sample_aux_info_offsets"] as? [String: Any])
        XCTAssertEqual(offsetsJSON["entry_count"] as? Int, 3)
        XCTAssertEqual(offsetsJSON["entry_size_bytes"] as? Int, 8)
        XCTAssertEqual(offsetsJSON["version"] as? Int, 0)
        XCTAssertEqual(offsetsJSON["flags"] as? Int, 1)
        XCTAssertEqual(offsetsJSON["aux_info_type"] as? String, "cenc")
        XCTAssertEqual(offsetsJSON["aux_info_type_parameter"] as? Int, 2)
        let entries = try XCTUnwrap(offsetsJSON["entries"] as? [String: Any])
        XCTAssertEqual(entries["length"] as? Int, 24)
        let entriesRange = try XCTUnwrap(entries["range"] as? [String: Any])
        XCTAssertEqual(entriesRange["start"] as? Int, 80)
        XCTAssertEqual(entriesRange["end"] as? Int, 104)

        let saizJSON = try XCTUnwrap(nodes.first { ($0["fourcc"] as? String) == "saiz" })
        let saizStructured = try XCTUnwrap(saizJSON["structured"] as? [String: Any])
        let sizesJSON = try XCTUnwrap(saizStructured["sample_aux_info_sizes"] as? [String: Any])
        XCTAssertEqual(sizesJSON["default_sample_info_size"] as? Int, 0)
        XCTAssertEqual(sizesJSON["entry_count"] as? Int, 3)
        XCTAssertEqual(sizesJSON["version"] as? Int, 0)
        XCTAssertEqual(sizesJSON["flags"] as? Int, 1)
        XCTAssertEqual(sizesJSON["aux_info_type"] as? String, "cenc")
        XCTAssertEqual(sizesJSON["aux_info_type_parameter"] as? Int, 2)
        let variable = try XCTUnwrap(sizesJSON["variable_sizes"] as? [String: Any])
        XCTAssertEqual(variable["length"] as? Int, 3)
        let variableRange = try XCTUnwrap(variable["range"] as? [String: Any])
        XCTAssertEqual(variableRange["start"] as? Int, 120)
        XCTAssertEqual(variableRange["end"] as? Int, 123)
    }

    func testBinaryCaptureRoundTripPreservesEvents() throws {
        let header = try makeHeader(type: "trak", size: 40)
        let metadata = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil), name: "Track Box",
            summary: "Track container", category: nil, specification: nil, version: nil, flags: nil)
        let issue = ValidationIssue(ruleID: "VR-002", message: "Mismatch", severity: .warning)
        let payload = ParsedBoxPayload(fields: [
            ParsedBoxPayload.Field(
                name: "dummy", value: "value", description: nil, byteRange: header.payloadRange)
        ])
        let events = [
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0), offset: header.startOffset,
                metadata: metadata, payload: payload, validationIssues: [issue]),
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0), offset: header.endOffset,
                metadata: metadata, payload: payload, validationIssues: []),
        ]

        let encoded = try ParseEventCaptureEncoder().encode(events: events)
        let decoded = try ParseEventCaptureDecoder().decode(data: encoded)
        XCTAssertEqual(decoded, events)
    }

    private func makeHeader(type: String, size: Int64, offset: Int64 = 0) throws -> BoxHeader {
        let fourcc = try FourCharCode(type)
        return BoxHeader(
            type: fourcc, totalSize: size, headerSize: 8,
            payloadRange: (offset + 8)..<(offset + size), range: offset..<(offset + size), uuid: nil
        )
    }

    private func makeBox(type: String, payload: Data) -> Data {
        precondition(type.utf8.count == 4, "Box type must be four characters")
        var data = Data()
        let size = UInt32(8 + payload.count).bigEndian
        withUnsafeBytes(of: size) { buffer in data.append(contentsOf: buffer) }
        data.append(contentsOf: type.utf8)
        data.append(payload)
        return data
    }
}
