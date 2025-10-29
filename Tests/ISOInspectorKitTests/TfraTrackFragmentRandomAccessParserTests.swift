import XCTest
@testable import ISOInspectorKit

final class TfraTrackFragmentRandomAccessParserTests: XCTestCase {
    func testParsesEntriesAndResolvesFragmentContext() throws {
        let trackID: UInt32 = 1
        let sequenceNumber: UInt32 = 9
        let baseDecodeTime: UInt64 = 9_000
        let baseDataOffset: UInt64 = 4_096
        let runDataOffset: Int32 = 64
        let sampleDurations: [UInt32] = [3_000, 3_000]
        let sampleSizes: [UInt32] = [1_200, 1_500]

        let entries: [TrackFragmentRandomAccessEntryParameters] = [
            .init(
                time: baseDecodeTime + UInt64(sampleDurations[0]),
                moofOffset: 0,
                trafNumber: 1,
                trunNumber: 1,
                sampleNumber: 2
            )
        ]
        let box = makeTrackFragmentRandomAccessBox(version: 1, trackID: trackID, entries: entries)
        let header = try makeHeader(for: box, type: "tfra")
        let reader = InMemoryRandomAccessReader(data: box)

        let environment = makeEnvironment(
            sequenceNumber: sequenceNumber,
            trackID: trackID,
            baseDecodeTime: baseDecodeTime,
            baseDataOffset: baseDataOffset,
            runDataOffset: runDataOffset,
            sampleDurations: sampleDurations,
            sampleSizes: sampleSizes
        )

        let parsed = try BoxParserRegistry.withRandomAccessEnvironmentProvider({ _, _ in environment }) {
            try BoxParserRegistry.shared.parse(header: header, reader: reader)
        }

        let detail = try XCTUnwrap(parsed?.trackFragmentRandomAccess)
        XCTAssertEqual(detail.version, 1)
        XCTAssertEqual(detail.trackID, trackID)
        XCTAssertEqual(detail.entries.count, 1)

        let entry = try XCTUnwrap(detail.entries.first)
        XCTAssertEqual(entry.index, 1)
        XCTAssertEqual(entry.time, baseDecodeTime + UInt64(sampleDurations[0]))
        XCTAssertEqual(entry.moofOffset, 0)
        XCTAssertEqual(entry.trafNumber, 1)
        XCTAssertEqual(entry.trunNumber, 1)
        XCTAssertEqual(entry.sampleNumber, 2)
        XCTAssertEqual(entry.fragmentSequenceNumber, sequenceNumber)
        XCTAssertEqual(entry.resolvedDecodeTime, baseDecodeTime + UInt64(sampleDurations[0]))
        XCTAssertEqual(entry.resolvedPresentationTime, Int64(baseDecodeTime + UInt64(sampleDurations[0])))
        XCTAssertEqual(entry.resolvedDataOffset, baseDataOffset + UInt64(Int64(runDataOffset)) + UInt64(sampleSizes[0]))
        XCTAssertEqual(entry.resolvedSampleSize, sampleSizes[1])

        let fields = Dictionary(uniqueKeysWithValues: parsed?.fields.map { ($0.name, $0) } ?? [])
        XCTAssertEqual(fields["track_ID"]?.value, String(trackID))
        XCTAssertEqual(fields["entries[0].traf_number"]?.value, "1")
        XCTAssertEqual(fields["entries[0].sample_number"]?.value, "2")
    }

    func testReturnsNilForTruncatedEntries() throws {
        var payload = Data()
        payload.append(0x01) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(1).bigEndianBytes) // track ID
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // length sizes
        payload.append(contentsOf: UInt32(1).bigEndianBytes) // entry count
        payload.append(contentsOf: UInt64(0).bigEndianBytes) // time
        // Truncated before moof offset / entry indices.

        let box = makeBox(type: "tfra", payload: payload)
        let header = try makeHeader(for: box, type: "tfra")
        let reader = InMemoryRandomAccessReader(data: box)

