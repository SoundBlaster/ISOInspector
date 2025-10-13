#if canImport(CoreData)
import Foundation
import XCTest
@testable import ISOInspectorApp

final class AnnotationBookmarkStoreTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testCreateAnnotationPersistsRecord() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 42, note: "Check major brand")

        XCTAssertEqual(annotation.nodeID, 42)
        XCTAssertEqual(annotation.note, "Check major brand")
        XCTAssertEqual(annotation.createdAt, referenceDate)
        XCTAssertEqual(annotation.updatedAt, referenceDate)

        let storedAnnotations: [AnnotationRecord] = try store.annotations(for: file)
        XCTAssertEqual(storedAnnotations, [annotation])

        let reloaded = try makeStore(directory: directory)
        let reloadedAnnotations: [AnnotationRecord] = try reloaded.annotations(for: file)
        XCTAssertEqual(reloadedAnnotations, [annotation])
    }

    func testUpdateAnnotationChangesNoteAndTimestamp() throws {
        let directory = try makeTemporaryDirectory()
        let now = DateBox(referenceDate)
        let store = try makeStore(directory: directory) { now.value }
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 7, note: "Initial")

        now.value = now.value.addingTimeInterval(60)
        let updated = try store.updateAnnotation(for: file, annotationID: annotation.id, note: "Revised note")

        XCTAssertEqual(updated.id, annotation.id)
        XCTAssertEqual(updated.createdAt, referenceDate)
        XCTAssertEqual(updated.updatedAt, referenceDate + 60)
        XCTAssertEqual(updated.note, "Revised note")
        let updatedAnnotations: [AnnotationRecord] = try store.annotations(for: file)
        XCTAssertEqual(updatedAnnotations, [updated])
    }

    func testDeleteAnnotationRemovesRecord() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 1, note: "Remove me")
        try store.deleteAnnotation(for: file, annotationID: annotation.id)

        XCTAssertTrue(try store.annotations(for: file).isEmpty)
    }

    func testToggleBookmarkPersistsState() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        try store.setBookmark(for: file, nodeID: 256, isBookmarked: true)
        XCTAssertEqual(try store.bookmarks(for: file).map(\.nodeID), [256])

        try store.setBookmark(for: file, nodeID: 256, isBookmarked: false)
        XCTAssertTrue(try store.bookmarks(for: file).isEmpty)
    }

    func testUpdateMissingAnnotationThrows() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory)
        let file = URL(fileURLWithPath: "/tmp/sample.mp4")

        XCTAssertThrowsError(
            try store.updateAnnotation(for: file, annotationID: UUID(), note: "Does not exist")
        ) { error in
            XCTAssertEqual(error as? AnnotationBookmarkStoreError, .annotationNotFound)
        }
    }

    func testSeparateFilesMaintainIndependentRecords() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory)
        let fileA = URL(fileURLWithPath: "/tmp/a.mp4")
        let fileB = URL(fileURLWithPath: "/tmp/b.mp4")

        let annotationA = try store.createAnnotation(for: fileA, nodeID: 1, note: "A")
        let annotationB = try store.createAnnotation(for: fileB, nodeID: 2, note: "B")

        try store.setBookmark(for: fileA, nodeID: 10, isBookmarked: true)

        let annotationsA: [AnnotationRecord] = try store.annotations(for: fileA)
        let annotationsB: [AnnotationRecord] = try store.annotations(for: fileB)
        XCTAssertEqual(annotationsA, [annotationA])
        XCTAssertEqual(annotationsB, [annotationB])
        XCTAssertEqual(try store.bookmarks(for: fileA).map(\.nodeID), [10])
        XCTAssertTrue(try store.bookmarks(for: fileB).isEmpty)
    }

    func testInitializingWithExplicitModelVersionUsesSchema() throws {
        let directory = try makeTemporaryDirectory()
        let store = try makeStore(directory: directory, modelVersion: .v1)
        let file = URL(fileURLWithPath: "/tmp/version-check.mp4")

        let annotation = try store.createAnnotation(for: file, nodeID: 99, note: "Ensure schema loads")

        XCTAssertEqual(annotation.nodeID, 99)
        let annotations: [AnnotationRecord] = try store.annotations(for: file)
        XCTAssertEqual(annotations, [annotation])
    }

    // MARK: - Helpers

    private func makeStore(
        directory: URL,
        modelVersion: CoreDataAnnotationBookmarkStore.ModelVersion = .latest,
        now: @escaping @Sendable () -> Date
    ) throws -> CoreDataAnnotationBookmarkStore {
        try CoreDataAnnotationBookmarkStore(directory: directory, modelVersion: modelVersion, makeDate: now)
    }

    private func makeStore(
        directory: URL,
        modelVersion: CoreDataAnnotationBookmarkStore.ModelVersion
    ) throws -> CoreDataAnnotationBookmarkStore {
        let date = referenceDate
        return try makeStore(directory: directory, modelVersion: modelVersion) { date }
    }

    private func makeStore(directory: URL) throws -> CoreDataAnnotationBookmarkStore {
        let date = referenceDate
        return try makeStore(directory: directory, modelVersion: .latest) { date }
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
#endif
