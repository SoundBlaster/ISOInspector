import XCTest
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class EventConsoleFormatterTests: XCTestCase {
    func testFormatterIncludesMetadataDetails() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            metadata: descriptor
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains(descriptor.name))
        XCTAssertTrue(output.contains(descriptor.summary))
    }

    func testFormatterIncludesValidationIssues() throws {
        let header = try makeHeader(type: "tkhd", size: 40)
        let descriptor = BoxCatalog.shared.descriptor(for: header)
        let issue = ValidationIssue(
            ruleID: "VR-003",
            message: "Expected version 0 but found 1",
            severity: .warning
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 1),
            offset: 8,
            metadata: descriptor,
            validationIssues: [issue]
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("VR-003"))
        XCTAssertTrue(output.contains("warning"))
        XCTAssertTrue(output.contains("Expected version 0 but found 1"))
    }

    private func makeHeader(type: String, size: Int64) throws -> BoxHeader {
        let fourCC = try FourCharCode(type)
        let range = Int64(0)..<size
        let payloadRange = Int64(8)..<size
        return BoxHeader(
            type: fourCC,
            totalSize: size,
            headerSize: 8,
            payloadRange: payloadRange,
            range: range,
            uuid: nil
        )
    }
}
