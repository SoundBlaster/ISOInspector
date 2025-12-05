import XCTest

@testable import ISOInspectorKit

final class Stz2CompactSampleSizeParserTests: XCTestCase {
    func testParsesFourBitSampleSizes() throws {
        let entrySizes: [UInt8] = [3, 10, 5]
        let parsed = try parse(fieldSize: 4, entrySizes: entrySizes)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["field_size"]?.value, "4")
        XCTAssertEqual(fields["sample_count"]?.value, "3")
        XCTAssertEqual(fields["entries[0].size"]?.value, "3")
        XCTAssertEqual(fields["entries[1].size"]?.value, "10")
        XCTAssertEqual(fields["entries[2].size"]?.value, "5")

        let detail = try XCTUnwrap(parsed.compactSampleSize)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.fieldSize, 4)
        XCTAssertEqual(detail.sampleCount, 3)
        XCTAssertEqual(detail.entries.count, 3)
        XCTAssertEqual(detail.entries[0].size, 3)
        XCTAssertEqual(detail.entries[0].byteRange, 20..<21)
        XCTAssertEqual(detail.entries[1].size, 10)
        XCTAssertEqual(detail.entries[1].byteRange, 20..<21)
        XCTAssertEqual(detail.entries[2].size, 5)
        XCTAssertEqual(detail.entries[2].byteRange, 21..<22)
    }

    func testParsesSixteenBitSampleSizes() throws {
        let entrySizes: [UInt16] = [512, 1024]
        let parsed = try parse(fieldSize: 16, entrySizes: entrySizes)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["field_size"]?.value, "16")
        XCTAssertEqual(fields["entries[0].size"]?.value, "512")
        XCTAssertEqual(fields["entries[1].size"]?.value, "1024")

        let detail = try XCTUnwrap(parsed.compactSampleSize)
        XCTAssertEqual(detail.fieldSize, 16)
        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].byteRange, 20..<22)
        XCTAssertEqual(detail.entries[1].byteRange, 22..<24)
    }

    func testReportsTruncatedEntries() throws {
        let data = Data([0xF0])
        let parsed = try parse(fieldSize: 4, rawEntryBytes: data, sampleCount: 3)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["entries[0].size"]?.value, "15")
        XCTAssertEqual(fields["entries[2].status"]?.value, "truncated")
        XCTAssertEqual(
            fields["entries[2].status"]?.description, "Entry truncated before size field completed")
        XCTAssertNil(parsed.compactSampleSize)
    }

    private func parse(fieldSize: UInt8, entrySizes: [UInt8]) throws -> ParsedBoxPayload {
        var data = Data()
        var packed: UInt8 = 0
        var bitCount: Int = 0
        for size in entrySizes {
            packed <<= fieldSize
            packed |= size & UInt8((1 << fieldSize) - 1)
            bitCount += Int(fieldSize)
            if bitCount >= 8 {
                let shift = bitCount - 8
                data.append(packed >> shift)
                packed &= UInt8((1 << shift) - 1)
                bitCount -= 8
            }
        }
        if bitCount > 0 { data.append(packed << (8 - bitCount)) }
        return try parse(
            fieldSize: fieldSize, rawEntryBytes: data, sampleCount: UInt32(entrySizes.count))
    }

    private func parse(fieldSize: UInt8, entrySizes: [UInt16]) throws -> ParsedBoxPayload {
        var data = Data()
        for size in entrySizes {
            data.append(UInt8((size >> 8) & 0xFF))
            data.append(UInt8(size & 0xFF))
        }
        return try parse(
            fieldSize: fieldSize, rawEntryBytes: data, sampleCount: UInt32(entrySizes.count))
    }

    private func parse(fieldSize: UInt8, rawEntryBytes: Data, sampleCount: UInt32) throws
        -> ParsedBoxPayload
    {
        var payload = Data()
        payload.append(0x00)
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(fieldSize)
        payload.append(contentsOf: sampleCount.bigEndianBytes)
        payload.append(rawEntryBytes)
        return try parse(payload: payload)
    }

    private func parse(payload: Data) throws -> ParsedBoxPayload {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stz2".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("stz2"), totalSize: Int64(totalSize), headerSize: 8,
            payloadRange: 8..<Int64(totalSize), range: 0..<Int64(totalSize), uuid: nil)
        let reader = InMemoryRandomAccessReader(data: data)
        return try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
    }
}

extension UInt32 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}
