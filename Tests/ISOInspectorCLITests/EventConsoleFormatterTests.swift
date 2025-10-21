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

    func testFormatterIncludesMovieFragmentSequenceNumber() throws {
        let header = try makeHeader(type: "mfhd", size: 16)
        let payload = ParsedBoxPayload(
            fields: [
                ParsedBoxPayload.Field(
                    name: "version",
                    value: "0",
                    description: "Structure version",
                    byteRange: 8..<9
                ),
                ParsedBoxPayload.Field(
                    name: "flags",
                    value: "0x000000",
                    description: "Bit flags",
                    byteRange: 9..<12
                ),
                ParsedBoxPayload.Field(
                    name: "sequence_number",
                    value: "7",
                    description: "Fragment sequence number",
                    byteRange: 12..<16
                )
            ],
            detail: .movieFragmentHeader(
                ParsedBoxPayload.MovieFragmentHeaderBox(
                    version: 0,
                    flags: 0,
                    sequenceNumber: 7
                )
            )
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            payload: payload
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("sequence=7"))
    }

    func testFormatterIncludesTrackFragmentHeaderTrackID() throws {
        let header = try makeHeader(type: "tfhd", size: 20)
        let payload = ParsedBoxPayload(
            fields: [
                ParsedBoxPayload.Field(
                    name: "track_id",
                    value: "42",
                    description: "Track identifier",
                    byteRange: 12..<16
                )
            ],
            detail: .trackFragmentHeader(
                ParsedBoxPayload.TrackFragmentHeaderBox(
                    version: 0,
                    flags: 0,
                    trackID: 42,
                    baseDataOffset: nil,
                    sampleDescriptionIndex: nil,
                    defaultSampleDuration: nil,
                    defaultSampleSize: nil,
                    defaultSampleFlags: nil,
                    durationIsEmpty: false,
                    defaultBaseIsMoof: false
                )
            )
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            payload: payload
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("track=42"))
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
