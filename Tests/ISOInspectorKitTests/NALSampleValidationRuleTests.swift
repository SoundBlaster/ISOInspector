import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct NALSampleValidationRuleTests {
    @Test(arguments: [("avc1", "avc"), ("hvc1", "hevc")])
    func reportsMultipleBadSamplesAndContinues(format: String, codec: String) throws {
        let data = Data([0xff, 0xff, 0, 0, 0, 4, 1, 2, 3, 4, 0xff, 0xff, 0, 0])
        let issues = try validate(data, format: format, codec: codec, selfContained: true)
        #expect(issues.count == 2)
        #expect(issues[0].message.contains("sample 1"))
        #expect(issues[1].message.contains("sample 3"))
        #expect(issues.allSatisfy { $0.message.contains("65535") })
    }

    @Test func doesNotInterpretExternalReferencesAsLocalBytes() throws {
        let data = Data([0xff, 0xff, 0, 0, 0, 4, 1, 2, 3, 4, 0xff, 0xff, 0, 0])
        #expect(try validate(data, format: "avc1", codec: "avc", selfContained: false).isEmpty)
    }

    private func validate(_ data: Data, format: String, codec: String, selfContained: Bool) throws -> [ValidationIssue] {
        let rule = NALSampleValidationRule()
        let reader = InMemoryRandomAccessReader(data: data)
        func send(_ type: String, _ payload: ParsedBoxPayload? = nil, finish: Bool = false) throws -> [ValidationIssue] {
            let header = BoxHeader(type: try FourCharCode(type), totalSize: 8, headerSize: 8,
                                   payloadRange: 8..<8, range: 0..<8, uuid: nil)
            let kind: ParseEvent.Kind = finish ? .didFinishBox(header: header, depth: 0) : .willStartBox(header: header, depth: 0)
            return try rule.issues(for: ParseEvent(kind: kind, offset: 0, payload: payload), reader: reader)
        }
        _ = try send("trak")
        let ref = ParsedBoxPayload.DataReferenceBox.Entry(
            index: 0, type: try FourCharCode("url "), version: 0, flags: 1,
            location: selfContained ? .selfContained : .url("https://example.com/media"), byteRange: 0..<0, payloadRange: nil)
        _ = try send("dref", ParsedBoxPayload(detail: .dataReference(.init(version: 0, flags: 0, entryCount: 1, entries: [ref]))))
        let fields: [ParsedBoxPayload.Field] = [
            .init(name: "entry_count", value: "1"),
            .init(name: "entries[0].format", value: format),
            .init(name: "entries[0].data_reference_index", value: "1"),
            .init(name: "entries[0].codec.\(codec).nal_unit_length_bytes", value: "2"),
        ]
        _ = try send("stsd", ParsedBoxPayload(fields: fields))
        let mapping = ParsedBoxPayload.SampleToChunkBox.Entry(firstChunk: 1, samplesPerChunk: 1, sampleDescriptionIndex: 1, byteRange: 0..<0)
        _ = try send("stsc", ParsedBoxPayload(detail: .sampleToChunk(.init(version: 0, flags: 0, entries: [mapping]))))
        let sizeEntries = [4, 6, 4].enumerated().map { ParsedBoxPayload.SampleSizeBox.Entry(index: UInt32($0.offset), size: UInt32($0.element), byteRange: 0..<0) }
        _ = try send("stsz", ParsedBoxPayload(detail: .sampleSize(.init(version: 0, flags: 0, defaultSampleSize: 0, sampleCount: 3, entries: sizeEntries))))
        let chunks = [0, 4, 10].enumerated().map { ParsedBoxPayload.ChunkOffsetBox.Entry(index: UInt32($0.offset), offset: UInt64($0.element), byteRange: 0..<0) }
        _ = try send("stco", ParsedBoxPayload(detail: .chunkOffset(.init(version: 0, flags: 0, entryCount: 3, width: .bits32, entries: chunks))))
        return try send("trak", finish: true)
    }
}
