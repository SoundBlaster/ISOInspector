import XCTest
@testable import ISOInspectorKit

final class ParsePipelineLiveTests: XCTestCase {
    func testLivePipelineEmitsEventsForNestedBoxes() async throws {
        let tkhd = makeBox(type: "tkhd", payload: Data())
        let trak = makeBox(type: ContainerTypes.track, payload: tkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let ftypPayload = Data(repeating: 0, count: 16)
        let ftyp = makeBox(type: "ftyp", payload: ftypPayload)
        let data = ftyp + moov

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        XCTAssertEqual(events.count, 8)
        try assertEvent(events[0], kind: .willStart, type: "ftyp", depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: "ftyp", depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[2], kind: .willStart, type: ContainerTypes.movie, depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[3], kind: .willStart, type: ContainerTypes.track, depth: 1, offset: Int64(ftyp.count + 8))
        try assertEvent(events[4], kind: .willStart, type: "tkhd", depth: 2, offset: Int64(ftyp.count + 16))
        try assertEvent(events[5], kind: .didFinish, type: "tkhd", depth: 2, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[6], kind: .didFinish, type: ContainerTypes.track, depth: 1, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[7], kind: .didFinish, type: ContainerTypes.movie, depth: 0, offset: Int64(ftyp.count + moov.count))
    }

    func testLivePipelineHandlesLargeSizeBoxes() async throws {
        let payload = Data(repeating: 0xFF, count: 12)
        let largeBox = makeBox(type: "mdat", payload: payload, useLargeSize: true)
        let data = largeBox
        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        XCTAssertEqual(events.count, 2)
        try assertEvent(events[0], kind: .willStart, type: "mdat", depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: "mdat", depth: 0, offset: Int64(largeBox.count))
    }

    func testLivePipelinePropagatesHeaderErrors() async {
        var corrupted = Data()
        corrupted.append(contentsOf: UInt32(24).bigEndianBytes)
        corrupted.append(contentsOf: "ftyp".utf8)
        corrupted.append(Data(repeating: 0, count: 4))
        // Missing remaining payload bytes triggers truncated read.
        let reader = InMemoryRandomAccessReader(data: corrupted)
        let pipeline = ParsePipeline.live()

        var iterator = pipeline.events(for: reader).makeAsyncIterator()
        do {
            _ = try await iterator.next()
            XCTFail("Expected stream to throw")
        } catch let error as BoxHeaderDecodingError {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLivePipelineAttachesMetadataForKnownBoxes() async throws {
        let known = makeBox(type: "ftyp", payload: Data(count: 20))
        let unknown = makeBox(type: "zzzz", payload: Data())
        let data = known + unknown

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let startEvents = events.compactMap { event -> ParseEvent? in
            if case .willStartBox = event.kind { return event }
            return nil
        }
        XCTAssertEqual(startEvents.count, 2)

        XCTAssertEqual(startEvents[0].metadata?.name, "File Type And Compatibility")
        XCTAssertNil(startEvents[1].metadata)
        XCTAssertTrue(startEvents[0].validationIssues.isEmpty)
        XCTAssertEqual(startEvents[1].validationIssues.count, 1)
        XCTAssertEqual(startEvents[1].validationIssues.first?.ruleID, "VR-006")
    }

    func testLivePipelineReportsVersionAndFlagMismatchWarnings() async throws {
        let mismatchTkhd = makeBox(
            type: "tkhd",
            payload: Data([0x01, 0x00, 0x00, 0x00]) + Data(repeating: 0, count: 28)
        )
        let trak = makeBox(type: ContainerTypes.track, payload: mismatchTkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let tkhdEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "tkhd"
            }
            return false
        }))

        let mismatches = tkhdEvent.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(mismatches.count, 2)
        XCTAssertTrue(mismatches.allSatisfy { $0.severity == .warning })
        XCTAssertTrue(mismatches.contains(where: { $0.message.contains("version") }))
        XCTAssertTrue(mismatches.contains(where: { $0.message.contains("flags") }))
    }

