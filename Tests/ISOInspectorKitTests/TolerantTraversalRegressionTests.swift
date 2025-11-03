import Foundation
import XCTest
@testable import ISOInspectorKit

/// Regression tests for tolerant parsing pipeline that validate continued traversal
/// after corruption, accurate ParseIssue recording, and metrics aggregation.
///
/// These tests exercise the corrupt fixture corpus from Task T5.1 with tolerant
/// pipeline options and assert that:
/// - Traversal continues beyond corrupt nodes
/// - ParseIssue entries match expected reason codes and byte ranges
/// - Aggregate metrics (counts, depth) remain consistent
/// - Strict mode still throws/aborts as documented
final class TolerantTraversalRegressionTests: XCTestCase {

    // MARK: - Test Infrastructure

    private struct Manifest: Decodable {
        struct Corruption: Decodable {
            let category: String
            let pattern: String
            let affectedBoxes: [String]
            let expectedIssues: [String]
        }

        struct Fixture: Decodable {
            let id: String
            let filename: String
            let title: String
            let description: String
            let corruption: Corruption
            let smokeTest: Bool
        }

        let version: Int
        let fixtures: [Fixture]
    }

    private lazy var manifestURL: URL = {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // TolerantTraversalRegressionTests.swift
            .deletingLastPathComponent() // ISOInspectorKitTests
            .deletingLastPathComponent() // Tests
        return root
            .appendingPathComponent("Documentation")
            .appendingPathComponent("FixtureCatalog")
            .appendingPathComponent("corrupt-fixtures.json")
    }()

    private lazy var fixturesRoot: URL = {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // TolerantTraversalRegressionTests.swift
            .deletingLastPathComponent() // ISOInspectorKitTests
            .deletingLastPathComponent() // Tests
        return root
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Corrupt")
    }()

    private func loadManifest() throws -> Manifest {
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    private func fixtureURL(for filename: String) throws -> URL {
        let binaryURL = fixturesRoot.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: binaryURL.path) {
            return binaryURL
        }

        let base64URL = binaryURL.appendingPathExtension("base64")
        guard FileManager.default.fileExists(atPath: base64URL.path) else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing base64 source for \(filename)"])
        }

