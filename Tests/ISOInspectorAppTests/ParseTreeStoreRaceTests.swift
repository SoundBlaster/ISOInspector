#if canImport(Combine)
    import Combine
    import Foundation
    import Synchronization
    import XCTest

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    final class ParseTreeStoreRaceTests: XCTestCase {
        @MainActor func testSupersededPipelineCannotMutateCurrentIssues() throws {
            let contexts = Mutex<[ParseIssueStore]>([])
            let pipeline = ParsePipeline(buildStream: { _, context in
                if let issueStore = context.issueStore { contexts.withLock { $0.append(issueStore) } }
                return AsyncThrowingStream { _ in }
            })
            let store = ParseTreeStore()
            let reader = InMemoryRandomAccessReader(data: Data())
            store.start(pipeline: pipeline, reader: reader)
            store.start(pipeline: pipeline, reader: reader)
            let captured = contexts.withLock { $0 }
            XCTAssertEqual(captured.count, 2)
            let old = try XCTUnwrap(captured.first)
            let current = try XCTUnwrap(captured.last)
            let newIssue = ParseIssue(
                severity: .warning, code: "NEW", message: "new", byteRange: 0..<1,
                affectedNodeIDs: [0])
            let staleIssue = ParseIssue(
                severity: .error, code: "OLD", message: "old", byteRange: 0..<1,
                affectedNodeIDs: [0])
            current.record(newIssue, depth: 1)
            XCTAssertEqual(store.issueStore.issuesSnapshot().map(\.code), ["NEW"])
            old.reset()
            old.record(staleIssue, depth: 9)
            XCTAssertEqual(store.issueStore.issuesSnapshot().map(\.code), ["NEW"])
            XCTAssertEqual(store.issueStore.metricsSnapshot().warningCount, 1)
            XCTAssertEqual(store.issueStore.metricsSnapshot().errorCount, 0)
            store.shutdown()
        }

        @MainActor func testQueuedOldIssueIsDiscardedAfterReplacement() throws {
            let contexts = Mutex<[ParseIssueStore]>([])
            let pipeline = ParsePipeline(buildStream: { _, context in
                if let issueStore = context.issueStore { contexts.withLock { $0.append(issueStore) } }
                return AsyncThrowingStream { _ in }
            })
            let store = ParseTreeStore()
            let reader = InMemoryRandomAccessReader(data: Data())
            store.start(pipeline: pipeline, reader: reader)
            let old = try XCTUnwrap(contexts.withLock { $0.first })
            let queued = DispatchSemaphore(value: 0)
            let staleIssue = ParseIssue(
                severity: .error, code: "OLD", message: "old", byteRange: 0..<1,
                affectedNodeIDs: [0])
            DispatchQueue.global().async {
                old.record(staleIssue, depth: 9)
                queued.signal()
            }
            XCTAssertEqual(queued.wait(timeout: .now() + 3), .success)
            store.start(pipeline: pipeline, reader: reader)
            let queueDrained = expectation(description: "Queued old issue was handled")
            DispatchQueue.main.async { queueDrained.fulfill() }
            wait(for: [queueDrained], timeout: 3)
            XCTAssertEqual(store.issueStore.issuesSnapshot(), [])
            XCTAssertEqual(store.issueStore.metricsSnapshot().totalCount, 0)
            store.shutdown()
        }

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
            let oldTerminated = expectation(description: "Old stream terminated")
            oldContinuation.onTermination = { _ in oldTerminated.fulfill() }
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
            case .cancelled:
                guard case .enqueued = oldContinuation.yield(makeStartEvent(type: "late")) else {
                    XCTFail("Could not queue the old event", file: file, line: line)
                    return
                }
            }
            store.start(pipeline: newPipeline, reader: reader, context: .init(source: newURL))

            wait(for: [oldTerminated], timeout: 3)

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
