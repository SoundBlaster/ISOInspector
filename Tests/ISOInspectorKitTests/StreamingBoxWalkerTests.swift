import XCTest
@testable import ISOInspectorKit

final class StreamingBoxWalkerTests: XCTestCase {
    func testWalkerEmitsEventsForNestedBoxes() throws {
        let tkhd = makeBox(type: "tkhd", payload: Data())
        let trakType = FourCharContainerCode.trak.rawValue
        let moovType = FourCharContainerCode.moov.rawValue
        let trak = makeBox(type: trakType, payload: tkhd)
        let moov = makeBox(type: moovType, payload: trak)
        let ftypPayload = Data(repeating: 0, count: 16)
        let ftyp = makeBox(type: "ftyp", payload: ftypPayload)
        let data = ftyp + moov

        let reader = InMemoryRandomAccessReader(data: data)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var finished = false
        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            onEvent: { event in
                events.append(event)
            },
            onFinish: {
                finished = true
            }
        )

        XCTAssertTrue(finished)
        XCTAssertEqual(events.count, 8)
        try assertEvent(events[0], kind: .willStart, type: "ftyp", depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: "ftyp", depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[2], kind: .willStart, type: moovType, depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[3], kind: .willStart, type: trakType, depth: 1, offset: Int64(ftyp.count + 8))
        try assertEvent(events[4], kind: .willStart, type: "tkhd", depth: 2, offset: Int64(ftyp.count + 16))
        try assertEvent(events[5], kind: .didFinish, type: "tkhd", depth: 2, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[6], kind: .didFinish, type: trakType, depth: 1, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[7], kind: .didFinish, type: moovType, depth: 0, offset: Int64(ftyp.count + moov.count))
    }

    func testWalkerHandlesLargeSizeBoxes() throws {
        let payload = Data(repeating: 0xFF, count: 12)
        let mediaType = MediaAndIndexBoxCode.mediaData.rawValue
        let largeBox = makeBox(type: mediaType, payload: payload, useLargeSize: true)
        let reader = InMemoryRandomAccessReader(data: largeBox)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var finished = false
        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            onEvent: { event in
                events.append(event)
            },
            onFinish: {
                finished = true
            }
        )

        XCTAssertTrue(finished)
        XCTAssertEqual(events.count, 2)
        try assertEvent(events[0], kind: .willStart, type: mediaType, depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: mediaType, depth: 0, offset: Int64(largeBox.count))
    }

    func testWalkerPropagatesHeaderErrors() {
        var corrupted = Data()
        corrupted.append(contentsOf: UInt32(24).bigEndianBytes)
        corrupted.append(contentsOf: "ftyp".utf8)
        corrupted.append(Data(repeating: 0, count: 4))
        let reader = InMemoryRandomAccessReader(data: corrupted)
        let walker = StreamingBoxWalker()

        XCTAssertThrowsError(
            try walker.walk(
                reader: reader,
                cancellationCheck: {},
                options: .strict,
                onEvent: { _ in },
                onFinish: {}
            )
        ) { error in
            XCTAssertTrue(error is BoxHeaderDecodingError)
        }
    }

    func testWalkerRecoversFromHeaderErrorsInTolerantMode() throws {
        var corrupted = Data()
        corrupted.append(contentsOf: UInt16(1).bigEndianBytes)
        let reader = InMemoryRandomAccessReader(data: corrupted)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var recordedIssues: [ParseIssue] = []
        var finished = false

        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            options: .tolerant,
            onEvent: { event in
                events.append(event)
            },
            onIssue: { issue, _ in
                recordedIssues.append(issue)
            },
            onFinish: {
                finished = true
            }
        )

        XCTAssertTrue(finished)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(recordedIssues.count, 1)
        let issue = try XCTUnwrap(recordedIssues.first)
        XCTAssertEqual(issue.severity, .error)
        XCTAssertEqual(issue.code, "header.truncated_field")
        XCTAssertEqual(issue.affectedNodeIDs, [])
        let range = try XCTUnwrap(issue.byteRange)
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertGreaterThan(range.upperBound, range.lowerBound)
    }

    func testWalkerClampsTruncatedChildPayloadInTolerantMode() throws {
        let moovType = FourCharContainerCode.moov.rawValue
        var truncatedChild = Data()
        truncatedChild.append(contentsOf: UInt32(32).bigEndianBytes)
        truncatedChild.append(contentsOf: moovType.utf8)
        truncatedChild.append(Data(repeating: 0, count: 4))
        let moov = makeBox(type: moovType, payload: truncatedChild)

        let reader = InMemoryRandomAccessReader(data: moov)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var recordedIssues: [ParseIssue] = []
        var finished = false

        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            options: .tolerant,
            onEvent: { event in
                events.append(event)
            },
            onIssue: { issue, _ in
                recordedIssues.append(issue)
            },
            onFinish: {
                finished = true
            }
        )

        XCTAssertTrue(finished)
        XCTAssertEqual(events.count, 2)
        try assertEvent(events[0], kind: .willStart, type: moovType, depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: moovType, depth: 0, offset: Int64(moov.count))

        let issue = try XCTUnwrap(recordedIssues.first)
        XCTAssertEqual(recordedIssues.count, 1)
        XCTAssertEqual(issue.severity, .error)
        XCTAssertEqual(issue.code, "payload.truncated")
        XCTAssertEqual(issue.affectedNodeIDs, [0])
        let range = try XCTUnwrap(issue.byteRange)
        XCTAssertEqual(range.lowerBound, 8)
        XCTAssertEqual(range.upperBound, Int64(moov.count))
    }

    func testWalkerEmitsZeroLengthGuardAfterLimit() throws {
        let containerType = FourCharContainerCode.moov.rawValue
        let zeroLength = makeBox(type: "free", payload: Data())
        let payload = zeroLength + zeroLength + zeroLength
        let container = makeBox(type: containerType, payload: payload)

        let reader = InMemoryRandomAccessReader(data: container)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var issues: [ParseIssue] = []
        var finished = false

        var options = ParsePipeline.Options.tolerant
        options.maxZeroLengthBoxesPerParent = 1

        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            options: options,
            onEvent: { events.append($0) },
            onIssue: { issue, _ in issues.append(issue) },
            onFinish: { finished = true }
        )

        XCTAssertTrue(finished)
        XCTAssertEqual(events.count, 4)
        try assertEvent(events[0], kind: .willStart, type: containerType, depth: 0, offset: 0)
        try assertEvent(events[1], kind: .willStart, type: "free", depth: 1, offset: 8)
        try assertEvent(events[2], kind: .didFinish, type: "free", depth: 1, offset: 16)
        try assertEvent(events[3], kind: .didFinish, type: containerType, depth: 0, offset: Int64(container.count))

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.code, "guard.zero_size_loop")
        XCTAssertEqual(issue.severity, .warning)
        XCTAssertEqual(issue.affectedNodeIDs, [0])
        let range = try XCTUnwrap(issue.byteRange)
        XCTAssertEqual(range.lowerBound, 16)
        XCTAssertEqual(range.upperBound, 24)
    }

    func testWalkerEnforcesRecursionDepthLimit() throws {
        let nested = makeNestedContainer(depth: 3)
        let reader = InMemoryRandomAccessReader(data: nested)
        let walker = StreamingBoxWalker()

        var events: [ParseEvent] = []
        var issues: [ParseIssue] = []
        var finished = false

        var options = ParsePipeline.Options.tolerant
        options.maxTraversalDepth = 2

        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            options: options,
            onEvent: { events.append($0) },
            onIssue: { issue, _ in issues.append(issue) },
            onFinish: { finished = true }
        )

        XCTAssertTrue(finished)
        XCTAssertFalse(events.isEmpty)
        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.code, "guard.recursion_depth_exceeded")
        XCTAssertEqual(issue.severity, .error)
        XCTAssertFalse(issue.affectedNodeIDs.isEmpty)
        XCTAssertEqual(issue.affectedNodeIDs.first, 0)
        let range = try XCTUnwrap(issue.byteRange)
        XCTAssertEqual(range.lowerBound, 16)
        XCTAssertGreaterThan(range.upperBound, range.lowerBound)
    }

    func testWalkerStopsWhenCancellationCheckThrows() {
        let payload = Data(repeating: 0xAA, count: 8)
        let free = makeBox(type: "free", payload: payload)
        let data = free + free
        let reader = InMemoryRandomAccessReader(data: data)
        let walker = StreamingBoxWalker()

        var shouldCancel = false
        var events: [ParseEvent] = []
        var finished = false

        struct TestCancellationError: Error {}

        XCTAssertThrowsError(
            try walker.walk(
                reader: reader,
                cancellationCheck: {
                    if shouldCancel {
                        throw TestCancellationError()
                    }
                },
                onEvent: { event in
                    events.append(event)
                    if events.count == 2 { // After first box start
                        shouldCancel = true
                    }
                },
                onFinish: {
                    finished = true
                }
            )
        ) { error in
            XCTAssertTrue(error is TestCancellationError)
        }

        XCTAssertFalse(finished)
        XCTAssertEqual(events.count, 2)
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
        let type = try IIFourCharCode(expectedType)
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

    private func makeNestedContainer(depth: Int) -> Data {
        precondition(depth >= 1)
        let containerTypes = [
            FourCharContainerCode.moov.rawValue,
            FourCharContainerCode.trak.rawValue,
            FourCharContainerCode.mdia.rawValue,
            FourCharContainerCode.minf.rawValue
        ]

        var payload = makeBox(type: "free", payload: Data())
        for index in 0..<depth {
            let type = containerTypes[index % containerTypes.count]
            payload = makeBox(type: type, payload: payload)
        }
        return payload
    }
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
