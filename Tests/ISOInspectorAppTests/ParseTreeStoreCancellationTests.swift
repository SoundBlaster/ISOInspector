#if canImport(Combine)
    import Combine
    import Foundation
    import XCTest

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    final class ParseTreeStoreCancellationTests: XCTestCase {
        @MainActor func testStreamCancellationErrorFinishesInsteadOfFailing() {
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            let finished = expectation(description: "Cancelled stream finishes the store")
            var subscriptions: Set<AnyCancellable> = []
            store.statePublisher.dropFirst().sink { state in
                if state == .finished { finished.fulfill() }
            }.store(in: &subscriptions)

            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in stream }),
                reader: InMemoryRandomAccessReader(data: Data()))
            continuation.finish(throwing: CancellationError())
            wait(for: [finished], timeout: 3)

            XCTAssertEqual(store.state, .finished)
            store.shutdown()
        }

        @MainActor func testExplicitCancelFinishesStoreAndNotifiesStreamCancellation() throws {
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            defer { continuation.finish() }
            let cancellationNotified = expectation(description: "Stream cancellation notified")
            continuation.onTermination = { termination in
                if case .cancelled = termination { cancellationNotified.fulfill() }
            }
            let header = BoxHeader(
                type: try FourCharCode("free"), totalSize: 8, headerSize: 8,
                payloadRange: 8..<8, range: 0..<8, uuid: nil)
            let start = ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0)
            let consumed = expectation(description: "First event consumed")
            var subscriptions: Set<AnyCancellable> = []
            store.$snapshot.dropFirst().sink { snapshot in
                if snapshot.nodes.first?.header.type.rawValue == "free" { consumed.fulfill() }
            }.store(in: &subscriptions)

            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in stream }),
                reader: InMemoryRandomAccessReader(data: Data(repeating: 0, count: 8)))
            continuation.yield(start)
            wait(for: [consumed], timeout: 3)
            XCTAssertEqual(store.state, .parsing)

            store.cancel()
            wait(for: [cancellationNotified], timeout: 3)
            XCTAssertEqual(store.state, .finished)
            XCTAssertEqual(store.snapshot.nodes.map(\.header.type.rawValue), ["free"])
            guard case .unavailable(.cancelled) = store.detailAccess else {
                return XCTFail("Cancelled parses must not expose a reader")
            }
        }
    }
#endif
