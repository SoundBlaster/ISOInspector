import XCTest
@testable import ISOInspectorKit

final class StscSampleToChunkParserTests: XCTestCase {
    func testParsesSampleToChunkEntries() throws {
        let entries: [(UInt32, UInt32, UInt32)] = [
            (firstChunk: 1, samplesPerChunk: 5, sampleDescriptionIndex: 2),
            (firstChunk: 10, samplesPerChunk: 8, sampleDescriptionIndex: 3)
        ]
        let parsed = try parse(entries: entries)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["entry_count"]?.value, "2")
        XCTAssertEqual(fields["entries[0].first_chunk"]?.value, "1")
        XCTAssertEqual(fields["entries[0].samples_per_chunk"]?.value, "5")
        XCTAssertEqual(fields["entries[0].sample_description_index"]?.value, "2")
        XCTAssertEqual(fields["entries[1].first_chunk"]?.value, "10")
        XCTAssertEqual(fields["entries[1].samples_per_chunk"]?.value, "8")
        XCTAssertEqual(fields["entries[1].sample_description_index"]?.value, "3")

        let detail = try XCTUnwrap(parsed.sampleToChunk)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].firstChunk, 1)
        XCTAssertEqual(detail.entries[0].samplesPerChunk, 5)
        XCTAssertEqual(detail.entries[0].sampleDescriptionIndex, 2)
        XCTAssertEqual(detail.entries[1].firstChunk, 10)
        XCTAssertEqual(detail.entries[1].samplesPerChunk, 8)
        XCTAssertEqual(detail.entries[1].sampleDescriptionIndex, 3)

        XCTAssertEqual(detail.entries[0].byteRange, 16..<28)
        XCTAssertEqual(detail.entries[1].byteRange, 28..<40)
    }

    func testReportsTruncatedEntryWithoutThrowing() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(1).bigEndianBytes) // entry_count
        payload.append(contentsOf: UInt32(4).bigEndianBytes) // first_chunk
        payload.append(contentsOf: UInt32(6).bigEndianBytes) // samples_per_chunk
        // Missing final sample_description_index field

        let parsed = try parse(payload: payload)
        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })

        XCTAssertEqual(fields["entries[0].first_chunk"]?.value, "4")
        XCTAssertEqual(fields["entries[0].samples_per_chunk"]?.value, "6")
        XCTAssertEqual(fields["entries[0].status"]?.value, "truncated")
        XCTAssertEqual(
            fields["entries[0].status"]?.description,
            "Entry truncated before sample_description_index field"
        )
        XCTAssertNil(parsed.sampleToChunk)
    }

    private func parse(entries: [(firstChunk: UInt32, samplesPerChunk: UInt32, sampleDescriptionIndex: UInt32)]) throws -> ParsedBoxPayload {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(contentsOf: entry.firstChunk.bigEndianBytes)
            payload.append(contentsOf: entry.samplesPerChunk.bigEndianBytes)
            payload.append(contentsOf: entry.sampleDescriptionIndex.bigEndianBytes)
        }
        return try parse(payload: payload)
    }

    private func parse(payload: Data) throws -> ParsedBoxPayload {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stsc".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("stsc"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)

        return try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
