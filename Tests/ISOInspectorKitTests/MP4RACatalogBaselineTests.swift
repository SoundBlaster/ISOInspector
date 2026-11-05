import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct MP4RACatalogBaselineTests {
    enum BaselineFormat: String, Sendable { case current, legacy }

    private struct StubRegistry: MP4RARegistryDataProvider {
        let sourceURL = URL(string: "https://example.invalid/registry")!
        let payload: Data

        func fetchRegistryPayload() throws -> Data { payload }
    }

    @Test func duplicateFourCCPrefersSpecificationAndThenDetails() throws {
        let payload = Data(
            """
            [
              {"code":" a b c d ","description":"basic"},
              {"code":"abcd","description":"better","specification":"ISO"},
              {"code":"abcd","description":"better","specification":"ISO","handler":"video"},
              {"code":"abcd","description":"less detailed"},
              {"code":"ab$GZ","description":"invalid escape"},
              {"code":"xyz","description":"invalid length"}
            ]
            """.utf8)
        let refresher = MP4RACatalogRefresher(dataProvider: StubRegistry(payload: payload))

        let catalog = try refresher.makeCatalog()

        #expect(catalog.metadata.recordCount == 1)
        let entry = try #require(catalog.boxes.first)
        #expect(entry.type == "abcd")
        #expect(entry.name == "Better")
        #expect(entry.specification == "ISO")
        #expect(entry.summary == "better (handler: video)")
    }

    @Test(arguments: [BaselineFormat.current, .legacy])
    func writeCatalogPreservesCurrentAndLegacyBaseline(format: BaselineFormat) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("catalog.json")
        let boxes = """
            [
              {"type":"abcd","name":"Old name","summary":"Long baseline description",
               "specification":"ISO/IEC 14496","version":2,"flags":"000001"},
              {"type":"keep","name":"Baseline only","summary":"Keep this entry"}
            ]
            """
        let baseline: String
        switch format {
        case .current:
            baseline = """
                {"metadata":{"source":"baseline","fetchedAt":"2025-01-01T00:00:00Z","recordCount":2},
                 "boxes":\(boxes)}
                """
        case .legacy: baseline = "{\"boxes\":\(boxes)}"
        }
        try Data(baseline.utf8).write(to: output)
        let payload = Data("""
            [{"code":"abcd","description":"new"}]
            """.utf8)
        let refresher = MP4RACatalogRefresher(
            dataProvider: StubRegistry(payload: payload),
            clock: { Date(timeIntervalSince1970: 1_700_000_000) })

        let catalog = try refresher.writeCatalog(to: output)

        #expect(catalog.boxes.map(\.type) == ["abcd", "keep"])
        #expect(catalog.metadata.recordCount == 2)
        let updated = try #require(catalog.boxes.first)
        #expect(updated.name == "New")
        #expect(updated.summary == "Long baseline description")
        #expect(updated.specification == "ISO/IEC 14496")
        #expect(updated.version == 2)
        #expect(updated.flags == "000001")
        let retained = try #require(catalog.boxes.last)
        #expect(retained.summary == "Keep this entry")
        #expect(try JSONDecoder().decode(MP4RACatalogRefresher.Catalog.self, from: Data(contentsOf: output)) == catalog)
    }

    @Test func invalidBaselineIsReplacedByTheNewCatalog() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("catalog.json")
        try Data("not JSON".utf8).write(to: output)
        let payload = Data("""
            [{"code":"abcd","description":"new"}]
            """.utf8)
        let refresher = MP4RACatalogRefresher(dataProvider: StubRegistry(payload: payload))

        let catalog = try refresher.writeCatalog(to: output)

        #expect(catalog.boxes.map(\.type) == ["abcd"])
        #expect(try JSONDecoder().decode(MP4RACatalogRefresher.Catalog.self, from: Data(contentsOf: output)) == catalog)
    }
}
