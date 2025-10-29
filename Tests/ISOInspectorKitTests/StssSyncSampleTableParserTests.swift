import XCTest
@testable import ISOInspectorKit

final class StssSyncSampleTableParserTests: XCTestCase {
    func testParsesSyncSampleEntries() throws {
        let parsed = try parse(sampleNumbers: [1, 4, 8])

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["entry_count"]?.value, "3")
        XCTAssertEqual(fields["entries[0].sample_number"]?.value, "1")
        XCTAssertEqual(fields["entries[1].sample_number"]?.value, "4")
        XCTAssertEqual(fields["entries[2].sample_number"]?.value, "8")

        let detail = try XCTUnwrap(parsed.syncSampleTable)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.entryCount, 3)
        XCTAssertEqual(detail.entries.count, 3)
        XCTAssertEqual(detail.entries[0].index, 0)
        XCTAssertEqual(detail.entries[0].sampleNumber, 1)
        XCTAssertEqual(detail.entries[1].sampleNumber, 4)
        XCTAssertEqual(detail.entries[2].sampleNumber, 8)

        XCTAssertEqual(detail.entries[0].byteRange, 16..<20)
        XCTAssertEqual(detail.entries[1].byteRange, 20..<24)
        XCTAssertEqual(detail.entries[2].byteRange, 24..<28)
    }

    func testHandlesTruncatedSampleEntry() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(1).bigEndianBytes) // entry_count
        payload.append(contentsOf: [0x00, 0x00]) // truncated sample_number

        let parsed = try parse(payload: payload)
        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })

        XCTAssertEqual(fields["entry_count"]?.value, "1")
        XCTAssertEqual(fields["entries[0].status"]?.value, "truncated")
        XCTAssertEqual(
            fields["entries[0].status"]?.description,
            "Entry truncated before sample_number field completed"
        )
        XCTAssertNil(parsed.syncSampleTable)
    }

    func testParsesEmptySyncSampleTable() throws {
        let parsed = try parse(sampleNumbers: [])

        let detail = try XCTUnwrap(parsed.syncSampleTable)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.entryCount, 0)
        XCTAssertTrue(detail.entries.isEmpty)
    }

    private func parse(sampleNumbers: [UInt32]) throws -> ParsedBoxPayload {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(sampleNumbers.count).bigEndianBytes)
        for number in sampleNumbers {
            payload.append(contentsOf: number.bigEndianBytes)
        }
        return try parse(payload: payload)
    }

    private func parse(payload: Data) throws -> ParsedBoxPayload {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stss".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try IIFourCharCode("stss"),
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
