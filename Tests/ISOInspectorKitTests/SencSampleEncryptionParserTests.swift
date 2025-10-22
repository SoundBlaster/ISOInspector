import XCTest
@testable import ISOInspectorKit

final class SencSampleEncryptionParserTests: XCTestCase {
    func testParsesSampleEncryptionWithOverrideAndSubsampleData() throws {
        let flags: UInt32 = 0x000001 | 0x000002
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: [0x01, 0x02, 0x03]) // algorithm ID (24-bit)
        payload.append(0x08) // per-sample IV size
        payload.append(contentsOf: (0x10...0x1F).map(UInt8.init)) // key identifier bytes
        payload.append(contentsOf: UInt32(2).bigEndianBytes) // sample_count
        payload.append(contentsOf: (0x21...0x28).map(UInt8.init)) // sample 0 IV (8 bytes)
        payload.append(contentsOf: UInt16(1).bigEndianBytes) // subsample count
        payload.append(contentsOf: UInt16(0x0003).bigEndianBytes) // bytes of clear data
        payload.append(contentsOf: UInt32(0x0000_0400).bigEndianBytes) // bytes of encrypted data
        payload.append(contentsOf: (0x31...0x38).map(UInt8.init)) // sample 1 IV (8 bytes)
        payload.append(contentsOf: UInt16(2).bigEndianBytes) // subsample count
        payload.append(contentsOf: UInt16(0x0004).bigEndianBytes)
        payload.append(contentsOf: UInt32(0x0000_0500).bigEndianBytes)
        payload.append(contentsOf: UInt16(0x0005).bigEndianBytes)
        payload.append(contentsOf: UInt32(0x0000_0600).bigEndianBytes)

        let parsed = try XCTUnwrap(parseSenc(payload: payload))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000003")
        XCTAssertEqual(fields["override_track_encryption_defaults"]?.value, "true")
        XCTAssertEqual(fields["uses_subsample_encryption"]?.value, "true")
        XCTAssertEqual(fields["algorithm_id"]?.value, "0x010203")
        XCTAssertEqual(fields["per_sample_iv_size"]?.value, "8")
        XCTAssertEqual(fields["sample_count"]?.value, "2")

        let payloadStart: Int64 = 8
        let keyRange = payloadStart + 8..<payloadStart + 24
        XCTAssertEqual(fields["key_identifier_range"]?.value, String(describing: keyRange))

        let sampleInfoRange = payloadStart + 28..<payloadStart + Int64(payload.count)
        XCTAssertEqual(fields["sample_info_length"]?.value, String(sampleInfoRange.count))
        XCTAssertEqual(fields["sample_info_range"]?.value, String(describing: sampleInfoRange))

        let detail = try XCTUnwrap(parsed.sampleEncryption)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, flags)
        XCTAssertEqual(detail.sampleCount, 2)
        XCTAssertEqual(detail.algorithmIdentifier, 0x010203)
        XCTAssertEqual(detail.perSampleIVSize, 8)
        XCTAssertEqual(detail.keyIdentifierRange, keyRange)
        XCTAssertEqual(detail.sampleInfoRange, sampleInfoRange)
        XCTAssertEqual(detail.sampleInfoByteLength, sampleInfoRange.count)
        XCTAssertNil(detail.constantIVRange)
        XCTAssertNil(detail.constantIVByteLength)
        XCTAssertTrue(detail.overrideTrackEncryptionDefaults)
        XCTAssertTrue(detail.usesSubsampleEncryption)
    }

    private func parseSenc(payload: Data) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data()
        data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
        data.append(contentsOf: Data("senc".utf8))
        data.append(payload)

        let header = BoxHeader(
            type: try FourCharCode("senc"),
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

private extension UInt16 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}

private extension Range where Bound == Int64 {
    var count: Int64 { upperBound - lowerBound }
}
