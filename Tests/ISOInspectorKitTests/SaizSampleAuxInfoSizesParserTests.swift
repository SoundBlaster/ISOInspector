import XCTest
@testable import ISOInspectorKit

final class SaizSampleAuxInfoSizesParserTests: XCTestCase {
    func testParsesAuxInfoSizesWithExplicitEntries() throws {
        let flags: UInt32 = 0x000001
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: Data("cenc".utf8)) // aux_info_type
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // aux_info_type_parameter
        payload.append(0x00) // default_sample_info_size (use per-entry sizes)
        payload.append(contentsOf: UInt32(3).bigEndianBytes) // entry_count
        payload.append(contentsOf: [UInt8(5), UInt8(6), UInt8(7)])

        let parsed = try XCTUnwrap(parseSaiz(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000001")
        XCTAssertEqual(fields["entry_count"]?.value, "3")
        XCTAssertEqual(fields["default_sample_info_size"]?.value, "0")
        XCTAssertEqual(fields["aux_info_type"]?.value, "cenc")
        XCTAssertEqual(fields["aux_info_type_parameter"]?.value, "0")

        let payloadStart: Int64 = 8
        let variableRange = payloadStart + 17..<payloadStart + Int64(payload.count)
        XCTAssertEqual(fields["variable_sizes_range"]?.value, String(describing: variableRange))
        XCTAssertEqual(fields["variable_sizes_length"]?.value, String(variableRange.count))

        let detail = try XCTUnwrap(parsed.sampleAuxInfoSizes)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, flags)
        XCTAssertEqual(detail.entryCount, 3)
        XCTAssertEqual(detail.defaultSampleInfoSize, 0)
        XCTAssertEqual(detail.auxInfoType?.rawValue, "cenc")
        XCTAssertEqual(detail.auxInfoTypeParameter, 0)
        XCTAssertEqual(detail.variableEntriesRange, variableRange)
        XCTAssertEqual(detail.variableEntriesByteLength, variableRange.count)
        XCTAssertFalse(detail.usesUniformSampleInfoSize)
    }

    private func parseSaiz(payload: Data) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data()
        data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
        data.append(contentsOf: Data("saiz".utf8))
        data.append(payload)

        let header = BoxHeader(
            type: try IIFourCharCode("saiz"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)
        return try BoxParserRegistry.shared.parse(header: header, reader: reader)
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }

    var bigEndianFlagBytes: [UInt8] {
        let value = self
        return [
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ]
    }
}

private extension Range where Bound == Int64 {
    var count: Int64 { upperBound - lowerBound }
}
