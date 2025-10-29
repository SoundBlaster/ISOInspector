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

    func testContainerRuleReportsChildOverflowBeyondParentPayload() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let moov = try makeHeader(type: ContainerTypes.movie, totalSize: 28, headerSize: 8, offset: 0)
        let oversizedChild = try makeHeader(type: ContainerTypes.track, totalSize: 24, headerSize: 8, offset: 8)

        let validator = BoxValidator()

        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: moov, depth: 0), offset: moov.startOffset),
            reader: reader
        )

        let annotatedChildStart = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: oversizedChild, depth: 1), offset: oversizedChild.startOffset),
            reader: reader
        )

        let vr002Issues = annotatedChildStart.validationIssues.filter { $0.ruleID == "VR-002" }
        XCTAssertEqual(vr002Issues.count, 1)
        XCTAssertEqual(vr002Issues.first?.severity, .error)
        let message = try XCTUnwrap(vr002Issues.first?.message)
        XCTAssertTrue(message.contains("extends beyond parent"))
    }

    func testContainerRuleReportsChildOverlapWithSibling() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let moov = try makeHeader(type: ContainerTypes.movie, totalSize: 40, headerSize: 8, offset: 0)
        let firstChild = try makeHeader(type: ContainerTypes.track, totalSize: 16, headerSize: 8, offset: 8)
        let overlappingChild = try makeHeader(type: ContainerTypes.track, totalSize: 16, headerSize: 8, offset: 20)

        let validator = BoxValidator()

        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: moov, depth: 0), offset: moov.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: firstChild, depth: 1), offset: firstChild.startOffset),
            reader: reader
        )
        _ = validator.annotate(
            event: ParseEvent(kind: .didFinishBox(header: firstChild, depth: 1), offset: firstChild.endOffset),
            reader: reader
        )

        let annotatedChildStart = validator.annotate(
            event: ParseEvent(kind: .willStartBox(header: overlappingChild, depth: 1), offset: overlappingChild.startOffset),
            reader: reader
        )

        let vr002Issues = annotatedChildStart.validationIssues.filter { $0.ruleID == "VR-002" }
        XCTAssertEqual(vr002Issues.count, 1)
        XCTAssertEqual(vr002Issues.first?.severity, .error)
        let message = try XCTUnwrap(vr002Issues.first?.message)
        XCTAssertTrue(message.contains("overlaps previous child"))
    }

    func testFragmentSequenceRuleWarnsOnNonMonotonicSequenceNumbers() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let validator = BoxValidator()

        _ = validator.annotate(event: try makeMfhdEvent(sequenceNumber: 10, offset: 0), reader: reader)
        let second = validator.annotate(event: try makeMfhdEvent(sequenceNumber: 9, offset: 16), reader: reader)

        let issues = second.validationIssues.filter { $0.ruleID == "VR-016" }
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .warning)
        XCTAssertTrue(issues.first?.message.contains("non-monotonic") ?? false)
    }

    func testFragmentSequenceRuleWarnsWhenSequenceNumberIsZero() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let validator = BoxValidator()

        let event = validator.annotate(event: try makeMfhdEvent(sequenceNumber: 0, offset: 0), reader: reader)
        let issues = event.validationIssues.filter { $0.ruleID == "VR-016" }
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .warning)
        XCTAssertTrue(issues.first?.message.contains("zero") ?? false)
    }

    func testFragmentSequenceRulePassesWhenSequenceNumbersIncrease() throws {
        let reader = InMemoryRandomAccessReader(data: Data(count: 64))
        let validator = BoxValidator()

        let first = validator.annotate(event: try makeMfhdEvent(sequenceNumber: 1, offset: 0), reader: reader)
        XCTAssertTrue(first.validationIssues.filter { $0.ruleID == "VR-016" }.isEmpty)

        let second = validator.annotate(event: try makeMfhdEvent(sequenceNumber: 2, offset: 16), reader: reader)
        XCTAssertTrue(second.validationIssues.filter { $0.ruleID == "VR-016" }.isEmpty)
    }

    func testFragmentRunRuleFlagsZeroSampleCount() throws {
        let header = try makeHeader(type: "trun", payloadSize: 0)
        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0,
            sampleCount: 0,
            dataOffset: nil,
            firstSampleFlags: nil,
            entries: [],
            totalSampleDuration: 0,
            totalSampleSize: 0,
            startDecodeTime: nil,
            endDecodeTime: nil,
            startPresentationTime: nil,
            endPresentationTime: nil,
            startDataOffset: nil,
            endDataOffset: nil,
            trackID: 1,
            sampleDescriptionIndex: nil,
            runIndex: 0,
            firstSampleGlobalIndex: 1
        )
        let payload = ParsedBoxPayload(detail: .trackRun(run))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )
        let reader = InMemoryRandomAccessReader(data: Data(count: Int(header.totalSize)))
        let validator = BoxValidator()

        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-017" }
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("track 1"))
        XCTAssertTrue(message.contains("run #0"))
        XCTAssertTrue(message.contains("declares 0 samples"))
    }

    func testFragmentRunRuleFlagsMissingDurations() throws {
        let header = try makeHeader(type: "trun", payloadSize: 0)
        let entry = ParsedBoxPayload.TrackRunBox.Entry(
            index: 1,
            decodeTime: nil,
            presentationTime: nil,
            sampleDuration: nil,
            sampleSize: 1024,
            sampleFlags: 0x0102_0304,
            sampleCompositionTimeOffset: nil,
            dataOffset: 4096,
            byteRange: nil
        )
        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0,
            sampleCount: 1,
            dataOffset: nil,
            firstSampleFlags: nil,
            entries: [entry],
            totalSampleDuration: nil,
            totalSampleSize: 1024,
            startDecodeTime: nil,
            endDecodeTime: nil,
            startPresentationTime: nil,
            endPresentationTime: nil,
            startDataOffset: 4096,
            endDataOffset: 4096 + 1024,
            trackID: 3,
            sampleDescriptionIndex: 4,
            runIndex: 0,
            firstSampleGlobalIndex: 1
        )
        let payload = ParsedBoxPayload(detail: .trackRun(run))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )
        let reader = InMemoryRandomAccessReader(data: Data(count: Int(header.totalSize)))
        let validator = BoxValidator()

        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-017" }
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("track 3"))
        XCTAssertTrue(message.contains("run #0"))
        XCTAssertTrue(message.contains("entries [1]"))
        XCTAssertTrue(message.contains("cannot advance decode timeline"))
    }

    func testFragmentRunRulePassesForWellFormedRun() throws {
        let header = try makeHeader(type: "trun", payloadSize: 0)
        let entry = ParsedBoxPayload.TrackRunBox.Entry(
            index: 1,
            decodeTime: 10,
            presentationTime: 10,
            sampleDuration: 100,
            sampleSize: 512,
            sampleFlags: 0x0,
            sampleCompositionTimeOffset: nil,
            dataOffset: 2048,
            byteRange: nil
        )
        let run = ParsedBoxPayload.TrackRunBox(
            version: 0,
            flags: 0,
            sampleCount: 1,
            dataOffset: nil,
            firstSampleFlags: nil,
            entries: [entry],
            totalSampleDuration: 100,
            totalSampleSize: 512,
            startDecodeTime: 10,
            endDecodeTime: 110,
            startPresentationTime: 10,
            endPresentationTime: 110,
            startDataOffset: 2048,
            endDataOffset: 2560,
            trackID: 5,
            sampleDescriptionIndex: 6,
            runIndex: 0,
            firstSampleGlobalIndex: 1
        )
        let payload = ParsedBoxPayload(detail: .trackRun(run))
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )
        let reader = InMemoryRandomAccessReader(data: Data(count: Int(header.totalSize)))
        let validator = BoxValidator()

        let annotated = validator.annotate(event: event, reader: reader)
        XCTAssertTrue(annotated.validationIssues.filter { $0.ruleID == "VR-017" }.isEmpty)
    }

    func testCodecRuleFlagsAvcSequenceCountMismatch() throws {
        let avcC = makeValidAvcConfigurationBox()
        var mutatedAvcC = avcC
        let spsCountOffset = 8 + 5
        mutatedAvcC[spsCountOffset] = 0xE0 | 0x02

        let stsd = makeStsdBox(entries: [makeVisualSampleEntry(additionalBoxes: [mutatedAvcC])])
        let header = try makeHeader(type: "stsd", payloadSize: stsd.count - 8)
        let reader = InMemoryRandomAccessReader(data: stsd)
        let payload = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-018" }

        XCTAssertEqual(issues.count, 1)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("sequence parameter"))
        XCTAssertTrue(message.contains("declares 2") || message.contains("expected 2"))
    }

    func testCodecRuleFlagsAvcMissingLengthSize() throws {
        let truncatedAvcC = makeBox(type: "avcC", payload: Data([0x01, 0x42, 0x80, 0x1F]))
        let stsd = makeStsdBox(entries: [makeVisualSampleEntry(additionalBoxes: [truncatedAvcC])])
        let header = try makeHeader(type: "stsd", payloadSize: stsd.count - 8)
        let reader = InMemoryRandomAccessReader(data: stsd)
        let payload = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-018" }

        XCTAssertEqual(issues.count, 1)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("length"))
        XCTAssertTrue(message.contains("avcC"))
    }

    func testCodecRuleAcceptsHevcArraysWithArrayCompletenessZero() throws {
        let hevcC = makeValidHevcConfigurationBox(arrayCompleteness: false)
        let stsd = makeStsdBox(entries: [makeVisualSampleEntry(format: "hvc1", additionalBoxes: [hevcC])])
        let header = try makeHeader(type: "stsd", payloadSize: stsd.count - 8)
        let reader = InMemoryRandomAccessReader(data: stsd)
        let payload = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-018" }

        XCTAssertTrue(issues.isEmpty, "Unexpected issues: \(issues)")
    }

    func testCodecRuleFlagsHevcArrayCountMismatch() throws {
        var hevcC = makeValidHevcConfigurationBox()
        let arrayCountOffset = 8 + 22
        hevcC[arrayCountOffset] = hevcC[arrayCountOffset] &+ 1

        let stsd = makeStsdBox(entries: [makeVisualSampleEntry(format: "hvc1", additionalBoxes: [hevcC])])
        let header = try makeHeader(type: "stsd", payloadSize: stsd.count - 8)
        let reader = InMemoryRandomAccessReader(data: stsd)
        let payload = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-018" }

        XCTAssertEqual(issues.count, 1)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("NAL array"))
        XCTAssertTrue(message.contains("declares"))
    }

    func testCodecRuleFlagsHevcMissingLengthSize() throws {
        let payload = Data([UInt8](repeating: 0x00, count: 10))
        let hevcC = makeBox(type: "hvcC", payload: payload)
        let stsd = makeStsdBox(entries: [makeVisualSampleEntry(format: "hvc1", additionalBoxes: [hevcC])])
        let header = try makeHeader(type: "stsd", payloadSize: stsd.count - 8)
        let reader = InMemoryRandomAccessReader(data: stsd)
        let payloadDetail = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payloadDetail
        )

        let validator = BoxValidator()
        let annotated = validator.annotate(event: event, reader: reader)
        let issues = annotated.validationIssues.filter { $0.ruleID == "VR-018" }

        XCTAssertEqual(issues.count, 1)
        let message = try XCTUnwrap(issues.first?.message)
        XCTAssertTrue(message.contains("hvcC"))
        XCTAssertTrue(message.contains("length"))
    }

    private func makeHeader(type: String, payloadSize: Int, offset: Int64 = 0) throws -> BoxHeader {
        let fourCC = try IIFourCharCode(type)
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

    private func makeMfhdEvent(sequenceNumber: UInt32, offset: Int64) throws -> ParseEvent {
        let header = try makeHeader(type: "mfhd", payloadSize: 8, offset: offset)
        let versionRange = header.payloadRange.lowerBound..<(header.payloadRange.lowerBound + 1)
        let flagsRange = (header.payloadRange.lowerBound + 1)..<(header.payloadRange.lowerBound + 4)
        let sequenceRange = (header.payloadRange.lowerBound + 4)..<(header.payloadRange.lowerBound + 8)
        let payload = ParsedBoxPayload(
            fields: [
                ParsedBoxPayload.Field(
                    name: "version",
                    value: "0",
                    description: "Structure version",
                    byteRange: versionRange
                ),
                ParsedBoxPayload.Field(
                    name: "flags",
                    value: "0x000000",
                    description: "Bit flags",
                    byteRange: flagsRange
                ),
                ParsedBoxPayload.Field(
                    name: "sequence_number",
                    value: String(sequenceNumber),
                    description: "Fragment sequence number",
                    byteRange: sequenceRange
                )
            ],
            detail: .movieFragmentHeader(
                ParsedBoxPayload.MovieFragmentHeaderBox(
                    version: 0,
                    flags: 0,
                    sequenceNumber: sequenceNumber
                )
            )
        )
        return ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            payload: payload
        )
    }

    private func makeHeader(type: String, totalSize: Int64, headerSize: Int64, offset: Int64) throws -> BoxHeader {
        let fourCC = try IIFourCharCode(type)
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
            category: nil,
            specification: nil,
            version: version,
            flags: flags
        )
    }

    private func makeStsdBox(entries: [Data]) -> Data {
        var payload = Data([0x00, 0x00, 0x00, 0x00])
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(entry)
        }
        return makeBox(type: "stsd", payload: payload)
    }

    private func makeVisualSampleEntry(
        format: String = "avc1",
        width: UInt16 = 1920,
        height: UInt16 = 1080,
        dataReferenceIndex: UInt16 = 1,
        additionalBoxes: [Data]
    ) -> Data {
        var entry = Data()
        entry.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        entry.append(contentsOf: Data(format.utf8))
        entry.append(Data(repeating: 0, count: 6))
        entry.append(contentsOf: dataReferenceIndex.bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: width.bigEndianBytes)
        entry.append(contentsOf: height.bigEndianBytes)
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes)
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: UInt16(1).bigEndianBytes)
        var compressorName = Data([3])
        compressorName.append(contentsOf: Data("AVC".utf8))
        compressorName.append(Data(repeating: 0, count: 32 - compressorName.count))
        entry.append(compressorName)
        entry.append(contentsOf: UInt16(0x0018).bigEndianBytes)
        entry.append(contentsOf: UInt16(0xFFFF).bigEndianBytes)
        for box in additionalBoxes {
            entry.append(box)
        }
        let size = UInt32(entry.count)
        entry.replaceSubrange(0..<4, with: size.bigEndianBytes)
        return entry
    }

    private func makeValidAvcConfigurationBox() -> Data {
        var payload = Data()
        payload.append(0x01)
        payload.append(0x4D)
        payload.append(0x40)
        payload.append(0x1F)
        payload.append(0xFC | 0x03)
        payload.append(0xE0 | 0x01)
        payload.append(contentsOf: UInt16(4).bigEndianBytes)
        payload.append(contentsOf: [0x67, 0x64, 0x00, 0x1F])
        payload.append(0x01)
        payload.append(contentsOf: UInt16(3).bigEndianBytes)
        payload.append(contentsOf: [0x68, 0xEE, 0x3C])
        return makeBox(type: "avcC", payload: payload)
    }

    private func makeValidHevcConfigurationBox(arrayCompleteness: Bool = true) -> Data {
        var payload = Data()
        payload.append(0x01)
        payload.append(0x60)
        payload.append(contentsOf: UInt32(0).bigEndianBytes)
        payload.append(Data(repeating: 0, count: 6))
        payload.append(0x78)
        payload.append(contentsOf: UInt16(0xF000).bigEndianBytes)
        payload.append(0xFC)
        payload.append(0xFC)
        payload.append(0xF8)
        payload.append(0xF8)
        payload.append(contentsOf: UInt16(0).bigEndianBytes)
        let arrays: [(UInt8, [UInt8])] = [
            (32, [0x40, 0x01]),
            (33, [0x42, 0x01, 0x01]),
            (34, [0x44, 0x01])
        ]
        payload.append(0x03)
        payload.append(UInt8(arrays.count))
        for (nalType, body) in arrays {
            let header = (arrayCompleteness ? UInt8(0x80) : UInt8(0x00)) | nalType
            payload.append(header)
            payload.append(contentsOf: UInt16(1).bigEndianBytes)
            payload.append(contentsOf: UInt16(body.count).bigEndianBytes)
            payload.append(contentsOf: body)
        }
        return makeBox(type: "hvcC", payload: payload)
    }

    private func makeBox(type: String, payload: Data) -> Data {
        var data = Data()
        data.append(contentsOf: UInt32(8 + payload.count).bigEndianBytes)
        data.append(contentsOf: Data(type.utf8))
        data.append(payload)
        return data
    }
}

private enum ContainerTypes {
    static let movie = FourCharContainerCode.moov.rawValue
    static let track = FourCharContainerCode.trak.rawValue
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
