import XCTest
@testable import ISOInspectorKit

final class StsdSampleDescriptionParserTests: XCTestCase {
    func testParsesVisualAndAudioSampleEntries() throws {
        let visualEntry = makeVisualSampleEntry(width: 1920, height: 1080, dataReferenceIndex: 1)
        let audioEntry = makeAudioSampleEntry(channelCount: 2, sampleSize: 16, sampleRate: 48_000, dataReferenceIndex: 2)
        let payload = makeStsdPayload(entries: [visualEntry, audioEntry])
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stsd".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("stsd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
        let fieldsByName = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })

        XCTAssertEqual(fieldsByName["entry_count"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[0].format"]?.value, "avc1")
        XCTAssertEqual(fieldsByName["entries[0].byte_length"]?.value, "86")
        XCTAssertEqual(fieldsByName["entries[0].data_reference_index"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].width"]?.value, "1920")
        XCTAssertEqual(fieldsByName["entries[0].height"]?.value, "1080")

        XCTAssertEqual(fieldsByName["entries[1].format"]?.value, "mp4a")
        XCTAssertEqual(fieldsByName["entries[1].byte_length"]?.value, "36")
        XCTAssertEqual(fieldsByName["entries[1].data_reference_index"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[1].channelcount"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[1].samplesize"]?.value, "16")
        XCTAssertEqual(fieldsByName["entries[1].samplerate"]?.value, "48000")
    }

    private func makeStsdPayload(entries: [Data]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(entry)
        }
        return payload
    }

    private func makeVisualSampleEntry(width: UInt16, height: UInt16, dataReferenceIndex: UInt16) -> Data {
        var entry = Data()
        entry.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // size placeholder
        entry.append(contentsOf: Data("avc1".utf8))
        entry.append(Data(repeating: 0, count: 6)) // reserved
        entry.append(contentsOf: dataReferenceIndex.bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes) // pre_defined
        entry.append(contentsOf: UInt16(0).bigEndianBytes) // reserved
        entry.append(Data(repeating: 0, count: 12)) // pre_defined[3]
        entry.append(contentsOf: width.bigEndianBytes)
        entry.append(contentsOf: height.bigEndianBytes)
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes) // horizresolution
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes) // vertresolution
        entry.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        entry.append(contentsOf: UInt16(1).bigEndianBytes) // frame_count
        var compressorName = Data([3])
        compressorName.append(contentsOf: Data("AVC".utf8))
        compressorName.append(Data(repeating: 0, count: 32 - compressorName.count))
        entry.append(compressorName)
        entry.append(contentsOf: UInt16(0x0018).bigEndianBytes) // depth
        entry.append(contentsOf: UInt16(0xFFFF).bigEndianBytes) // pre_defined

        let size = UInt32(entry.count)
        entry.replaceSubrange(0..<4, with: size.bigEndianBytes)
        return entry
    }

    private func makeAudioSampleEntry(
        channelCount: UInt16,
        sampleSize: UInt16,
        sampleRate: UInt32,
        dataReferenceIndex: UInt16
    ) -> Data {
        var entry = Data()
        entry.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // size placeholder
        entry.append(contentsOf: Data("mp4a".utf8))
        entry.append(Data(repeating: 0, count: 6))
        entry.append(contentsOf: dataReferenceIndex.bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: channelCount.bigEndianBytes)
        entry.append(contentsOf: sampleSize.bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes)
        entry.append(contentsOf: UInt32(sampleRate << 16).bigEndianBytes)

        let size = UInt32(entry.count)
        entry.replaceSubrange(0..<4, with: size.bigEndianBytes)
        return entry
    }
}

private extension UInt16 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
