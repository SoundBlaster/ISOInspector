#if canImport(Combine)
    import Combine
    import Foundation
    import XCTest

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    final class ParseTreeStoreRaceTests: XCTestCase {
        @MainActor func testOldFailureCannotFailNewParse() {
            assertReplacingParse(oldEnding: .failure)
        }

        @MainActor func testOldCompletionCannotFinishNewParse() {
            assertReplacingParse(oldEnding: .success)
        }

        @MainActor func testCancelledOldStreamCannotAddEventsToNewParse() {
            assertReplacingParse(oldEnding: .cancelled)
        }

        private enum OldEnding { case success, failure, cancelled }
        private enum OldError: Error { case expectedFailure }

        @MainActor private func assertReplacingParse(
            oldEnding: OldEnding, file: StaticString = #filePath, line: UInt = #line
        ) {
            let (oldStream, oldContinuation) = ParsePipeline.EventStream.makeStream()
            let (newStream, newContinuation) = ParsePipeline.EventStream.makeStream()
            defer {
                oldContinuation.finish()
                newContinuation.finish()
            }

            let oldPipeline = ParsePipeline(buildStream: { _, _ in oldStream })
            let newPipeline = ParsePipeline(buildStream: { _, _ in newStream })
            let reader = InMemoryRandomAccessReader(data: Data())
            let store = ParseTreeStore()
            let oldURL = URL(fileURLWithPath: "/tmp/old.mp4")
            let newURL = URL(fileURLWithPath: "/tmp/new.mp4")
            var subscriptions: Set<AnyCancellable> = []

            let oldEventConsumed = expectation(description: "Old event consumed")
            store.$snapshot.dropFirst().sink { snapshot in
                if snapshot.nodes.first?.header.type.rawValue == "old1" { oldEventConsumed.fulfill() }
            }.store(in: &subscriptions)
            store.start(pipeline: oldPipeline, reader: reader, context: .init(source: oldURL))
            oldContinuation.yield(makeStartEvent(type: "old1"))
            wait(for: [oldEventConsumed], timeout: 3)

            // MainActor cannot resume the old consumer until this test yields again.
            switch oldEnding {
            case .success: oldContinuation.finish()
            case .failure: oldContinuation.finish(throwing: OldError.expectedFailure)
            case .cancelled: break
            }
            store.start(pipeline: newPipeline, reader: reader, context: .init(source: newURL))

            if case .cancelled = oldEnding {
                if case .terminated = oldContinuation.yield(makeStartEvent(type: "late")) {} else {
                    XCTFail("The old stream accepted an event after cancellation", file: file, line: line)
                }
                oldContinuation.finish(throwing: OldError.expectedFailure)
            }

            let newEventConsumed = expectation(description: "New event consumed")
            store.$snapshot.dropFirst().sink { snapshot in
                if snapshot.nodes.first?.header.type.rawValue == "new1" { newEventConsumed.fulfill() }
            }.store(in: &subscriptions)
            newContinuation.yield(makeStartEvent(type: "new1"))
            wait(for: [newEventConsumed], timeout: 3)

            XCTAssertEqual(store.state, .parsing, file: file, line: line)
            XCTAssertEqual(store.fileURL, newURL.standardizedFileURL, file: file, line: line)
            XCTAssertEqual(store.snapshot.nodes.map(\.header.type.rawValue), ["new1"], file: file, line: line)

            let newFinished = expectation(description: "New parse finished")
            store.statePublisher.dropFirst().sink { state in
                if state == .finished { newFinished.fulfill() }
            }.store(in: &subscriptions)
            newContinuation.finish()
            wait(for: [newFinished], timeout: 3)
            XCTAssertEqual(store.state, .finished, file: file, line: line)
            XCTAssertEqual(store.snapshot.nodes.map(\.header.type.rawValue), ["new1"], file: file, line: line)
        }

        private func makeStartEvent(type: String) -> ParseEvent {
            let header = BoxHeader(
                type: try! FourCharCode(type), totalSize: 8, headerSize: 8, payloadRange: 8..<8,
                range: 0..<8, uuid: nil)
            return ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0)
        }
    }
#endif
