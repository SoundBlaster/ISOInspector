import XCTest
@testable import ISOInspectorKit

final class FragmentFixtureCoverageTests: XCTestCase {
    private var catalog: FixtureCatalog!
    private var pipeline: ParsePipeline!

    override func setUpWithError() throws {
        catalog = try FixtureCatalog.load()
        pipeline = .live()
    }

    func testMultiRunFixtureAggregatesRuns() async throws {
        let fragment = try await parseFragmentSummary(forFixtureID: "fragmented-multi-trun")
        XCTAssertEqual(fragment.trackID, 1)
        XCTAssertEqual(fragment.runs.count, 2)
        XCTAssertEqual(fragment.totalSampleCount, 3)
        XCTAssertEqual(fragment.totalSampleDuration, 280)
        XCTAssertEqual(fragment.totalSampleSize, 1000)
        XCTAssertEqual(fragment.firstDecodeTime, 1_000)
        XCTAssertEqual(fragment.lastDecodeTime, 1_280)

        let firstRun = try XCTUnwrap(fragment.runs.first)
        XCTAssertEqual(firstRun.sampleCount, 2)
        XCTAssertEqual(firstRun.totalSampleDuration, 180)
        XCTAssertEqual(firstRun.totalSampleSize, 620)
        XCTAssertEqual(firstRun.entries.count, 2)
        XCTAssertEqual(firstRun.entries[0].sampleCompositionTimeOffset, 5)
        XCTAssertEqual(firstRun.entries[0].decodeTime, 1_000)
        XCTAssertEqual(firstRun.entries[0].presentationTime, 1_005)
        XCTAssertEqual(firstRun.entries[1].decodeTime, 1_090)
        XCTAssertEqual(firstRun.entries[1].presentationTime, 1_105)

        let secondRun = try XCTUnwrap(fragment.runs.dropFirst().first)
        XCTAssertNil(secondRun.dataOffset)
        XCTAssertEqual(secondRun.sampleCount, 1)
        XCTAssertEqual(secondRun.totalSampleDuration, 100)
        XCTAssertEqual(secondRun.totalSampleSize, 380)
        let secondEntry = try XCTUnwrap(secondRun.entries.first)
        XCTAssertEqual(secondEntry.decodeTime, 1_180)
        XCTAssertEqual(secondEntry.presentationTime, 1_180)
        XCTAssertEqual(secondRun.startDataOffset, firstRun.endDataOffset)
    }

    func testNegativeDataOffsetRunOmitsResolvedPositions() async throws {
        let fragment = try await parseFragmentSummary(forFixtureID: "fragmented-negative-offset")
        XCTAssertEqual(fragment.trackID, 2)
        XCTAssertEqual(fragment.totalSampleCount, 1)
        let run = try XCTUnwrap(fragment.runs.first)
        XCTAssertEqual(run.dataOffset, -64)
        XCTAssertNil(run.startDataOffset)
        XCTAssertNil(run.endDataOffset)
        let entry = try XCTUnwrap(run.entries.first)
        XCTAssertNil(entry.dataOffset)
        XCTAssertEqual(entry.sampleDuration, 200)
        XCTAssertEqual(entry.sampleSize, 450)
    }

    func testFragmentWithoutDecodeTimeDefaultsToNilTimes() async throws {
        let fragment = try await parseFragmentSummary(forFixtureID: "fragmented-no-tfdt")
        XCTAssertEqual(fragment.trackID, 3)
        XCTAssertNil(fragment.baseDecodeTime)
        XCTAssertNil(fragment.firstDecodeTime)
        XCTAssertNil(fragment.lastDecodeTime)
        XCTAssertEqual(fragment.totalSampleCount, 2)
        XCTAssertEqual(fragment.totalSampleDuration, 240)
        let run = try XCTUnwrap(fragment.runs.first)
        XCTAssertNil(run.startDecodeTime)
        XCTAssertNil(run.endDecodeTime)
        XCTAssertEqual(run.totalSampleDuration, 240)
        XCTAssertEqual(run.sampleCount, 2)
        let firstEntry = try XCTUnwrap(run.entries.first)
        XCTAssertNil(firstEntry.decodeTime)
        XCTAssertNil(firstEntry.presentationTime)
        XCTAssertNil(firstEntry.sampleCompositionTimeOffset)
    }

    private func parseFragmentSummary(forFixtureID id: String) async throws -> ParsedBoxPayload.TrackFragmentBox {
        let fixture = try XCTUnwrap(catalog.fixture(withID: id), "Missing fixture \(id)")
        let data = try fixture.data(in: .module)
        let reader = InMemoryRandomAccessReader(data: data)
        for try await event in pipeline.events(for: reader, context: .init()) {
            guard case let .didFinishBox(header, _) = event.kind else { continue }
            if header.type.rawValue == "traf", let fragment = event.payload?.trackFragment {
                return fragment
            }
        }
        struct MissingFragment: Error {}
        throw MissingFragment()
    }
}
