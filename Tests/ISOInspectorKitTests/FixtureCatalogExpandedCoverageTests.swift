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

    func testFragmentedMultiTrunFixtureDeclaresFragmentTags() throws {
        let fixture = try fixture(withID: "fragmented-multi-trun")
        XCTAssertTrue(fixture.tags.contains("fragmented"))
        XCTAssertTrue(fixture.tags.contains("segment"))
        XCTAssertTrue(fixture.tags.contains("multi-run"))
        let types = try topLevelBoxTypes(for: fixture)
        XCTAssertTrue(types.contains("moof"))
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
    }

    func testFragmentedNegativeOffsetFixtureHighlightsEdgeCase() throws {
        let fixture = try fixture(withID: "fragmented-negative-offset")
        XCTAssertTrue(fixture.tags.contains("fragmented"))
        XCTAssertTrue(fixture.tags.contains("negative-offset"))
        XCTAssertTrue(fixture.tags.contains("segment"))
        XCTAssertTrue(fixture.expectations.warnings.isEmpty)
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
    }

    func testFragmentedNoTfdtFixtureDocumentsDefaultingBehavior() throws {
        let fixture = try fixture(withID: "fragmented-no-tfdt")
        XCTAssertTrue(fixture.tags.contains("fragmented"))
        XCTAssertTrue(fixture.tags.contains("no-tfdt"))
        XCTAssertTrue(fixture.tags.contains("segment"))
        XCTAssertEqual(fixture.expectations.warnings, [
            "Track fragment omits tfdt; decode times default to context state"
        ])
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
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

    func testEditListEmptyFixtureReportsDurationWarnings() throws {
        let fixture = try fixture(withID: "edit-list-empty")
        XCTAssertTrue(fixture.tags.contains("edit-list"))
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        let warnings = Set(fixture.expectations.warnings)
        XCTAssertTrue(warnings.contains("Track 1 edit list spans 0 movie ticks but movie header duration is 1200 (short by 1200 > 1 tick)."))
        XCTAssertTrue(warnings.contains("Track 1 edit list spans 0 movie ticks but track header duration is 900 (short by 900 > 1 tick)."))
        XCTAssertTrue(warnings.contains("Track 1 edit list consumes 0 media ticks but media duration is 96000 (short by 96000 > 1 tick)."))
    }

    func testEditListSingleOffsetFixtureReportsMediaDurationWarning() throws {
        let fixture = try fixture(withID: "edit-list-single-offset")
        XCTAssertTrue(fixture.tags.contains("edit-list"))
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        XCTAssertEqual(fixture.expectations.warnings, [
            "Track 2 edit list consumes 62400 media ticks but media duration is 64000 (short by 1600 > 1 tick)."
        ])
    }

    func testEditListMultiSegmentFixtureReportsOverageWarnings() throws {
        let fixture = try fixture(withID: "edit-list-multi-segment")
        XCTAssertTrue(fixture.tags.contains("edit-list"))
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        let warnings = Set(fixture.expectations.warnings)
        XCTAssertTrue(warnings.contains("Track 3 edit list spans 1200 movie ticks but movie header duration is 1000 (over by 200 > 1 tick)."))
        XCTAssertTrue(warnings.contains("Track 3 edit list spans 1200 movie ticks but track header duration is 950 (over by 250 > 1 tick)."))
    }

    func testEditListRateAdjustedFixtureReportsPlaybackWarnings() throws {
        let fixture = try fixture(withID: "edit-list-rate-adjusted")
        XCTAssertTrue(fixture.tags.contains("edit-list"))
        XCTAssertTrue(fixture.expectations.errors.isEmpty)
        let warnings = Set(fixture.expectations.warnings)
        XCTAssertTrue(warnings.contains("Track 4 edit list entry 0 uses media_rate_integer=-1; reverse playback is unsupported."))
        XCTAssertTrue(warnings.contains("Track 4 edit list entry 1 uses media_rate_integer=2; playback rate adjustments above 1x are unsupported."))
        XCTAssertTrue(warnings.contains("Track 4 edit list entry 2 sets media_rate_fraction=1; fractional playback rates are unsupported."))
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
