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
                onEvent: { _ in },
                onFinish: {}
            )
        ) { error in
            XCTAssertTrue(error is BoxHeaderDecodingError)
        }
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

    func testWalkerThrowsWhenExceedingMaximumDepth() {
        let limit = ParserLimits.maximumBoxNestingDepth
        let leaf = makeBox(type: "free", payload: Data(count: 1))
        let trackType = FourCharContainerCode.trak.rawValue

        var nested = leaf
        for _ in 0..<(limit + 1) {
            nested = makeBox(type: trackType, payload: nested)
        }

        let root = makeBox(type: FourCharContainerCode.moov.rawValue, payload: nested)
        let reader = InMemoryRandomAccessReader(data: root)
        let walker = StreamingBoxWalker()

        XCTAssertThrowsError(
            try walker.walk(
                reader: reader,
                cancellationCheck: {},
                onEvent: { _ in },
                onFinish: {}
            )
        ) { error in
            guard case let StreamingBoxWalkerError.exceededMaximumDepth(header, depth, limitReached) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(limitReached, ParserLimits.maximumBoxNestingDepth)
            XCTAssertEqual(depth, ParserLimits.maximumBoxNestingDepth + 1)
            XCTAssertEqual(header.type.rawValue, trackType)
        }
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

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
