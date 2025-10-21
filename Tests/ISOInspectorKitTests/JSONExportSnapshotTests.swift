import Foundation
import XCTest
@testable import ISOInspectorKit

final class JSONExportSnapshotTests: XCTestCase {
    private var catalog: FixtureCatalog!
    private let exporter = JSONParseTreeExporter()
    private let snapshotsSubdirectory = "Snapshots"
    // Set ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 when schema updates require refreshing baselines.
    private let regenerateSnapshots = ProcessInfo.processInfo.environment["ISOINSPECTOR_REGENERATE_SNAPSHOTS"] != nil

    override func setUpWithError() throws {
        catalog = try FixtureCatalog.load()
    }

    func testBaselineSampleSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "baseline-sample")
    }

    func testFragmentedStreamInitSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "fragmented-stream-init")
    }

    func testDashSegmentSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "dash-segment-1")
    }

    func testFragmentedMultiTrunSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "fragmented-multi-trun")
    }

    func testFragmentedNegativeOffsetSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "fragmented-negative-offset")
    }

    func testFragmentedNoTfdtSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "fragmented-no-tfdt")
    }

    func testEditListEmptySnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "edit-list-empty")
    }

    func testEditListSingleOffsetSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "edit-list-single-offset")
    }

    func testEditListMultiSegmentSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "edit-list-multi-segment")
    }

    func testEditListRateAdjustedSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "edit-list-rate-adjusted")
    }

    private func assertSnapshotMatchesFixture(id: String) async throws {
        let tree = try await makeParseTree(forFixtureID: id)
        let canonical = try canonicalJSONString(for: tree)
        try assertSnapshot(named: id, matches: canonical)
    }

    private func makeParseTree(forFixtureID id: String) async throws -> ParseTree {
        let fixture = try XCTUnwrap(catalog.fixture(withID: id), "Fixture \(id) not found in catalog")
        let data = try fixture.data(in: .module)
        let reader = InMemoryRandomAccessReader(data: data)
        var builder = ParseTreeBuilder()
        let pipeline = ParsePipeline.live()
        for try await event in pipeline.events(for: reader, context: .init(source: nil)) {
            builder.consume(event)
        }
        return builder.makeTree()
    }

    private func canonicalJSONString(for tree: ParseTree) throws -> String {
        let raw = try exporter.export(tree: tree)
        let object = try JSONSerialization.jsonObject(with: raw, options: [.fragmentsAllowed])
        let canonicalData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .prettyPrinted])
        var string = String(decoding: canonicalData, as: UTF8.self)
        if !string.hasSuffix("\n") {
            string.append("\n")
        }
        return string
    }

    private func assertSnapshot(named name: String, matches json: String) throws {
        let bundleURL = snapshotBundleURL(named: name)
        let sourceURL = snapshotSourceURL(named: name)
        let data = Data(json.utf8)
        let fileManager = FileManager.default
        if regenerateSnapshots || bundleURL == nil {
            try fileManager.createDirectory(at: sourceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: sourceURL, options: .atomic)
            print("✅ Regenerated snapshot baseline for \(name) at \(sourceURL.path)")
            print(json)
            XCTFail("Snapshot baseline for \(name) was regenerated. Re-run tests without ISOINSPECTOR_REGENERATE_SNAPSHOTS to validate the output.")
            return
        }

        let baselineURL = try XCTUnwrap(bundleURL, "Snapshot baseline for \(name) missing from bundle")
        let baseline = try String(contentsOf: baselineURL, encoding: .utf8)
        XCTAssertEqual(json, baseline, "Snapshot mismatch for \(name). Set ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests to refresh baselines after intentional schema updates.")
    }

    private func snapshotBundleURL(named name: String) -> URL? {
        if let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: snapshotsSubdirectory
        ) {
            return url
        }
        return Bundle.module.url(
            forResource: name,
            withExtension: "json"
        )
    }

    private func snapshotSourceURL(named name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(snapshotsSubdirectory, isDirectory: true)
            .appendingPathComponent("\(name).json", isDirectory: false)
    }
}
