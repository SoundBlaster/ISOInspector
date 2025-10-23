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

    func testCodecInvalidConfigsSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "codec-invalid-configs")
    }

    func testSampleEncryptionPlaceholderSnapshotMatchesFixture() async throws {
        try await assertSnapshotMatchesFixture(id: "sample-encryption-placeholder")
    }

    func testBaselineSampleNodesExposeCompatibilityAliases() async throws {
        let tree = try await makeParseTree(forFixtureID: "baseline-sample")
        let object = try canonicalJSONObject(for: tree)
        let nodes = try XCTUnwrap(object["nodes"] as? [[String: Any]], "nodes array missing from export")
        let flattened = flatten(nodes: nodes)

        for node in flattened {
            let fourcc = node["fourcc"] as? String
            let name = node["name"] as? String
            XCTAssertEqual(name, fourcc, "Compatibility alias name should mirror fourcc for node \(String(describing: fourcc))")

            let sizes = node["sizes"] as? [String: Any]
            let header = Self.intValue(forKey: "header", in: sizes)
            let total = Self.intValue(forKey: "total", in: sizes)
            let headerAlias = Self.intValue(forKey: "header_size", in: node)
            let sizeAlias = Self.intValue(forKey: "size", in: node)

            XCTAssertEqual(headerAlias, header, "header_size alias should equal sizes.header for node \(String(describing: fourcc))")
            XCTAssertEqual(sizeAlias, total, "size alias should equal sizes.total for node \(String(describing: fourcc))")
        }
    }

    func testBaselineSampleFormatSummaryIncludesBrandsAndDuration() async throws {
        let tree = try await makeParseTree(forFixtureID: "baseline-sample")
        let object = try canonicalJSONObject(for: tree)
        let format = try XCTUnwrap(object["format"] as? [String: Any], "format summary missing")

        let fileType = try XCTUnwrap(findFileType(in: tree), "File type detail missing from parse tree")
        XCTAssertEqual(format["major_brand"] as? String, fileType.majorBrand.rawValue)
        XCTAssertEqual(Self.intValue(forKey: "minor_version", in: format), Int(fileType.minorVersion))
        let compatible = try XCTUnwrap(format["compatible_brands"] as? [String])
        XCTAssertEqual(compatible, fileType.compatibleBrands.map(\.rawValue))

        let movieHeader = try XCTUnwrap(findMovieHeader(in: tree), "Movie header detail missing from parse tree")
        let expectedDuration = Double(movieHeader.duration) / Double(movieHeader.timescale)
        let duration = try XCTUnwrap(format["duration_seconds"] as? Double)
        XCTAssertEqual(duration, expectedDuration, accuracy: 0.0001)

        let trackCount = countTracks(in: tree.nodes)
        XCTAssertEqual(Self.intValue(forKey: "track_count", in: format), trackCount)

        let byteSize = Self.intValue(forKey: "byte_size", in: format)
        let data = try treeData(forFixtureID: "baseline-sample")
        XCTAssertEqual(byteSize, data.count)

        let expectedBitrate = Int((Double(data.count) * 8.0 / expectedDuration).rounded())
        XCTAssertEqual(Self.intValue(forKey: "bitrate", in: format), expectedBitrate)
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

    private func canonicalJSONObject(for tree: ParseTree) throws -> [String: Any] {
        let raw = try canonicalJSONString(for: tree)
        let data = Data(raw.utf8)
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try XCTUnwrap(object as? [String: Any], "Export root object must be a dictionary")
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

    private func flatten(nodes: [[String: Any]]) -> [[String: Any]] {
        var result: [[String: Any]] = []
        for node in nodes {
            result.append(node)
            if let children = node["children"] as? [[String: Any]] {
                result.append(contentsOf: flatten(nodes: children))
            }
        }
        return result
    }

    private static func intValue(forKey key: String, in dictionary: [String: Any]?) -> Int {
        guard let value = dictionary?[key] else { return 0 }
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        return 0
    }

    private func findFileType(in tree: ParseTree) -> ParsedBoxPayload.FileTypeBox? {
        for node in flatten(nodes: tree.nodes) {
            if let fileType = node.payload?.fileType {
                return fileType
            }
        }
        return nil
    }

    private func findMovieHeader(in tree: ParseTree) -> ParsedBoxPayload.MovieHeaderBox? {
        for node in flatten(nodes: tree.nodes) {
            if let movieHeader = node.payload?.movieHeader {
                return movieHeader
            }
        }
        return nil
    }

    private func countTracks(in nodes: [ParseTreeNode]) -> Int {
        nodes.reduce(0) { partialResult, node in
            let childrenCount = countTracks(in: node.children)
            let isTrack = node.header.type.rawValue == "trak" ? 1 : 0
            return partialResult + isTrack + childrenCount
        }
    }

    private func flatten(nodes: [ParseTreeNode]) -> [ParseTreeNode] {
        var result: [ParseTreeNode] = []
        for node in nodes {
            result.append(node)
            result.append(contentsOf: flatten(nodes: node.children))
        }
        return result
    }

    private func treeData(forFixtureID id: String) throws -> Data {
        let fixture = try XCTUnwrap(catalog.fixture(withID: id))
        return try fixture.data(in: .module)
    }
}
