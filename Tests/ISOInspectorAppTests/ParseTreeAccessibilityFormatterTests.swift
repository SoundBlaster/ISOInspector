#if canImport(Combine)
import XCTest
import ISOInspectorKit
@testable import ISOInspectorApp

final class ParseTreeAccessibilityFormatterTests: XCTestCase {
    func testOutlineRowDescriptorIncludesTypeSeverityAndBookmarkState() throws {
        let header = BoxHeader(
            type: try FourCharCode("trak"),
            totalSize: 128,
            headerSize: 8,
            payloadRange: 8..<120,
            range: 0..<128,
            uuid: nil
        )
        let metadata = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let node = ParseTreeNode(
            header: header,
            metadata: metadata,
            payload: nil,
            validationIssues: [ValidationIssue(ruleID: "VR-002", message: "Track missing language", severity: .warning)],
            children: [
                ParseTreeNode(
                    header: BoxHeader(
                        type: try FourCharCode("mdia"),
                        totalSize: 64,
                        headerSize: 8,
                        payloadRange: 8..<56,
                        range: 200..<264,
                        uuid: nil
                    ),
                    metadata: nil,
                    payload: nil,
                    validationIssues: [],
                    children: []
                )
            ]
        )
        let row = ParseTreeOutlineRow(
            node: node,
            depth: 1,
            isExpanded: false,
            isSearchMatch: false,
            hasMatchingDescendant: false,
            hasValidationIssues: true
        )

        let descriptor = row.accessibilityDescriptor(isBookmarked: true)

        XCTAssertTrue(descriptor.label.contains("Track"))
        XCTAssertTrue(descriptor.label.contains("trak"))
        XCTAssertTrue(descriptor.label.contains("warning"))
        XCTAssertTrue(descriptor.label.contains("1 child"))
        XCTAssertEqual(descriptor.value, "Bookmarked")
        XCTAssertEqual(descriptor.hint, "Press Return to expand or collapse. Press Space to toggle bookmark.")
    }

    func testDetailSummaryEnumeratesKeyFields() throws {
        let header = BoxHeader(
            type: try FourCharCode("mvhd"),
            totalSize: 200,
            headerSize: 12,
            payloadRange: 12..<200,
            range: 100..<300,
            uuid: nil
        )
        let metadata = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let detail = ParseTreeNodeDetail(
            header: header,
            metadata: metadata,
            payload: nil,
            validationIssues: [
                ValidationIssue(ruleID: "VR-101", message: "Duration missing", severity: .error)
            ],
            issues: [],
            status: .valid,
            snapshotTimestamp: Date(timeIntervalSince1970: 0),
            hexSlice: nil
        )

        let summary = detail.accessibilitySummary

        XCTAssertTrue(summary.contains("Movie Header"))
        XCTAssertTrue(summary.contains("mvhd"))
        XCTAssertTrue(summary.contains("Range 100 – 300"))
        XCTAssertTrue(summary.contains("Payload 12 – 200"))
        XCTAssertTrue(summary.contains("error"))
        XCTAssertTrue(summary.contains("Status Valid"))
    }

    func testDetailSummaryMentionsSampleEncryptionMetadata() throws {
        let header = BoxHeader(
            type: try FourCharCode("senc"),
            totalSize: 64,
            headerSize: 8,
            payloadRange: 8..<64,
            range: 0..<64,
            uuid: nil
        )
        let payload = ParsedBoxPayload(detail: .sampleEncryption(
            ParsedBoxPayload.SampleEncryptionBox(
                version: 0,
                flags: 0x000003,
                sampleCount: 2,
                algorithmIdentifier: 0x010203,
                perSampleIVSize: 8,
                keyIdentifierRange: 24..<40,
                sampleInfoRange: 40..<48,
                sampleInfoByteLength: 8,
                constantIVRange: nil,
                constantIVByteLength: nil
            )
        ))
        let detail = ParseTreeNodeDetail(
            header: header,
            metadata: nil,
            payload: payload,
            validationIssues: [],
            issues: [],
            status: .valid,
            snapshotTimestamp: Date(timeIntervalSince1970: 0),
            hexSlice: nil
        )

        let summary = detail.accessibilitySummary

        XCTAssertTrue(summary.contains("Sample encryption entries 2"))
        XCTAssertTrue(summary.contains("Per-sample IV size 8"))
        XCTAssertTrue(summary.contains("Algorithm 0x010203"))
    }

    func testDetailSummaryMentionsSampleAuxInfoOffsets() throws {
        let header = BoxHeader(
            type: try FourCharCode("saio"),
            totalSize: 56,
            headerSize: 8,
            payloadRange: 8..<56,
            range: 0..<56,
            uuid: nil
        )
        let payload = ParsedBoxPayload(detail: .sampleAuxInfoOffsets(
            ParsedBoxPayload.SampleAuxInfoOffsetsBox(
                version: 0,
                flags: 0x000001,
                entryCount: 3,
                auxInfoType: try FourCharCode("cenc"),
                auxInfoTypeParameter: 2,
                entrySize: .eightBytes,
                entriesRange: 32..<56,
                entriesByteLength: 24
            )
        ))
        let detail = ParseTreeNodeDetail(
            header: header,
            metadata: nil,
            payload: payload,
            validationIssues: [],
            issues: [],
            status: .valid,
            snapshotTimestamp: Date(timeIntervalSince1970: 0),
            hexSlice: nil
        )

        let summary = detail.accessibilitySummary

        XCTAssertTrue(summary.contains("Auxiliary info offsets entries 3"))
        XCTAssertTrue(summary.contains("Bytes per entry 8"))
        XCTAssertTrue(summary.contains("Range 32 – 56"))
    }

    func testDetailSummaryMentionsSampleAuxInfoSizes() throws {
        let header = BoxHeader(
            type: try FourCharCode("saiz"),
            totalSize: 48,
            headerSize: 8,
            payloadRange: 8..<48,
            range: 0..<48,
            uuid: nil
        )
        let payload = ParsedBoxPayload(detail: .sampleAuxInfoSizes(
            ParsedBoxPayload.SampleAuxInfoSizesBox(
                version: 0,
                flags: 0x000001,
                defaultSampleInfoSize: 0,
                entryCount: 3,
                auxInfoType: try FourCharCode("cenc"),
                auxInfoTypeParameter: 2,
                variableEntriesRange: 40..<43,
                variableEntriesByteLength: 3
            )
        ))
        let detail = ParseTreeNodeDetail(
            header: header,
            metadata: nil,
            payload: payload,
            validationIssues: [],
            issues: [],
            status: .valid,
            snapshotTimestamp: Date(timeIntervalSince1970: 0),
            hexSlice: nil
        )

        let summary = detail.accessibilitySummary

        XCTAssertTrue(summary.contains("Auxiliary info sizes default 0"))
        XCTAssertTrue(summary.contains("Entry count 3"))
        XCTAssertTrue(summary.contains("Variable bytes 3"))
    }

    func testHexByteFormatterAnnouncesSelectionAndOffset() {
        let formatter = HexByteAccessibilityFormatter()
        let label = formatter.label(for: 0xAF, at: 512, highlighted: true)

        XCTAssertEqual(label, "Byte 0xAF at offset 512, selected")
    }
}
#endif
