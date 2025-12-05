import XCTest

@testable import ISOInspectorKit

final class TfdtTrackFragmentDecodeTimeParserTests: XCTestCase {
    func testParsesVersion0DecodeTime() throws {
        var payload = Data()
        payload.append(0x00)  // version
        payload.append(contentsOf: [0x00, 0x00, 0x00])  // flags
        payload.append(contentsOf: UInt32(0x0102_0304).bigEndianBytes)

        let parsed = try XCTUnwrap(parseTfdt(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["base_media_decode_time"]?.value, "16909060")
        XCTAssertEqual(fields["base_media_decode_time"]?.byteRange, 12..<16)

        let detail = try XCTUnwrap(parsed.trackFragmentDecodeTime)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.baseMediaDecodeTime, 0x0102_0304)
        XCTAssertFalse(detail.baseMediaDecodeTimeIs64Bit)
    }

    func testParsesVersion1DecodeTime() throws {
        var payload = Data()
        payload.append(0x01)  // version
        payload.append(contentsOf: [0x00, 0x00, 0x00])  // flags
        payload.append(contentsOf: UInt64(0x0102_0304_0506_0708).bigEndianBytes)

        let parsed = try XCTUnwrap(parseTfdt(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "1")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["base_media_decode_time"]?.value, "72623859790382856")
        XCTAssertEqual(fields["base_media_decode_time"]?.byteRange, 12..<20)

        let detail = try XCTUnwrap(parsed.trackFragmentDecodeTime)
        XCTAssertEqual(detail.version, 1)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.baseMediaDecodeTime, 0x0102_0304_0506_0708)
        XCTAssertTrue(detail.baseMediaDecodeTimeIs64Bit)
    }

    func testReturnsNilWhenPayloadTooSmall() throws {
        let parsed = try parseTfdt(payload: Data([0x00, 0x00, 0x00]))
        XCTAssertNil(parsed)
    }

    private func parseTfdt(payload: Data) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("tfdt".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("tfdt"), totalSize: Int64(totalSize), headerSize: 8,
            payloadRange: 8..<Int64(totalSize), range: 0..<Int64(totalSize), uuid: nil)
        let reader = InMemoryRandomAccessReader(data: data)

        return try BoxParserRegistry.shared.parse(header: header, reader: reader)
    }
}

extension UInt32 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}

extension UInt64 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}
