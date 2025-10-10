import XCTest
@testable import ISOInspectorApp

final class AnnotationBookmarkStoreTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testCreateAnnotationPersistsRecord() throws {
        let directory = try makeTemporaryDirectory()
        let store = makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 42, note: "Check major brand")

        XCTAssertEqual(annotation.nodeID, 42)
        XCTAssertEqual(annotation.note, "Check major brand")
        XCTAssertEqual(annotation.createdAt, referenceDate)
        XCTAssertEqual(annotation.updatedAt, referenceDate)

        XCTAssertEqual(try store.annotations(for: file), [annotation])

        let reloaded = makeStore(directory: directory)
        XCTAssertEqual(try reloaded.annotations(for: file), [annotation])
    }

    func testUpdateAnnotationChangesNoteAndTimestamp() throws {
        let directory = try makeTemporaryDirectory()
        let now = DateBox(referenceDate)
        let store = makeStore(directory: directory) { now.value }
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 7, note: "Initial")

        now.value = now.value.addingTimeInterval(60)
        let updated = try store.updateAnnotation(for: file, annotationID: annotation.id, note: "Revised note")

        XCTAssertEqual(updated.id, annotation.id)
        XCTAssertEqual(updated.createdAt, referenceDate)
        XCTAssertEqual(updated.updatedAt, referenceDate + 60)
        XCTAssertEqual(updated.note, "Revised note")
        XCTAssertEqual(try store.annotations(for: file), [updated])
    }

    func testDeleteAnnotationRemovesRecord() throws {
        let directory = try makeTemporaryDirectory()
        let store = makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 1, note: "Remove me")
        try store.deleteAnnotation(for: file, annotationID: annotation.id)

        XCTAssertTrue(try store.annotations(for: file).isEmpty)
    }

    func testToggleBookmarkPersistsState() throws {
        let directory = try makeTemporaryDirectory()
        let store = makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        try store.setBookmark(for: file, nodeID: 256, isBookmarked: true)
        XCTAssertEqual(try store.bookmarks(for: file).map(\.nodeID), [256])

        try store.setBookmark(for: file, nodeID: 256, isBookmarked: false)
        XCTAssertTrue(try store.bookmarks(for: file).isEmpty)
    }

    // MARK: - Helpers

    private func makeStore(directory: URL, now: @escaping @Sendable () -> Date) -> FileBackedAnnotationBookmarkStore {
        FileBackedAnnotationBookmarkStore(directory: directory, makeDate: now)
    }

    private func makeStore(directory: URL) -> FileBackedAnnotationBookmarkStore {
        let date = referenceDate
        return makeStore(directory: directory) { date }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private final class DateBox: @unchecked Sendable {
    var value: Date

    init(_ value: Date) {
        self.value = value
    }
}
