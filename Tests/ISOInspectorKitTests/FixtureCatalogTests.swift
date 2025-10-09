import Foundation
import XCTest
@testable import ISOInspectorKit

final class FixtureCatalogTests: XCTestCase {
    func testLoadsBundledCatalog() throws {
        let catalog = try FixtureCatalog.load()
        XCTAssertGreaterThan(catalog.fixtures.count, 0)
    }

    func testProvidesURLForBaselineFixture() throws {
        let catalog = try FixtureCatalog.load()
        let fixture = try XCTUnwrap(catalog.fixture(withID: "baseline-sample"))
        let url = try fixture.url(in: .module)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(fixture.expectations.warnings, [])
        XCTAssertEqual(fixture.expectations.errors, [])
        XCTAssertTrue(fixture.tags.contains("baseline"))
    }
}
