#if canImport(Combine)
import Combine
import Foundation
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

final class ParseTreeStoreTests: XCTestCase {
    func testBridgeDeliversEventsToMultipleSubscribers() {
        let events = makeSampleEvents()
        let bridge = ParsePipelineEventBridge()
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            Task {
                try? await Task.sleep(nanoseconds: 20_000_000)
                for event in events {
                    continuation.yield(event)
                    try? await Task.sleep(nanoseconds: 5_000_000)
                }
                continuation.finish()
            }
        }
        let connection = bridge.makeConnection(stream: stream)

        let expectationA = expectation(description: "Subscriber A completed")
        let expectationB = expectation(description: "Subscriber B completed")
        var receivedA: [ParseEvent] = []
        var receivedB: [ParseEvent] = []
        var cancellables: Set<AnyCancellable> = []

        connection.events
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    expectationA.fulfill()
                } else {
                    XCTFail("Unexpected completion: \(completion)")
                }
            }, receiveValue: { event in
                receivedA.append(event)
            })
            .store(in: &cancellables)

        connection.events
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    expectationB.fulfill()
                } else {
                    XCTFail("Unexpected completion: \(completion)")
                }
            }, receiveValue: { event in
                receivedB.append(event)
            })
            .store(in: &cancellables)

        wait(for: [expectationA, expectationB], timeout: 2.0)

        XCTAssertEqual(receivedA, events)
        XCTAssertEqual(receivedB, events)
    }

    @MainActor
    func testFilteringValidationIssuesUpdatesSnapshot() {
        let filteredIssue = ValidationIssue(ruleID: "VR-006", message: "research", severity: .info)
        let retainedIssue = ValidationIssue(ruleID: "VR-001", message: "structure", severity: .error)
        let events = makeSampleEvents(childIssues: [filteredIssue, retainedIssue])
        let bridge = ParsePipelineEventBridge()
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let connection = bridge.makeConnection(stream: stream)
        let store = ParseTreeStore(bridge: bridge)
        let finished = expectation(description: "Parsing finished")
        var cancellables: Set<AnyCancellable> = []

        store.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        store.bind(to: connection)
        wait(for: [finished], timeout: 2.0)

        XCTAssertEqual(store.snapshot.validationIssues.count, 4)
        XCTAssertEqual(store.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 2)
        XCTAssertEqual(store.snapshot.validationIssues.filter { $0.ruleID == "VR-001" }.count, 2)

        store.setValidationIssueFilter { $0.ruleID != "VR-006" }

        XCTAssertEqual(store.snapshot.validationIssues.count, 2)
        XCTAssertTrue(store.snapshot.validationIssues.allSatisfy { $0.ruleID == "VR-001" })
        let childIssues = store.snapshot.nodes.first?.children.first?.validationIssues ?? []
        XCTAssertEqual(childIssues.count, 1)
        XCTAssertEqual(childIssues.first?.ruleID, "VR-001")

        store.setValidationIssueFilter(nil)

        XCTAssertEqual(store.snapshot.validationIssues.count, 4)
        XCTAssertEqual(store.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 2)
    }

    @MainActor
    func testTreeStoreBuildsHierarchyAndAggregatesIssues() {
        let events = makeSampleEvents(
            childIssues: [ValidationIssue(ruleID: "VR-999", message: "Stub issue", severity: .warning)]
        )
        let bridge = ParsePipelineEventBridge()
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let connection = bridge.makeConnection(stream: stream)
        let store = ParseTreeStore(bridge: bridge)
        let finished = expectation(description: "Parsing finished")
        var cancellables: Set<AnyCancellable> = []

        store.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        store.bind(to: connection)
        wait(for: [finished], timeout: 2.0)

        XCTAssertEqual(store.state, .finished)
        XCTAssertEqual(store.snapshot.validationIssues.count, 2)
        XCTAssertGreaterThan(store.snapshot.lastUpdatedAt.timeIntervalSince1970, Date.distantPast.timeIntervalSince1970)
        guard let root = store.snapshot.nodes.first else {
            XCTFail("Missing root node")
            return
        }
        XCTAssertEqual(root.children.count, 1)
        let child = root.children[0]
        XCTAssertEqual(child.validationIssues.count, 2)
        XCTAssertEqual(child.header.type.rawValue, "test")
    }

    @MainActor
    func testTreeStoreSurfacesFailures() {
        enum SampleError: Error { case failure }
        let events = makeSampleEvents()
        let bridge = ParsePipelineEventBridge()
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for (index, event) in events.enumerated() {
                continuation.yield(event)
                if index == 1 {
                    continuation.finish(throwing: SampleError.failure)
                    return
                }
            }
            continuation.finish()
        }
        let connection = bridge.makeConnection(stream: stream)
        let store = ParseTreeStore(bridge: bridge)
        let failed = expectation(description: "Parsing failed")
        var cancellables: Set<AnyCancellable> = []

        store.$state
            .dropFirst()
            .sink { state in
                if case let .failed(message) = state {
                    XCTAssertTrue(message.contains("failure"))
                    failed.fulfill()
                }
            }
            .store(in: &cancellables)

        store.bind(to: connection)
        wait(for: [failed], timeout: 2.0)
    }

    private func makeSampleEvents(childIssues: [ValidationIssue] = []) -> [ParseEvent] {
        let parentHeader = BoxHeader(
            type: try! FourCharCode("root"),
            totalSize: 32,
            headerSize: 8,
            payloadRange: 8..<32,
            range: 0..<32,
            uuid: nil
        )
        let childHeader = BoxHeader(
            type: try! FourCharCode("test"),
            totalSize: 16,
            headerSize: 8,
            payloadRange: 8..<16,
            range: 8..<24,
            uuid: nil
        )

        return [
            ParseEvent(kind: .willStartBox(header: parentHeader, depth: 0), offset: 0, metadata: nil, validationIssues: []),
            ParseEvent(kind: .willStartBox(header: childHeader, depth: 1), offset: 8, metadata: nil, validationIssues: childIssues),
            ParseEvent(kind: .didFinishBox(header: childHeader, depth: 1), offset: 24, metadata: nil, validationIssues: childIssues),
            ParseEvent(kind: .didFinishBox(header: parentHeader, depth: 0), offset: 32, metadata: nil, validationIssues: [])
        ]
    }
}
#endif
