import XCTest

@testable import ISOInspectorKit

final class SaioSampleAuxInfoOffsetsParserTests: XCTestCase {
    func testParsesAuxInfoOffsetsWithAuxType() throws {
        let flags: UInt32 = 0x000001
        let entryCount: UInt32 = 2
        var payload = Data()
        payload.append(0x00)  // version 0 -> 32-bit offsets
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: Data("cenc".utf8))  // aux_info_type
        payload.append(contentsOf: UInt32(2).bigEndianBytes)  // aux_info_type_parameter
        payload.append(contentsOf: entryCount.bigEndianBytes)  // entry_count
        payload.append(contentsOf: UInt32(0x0102_0304).bigEndianBytes)
        payload.append(contentsOf: UInt32(0x0506_0708).bigEndianBytes)

        let parsed = try XCTUnwrap(parseSaio(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000001")
        XCTAssertEqual(fields["entry_count"]?.value, "2")
        XCTAssertEqual(fields["entry_size_bytes"]?.value, "4")
        XCTAssertEqual(fields["aux_info_type"]?.value, "cenc")
        XCTAssertEqual(fields["aux_info_type_parameter"]?.value, "2")

        let payloadStart: Int64 = 8
        let entriesLength: Int64 = Int64(entryCount) * 4
        let entriesRangeStart = payloadStart + Int64(payload.count) - entriesLength
        let entriesRangeEnd = payloadStart + Int64(payload.count)
        let entriesRange = entriesRangeStart..<entriesRangeEnd
        XCTAssertEqual(fields["entries_range"]?.value, String(describing: entriesRange))
        XCTAssertEqual(fields["entries_length"]?.value, String(entriesRange.count))

        let detail = try XCTUnwrap(parsed.sampleAuxInfoOffsets)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, flags)
        XCTAssertEqual(detail.entryCount, 2)
        XCTAssertEqual(detail.auxInfoType?.rawValue, "cenc")
        XCTAssertEqual(detail.auxInfoTypeParameter, 2)
        XCTAssertEqual(detail.entrySize, .fourBytes)
        XCTAssertEqual(detail.entriesRange, entriesRange)
        XCTAssertEqual(detail.entriesByteLength, entriesRange.count)
    }

    private func parseSaio(payload: Data) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data()
        data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
        data.append(contentsOf: Data("saio".utf8))
        data.append(payload)

        let header = BoxHeader(
            type: try FourCharCode("saio"), totalSize: Int64(totalSize), headerSize: 8,
            payloadRange: 8..<Int64(totalSize), range: 0..<Int64(totalSize), uuid: nil)
        let reader = InMemoryRandomAccessReader(data: data)
        return try BoxParserRegistry.shared.parse(header: header, reader: reader)
    }
}

extension UInt32 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }

    fileprivate var bigEndianFlagBytes: [UInt8] {
        let value = self
        return [UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }
}

extension Range where Bound == Int64 { fileprivate var count: Int64 { upperBound - lowerBound } }