    func testLivePipelineLeavesMatchingVersionAndFlagsUnchanged() async throws {
        let matchingTkhd = makeBox(
            type: "tkhd",
            payload: Data([0x00, 0x00, 0x00, 0x07]) + Data(repeating: 0, count: 28)
        )
        let trak = makeBox(type: ContainerTypes.track, payload: matchingTkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let tkhdEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "tkhd"
            }
            return false
        }))

        let vr003Issues = tkhdEvent.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertTrue(vr003Issues.isEmpty)
    }

    func testLivePipelineEmitsResearchIssueForUnknownBoxes() async throws {
        let unknown = makeBox(type: "zzzz", payload: Data(count: 4))
        let reader = InMemoryRandomAccessReader(data: unknown)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let unknownEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "zzzz"
            }
            return false
        }))

        let researchIssues = unknownEvent.validationIssues.filter { $0.ruleID == "VR-006" }
        XCTAssertEqual(researchIssues.count, 1)
        XCTAssertEqual(researchIssues.first?.severity, .info)
        XCTAssertTrue(researchIssues.first?.message.contains("zzzz") ?? false)
    }

    func testLivePipelineReportsErrorWhenMediaAppearsBeforeFileType() async throws {
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let mdat = makeBox(type: "mdat", payload: Data(count: 8))
        let reader = InMemoryRandomAccessReader(data: moov + mdat)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let offendingEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == ContainerTypes.movie
            }
            return false
        }))

        let vr004Issues = offendingEvent.validationIssues.filter { $0.ruleID == "VR-004" }
        XCTAssertEqual(vr004Issues.count, 1)
        XCTAssertEqual(vr004Issues.first?.severity, .error)
        XCTAssertTrue(vr004Issues.first?.message.contains("ftyp") ?? false)
    }

    func testLivePipelineWarnsWhenMovieDataPrecedesMovieBox() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let mdat = makeBox(type: "mdat", payload: Data(count: 8))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: ftyp + mdat + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mdatEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "mdat"
            }
            return false
        }))

        let vr005Issues = mdatEvent.validationIssues.filter { $0.ruleID == "VR-005" }
        XCTAssertEqual(vr005Issues.count, 1)
        XCTAssertEqual(vr005Issues.first?.severity, .warning)
        XCTAssertTrue(vr005Issues.first?.message.contains(ContainerTypes.movie) ?? false)
    }

    func testLivePipelineAllowsEarlyMovieDataWhenStreamingLayoutDetected() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let moof = makeBox(type: ContainerTypes.movieFragment, payload: Data())
        let mdat = makeBox(type: "mdat", payload: Data(count: 8))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: ftyp + moof + mdat + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mdatEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "mdat"
            }
            return false
        }))

        let vr005Issues = mdatEvent.validationIssues.filter { $0.ruleID == "VR-005" }
        XCTAssertTrue(vr005Issues.isEmpty)
    }

    private func collectEvents(from stream: ParsePipeline.EventStream) async throws -> [ParseEvent] {
        var result: [ParseEvent] = []
        for try await event in stream {
            result.append(event)
        }
        return result
    }

    private enum EventKind {
        case willStart
        case didFinish
    }

    private func assertEvent(
        _ event: ParseEvent,
        kind expectedKind: EventKind,
        type expectedType: String,
        depth expectedDepth: Int,
        offset expectedOffset: Int64
    ) throws {
        let type = try FourCharCode(expectedType)
        switch (event.kind, expectedKind) {
        case let (.willStartBox(header, depth), .willStart):
            XCTAssertEqual(header.type, type)
            XCTAssertEqual(depth, expectedDepth)
            XCTAssertEqual(event.offset, expectedOffset)
        case let (.didFinishBox(header, depth), .didFinish):
            XCTAssertEqual(header.type, type)
            XCTAssertEqual(depth, expectedDepth)
            XCTAssertEqual(event.offset, expectedOffset)
        default:
            XCTFail("Unexpected event kind: \(event.kind)")
        }
    }

    private func makeBox(type: String, payload: Data, useLargeSize: Bool = false) -> Data {
        precondition(type.utf8.count == 4, "Box type must be four characters")
        var data = Data()
        let payloadCount = payload.count
        if useLargeSize {
            let headerSize = 16
            let totalSize = headerSize + payloadCount
            data.append(contentsOf: UInt32(1).bigEndianBytes)
            data.append(contentsOf: type.utf8)
            data.append(contentsOf: UInt64(totalSize).bigEndianBytes)
        } else {
            let totalSize = 8 + payloadCount
            data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
            data.append(contentsOf: type.utf8)
        }
        data.append(payload)
        return data
    }
}

private enum ContainerTypes {
    static let movie = FourCharContainerCode.movie.rawValue
    static let track = FourCharContainerCode.track.rawValue
    static let movieFragment = FourCharContainerCode.movieFragment.rawValue
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
