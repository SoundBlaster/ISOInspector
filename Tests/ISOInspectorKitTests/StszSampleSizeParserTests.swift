import XCTest

@testable import ISOInspectorKit

final class StszSampleSizeParserTests: XCTestCase {
    func testParsesVariableSampleSizes() throws {
        let entrySizes: [UInt32] = [120, 98, 456]
        let parsed = try parse(sampleSize: 0, entrySizes: entrySizes)

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000000")
        XCTAssertEqual(fields["sample_size"]?.value, "0")
        XCTAssertEqual(fields["sample_count"]?.value, "3")
        XCTAssertEqual(fields["entries[0].size"]?.value, "120")
        XCTAssertEqual(fields["entries[1].size"]?.value, "98")
        XCTAssertEqual(fields["entries[2].size"]?.value, "456")

        let detail = try XCTUnwrap(parsed.sampleSize)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.defaultSampleSize, 0)
        XCTAssertEqual(detail.sampleCount, 3)
        XCTAssertEqual(detail.entries.count, 3)
        XCTAssertEqual(detail.entries[0].size, 120)
        XCTAssertEqual(detail.entries[1].size, 98)
        XCTAssertEqual(detail.entries[2].size, 456)
        XCTAssertEqual(detail.entries[0].byteRange, 20..<24)
        XCTAssertEqual(detail.entries[1].byteRange, 24..<28)
        XCTAssertEqual(detail.entries[2].byteRange, 28..<32)
    }

    func testConstantSampleSizeDoesNotEmitEntries() throws {
        let parsed = try parse(sampleSize: 512, entrySizes: [])

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["sample_size"]?.value, "512")
        XCTAssertEqual(fields["sample_count"]?.value, "0")
        XCTAssertNil(fields["entries[0].size"])

        let detail = try XCTUnwrap(parsed.sampleSize)
        XCTAssertEqual(detail.defaultSampleSize, 512)
        XCTAssertEqual(detail.sampleCount, 0)
        XCTAssertTrue(detail.entries.isEmpty)
    }

    func testReportsTruncatedSampleArray() throws {
        let parsed = try parse(sampleSize: 0, rawEntryBytes: Data(UInt32(111).bigEndianBytes))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["entries[0].size"]?.value, "111")
        XCTAssertEqual(fields["entries[1].status"]?.value, "truncated")
        XCTAssertEqual(
            fields["entries[1].status"]?.description, "Entry truncated before size field completed")
        XCTAssertNil(parsed.sampleSize)
    }

    private func parse(sampleSize: UInt32, entrySizes: [UInt32]) throws -> ParsedBoxPayload {
        var payload = Data()
        payload.append(0x00)  // version
        payload.append(contentsOf: [0x00, 0x00, 0x00])  // flags
        payload.append(contentsOf: sampleSize.bigEndianBytes)
        payload.append(contentsOf: UInt32(entrySizes.count).bigEndianBytes)
        for size in entrySizes { payload.append(contentsOf: size.bigEndianBytes) }
        return try parse(payload: payload)
    }

    private func parse(sampleSize: UInt32, rawEntryBytes: Data) throws -> ParsedBoxPayload {
        var payload = Data()
        payload.append(0x00)
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(contentsOf: sampleSize.bigEndianBytes)
        payload.append(contentsOf: UInt32(2).bigEndianBytes)
        payload.append(rawEntryBytes)
        return try parse(payload: payload)
    }

    private func parse(payload: Data) throws -> ParsedBoxPayload {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stsz".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("stsz"), totalSize: Int64(totalSize), headerSize: 8,
            payloadRange: 8..<Int64(totalSize), range: 0..<Int64(totalSize), uuid: nil)
        let reader = InMemoryRandomAccessReader(data: data)

        return try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
    }
}

extension UInt32 {
    fileprivate var bigEndianBytes: [UInt8] { withUnsafeBytes(of: bigEndian, Array.init) }
}
