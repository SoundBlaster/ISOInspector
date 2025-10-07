import XCTest
@testable import ISOInspectorKit

final class MP4RACatalogRefresherTests: XCTestCase {
    private struct StubDataProvider: MP4RARegistryDataProvider {
        let payload: Data
        let sourceURL: URL

        func fetchRegistryPayload() throws -> Data {
            payload
        }
    }

    func testBuildCatalogTransformsRecords() throws {
        let payload = Data("""
        [
            {"code":"abcd","description":"example description","specification":"ISO"},
            {"code":"aud$20","description":"Access unit delimiter","specification":"NALu Video","type":"sample group"},
            {"code":"efgh","description":"audio handler entry","specification":"Example","handler":"Audio","ObjectType":"0xAF"},
            {"code":"bad","description":"invalid length","specification":"Test"}
        ]
        """.utf8)
        let provider = StubDataProvider(payload: payload, sourceURL: URL(string: "https://example.com/api")!)
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let refresher = MP4RACatalogRefresher(dataProvider: provider, clock: { fixedDate })

        let catalog = try refresher.makeCatalog()

        XCTAssertEqual(catalog.metadata.source, "https://example.com/api")
        XCTAssertEqual(catalog.metadata.recordCount, 3)
        XCTAssertEqual(catalog.boxes.map(\.type), ["abcd", "aud ", "efgh"])
        XCTAssertEqual(catalog.boxes[0].name, "Example Description")
        XCTAssertEqual(catalog.boxes[0].summary, "example description")
        XCTAssertEqual(catalog.boxes[0].specification, "ISO")
        XCTAssertNil(catalog.boxes[0].version)
        XCTAssertNil(catalog.boxes[0].flags)

        XCTAssertEqual(catalog.boxes[1].type, "aud ")
        XCTAssertEqual(catalog.boxes[1].name, "Access Unit Delimiter")
        XCTAssertEqual(catalog.boxes[1].summary, "Access unit delimiter (category: sample group)")

        XCTAssertEqual(catalog.boxes[2].summary, "audio handler entry (handler: Audio, objectType: 0xAF)")
        XCTAssertEqual(catalog.boxes[2].name, "Audio Handler Entry")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertEqual(catalog.metadata.fetchedAt, formatter.string(from: fixedDate))
    }

    func testWriteCatalogPersistsJSONWithMetadata() throws {
        struct Registry: Decodable {
            struct Metadata: Decodable {
                let source: String
                let fetchedAt: String
                let recordCount: Int
            }

            struct Entry: Decodable {
                let type: String
                let uuid: String?
                let name: String
                let summary: String
                let specification: String?
                let version: Int?
                let flags: String?
            }

            let metadata: Metadata
            let boxes: [Entry]
        }

        let payload = Data("""
        [
            {"code":"abcd","description":"example description","specification":"ISO"}
        ]
        """.utf8)
        let provider = StubDataProvider(payload: payload, sourceURL: URL(string: "https://example.com/api")!)
        let refresher = MP4RACatalogRefresher(dataProvider: provider, clock: { Date(timeIntervalSince1970: 1_700_000_000) })
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")

        let catalog = try refresher.writeCatalog(to: outputURL)
        let data = try Data(contentsOf: outputURL)
        let decoded = try JSONDecoder().decode(Registry.self, from: data)

        XCTAssertEqual(decoded.metadata.source, catalog.metadata.source)
        XCTAssertEqual(decoded.metadata.recordCount, 1)
        XCTAssertEqual(decoded.boxes.count, 1)
        XCTAssertEqual(decoded.boxes[0].type, "abcd")
        XCTAssertEqual(decoded.boxes[0].name, "Example Description")
        XCTAssertEqual(decoded.boxes[0].summary, "example description")
    }
}
