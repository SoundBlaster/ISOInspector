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
            snapshotTimestamp: Date(timeIntervalSince1970: 0),
            hexSlice: nil
        )

        let summary = detail.accessibilitySummary

        XCTAssertTrue(summary.contains("Movie Header"))
        XCTAssertTrue(summary.contains("mvhd"))
        XCTAssertTrue(summary.contains("Range 100 – 300"))
        XCTAssertTrue(summary.contains("Payload 12 – 200"))
        XCTAssertTrue(summary.contains("error"))
    }

    func testHexByteFormatterAnnouncesSelectionAndOffset() {
        let formatter = HexByteAccessibilityFormatter()
        let label = formatter.label(for: 0xAF, at: 512, highlighted: true)

        XCTAssertEqual(label, "Byte 0xAF at offset 512, selected")
    }
}
#endif
