#if canImport(Combine)
import Combine
import Foundation
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

final class ParseTreeStoreTests: XCTestCase {
    @MainActor
    func testFilteringValidationIssuesUpdatesSnapshot() {
        let filteredIssue = ValidationIssue(ruleID: "VR-006", message: "research", severity: .info)
        let retainedIssue = ValidationIssue(ruleID: "VR-001", message: "structure", severity: .error)
        let events = makeSampleEvents(childIssues: [filteredIssue, retainedIssue])
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
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
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
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
        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
        wait(for: [failed], timeout: 2.0)
    }

    @MainActor
    func testIssueMetricsPublishesAggregatedCounts() {
        let store = ParseTreeStore()
        XCTAssertEqual(store.issueMetrics.totalCount, 0)

        let expectation = expectation(description: "Issue metrics updated")
        var cancellables: Set<AnyCancellable> = []

        store.$issueMetrics
            .dropFirst()
            .sink { metrics in
                XCTAssertEqual(metrics.errorCount, 1)
                XCTAssertEqual(metrics.warningCount, 1)
                XCTAssertEqual(metrics.deepestAffectedDepth, 2)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let issue = ParseIssue(
            severity: .error,
            code: "VR-999",
            message: "Stub issue",
            byteRange: 0..<8,
            affectedNodeIDs: [1, 2]
        )
        let warning = ParseIssue(
            severity: .warning,
            code: "VR-998",
            message: "Stub warning",
            byteRange: 8..<16,
            affectedNodeIDs: [1]
        )
        store.issueStore.record(issue, depth: 2)
        store.issueStore.record(warning, depth: 1)

        wait(for: [expectation], timeout: 1.0)

        store.shutdown()

        XCTAssertEqual(store.issueMetrics.totalCount, 0)
        XCTAssertEqual(store.issueMetrics.deepestAffectedDepth, 0)
    }

    @MainActor
    func testSnapshotIncludesParseIssuesFromEvents() {
        let parseIssue = ParseIssue(
            severity: .error,
            code: "VR-900",
            message: "Stub parse issue",
            byteRange: 8..<16,
            affectedNodeIDs: [1, 2]
        )
        let events = makeSampleEvents(childIssues: [], childParseIssues: [parseIssue])
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
        wait(for: [finished], timeout: 2.0)

        let child = store.snapshot.nodes.first?.children.first
        XCTAssertEqual(child?.issues.count, 1)
        XCTAssertEqual(child?.issues.first?.code, parseIssue.code)
        XCTAssertEqual(child?.issues.first?.severity, .error)
        XCTAssertEqual(child?.issues.first?.affectedNodeIDs, parseIssue.affectedNodeIDs)
    }

    @MainActor
    func testFinishingBoxDoesNotDuplicateParseIssues() {
        let initialIssue = ParseIssue(
            severity: .warning,
            code: "VR-901",
            message: "Initial issue",
            byteRange: 0..<4,
            affectedNodeIDs: [2]
        )
        let additionalIssue = ParseIssue(
            severity: .error,
            code: "VR-902",
            message: "Additional issue",
            byteRange: 4..<8,
            affectedNodeIDs: [2]
        )
        let events = makeSampleEvents(
            childParseIssues: [initialIssue],
            childFinishParseIssues: [initialIssue, additionalIssue]
        )
        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
        wait(for: [finished], timeout: 2.0)

        let childIssues = store.snapshot.nodes.first?.children.first?.issues ?? []
        XCTAssertEqual(childIssues.count, 2)
        XCTAssertEqual(Set(childIssues.map(\.code)), Set([initialIssue.code, additionalIssue.code]))
    }

    @MainActor
    func testPlaceholderNodesRecordedForMissingRequiredChildren() throws {
        let minfType = try FourCharCode("minf")
        let smhdType = try FourCharCode("smhd")

        let minfHeader = BoxHeader(
            type: minfType,
            totalSize: 64,
            headerSize: 8,
            payloadRange: 8..<64,
            range: 0..<64,
            uuid: nil
        )
        let smhdHeader = BoxHeader(
            type: smhdType,
            totalSize: 16,
            headerSize: 8,
            payloadRange: 8..<16,
            range: 8..<24,
            uuid: nil
        )

        let events: [ParseEvent] = [
            ParseEvent(kind: .willStartBox(header: minfHeader, depth: 0), offset: minfHeader.startOffset),
            ParseEvent(kind: .willStartBox(header: smhdHeader, depth: 1), offset: smhdHeader.startOffset),
            ParseEvent(kind: .didFinishBox(header: smhdHeader, depth: 1), offset: smhdHeader.endOffset),
            ParseEvent(kind: .didFinishBox(header: minfHeader, depth: 0), offset: minfHeader.endOffset)
        ]

        let stream = AsyncThrowingStream<ParseEvent, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }

        let pipeline = ParsePipeline(buildStream: { _, _ in stream })
        let reader = InMemoryRandomAccessReader(data: Data())
        let store = ParseTreeStore()
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

        store.start(pipeline: pipeline, reader: reader)
        wait(for: [finished], timeout: 2.0)

        let root = try XCTUnwrap(store.snapshot.nodes.first)
        XCTAssertEqual(root.header.type.rawValue, "minf")
        XCTAssertEqual(root.status, .partial)
        XCTAssertEqual(root.children.count, 2)

        let placeholder = try XCTUnwrap(root.children.first(where: { $0.header.type.rawValue == "stbl" }))
        XCTAssertEqual(placeholder.status, .corrupt)
        XCTAssertEqual(placeholder.children.count, 0)
        XCTAssertLessThan(placeholder.header.startOffset, 0)

        let issue = try XCTUnwrap(placeholder.issues.first)
        XCTAssertEqual(issue.code, "structure.missing_child")
        XCTAssertEqual(issue.severity, .error)
        XCTAssertTrue(issue.message.contains("stbl"))
        XCTAssertTrue(issue.message.contains("minf"))

        let placeholderStoreIssues = store.issueStore.issues(forNodeID: placeholder.id)
        XCTAssertTrue(placeholderStoreIssues.contains(issue))

        let parentIssues = store.issueStore.issues(forNodeID: root.id)
        XCTAssertTrue(parentIssues.contains(issue))

        let metrics = store.issueStore.metricsSnapshot()
        XCTAssertEqual(metrics.errorCount, 1)
        XCTAssertGreaterThanOrEqual(metrics.deepestAffectedDepth, 1)
    }

    private func makeSampleEvents(
        childIssues: [ValidationIssue] = [],
        childParseIssues: [ParseIssue] = [],
        childFinishParseIssues: [ParseIssue]? = nil
    ) -> [ParseEvent] {
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
            ParseEvent(
                kind: .willStartBox(header: childHeader, depth: 1),
                offset: 8,
                metadata: nil,
                validationIssues: childIssues,
                issues: childParseIssues
            ),
            ParseEvent(
                kind: .didFinishBox(header: childHeader, depth: 1),
                offset: 24,
                metadata: nil,
                validationIssues: childIssues,
                issues: childFinishParseIssues ?? childParseIssues
            ),
            ParseEvent(kind: .didFinishBox(header: parentHeader, depth: 0), offset: 32, metadata: nil, validationIssues: [])
        ]
    }
}
#endif
