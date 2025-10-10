import Foundation
import XCTest
@testable import ISOInspectorKit

final class FixtureCatalogExpandedCoverageTests: XCTestCase {
    private var catalog: FixtureCatalog!

    override func setUpWithError() throws {
        catalog = try FixtureCatalog.load()
    }

    func testFragmentedInitFixtureContainsMoovBox() throws {
        let fixture = try fixture(withID: "fragmented-stream-init")
        XCTAssertTrue(fixture.tags.contains("fragmented"))
        XCTAssertTrue(fixture.tags.contains("init"))
        let types = try topLevelBoxTypes(for: fixture)
        XCTAssertEqual(Array(types.prefix(2)), ["ftyp", "moov"])
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        XCTAssertTrue(fixture.expectations.warnings.contains("Expected streaming markers present"))
    }

    func testDashSegmentFixtureContainsStreamingBoxes() throws {
        let fixture = try fixture(withID: "dash-segment-1")
        XCTAssertTrue(fixture.tags.contains("dash"))
        XCTAssertTrue(fixture.tags.contains("segment"))
        let types = try topLevelBoxTypes(for: fixture)
        XCTAssertEqual(types, ["styp", "sidx", "moof", "mdat"])
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        XCTAssertTrue(fixture.expectations.warnings.contains("Contains streaming media segment"))
    }

    func testLargeMdatFixtureReportsExpectedWarning() throws {
        let fixture = try fixture(withID: "large-mdat")
        let types = try topLevelBoxTypes(for: fixture)
        XCTAssertTrue(types.contains("mdat"))
        let data = try fixture.data(in: .module)
        XCTAssertGreaterThan(data.count, 4096)
        XCTAssertTrue(fixture.expectations.warnings.contains("Large mdat payload"))
    }

    func testMalformedFixtureDocumentsExpectedErrors() throws {
        let fixture = try fixture(withID: "malformed-truncated")
        XCTAssertTrue(fixture.tags.contains("malformed"))
        XCTAssertFalse(fixture.expectations.errors.isEmpty)
        XCTAssertTrue(fixture.expectations.errors.contains("Truncated box payload"))
    }

    private func fixture(withID id: String) throws -> FixtureCatalog.Fixture {
        struct MissingFixtureError: Error {}
        guard let fixture = catalog.fixture(withID: id) else {
            XCTFail("Fixture with id \(id) not found")
            throw MissingFixtureError()
        }
        return fixture
    }

    private func topLevelBoxTypes(for fixture: FixtureCatalog.Fixture) throws -> [String] {
        let data = try fixture.data(in: .module)
        let reader = InMemoryRandomAccessReader(data: data)
        var offset: Int64 = 0
        var types: [String] = []
        while offset < reader.length {
            let header = try BoxHeaderDecoder.readHeader(from: reader, at: offset)
            types.append(header.type.rawValue)
            let nextOffset = header.range.upperBound
            guard nextOffset > offset else {
                break
            }
            offset = nextOffset
        }
        return types
    }
}
