import XCTest
@testable import ISOInspectorKit

final class TrunTrackRunParserTests: XCTestCase {
    func testParsesTrackRunWithAllFields() throws {
        let flags: UInt32 = 0x000001 | 0x000004 | 0x000100 | 0x000200 | 0x000400 | 0x000800
        var payload = Data()
        payload.append(0x01) // version 1 to allow signed composition offsets
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: UInt32(2).bigEndianBytes) // sample_count
        payload.append(contentsOf: Int32(256).bigEndianBytes) // data_offset
        payload.append(contentsOf: UInt32(0x1111_2222).bigEndianBytes) // first_sample_flags
        payload.append(contentsOf: UInt32(100).bigEndianBytes) // sample 1 duration
        payload.append(contentsOf: UInt32(1000).bigEndianBytes) // sample 1 size
        payload.append(contentsOf: UInt32(0xAAAA_BBBB).bigEndianBytes) // sample 1 flags
        payload.append(contentsOf: Int32(10).bigEndianBytes) // sample 1 comp offset
        payload.append(contentsOf: UInt32(120).bigEndianBytes) // sample 2 duration
        payload.append(contentsOf: UInt32(1200).bigEndianBytes) // sample 2 size
        payload.append(contentsOf: UInt32(0xCCCC_DDDD).bigEndianBytes) // sample 2 flags
        payload.append(contentsOf: Int32(-5).bigEndianBytes) // sample 2 comp offset

        let environment = BoxParserRegistry.FragmentEnvironment(
            trackID: 1,
            sampleDescriptionIndex: 7,
            defaultSampleDuration: 90,
            defaultSampleSize: 800,
            defaultSampleFlags: 0x0102_0304,
            baseDataOffset: 5000,
            dataCursor: nil,
            nextDecodeTime: 9000,
            baseDecodeTime: 9000,
            baseDecodeTimeIs64Bit: false,
            trackExtendsDefaults: nil,
            trackFragmentHeader: nil,
            trackFragmentDecodeTime: nil,
            runIndex: 0,
            nextSampleNumber: 1
        )

