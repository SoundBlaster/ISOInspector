#if canImport(Combine)
    import Combine
    import Foundation
    import XCTest

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    final class ParseTreeSessionStateTests: XCTestCase {
        @MainActor func testStateNotificationsMatchTheStoreAndItsReader() {
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            defer {
                continuation.finish()
                store.shutdown()
            }
            let parsing = expectation(description: "Parsing state and reader are visible")
            let finished = expectation(description: "Finished state and reader are visible")
            var subscriptions: Set<AnyCancellable> = []
            store.statePublisher.dropFirst().sink { nextState in
                switch nextState {
                case .parsing:
                    XCTAssertEqual(store.state, .parsing)
                    guard case .available = store.detailAccess else {
                        return XCTFail("Parsing must expose its reader")
                    }
                    parsing.fulfill()
                case .finished:
                    XCTAssertEqual(store.state, .finished)
                    guard case .available = store.detailAccess else {
                        return XCTFail("Finished parses must retain their reader")
                    }
                    finished.fulfill()
                default: break
                }
            }.store(in: &subscriptions)

            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in stream }),
                reader: InMemoryRandomAccessReader(data: Data([1, 2, 3])))
            wait(for: [parsing], timeout: 3)
            continuation.finish()
            wait(for: [finished], timeout: 3)
        }

        @MainActor func testCancellationDuringParsingNotificationCancelsTheInstalledSession() {
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            defer { continuation.finish(); store.shutdown() }
            let terminated = expectation(description: "Reentrantly cancelled stream terminates")
            continuation.onTermination = { termination in
                if case .cancelled = termination { terminated.fulfill() }
            }
            var subscriptions: Set<AnyCancellable> = []
            store.statePublisher.dropFirst().sink { state in
                if state == .parsing { store.cancel() }
            }.store(in: &subscriptions)

            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in stream }),
                reader: InMemoryRandomAccessReader(data: Data([1])))

            XCTAssertEqual(store.state, .finished)
            guard case .unavailable(.cancelled) = store.detailAccess else {
                return XCTFail("Reentrant cancellation must remove the active reader")
            }
            wait(for: [terminated], timeout: 3)
        }

        @MainActor func testIdleCancelledAndMirroredStatesAreDistinct() {
            let store = ParseTreeStore()
            guard case .unavailable(.noDocument) = store.detailAccess else {
                return XCTFail("An idle store must report that there is no document")
            }
            store.cancel()
            guard case .unavailable(.cancelled) = store.detailAccess else {
                return XCTFail("Cancellation must have an explicit reason")
            }
            store.replaceContents(snapshot: .empty, state: .parsing, fileURL: nil, issues: [])
            XCTAssertEqual(store.state, .parsing)
            guard case .unavailable(.mirroredSnapshot) = store.detailAccess else {
                return XCTFail("A mirrored snapshot is not a locally owned parse")
            }
            store.shutdown()
            guard case .unavailable(.noDocument) = store.detailAccess else {
                return XCTFail("Shutdown must return the store to idle")
            }
        }

        @MainActor func testFailedParseRetainsItsReader() {
            enum TestError: Error { case failure }
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            defer { continuation.finish(); store.shutdown() }
            let failed = expectation(description: "Parse failure is published with its reader")
            var subscriptions: Set<AnyCancellable> = []
            store.statePublisher.dropFirst().sink { state in
                if case .failed = state {
                    XCTAssertEqual(store.state, state)
                    guard case .available = store.detailAccess else {
                        return XCTFail("A failed parse must retain its reader")
                    }
                    failed.fulfill()
                }
            }.store(in: &subscriptions)
            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in stream }),
                reader: InMemoryRandomAccessReader(data: Data([1])))
            continuation.finish(throwing: TestError.failure)
            wait(for: [failed], timeout: 3)
        }
    }
#endif
