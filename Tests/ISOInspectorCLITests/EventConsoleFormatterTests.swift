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

    func testFormatterIncludesTrackFragmentDecodeTime() throws {
        let header = try makeHeader(type: "tfdt", size: 20)
        let payload = ParsedBoxPayload(
            detail: .trackFragmentDecodeTime(
                ParsedBoxPayload.TrackFragmentDecodeTimeBox(
                    version: 1,
                    flags: 0,
                    baseMediaDecodeTime: 9000,
                    baseMediaDecodeTimeIs64Bit: true
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

        XCTAssertTrue(output.contains("base_decode_time=9000"))
    }

    func testFormatterIncludesTrackRunSummary() throws {
        let header = try makeHeader(type: "trun", size: 24)
        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0x000001,
            sampleCount: 3,
            dataOffset: 256,
            firstSampleFlags: nil,
            entries: [],
            totalSampleDuration: 180,
            totalSampleSize: 1500,
            startDecodeTime: 1000,
            endDecodeTime: 1180,
            startPresentationTime: 1000,
            endPresentationTime: 1180,
            startDataOffset: 2048,
            endDataOffset: 2048 + 1500,
            trackID: 7,
            sampleDescriptionIndex: 2,
            runIndex: 0,
            firstSampleGlobalIndex: 1
        )
        let payload = ParsedBoxPayload(detail: .trackRun(run))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            payload: payload
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("track=7"))
        XCTAssertTrue(output.contains("run=0"))
        XCTAssertTrue(output.contains("samples=3"))
        XCTAssertTrue(output.contains("first_sample=1"))
        XCTAssertTrue(output.contains("duration=180"))
        XCTAssertTrue(output.contains("size=1500"))
        XCTAssertTrue(output.contains("data_offset=256"))
        XCTAssertTrue(output.contains("data_range=2048-3548"))
        XCTAssertTrue(output.contains("decode=1000-1180"))
        XCTAssertTrue(output.contains("presentation=1000-1180"))
    }

    func testFormatterHighlightsRunWithNegativeDataOffset() throws {
        let header = try makeHeader(type: "trun", size: 24)
        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0x000200,
            sampleCount: 1,
            dataOffset: -64,
            firstSampleFlags: nil,
            entries: [],
            totalSampleDuration: 240,
            totalSampleSize: 480,
            startDecodeTime: nil,
            endDecodeTime: nil,
            startPresentationTime: nil,
            endPresentationTime: nil,
            startDataOffset: nil,
            endDataOffset: nil,
            trackID: 2,
            sampleDescriptionIndex: 1,
            runIndex: 1,
            firstSampleGlobalIndex: 5
        )
        let payload = ParsedBoxPayload(detail: .trackRun(run))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            payload: payload
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("track=2"))
        XCTAssertTrue(output.contains("run=1"))
        XCTAssertTrue(output.contains("data_offset=-64"))
        XCTAssertTrue(output.contains("data_range=unresolved"))
        XCTAssertTrue(output.contains("decode=unresolved"))
    }

    func testFormatterIncludesTrackFragmentSummary() throws {
        let header = try makeHeader(type: "traf", size: 40)
        let fragment = ParsedBoxPayload.TrackFragmentBox(
            trackID: 9,
            sampleDescriptionIndex: 5,
            baseDataOffset: 4096,
            defaultSampleDuration: 100,
            defaultSampleSize: 512,
            defaultSampleFlags: 0x0102_0304,
            durationIsEmpty: false,
            defaultBaseIsMoof: true,
            baseDecodeTime: 1200,
            baseDecodeTimeIs64Bit: false,
            runs: [],
            totalSampleCount: 4,
            totalSampleSize: 2048,
            totalSampleDuration: 400,
            earliestPresentationTime: 1000,
            latestPresentationTime: 1600,
            firstDecodeTime: 1200,
            lastDecodeTime: 1600
        )
        let payload = ParsedBoxPayload(detail: .trackFragment(fragment))
        let event = ParseEvent(
            kind: .didFinishBox(header: header, depth: 0),
            offset: header.endOffset,
            payload: payload
        )

        let formatter = EventConsoleFormatter()
        let output = formatter.format(event)

        XCTAssertTrue(output.contains("track=9"))
        XCTAssertTrue(output.contains("runs=0"))
        XCTAssertTrue(output.contains("samples=4"))
        XCTAssertTrue(output.contains("duration=400"))
        XCTAssertTrue(output.contains("size=2048"))
        XCTAssertTrue(output.contains("base_decode=1200"))
        XCTAssertTrue(output.contains("decode=1200-1600"))
        XCTAssertTrue(output.contains("presentation=1000-1600"))
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
