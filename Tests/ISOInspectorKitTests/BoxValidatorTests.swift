import XCTest
@testable import ISOInspectorKit

final class BoxValidatorTests: XCTestCase {
    func testVersionFlagsRuleProducesNoIssuesWhenExpectationsMatch() throws {
        let header = try makeHeader(type: "tkhd", payloadSize: 32)
        let descriptor = makeDescriptor(for: header, version: 0, flags: 0x000007)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor
        )
        var data = Data(repeating: 0, count: Int(header.headerSize))
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x07])
        data.append(Data(repeating: 0, count: 28))
        let reader = InMemoryRandomAccessReader(data: data)

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)

        let vr003Issues = annotated.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertTrue(vr003Issues.isEmpty)
    }

    func testVersionFlagsRuleReportsMismatchedVersionAndFlags() throws {
        let header = try makeHeader(type: "tkhd", payloadSize: 32)
        let descriptor = makeDescriptor(for: header, version: 0, flags: 0x000007)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor
        )
        var data = Data(repeating: 0, count: Int(header.headerSize))
        data.append(contentsOf: [0x01, 0x00, 0x00, 0x00])
        data.append(Data(repeating: 0, count: 28))
        let reader = InMemoryRandomAccessReader(data: data)

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)

        let vr003Issues = annotated.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(vr003Issues.count, 2)
        XCTAssertTrue(vr003Issues.contains(where: { $0.message.contains("version") }))
        XCTAssertTrue(vr003Issues.contains(where: { $0.message.contains("flags") }))
        XCTAssertTrue(vr003Issues.allSatisfy { $0.severity == .warning })
    }

    func testVersionFlagsRuleWarnsWhenPayloadTooSmall() throws {
        let header = try makeHeader(type: "tkhd", payloadSize: 2)
        let descriptor = makeDescriptor(for: header, version: 0, flags: 0x000007)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor
        )
        let data = Data(repeating: 0, count: Int(header.totalSize))
        let reader = InMemoryRandomAccessReader(data: data)

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)

        let vr003Issues = annotated.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(vr003Issues.count, 1)
        XCTAssertTrue(vr003Issues.first?.message.contains("payload too small") ?? false)
        XCTAssertEqual(vr003Issues.first?.severity, .warning)
    }

    func testVersionFlagsRuleWarnsWhenReadReturnsTruncatedData() throws {
        let header = try makeHeader(type: "tkhd", payloadSize: 32)
        let descriptor = makeDescriptor(for: header, version: 0, flags: 0x000007)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor
        )
        var data = Data(repeating: 0, count: Int(header.headerSize))
        data.append(contentsOf: [0x00, 0x00])
        let reader = InMemoryRandomAccessReader(data: data)

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)

        let vr003Issues = annotated.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(vr003Issues.count, 1)
        XCTAssertTrue(vr003Issues.first?.message.contains("payload truncated") ?? false)
        XCTAssertEqual(vr003Issues.first?.severity, .warning)
    }

    private func makeHeader(type: String, payloadSize: Int, offset: Int64 = 0) throws -> BoxHeader {
        let fourCC = try FourCharCode(type)
        let headerSize: Int64 = 8
        let totalSize = headerSize + Int64(payloadSize)
        let payloadRange = (offset + headerSize)..<(offset + headerSize + Int64(payloadSize))
        let range = offset..<(offset + totalSize)
        return BoxHeader(
            type: fourCC,
            totalSize: totalSize,
            headerSize: headerSize,
            payloadRange: payloadRange,
            range: range,
            uuid: nil
        )
    }

    private func makeDescriptor(for header: BoxHeader, version: Int?, flags: UInt32?) -> BoxDescriptor {
        let identifier = BoxDescriptor.Identifier(type: header.type, extendedType: nil)
        return BoxDescriptor(
            identifier: identifier,
            name: "Test",
            summary: "Test descriptor",
            specification: nil,
            version: version,
            flags: flags
        )
    }
}
