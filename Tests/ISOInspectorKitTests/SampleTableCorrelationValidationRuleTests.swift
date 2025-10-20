import XCTest
@testable import ISOInspectorKit

final class SampleTableCorrelationValidationRuleTests: XCTestCase {
    // MARK: - Chunk Count Validation Tests

    /// VR-015: When stsc references more chunks than stco declares, emit a warning
    func testReportsChunkCountMismatchWhenStscExceedsStco() throws {
        // Arrange: Create a track with mismatched chunk counts
        // stsc says: 10 chunks exist (firstChunk: 1...10)
        // stco says: only 8 chunks exist

        let reader = InMemoryRandomAccessReader(data: Data(count: 1024))
        let validator = BoxValidator()

        // Track container
        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 512, offset: 0)
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 0), offset: trak.startOffset),
            reader: reader
        )

        // stsc box: 2 entries, last firstChunk = 9 (so 10 chunks total: 1-8 in first run, 9-10 in second run)
        let stscHeader = try makeHeader(type: "stsc", offset: 8)
        let stscPayload = ParsedBoxPayload(
            detail: .sampleToChunk(
                ParsedBoxPayload.SampleToChunkBox(
                    version: 0,
                    flags: 0,
                    entries: [
                        .init(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1, byteRange: 0..<12),
                        .init(firstChunk: 9, samplesPerChunk: 3, sampleDescriptionIndex: 1, byteRange: 12..<24)
                    ]
                )
            )
        )
        _ = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stscHeader, depth: 1),
                offset: stscHeader.startOffset,
                payload: stscPayload
            ),
            reader: reader
        )

        // stco box: 8 chunks (0-7)
        let stcoHeader = try makeHeader(type: "stco", offset: 16)
        let stcoPayload = ParsedBoxPayload(
            detail: .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: 0,
                    flags: 0,
                    entryCount: 8,
                    width: .bits32,
                    entries: (0..<8).map { i in
                        .init(index: UInt32(i), offset: UInt64(i * 100), byteRange: 0..<4)
                    }
                )
            )
        )
        let annotatedStco = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stcoHeader, depth: 1),
                offset: stcoHeader.startOffset,
                payload: stcoPayload
            ),
            reader: reader
        )

        // Act & Assert: VR-015 should detect mismatch
        let vr015Issues = annotatedStco.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertEqual(vr015Issues.count, 1, "Expected exactly one VR-015 issue for chunk count mismatch")
        XCTAssertTrue(
            vr015Issues.first?.message.contains("chunk count mismatch") ?? false,
            "Issue message should mention chunk count mismatch"
        )
        XCTAssertEqual(vr015Issues.first?.severity, .warning)
    }

    /// VR-015: When stsc and stco chunk counts match, no issues should be raised
    func testProducesNoIssuesWhenChunkCountsMatch() throws {
        // Arrange: Create a track with matching chunk counts
        // stsc says: 10 chunks exist (firstChunk: 1...10)
        // stco says: 10 chunks exist

        let reader = InMemoryRandomAccessReader(data: Data(count: 1024))
        let validator = BoxValidator()

        // Track container
        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 512, offset: 0)
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 0), offset: trak.startOffset),
            reader: reader
        )

        // stsc box: 2 entries, last firstChunk = 9 (so chunks 1-10)
        let stscHeader = try makeHeader(type: "stsc", offset: 8)
        let stscPayload = ParsedBoxPayload(
            detail: .sampleToChunk(
                ParsedBoxPayload.SampleToChunkBox(
                    version: 0,
                    flags: 0,
                    entries: [
                        .init(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1, byteRange: 0..<12),
                        .init(firstChunk: 9, samplesPerChunk: 3, sampleDescriptionIndex: 1, byteRange: 12..<24)
                    ]
                )
            )
        )
        _ = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stscHeader, depth: 1),
                offset: stscHeader.startOffset,
                payload: stscPayload
            ),
            reader: reader
        )

        // stco box: 10 chunks (matching stsc)
        let stcoHeader = try makeHeader(type: "stco", offset: 16)
        let stcoPayload = ParsedBoxPayload(
            detail: .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: 0,
                    flags: 0,
                    entryCount: 10,
                    width: .bits32,
                    entries: (0..<10).map { i in
                        .init(index: UInt32(i), offset: UInt64(i * 100), byteRange: 0..<4)
                    }
                )
            )
        )
        let annotatedStco = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stcoHeader, depth: 1),
                offset: stcoHeader.startOffset,
                payload: stcoPayload
            ),
            reader: reader
        )

        // Act & Assert: No VR-015 issues should be present
        let vr015Issues = annotatedStco.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertTrue(vr015Issues.isEmpty, "Expected no VR-015 issues when chunk counts match")
    }

    // MARK: - Sample Count Validation Tests

    /// VR-015: When stsc-computed sample count doesn't match stsz sample count, emit a warning
    func testReportsSampleCountMismatchBetweenStscAndStsz() throws {
        // Arrange: Create mismatched sample counts
        // stsc: 2 chunks × 5 samples/chunk = 10 samples
        // stsz: declares 8 samples

        let reader = InMemoryRandomAccessReader(data: Data(count: 1024))
        let validator = BoxValidator()

        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 512, offset: 0)
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 0), offset: trak.startOffset),
            reader: reader
        )

        // stsc: 1 entry, chunks 1-2, 5 samples per chunk = 10 total samples
        let stscHeader = try makeHeader(type: "stsc", offset: 8)
        let stscPayload = ParsedBoxPayload(
            detail: .sampleToChunk(
                ParsedBoxPayload.SampleToChunkBox(
                    version: 0,
                    flags: 0,
                    entries: [
                        .init(firstChunk: 1, samplesPerChunk: 5, sampleDescriptionIndex: 1, byteRange: 0..<12)
                    ]
                )
            )
        )
        _ = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stscHeader, depth: 1),
                offset: stscHeader.startOffset,
                payload: stscPayload
            ),
            reader: reader
        )

        // stsz: 8 samples (mismatch!)
        let stszHeader = try makeHeader(type: "stsz", offset: 16)
        let stszPayload = ParsedBoxPayload(
            detail: .sampleSize(
                ParsedBoxPayload.SampleSizeBox(
                    version: 0,
                    flags: 0,
                    defaultSampleSize: 0,
                    sampleCount: 8,
                    entries: (0..<8).map { i in
                        .init(index: UInt32(i), size: 1024, byteRange: 0..<4)
                    }
                )
            )
        )
        _ = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stszHeader, depth: 1),
                offset: stszHeader.startOffset,
                payload: stszPayload
            ),
            reader: reader
        )

        // stco: 2 chunks
        let stcoHeader = try makeHeader(type: "stco", offset: 24)
        let stcoPayload = ParsedBoxPayload(
            detail: .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: 0,
                    flags: 0,
                    entryCount: 2,
                    width: .bits32,
                    entries: (0..<2).map { i in
                        .init(index: UInt32(i), offset: UInt64(i * 100), byteRange: 0..<4)
                    }
                )
            )
        )
        let annotatedStco = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stcoHeader, depth: 1),
                offset: stcoHeader.startOffset,
                payload: stcoPayload
            ),
            reader: reader
        )

        // Act & Assert: Should detect sample count mismatch
        let vr015Issues = annotatedStco.validationIssues.filter { $0.ruleID == "VR-015" }
        let sampleCountIssues = vr015Issues.filter { $0.message.contains("sample count") }
        XCTAssertFalse(sampleCountIssues.isEmpty, "Expected VR-015 issue for sample count mismatch")
        XCTAssertEqual(sampleCountIssues.first?.severity, .warning)
    }

    // MARK: - Chunk Offset Monotonicity Tests

    /// VR-015: When chunk offsets are not monotonically increasing, emit a warning
    func testReportsNonMonotonicChunkOffsets() throws {
        // Arrange: Create chunk offsets that are not monotonic
        let reader = InMemoryRandomAccessReader(data: Data(count: 1024))
        let validator = BoxValidator()

        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 512, offset: 0)
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 0), offset: trak.startOffset),
            reader: reader
        )

        // stco: offsets are not monotonic (500 > 300)
        let stcoHeader = try makeHeader(type: "stco", offset: 8)
        let stcoPayload = ParsedBoxPayload(
            detail: .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: 0,
                    flags: 0,
                    entryCount: 4,
                    width: .bits32,
                    entries: [
                        .init(index: 0, offset: 100, byteRange: 0..<4),
                        .init(index: 1, offset: 200, byteRange: 4..<8),
                        .init(index: 2, offset: 500, byteRange: 8..<12),
                        .init(index: 3, offset: 300, byteRange: 12..<16)  // Non-monotonic!
                    ]
                )
            )
        )
        let annotatedStco = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stcoHeader, depth: 1),
                offset: stcoHeader.startOffset,
                payload: stcoPayload
            ),
            reader: reader
        )

        // Act & Assert: Should detect non-monotonic offsets
        let vr015Issues = annotatedStco.validationIssues.filter { $0.ruleID == "VR-015" }
        let monotonicityIssues = vr015Issues.filter { $0.message.contains("monotonic") }
        XCTAssertFalse(monotonicityIssues.isEmpty, "Expected VR-015 issue for non-monotonic offsets")
        XCTAssertEqual(monotonicityIssues.first?.severity, .warning)
    }

    /// VR-015: When chunk offsets are monotonically increasing, no issues should be raised
    func testProducesNoIssuesWhenChunkOffsetsAreMonotonic() throws {
        // Arrange: Create chunk offsets that are properly monotonic
        let reader = InMemoryRandomAccessReader(data: Data(count: 1024))
        let validator = BoxValidator()

        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 512, offset: 0)
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 0), offset: trak.startOffset),
            reader: reader
        )

        // stco: offsets are monotonic
        let stcoHeader = try makeHeader(type: "stco", offset: 8)
        let stcoPayload = ParsedBoxPayload(
            detail: .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: 0,
                    flags: 0,
                    entryCount: 4,
                    width: .bits32,
                    entries: [
                        .init(index: 0, offset: 100, byteRange: 0..<4),
                        .init(index: 1, offset: 200, byteRange: 4..<8),
                        .init(index: 2, offset: 300, byteRange: 8..<12),
                        .init(index: 3, offset: 500, byteRange: 12..<16)
                    ]
                )
            )
        )
        let annotatedStco = validator.annotate(
            event: ParseEvent(
                kind: .willStartBox(header: stcoHeader, depth: 1),
                offset: stcoHeader.startOffset,
                payload: stcoPayload
            ),
            reader: reader
        )

        // Act & Assert: No monotonicity issues
        let vr015Issues = annotatedStco.validationIssues.filter { $0.ruleID == "VR-015" }
        let monotonicityIssues = vr015Issues.filter { $0.message.contains("monotonic") }
        XCTAssertTrue(monotonicityIssues.isEmpty, "Expected no VR-015 issues for monotonic offsets")
    }

    // MARK: - Helper Methods

    private func makeHeader(
        type: String,
        totalSize: Int64 = 32,
        offset: Int64
    ) throws -> BoxHeader {
        let fourCC = try FourCharCode(type)
        let headerSize: Int64 = 8
        let payloadRange = (offset + headerSize)..<(offset + totalSize)
        return BoxHeader(
            totalSize: totalSize,
            headerSize: headerSize,
            type: fourCC,
            extendedType: nil,
            startOffset: offset,
            payloadRange: payloadRange
        )
    }
}
