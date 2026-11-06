import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct TrackHeaderFlagsValidationTests {
    @Test(arguments: UInt8(0)...UInt8(7))
    func standardFlagCombinationsDoNotProduceMismatch(flags: UInt8) throws {
        let header = BoxHeader(
            type: try FourCharCode("tkhd"), totalSize: 12, headerSize: 8,
            payloadRange: 8..<12, range: 0..<12, uuid: nil)
        let descriptor = try #require(BoxCatalog.shared.descriptor(for: header))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0), offset: 0, metadata: descriptor)
        let reader = InMemoryRandomAccessReader(data: Data([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, flags]))

        let annotated = try BoxValidator().annotate(event: event, reader: reader)

        #expect(annotated.validationIssues.filter { $0.ruleID == "VR-003" }.isEmpty)
    }
}
