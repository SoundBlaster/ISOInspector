import XCTest
@testable import ISOInspectorKit

final class ParsePipelineLiveTests: XCTestCase {
    func testLivePipelineEmitsEventsForNestedBoxes() async throws {
        let tkhd = makeBox(type: "tkhd", payload: Data())
        let trak = makeBox(type: "trak", payload: tkhd)
        let moov = makeBox(type: "moov", payload: trak)
        let ftypPayload = Data(repeating: 0, count: 16)
        let ftyp = makeBox(type: "ftyp", payload: ftypPayload)
        let data = ftyp + moov

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        XCTAssertEqual(events.count, 8)
        try assertEvent(events[0], kind: .willStart, type: "ftyp", depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: "ftyp", depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[2], kind: .willStart, type: "moov", depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[3], kind: .willStart, type: "trak", depth: 1, offset: Int64(ftyp.count + 8))
        try assertEvent(events[4], kind: .willStart, type: "tkhd", depth: 2, offset: Int64(ftyp.count + 16))
        try assertEvent(events[5], kind: .didFinish, type: "tkhd", depth: 2, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[6], kind: .didFinish, type: "trak", depth: 1, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[7], kind: .didFinish, type: "moov", depth: 0, offset: Int64(ftyp.count + moov.count))
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

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
