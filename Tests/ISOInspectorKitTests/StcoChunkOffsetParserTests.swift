import XCTest

@testable import ISOInspectorKit

final class StcoChunkOffsetParserTests: XCTestCase {
    func testParses32BitChunkOffsets() throws {
        let offsets: [UInt32] = [128, 2048, 1_048_576]
        let parsed = try parseChunkOffsets(fourCC: "stco", offsets: offsets.map(UInt64.init))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["entry_count"]?.value, "3")
        XCTAssertEqual(fields["entries[0].chunk_offset"]?.value, "128 (0x00000080)")
        XCTAssertEqual(fields["entries[1].chunk_offset"]?.value, "2048 (0x00000800)")
        XCTAssertEqual(fields["entries[2].chunk_offset"]?.value, "1048576 (0x00100000)")

        let detail = try XCTUnwrap(parsed.chunkOffset)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.entryCount, 3)
        XCTAssertEqual(detail.width, .bits32)
        XCTAssertEqual(detail.entries.count, 3)
        XCTAssertEqual(detail.entries.map(\.offset), [128, 2048, 1_048_576])
        XCTAssertEqual(detail.entries[0].byteRange, 16..<20)
        XCTAssertEqual(detail.entries[1].byteRange, 20..<24)
        XCTAssertEqual(detail.entries[2].byteRange, 24..<28)
    }

    func testParses64BitChunkOffsets() throws {
        let offsets: [UInt64] = [65_536, 4_294_967_295, 1_099_511_627_776]
        let parsed = try parseChunkOffsets(fourCC: "co64", offsets: offsets)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["entry_count"]?.value, "3")
        XCTAssertEqual(fields["entries[0].chunk_offset"]?.value, "65536 (0x0000000000010000)")
        XCTAssertEqual(fields["entries[1].chunk_offset"]?.value, "4294967295 (0x00000000FFFFFFFF)")
        XCTAssertEqual(
            fields["entries[2].chunk_offset"]?.value, "1099511627776 (0x0000010000000000)")

        let detail = try XCTUnwrap(parsed.chunkOffset)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.entryCount, 3)
        XCTAssertEqual(detail.width, .bits64)
        XCTAssertEqual(detail.entries.count, 3)
        XCTAssertEqual(detail.entries.map(\.offset), offsets)
        XCTAssertEqual(detail.entries[0].byteRange, 16..<24)
        XCTAssertEqual(detail.entries[1].byteRange, 24..<32)
        XCTAssertEqual(detail.entries[2].byteRange, 32..<40)
    }

    func testReportsTruncatedChunkOffsetTable() throws {
        var payload = Data()
        payload.append(0x00)  // version
        payload.append(contentsOf: [0x00, 0x00, 0x00])  // flags
        payload.append(contentsOf: UInt32(3).bigEndianBytes)  // entry_count
        payload.append(contentsOf: UInt32(128).bigEndianBytes)  // complete entry 0
        payload.append(0x00)  // truncated entry 1

        let parsed = try parseChunkOffsets(fourCC: "stco", payload: payload)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["entries[0].chunk_offset"]?.value, "128 (0x00000080)")
        XCTAssertEqual(fields["entries[1].status"]?.value, "truncated")
        XCTAssertEqual(
            fields["entries[1].status"]?.description,
            "Entry truncated before chunk offset completed")
        XCTAssertNil(parsed.chunkOffset)
    }

    // MARK: - Helpers

    private func parseChunkOffsets(fourCC: String, offsets: [UInt64]) throws -> ParsedBoxPayload {
        var payload = Data()
        payload.append(0x00)
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(contentsOf: UInt32(offsets.count).bigEndianBytes)
        for offset in offsets {
            if fourCC == "co64" {
                payload.append(contentsOf: offset.bigEndianBytes64)
            } else {
                payload.append(contentsOf: UInt32(offset).bigEndianBytes)
            }
        }
        return try parseChunkOffsets(fourCC: fourCC, payload: payload)
    }

    private func parseChunkOffsets(fourCC: String, payload: Data) throws -> ParsedBoxPayload {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data(fourCC.utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode(fourCC), totalSize: Int64(totalSize), headerSize: 8,
            payloadRange: 8..<Int64(totalSize), range: 0..<Int64(totalSize), uuid: nil)
        let reader = InMemoryRandomAccessReader(data: data)

        return try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
    }
}

extension UInt32 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}

extension UInt64 {
    fileprivate var bigEndianBytes64: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}