        let parsed = try XCTUnwrap(parseTrun(payload: payload, environment: environment))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "1")
        XCTAssertEqual(fields["flags"]?.value, "0x000F05")
        XCTAssertEqual(fields["sample_count"]?.value, "2")
        XCTAssertEqual(fields["data_offset"]?.value, "256")
        XCTAssertEqual(fields["first_sample_flags"]?.value, "0x11112222")
        XCTAssertEqual(fields["entries[0].sample_duration"]?.value, "100")
        XCTAssertEqual(fields["entries[0].sample_size"]?.value, "1000")
        XCTAssertEqual(fields["entries[0].sample_flags"]?.value, "0xAAAABBBB")
        XCTAssertEqual(fields["entries[0].sample_composition_time_offset"]?.value, "10")
        XCTAssertEqual(fields["entries[1].sample_composition_time_offset"]?.value, "-5")

        let detail = try XCTUnwrap(parsed.trackRun)
        XCTAssertEqual(detail.version, 1)
        XCTAssertEqual(detail.flags, flags)
        XCTAssertEqual(detail.sampleCount, 2)
        XCTAssertEqual(detail.dataOffset, 256)
        XCTAssertEqual(detail.firstSampleFlags, 0x1111_2222)
        XCTAssertEqual(detail.startDataOffset, 5256)
        XCTAssertEqual(detail.endDataOffset, 5256 + 1000 + 1200)
        XCTAssertEqual(detail.totalSampleDuration, 220)
        XCTAssertEqual(detail.totalSampleSize, 2200)
        XCTAssertEqual(detail.startDecodeTime, 9000)
        XCTAssertEqual(detail.endDecodeTime, 9000 + 220)
        XCTAssertEqual(detail.trackID, 1)
        XCTAssertEqual(detail.sampleDescriptionIndex, 7)
        XCTAssertEqual(detail.firstSampleGlobalIndex, 1)

        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].index, 1)
        XCTAssertEqual(detail.entries[0].sampleDuration, 100)
        XCTAssertEqual(detail.entries[0].sampleSize, 1000)
        XCTAssertEqual(detail.entries[0].sampleFlags, 0xAAAA_BBBB)
        XCTAssertEqual(detail.entries[0].sampleCompositionTimeOffset, 10)
        XCTAssertEqual(detail.entries[0].decodeTime, 9000)
        XCTAssertEqual(detail.entries[0].presentationTime, 9010)
        XCTAssertEqual(detail.entries[0].dataOffset, 5256)

        XCTAssertEqual(detail.entries[1].index, 2)
        XCTAssertEqual(detail.entries[1].sampleDuration, 120)
        XCTAssertEqual(detail.entries[1].sampleSize, 1200)
        XCTAssertEqual(detail.entries[1].sampleFlags, 0xCCCC_DDDD)
        XCTAssertEqual(detail.entries[1].sampleCompositionTimeOffset, -5)
        XCTAssertEqual(detail.entries[1].decodeTime, 9100)
        XCTAssertEqual(detail.entries[1].presentationTime, 9095)
        XCTAssertEqual(detail.entries[1].dataOffset, 5256 + 1000)
    }

    func testParsesTrackRunUsingDefaultsWhenOptionalFieldsMissing() throws {
        let flags: UInt32 = 0x000001 | 0x000004
        var payload = Data()
        payload.append(0x00) // version 0
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: UInt32(2).bigEndianBytes) // sample_count
        payload.append(contentsOf: Int32(64).bigEndianBytes) // data_offset
        payload.append(contentsOf: UInt32(0xFFFFFFFF).bigEndianBytes) // first_sample_flags

        let environment = BoxParserRegistry.FragmentEnvironment(
            trackID: 2,
            sampleDescriptionIndex: 9,
            defaultSampleDuration: 200,
            defaultSampleSize: 1500,
            defaultSampleFlags: 0x0102_0304,
            baseDataOffset: 8000,
            dataCursor: nil,
            nextDecodeTime: 5000,
            baseDecodeTime: 5000,
            baseDecodeTimeIs64Bit: false,
            trackExtendsDefaults: nil,
            trackFragmentHeader: ParsedBoxPayload.TrackFragmentHeaderBox(
                version: 0,
                flags: 0,
                trackID: 2,
                baseDataOffset: nil,
                sampleDescriptionIndex: nil,
                defaultSampleDuration: nil,
                defaultSampleSize: nil,
                defaultSampleFlags: nil,
                durationIsEmpty: false,
                defaultBaseIsMoof: true
            ),
            trackFragmentDecodeTime: ParsedBoxPayload.TrackFragmentDecodeTimeBox(
                version: 0,
                flags: 0,
                baseMediaDecodeTime: 5000,
                baseMediaDecodeTimeIs64Bit: false
            ),
            runIndex: 0,
            nextSampleNumber: 1
        )

        let parsed = try XCTUnwrap(parseTrun(payload: payload, environment: environment))

        let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
        XCTAssertEqual(fields["version"]?.value, "0")
        XCTAssertEqual(fields["flags"]?.value, "0x000005")
        XCTAssertEqual(fields["sample_count"]?.value, "2")
        XCTAssertEqual(fields["data_offset"]?.value, "64")
        XCTAssertEqual(fields["first_sample_flags"]?.value, "0xFFFFFFFF")
        XCTAssertNil(fields["entries[0].sample_duration"]) // derived, not stored in payload

        let detail = try XCTUnwrap(parsed.trackRun)
        XCTAssertEqual(detail.sampleCount, 2)
        XCTAssertEqual(detail.dataOffset, 64)
        XCTAssertEqual(detail.firstSampleFlags, 0xFFFF_FFFF)
        XCTAssertEqual(detail.startDataOffset, 8064)
        XCTAssertEqual(detail.totalSampleDuration, 400)
        XCTAssertEqual(detail.totalSampleSize, 3000)
        XCTAssertEqual(detail.startDecodeTime, 5000)
        XCTAssertEqual(detail.endDecodeTime, 5400)
        XCTAssertEqual(detail.trackID, 2)
        XCTAssertEqual(detail.sampleDescriptionIndex, 9)

        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].sampleDuration, 200)
        XCTAssertEqual(detail.entries[0].sampleSize, 1500)
        XCTAssertEqual(detail.entries[0].sampleFlags, 0xFFFF_FFFF)
        XCTAssertEqual(detail.entries[0].decodeTime, 5000)
        XCTAssertEqual(detail.entries[0].dataOffset, 8064)

        XCTAssertEqual(detail.entries[1].sampleDuration, 200)
        XCTAssertEqual(detail.entries[1].sampleSize, 1500)
        XCTAssertEqual(detail.entries[1].sampleFlags, 0x0102_0304)
        XCTAssertEqual(detail.entries[1].decodeTime, 5200)
        XCTAssertEqual(detail.entries[1].dataOffset, 8064 + 1500)
    }

    private func parseTrun(
        payload: Data,
        environment: BoxParserRegistry.FragmentEnvironment
    ) throws -> ParsedBoxPayload? {
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("trun".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try IIFourCharCode("trun"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)

        return try BoxParserRegistry.withFragmentEnvironmentProvider({ _, _ in environment }) {
            try BoxParserRegistry.shared.parse(header: header, reader: reader)
        }
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }

    var bigEndianFlagBytes: [UInt8] {
        [
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}

private extension UInt64 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}

private extension Int32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