        let parsed = try BoxParserRegistry.shared.parse(header: header, reader: reader)
        XCTAssertNil(parsed)
    }

    private func makeEnvironment(
        sequenceNumber: UInt32,
        trackID: UInt32,
        baseDecodeTime: UInt64,
        baseDataOffset: UInt64,
        runDataOffset: Int32,
        sampleDurations: [UInt32],
        sampleSizes: [UInt32]
    ) -> BoxParserRegistry.RandomAccessEnvironment {
        let entries: [ParsedBoxPayload.TrackRunBox.Entry] = sampleDurations.enumerated().map { index, duration in
            ParsedBoxPayload.TrackRunBox.Entry(
                index: UInt32(index + 1),
                decodeTime: baseDecodeTime + UInt64(duration) * UInt64(index),
                presentationTime: Int64(baseDecodeTime + UInt64(duration) * UInt64(index)),
                sampleDuration: duration,
                sampleSize: sampleSizes[index],
                sampleFlags: nil,
                sampleCompositionTimeOffset: nil,
                dataOffset: baseDataOffset + UInt64(Int64(runDataOffset)) + UInt64(sampleSizes.prefix(index).reduce(0, +)),
                byteRange: nil
            )
        }

        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0,
            sampleCount: UInt32(entries.count),
            dataOffset: runDataOffset,
            firstSampleFlags: nil,
            entries: entries,
            totalSampleDuration: UInt64(sampleDurations.reduce(0, +)),
            totalSampleSize: UInt64(sampleSizes.reduce(0, +)),
            startDecodeTime: baseDecodeTime,
            endDecodeTime: baseDecodeTime + UInt64(sampleDurations.reduce(0, +)),
            startPresentationTime: Int64(baseDecodeTime),
            endPresentationTime: Int64(baseDecodeTime + UInt64(sampleDurations.reduce(0, +))),
            startDataOffset: baseDataOffset + UInt64(Int64(runDataOffset)),
            endDataOffset: baseDataOffset + UInt64(Int64(runDataOffset)) + UInt64(sampleSizes.reduce(0, +)),
            trackID: trackID,
            sampleDescriptionIndex: 1,
            runIndex: 0,
            firstSampleGlobalIndex: 1
        )

        let fragment = ParsedBoxPayload.TrackFragmentBox(
            trackID: trackID,
            sampleDescriptionIndex: 1,
            baseDataOffset: baseDataOffset,
            defaultSampleDuration: sampleDurations.first,
            defaultSampleSize: sampleSizes.first,
            defaultSampleFlags: nil,
            durationIsEmpty: false,
            defaultBaseIsMoof: false,
            baseDecodeTime: baseDecodeTime,
            baseDecodeTimeIs64Bit: true,
            runs: [run],
            totalSampleCount: UInt64(entries.count),
            totalSampleSize: UInt64(sampleSizes.reduce(0, +)),
            totalSampleDuration: UInt64(sampleDurations.reduce(0, +)),
            earliestPresentationTime: Int64(baseDecodeTime),
            latestPresentationTime: Int64(baseDecodeTime + UInt64(sampleDurations.reduce(0, +))),
            firstDecodeTime: baseDecodeTime,
            lastDecodeTime: baseDecodeTime + UInt64(sampleDurations.reduce(0, +))
        )

        let trackFragment = BoxParserRegistry.RandomAccessEnvironment.TrackFragment(order: 1, detail: fragment)
        let fragmentSummary = BoxParserRegistry.RandomAccessEnvironment.Fragment(
            sequenceNumber: sequenceNumber,
            trackFragments: [trackFragment]
        )

        return BoxParserRegistry.RandomAccessEnvironment(fragmentsByMoofOffset: [0: fragmentSummary])
    }

    private func makeHeader(for boxData: Data, type: String) throws -> BoxHeader {
        return BoxHeader(
            type: try IIFourCharCode(type),
            totalSize: Int64(boxData.count),
            headerSize: 8,
            payloadRange: 8..<Int64(boxData.count),
            range: 0..<Int64(boxData.count),
            uuid: nil
        )
    }

    private struct TrackFragmentRandomAccessEntryParameters {
        let time: UInt64
        let moofOffset: UInt64
        let trafNumber: UInt64
        let trunNumber: UInt64
        let sampleNumber: UInt64
    }

    private func makeTrackFragmentRandomAccessBox(
        version: UInt8,
        trackID: UInt32,
        entries: [TrackFragmentRandomAccessEntryParameters]
    ) -> Data {
        var payload = Data()
        payload.append(version)
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(contentsOf: trackID.bigEndianBytes)
        payload.append(contentsOf: UInt32(0b00_00_00).bigEndianBytes)
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            if version == 1 {
                payload.append(contentsOf: entry.time.bigEndianBytes)
                payload.append(contentsOf: entry.moofOffset.bigEndianBytes)
            } else {
                payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.time).bigEndianBytes)
                payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.moofOffset).bigEndianBytes)
            }
            payload.append(UInt8(truncatingIfNeeded: entry.trafNumber))
            payload.append(UInt8(truncatingIfNeeded: entry.trunNumber))
            payload.append(UInt8(truncatingIfNeeded: entry.sampleNumber))
        }
        return makeBox(type: "tfra", payload: payload)
    }

    private func makeBox(type: String, payload: Data) -> Data {
        var data = Data()
        data.append(contentsOf: UInt32(8 + payload.count).bigEndianBytes)
        data.append(contentsOf: type.utf8)
        data.append(payload)
        return data
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}

private extension UInt64 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