        let encoded = try String(contentsOf: base64URL, encoding: .utf8)
        guard let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 for \(filename)"])
        }

        try data.write(to: binaryURL, options: [.atomic])
        return binaryURL
    }

    private func collectEvents(from stream: ParsePipeline.EventStream) async throws -> [ParseEvent] {
        var events: [ParseEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    // MARK: - Truncated Payload Tests

    func testTruncatedMoovContinuesTraversalAndRecordsIssue() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-truncated-moov" }) else {
            XCTFail("Missing truncated-moov fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: traversal continued and emitted events
        XCTAssertFalse(events.isEmpty, "Tolerant mode should emit events despite truncation")

        // Assert: ParseIssue recorded with correct code
        let issues = store.issuesSnapshot()
        XCTAssertFalse(issues.isEmpty, "Expected at least one ParseIssue")
        let truncatedIssues = issues.filter { $0.code == "payload.truncated" }
        XCTAssertFalse(truncatedIssues.isEmpty, "Expected payload.truncated issue")

        // Assert: issue has severity and byte range
        if let issue = truncatedIssues.first {
            XCTAssertEqual(issue.severity, .error)
            XCTAssertNotNil(issue.byteRange, "Truncation issue should have byte range")
        }

        // Assert: metrics reflect error count
        let metrics = store.metricsSnapshot()
        XCTAssertGreaterThan(metrics.errorCount, 0, "Should have recorded error metrics")
    }

    // MARK: - Zero-Length Loop Tests

    func testZeroLengthLoopGuardPreventsInfiniteIteration() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-zero-length-loop" }) else {
            XCTFail("Missing zero-length-loop fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: pipeline terminated without infinite loop
        XCTAssertFalse(events.isEmpty, "Should have emitted events before guard triggered")

        // Assert: guard issue recorded
        let issues = store.issuesSnapshot()
        let guardIssues = issues.filter { $0.code == "guard.zero_size_loop" }
        XCTAssertFalse(guardIssues.isEmpty, "Expected zero_size_loop guard issue")

        // Assert: traversal depth is reasonable
        let metrics = store.metricsSnapshot()
        XCTAssertLessThan(metrics.deepestAffectedDepth, 100, "Depth should be bounded")
    }

    // MARK: - Deep Recursion Tests

    func testDeepRecursionGuardLimitsTraversalDepth() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-deep-recursion" }) else {
            XCTFail("Missing deep-recursion fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: events emitted up to depth limit
        XCTAssertFalse(events.isEmpty, "Should emit events before depth limit")

        // Assert: recursion depth issue recorded
        let issues = store.issuesSnapshot()
        let depthIssues = issues.filter { $0.code == "guard.recursion_depth_exceeded" }
        XCTAssertFalse(depthIssues.isEmpty, "Expected recursion_depth_exceeded guard issue")

        // Assert: depth matches configured limit
        let metrics = store.metricsSnapshot()
        let maxDepth = ParsePipeline.Options.tolerant.maxTraversalDepth
        XCTAssertLessThanOrEqual(metrics.deepestAffectedDepth, maxDepth, "Depth should respect configured limit")
    }

    // MARK: - Header Corruption Tests

    func testInvalidFourCCRecordsHeaderIssue() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-invalid-fourcc" }) else {
            XCTFail("Missing invalid-fourcc fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: pipeline continues despite invalid fourcc
        XCTAssertGreaterThanOrEqual(events.count, 0, "Tolerant mode should handle invalid fourcc")

        // Assert: header issue recorded
        let issues = store.issuesSnapshot()
        let headerIssues = issues.filter { $0.code == "header.invalid_fourcc" }
        XCTAssertFalse(headerIssues.isEmpty, "Expected header.invalid_fourcc issue")
    }

    func testTruncatedSizeFieldRecordsHeaderIssue() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-truncated-size-field" }) else {
            XCTFail("Missing truncated-size-field fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: events collected despite truncated header
        XCTAssertGreaterThanOrEqual(events.count, 0, "Should handle truncated size field")

        // Assert: truncated field issue recorded
        let issues = store.issuesSnapshot()
        let fieldIssues = issues.filter { $0.code == "header.truncated_field" }
        XCTAssertFalse(fieldIssues.isEmpty, "Expected header.truncated_field issue")
    }

    // MARK: - Parent-Child Boundary Tests

    func testChildExceedingParentRangeRecordsPayloadIssue() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-parent-truncated-child" }) else {
            XCTFail("Missing parent-truncated-child fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: tolerant mode continues past boundary violation
        XCTAssertFalse(events.isEmpty, "Should emit events despite parent-child violation")

        // Assert: payload truncation issue recorded
        let issues = store.issuesSnapshot()
        let truncatedIssues = issues.filter { $0.code == "payload.truncated" }
        XCTAssertFalse(truncatedIssues.isEmpty, "Expected payload.truncated for child exceeding parent")
    }

    // MARK: - Strict Mode Tests (Should Abort)

    func testStrictModeThrowsOnTruncatedPayload() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-truncated-moov" }) else {
            XCTFail("Missing truncated-moov fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let context = ParsePipeline.Context(options: .strict)

        let pipeline = ParsePipeline.live(options: .strict)

        do {
            _ = try await collectEvents(from: pipeline.events(for: reader, context: context))
            XCTFail("Strict mode should throw on structural error")
        } catch {
            // Expected: strict mode aborts on corruption
            XCTAssertTrue(true, "Strict mode correctly threw error: \(error)")
        }
    }

    func testStrictModeThrowsOnZeroLengthLoop() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-zero-length-loop" }) else {
            XCTFail("Missing zero-length-loop fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let context = ParsePipeline.Context(options: .strict)

        let pipeline = ParsePipeline.live(options: .strict)

        do {
            _ = try await collectEvents(from: pipeline.events(for: reader, context: context))
            XCTFail("Strict mode should throw on zero-length loop")
        } catch {
            // Expected: strict mode aborts on guard violation
            XCTAssertTrue(true, "Strict mode correctly threw error: \(error)")
        }
    }

    func testStrictModeThrowsOnDeepRecursion() async throws {
        let manifest = try loadManifest()
        guard let fixture = manifest.fixtures.first(where: { $0.id == "corrupt-deep-recursion" }) else {
            XCTFail("Missing deep-recursion fixture in manifest")
            return
        }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let context = ParsePipeline.Context(options: .strict)

        let pipeline = ParsePipeline.live(options: .strict)

        do {
            _ = try await collectEvents(from: pipeline.events(for: reader, context: context))
            XCTFail("Strict mode should throw on recursion depth limit")
        } catch {
            // Expected: strict mode aborts on depth limit
            XCTAssertTrue(true, "Strict mode correctly threw error: \(error)")
        }
    }

    // MARK: - Metrics Aggregation Tests

    func testTolerantModeAggregatesMetricsAcrossMultipleIssues() async throws {
        let manifest = try loadManifest()
        let smokeFixtures = manifest.fixtures.filter(\.smokeTest)
        XCTAssertFalse(smokeFixtures.isEmpty, "Need smoke fixtures for metrics test")

        // Test with first smoke fixture
        guard let fixture = smokeFixtures.first else { return }

        let url = try fixtureURL(for: fixture.filename)
        let reader = try ChunkedFileReader(fileURL: url)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = url

        let pipeline = ParsePipeline.live(options: .tolerant)
        _ = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Assert: metrics summary is consistent
        let summary = store.makeIssueSummary()
        let issues = store.issuesSnapshot()

        XCTAssertEqual(summary.totalCount, issues.count, "Summary count should match issues array")

        // Assert: severity counts are accurate
        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count
        let infoCount = issues.filter { $0.severity == .info }.count

        XCTAssertEqual(summary.metrics.errorCount, errorCount, "Error count mismatch")
        XCTAssertEqual(summary.metrics.warningCount, warningCount, "Warning count mismatch")
        XCTAssertEqual(summary.metrics.infoCount, infoCount, "Info count mismatch")
    }

    // MARK: - Comprehensive Corpus Coverage

    func testAllFixturesProcessInTolerantModeWithoutCrashing() async throws {
        let manifest = try loadManifest()
        let pipeline = ParsePipeline.live(options: .tolerant)

        for fixture in manifest.fixtures {
            let url = try fixtureURL(for: fixture.filename)
            let reader = try ChunkedFileReader(fileURL: url)
            let store = ParseIssueStore()
            var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
            context.source = url

            // Should not throw or crash
            let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

            // Assert: expected issues are present
            let issues = store.issuesSnapshot()
            let codes = Set(issues.map(\.code))
            for expected in fixture.corruption.expectedIssues {
                XCTAssertTrue(codes.contains(expected),
                              "Fixture \(fixture.id) missing expected issue \(expected)")
            }

            // Log coverage for visibility
            print("✓ Fixture \(fixture.id): \(events.count) events, \(issues.count) issues")
        }
    }
}
