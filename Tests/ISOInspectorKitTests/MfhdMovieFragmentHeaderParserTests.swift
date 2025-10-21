import XCTest
@testable import ISOInspectorKit

final class MfhdMovieFragmentHeaderParserTests: XCTestCase {
    func testParsesSequenceNumber() throws {
        let payload = makeMfhdPayload(sequenceNumber: 0x0102_0304)
        let parsed = try XCTUnwrap(parseMfhd(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["sequence_number"]?.value, "16909060")
        XCTAssertEqual(fields["sequence_number"]?.byteRange, 12..<16)

        let detail = try XCTUnwrap(parsed.movieFragmentHeader)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.sequenceNumber, 0x0102_0304)
    }

    func testReturnsNilWhenPayloadTooSmall() throws {
        let parsed = try parseMfhd(payload: Data([0x00, 0x00, 0x00, 0x00, 0x12]))
        XCTAssertNil(parsed)
    }

    private func parseMfhd(payload: Data) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("mfhd".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("mfhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)

        return try BoxParserRegistry.shared.parse(header: header, reader: reader)
    }

    private func makeMfhdPayload(sequenceNumber: UInt32) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: sequenceNumber.bigEndianBytes)
        return payload
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
