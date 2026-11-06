import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct TKHDDifferentialTests {
    private struct Reference: Decodable {
        let parsed: [String: Expected]
        let notParsed: [String]
    }

    private struct Expected: Decodable {
        let version: UInt8
        let flags: UInt32
        let creationTime: UInt64
        let modificationTime: UInt64
        let trackID: UInt32
        let duration: UInt64
        let layer: Int16
        let alternateGroup: Int16
        let volume: Double
        let matrix: [Double]
        let width: Double
        let height: Double
    }

    @Test func agreesWithMP4BoxOnFieldsAndIncompleteBoxes() throws {
        let decoder = JSONDecoder()
        let inputs = try decoder.decode([String: String].self, from: resource("tkhd_differential_inputs"))
        let reference = try decoder.decode(Reference.self, from: resource("tkhd_mp4box_2_5_0"))
        #expect(Set(inputs.keys) == Set(reference.parsed.keys).union(reference.notParsed))
        for name in inputs.keys.sorted() {
            let encoded = try #require(inputs[name])
            let data = try #require(Data(base64Encoded: encoded))
            let declaredSize = data.prefix(4).reduce(Int64(0)) { ($0 << 8) | Int64($1) }
            let header = BoxHeader(
                type: try FourCharCode("tkhd"), totalSize: declaredSize, headerSize: 8,
                payloadRange: 8..<declaredSize, range: 0..<declaredSize, uuid: nil)
            let parsed: ParsedBoxPayload?
            do {
                parsed = try BoxParserRegistry.shared.parse(
                    header: header, reader: InMemoryRandomAccessReader(data: data))
            } catch RandomAccessReaderValueDecodingError.truncatedRead(let expected, let actual) {
                #expect(name.hasSuffix("_incomplete"), "Unexpected truncated read for \(name)")
                #expect(reference.notParsed.contains(name), "Fixture \(name)")
                #expect(expected == 4 && actual == 3, "Fixture \(name)")
                continue
            }
            if let expected = reference.parsed[name] {
                let actual = try #require(parsed?.trackHeader, "Fixture \(name)")
                #expect(actual.version == expected.version, "Fixture \(name)")
                #expect(actual.flags == expected.flags, "Fixture \(name)")
                #expect(actual.creationTime == expected.creationTime, "Fixture \(name)")
                #expect(actual.modificationTime == expected.modificationTime, "Fixture \(name)")
                #expect(actual.trackID == expected.trackID, "Fixture \(name)")
                #expect(actual.duration == expected.duration, "Fixture \(name)")
                #expect(actual.layer == expected.layer, "Fixture \(name)")
                #expect(actual.alternateGroup == expected.alternateGroup, "Fixture \(name)")
                #expect(actual.volume == expected.volume, "Fixture \(name)")
                let matrix = actual.matrix
                #expect([matrix.a, matrix.b, matrix.u, matrix.c, matrix.d, matrix.v, matrix.x, matrix.y, matrix.w] == expected.matrix, "Fixture \(name)")
                #expect(actual.width == expected.width, "Fixture \(name)")
                #expect(actual.height == expected.height, "Fixture \(name)")
            } else {
                #expect(reference.notParsed.contains(name), "Fixture \(name)")
                #expect(parsed?.trackHeader == nil, "Fixture \(name)")
            }
        }
    }

    private func resource(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
