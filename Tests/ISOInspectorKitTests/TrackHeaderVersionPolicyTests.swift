import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct TrackHeaderVersionPolicyTests {
    @Test(arguments: [UInt8(0), 1])
    func supportedVersionsParseWithoutVersionWarning(version: UInt8) throws {
        let (header, reader) = try fixture(version: version)
        let descriptor = try #require(BoxCatalog.shared.descriptor(for: header))
        let event = ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0, metadata: descriptor)

        let parsed = try BoxParserRegistry.shared.parse(header: header, reader: reader)
        let detail = try #require(parsed?.trackHeader)
        #expect(detail.version == version)
        #expect(detail.trackID == 1)
        #expect(detail.durationIs64Bit == (version == 1))
        let annotated = try BoxValidator().annotate(event: event, reader: reader)
        #expect(annotated.validationIssues.filter { $0.ruleID == "VR-003" }.isEmpty)
    }

    @Test(arguments: [UInt8(2), 255])
    func unsupportedVersionIsNotParsedAsVersionZero(version: UInt8) throws {
        let (header, reader) = try fixture(version: version)
        let descriptor = try #require(BoxCatalog.shared.descriptor(for: header))
        let event = ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0, metadata: descriptor)

        let parsed = try BoxParserRegistry.shared.parse(header: header, reader: reader)
        #expect(parsed?.trackHeader == nil)
        let annotated = try BoxValidator().annotate(event: event, reader: reader)
        #expect(annotated.validationIssues.contains { $0.ruleID == "VR-003" && $0.message.contains("version") })
    }

    private func fixture(version: UInt8) throws -> (BoxHeader, InMemoryRandomAccessReader) {
        let bodySize = version == 1 ? 92 : 80
        var data = Data(repeating: 0, count: 12 + bodySize)
        data[8] = version
        data[version == 1 ? 31 : 23] = 1  // track_ID
        let end = Int64(data.count)
        let header = BoxHeader(
            type: try FourCharCode("tkhd"), totalSize: end, headerSize: 8,
            payloadRange: 8..<end, range: 0..<end, uuid: nil)
        return (header, InMemoryRandomAccessReader(data: data))
    }
}
