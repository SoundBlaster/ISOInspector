import XCTest

@testable import ISOInspectorKit

typealias BookmarkResolutionState = BookmarkPersistenceStore.Record.ResolutionState

final class BookmarkPersistenceStoreTests: XCTestCase {
    private var directory: URL!
    private var makeDate: DateGenerator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        makeDate = DateGenerator()
    }

    override func tearDownWithError() throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
        try super.tearDownWithError()
    }

    func testUpsertingNewBookmarkCreatesRecord() throws {
        let store = BookmarkPersistenceStore(directory: directory, makeDate: makeDate.sendableNext)
        let fileURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        let data = Data("bookmark".utf8)

        let record = try store.upsertBookmark(for: fileURL, bookmarkData: data)

        XCTAssertEqual(
            record.canonicalURL,
            fileURL.standardizedFileURL.resolvingSymlinksInPath().absoluteString)
        XCTAssertEqual(record.bookmarkData, data)
        XCTAssertEqual(record.createdAt, makeDate.history[0])
        XCTAssertEqual(record.updatedAt, makeDate.history[0])
        XCTAssertEqual(record.lastResolutionState, .unknown)
        XCTAssertNil(record.lastResolvedAt)
        XCTAssertNotNil(record.id)
    }

    func testUpsertingExistingBookmarkUpdatesRecord() throws {
        let store = BookmarkPersistenceStore(directory: directory, makeDate: makeDate.sendableNext)
        let fileURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        let original = try store.upsertBookmark(for: fileURL, bookmarkData: Data([0x01]))

        makeDate.advance(by: 60)
        let updated = try store.upsertBookmark(for: fileURL, bookmarkData: Data([0x02]))

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.createdAt, original.createdAt)
        XCTAssertEqual(updated.updatedAt, makeDate.history.last)
        XCTAssertEqual(updated.bookmarkData, Data([0x02]))
    }

    func testMarkingResolutionUpdatesState() throws {
        let store = BookmarkPersistenceStore(directory: directory, makeDate: makeDate.sendableNext)
        let fileURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        _ = try store.upsertBookmark(for: fileURL, bookmarkData: Data([0x01]))

        makeDate.advance(by: 30)
        let resolved = try store.markResolution(for: fileURL, state: .stale)

        XCTAssertEqual(resolved?.lastResolvedAt, makeDate.history.last)
        XCTAssertEqual(resolved?.lastResolutionState, .stale)
        XCTAssertEqual(resolved?.updatedAt, makeDate.history.last)
    }

    func testRemovingBookmarkDeletesRecord() throws {
        let store = BookmarkPersistenceStore(directory: directory, makeDate: makeDate.sendableNext)
        let fileURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        _ = try store.upsertBookmark(for: fileURL, bookmarkData: Data([0x01]))

        try store.removeBookmark(for: fileURL)

        XCTAssertNil(try store.record(for: fileURL))
        XCTAssertTrue(try store.loadAll().isEmpty)
    }

    func testRecordsPersistToDisk() throws {
        let fileURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        do {
            let store = BookmarkPersistenceStore(
                directory: directory, makeDate: makeDate.sendableNext)
            _ = try store.upsertBookmark(for: fileURL, bookmarkData: Data([0xAA]))
            _ = try store.upsertBookmark(
                for: fileURL.appendingPathComponent("other"), bookmarkData: Data([0xBB]))
            makeDate.advance(by: 10)
            _ = try store.markResolution(for: fileURL, state: .succeeded)
        }

        let reloaded = BookmarkPersistenceStore(
            directory: directory, makeDate: makeDate.sendableNext)
        let records = try reloaded.loadAll().sorted { $0.canonicalURL < $1.canonicalURL }

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0].lastResolutionState, .succeeded)
        XCTAssertEqual(records[0].bookmarkData, Data([0xAA]))
        XCTAssertEqual(records[1].bookmarkData, Data([0xBB]))
    }
}

private final class DateGenerator: @unchecked Sendable {
    private(set) var history: [Date] = []
    private var current: Date

    init(start: Date = Date(timeIntervalSince1970: 1_700_000_000)) { current = start }

    var sendableNext: @Sendable () -> Date { { [unowned self] in self.next() } }

    func next() -> Date {
        history.append(current)
        return current
    }

    func advance(by interval: TimeInterval) { current = current.addingTimeInterval(interval) }
}
