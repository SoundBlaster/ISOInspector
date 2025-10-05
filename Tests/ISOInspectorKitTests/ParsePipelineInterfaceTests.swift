import XCTest
@testable import ISOInspectorKit

final class ParsePipelineInterfaceTests: XCTestCase {
    func testEventStreamDeliversEventsInDeclaredOrder() async throws {
        let reader = InMemoryRandomAccessReader(data: Data())
        let headers: [BoxHeader] = try [
            BoxHeader(
                type: FourCharCode("ftyp"),
                totalSize: Int64(24),
                headerSize: Int64(16),
                payloadRange: Int64(16)..<Int64(24),
                range: Int64(0)..<Int64(24),
                uuid: nil
            ),
            BoxHeader(
                type: FourCharCode("moov"),
                totalSize: Int64(104),
                headerSize: Int64(8),
                payloadRange: Int64(8)..<Int64(104),
                range: Int64(24)..<Int64(128),
                uuid: nil
            )
        ]

        let expectedEvents: [ParseEvent] = headers.enumerated().map { index, header in
            ParseEvent(kind: .willStartBox(header: header, depth: index), offset: header.startOffset)
        }

        let pipeline = ParsePipeline(buildStream: { _ in
            AsyncThrowingStream { continuation in
                for event in expectedEvents {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        })

        var collected: [ParseEvent] = []
        for try await event in pipeline.events(for: reader) {
            collected.append(event)
        }

        XCTAssertEqual(collected, expectedEvents)
    }

    func testEventStreamPropagatesErrors() async {
        struct StubError: Swift.Error, Equatable {}

        let reader = InMemoryRandomAccessReader(data: Data())
        let pipeline = ParsePipeline(buildStream: { _ in
            AsyncThrowingStream<ParseEvent, Error> { continuation in
                continuation.finish(throwing: StubError())
            }
        })

        var iterator = pipeline.events(for: reader).makeAsyncIterator()
        do {
            _ = try await iterator.next()
            XCTFail("Expected stream to throw")
        } catch let error as StubError {
            XCTAssertEqual(error, StubError())
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
