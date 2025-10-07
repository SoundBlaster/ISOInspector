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

    func testStructuralRuleReportsHeaderExtendingBeyondReaderLength() throws {
        let header = try makeHeader(type: ContainerTypes.movie, totalSize: 32, headerSize: 8, offset: 0)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: nil
        )
        let reader = InMemoryRandomAccessReader(data: Data(count: 16))

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)

        let vr001Issues = annotated.validationIssues.filter { $0.ruleID == "VR-001" }
        XCTAssertEqual(vr001Issues.count, 1)
        XCTAssertTrue(vr001Issues.first?.message.contains("extends beyond file length") ?? false)
        XCTAssertEqual(vr001Issues.first?.severity, .error)
    }

    func testContainerRuleReportsUnderflowWhenClosingContainerEarly() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let moov = try makeHeader(type: ContainerTypes.movie, totalSize: 28, headerSize: 8, offset: 0)
        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 12, headerSize: 8, offset: 8)

        let validator = BoxValidator()

        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: moov, depth: 0), offset: moov.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 1), offset: trak.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: trak, depth: 1), offset: trak.endOffset),
            reader: reader
        )
        let finishedMoov = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: moov, depth: 0), offset: moov.endOffset),
            reader: reader
        )

        let vr002Issues = finishedMoov.validationIssues.filter { $0.ruleID == "VR-002" }
        XCTAssertEqual(vr002Issues.count, 1)
        XCTAssertTrue(vr002Issues.first?.message.contains("expected to close at offset") ?? false)
        XCTAssertEqual(vr002Issues.first?.severity, .error)
    }

    func testContainerRuleReportsChildOffsetMismatch() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let moov = try makeHeader(type: ContainerTypes.movie, totalSize: 32, headerSize: 8, offset: 0)
        let misalignedChild = try makeHeader(type: ContainerTypes.track, totalSize: 12, headerSize: 8, offset: 10)

        let validator = BoxValidator()

        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: moov, depth: 0), offset: moov.startOffset),
            reader: reader
        )
        let annotatedChildStart = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: misalignedChild, depth: 1), offset: misalignedChild.startOffset),
            reader: reader
        )

        let vr002Issues = annotatedChildStart.validationIssues.filter { $0.ruleID == "VR-002" }
        XCTAssertEqual(vr002Issues.count, 1)
        XCTAssertTrue(vr002Issues.first?.message.contains("expected child to start at offset") ?? false)
        XCTAssertEqual(vr002Issues.first?.severity, .error)
    }

    func testContainerRuleAllowsPerfectlyConsumedContainer() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let moov = try makeHeader(type: ContainerTypes.movie, totalSize: 28, headerSize: 8, offset: 0)
        let trak = try makeHeader(type: ContainerTypes.track, totalSize: 20, headerSize: 8, offset: 8)
        let tkhd = try makeHeader(type: "tkhd", totalSize: 12, headerSize: 8, offset: 16)

        let validator = BoxValidator()

        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: moov, depth: 0), offset: moov.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: trak, depth: 1), offset: trak.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: tkhd, depth: 2), offset: tkhd.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: tkhd, depth: 2), offset: tkhd.endOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: trak, depth: 1), offset: trak.endOffset),
            reader: reader
        )
        let finishedMoov = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: moov, depth: 0), offset: moov.endOffset),
            reader: reader
        )

        let vr002Issues = finishedMoov.validationIssues.filter { $0.ruleID == "VR-002" }
        XCTAssertTrue(vr002Issues.isEmpty)
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

    private func makeHeader(type: String, totalSize: Int64, headerSize: Int64, offset: Int64) throws -> BoxHeader {
        let fourCC = try FourCharCode(type)
        let payloadRange = (offset + headerSize)..<(offset + totalSize)
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

private enum ContainerTypes {
    static let movie = FourCharContainerCode.moov.rawValue
    static let track = FourCharContainerCode.trak.rawValue
}
