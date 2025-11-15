#if canImport(Combine)
  import XCTest
  @testable import ISOInspectorApp

  @MainActor
  final class AnnotationBookmarkSessionTests: XCTestCase {
    func testLoadsAnnotationsAndBookmarksForSelectedNode() {
      let store = ConfigurableAnnotationBookmarkStoreStub()
      let file = URL(fileURLWithPath: "/tmp/example.mp4")
      let createdAt = Date(timeIntervalSince1970: 100)
      let later = Date(timeIntervalSince1970: 200)
      store.annotationsStorage[file] = [
        AnnotationRecord(
          id: UUID(), nodeID: 1, note: "Root note", createdAt: createdAt,
          updatedAt: createdAt),
        AnnotationRecord(
          id: UUID(), nodeID: 2, note: "Other node", createdAt: createdAt,
          updatedAt: createdAt),
        AnnotationRecord(
          id: UUID(), nodeID: 1, note: "Follow up", createdAt: later, updatedAt: later),
      ]
      store.bookmarksStorage[file] = [2]

      let session = AnnotationBookmarkSession(store: store)

      session.setFileURL(file)
      session.setSelectedNode(1)

      XCTAssertTrue(session.isEnabled)
      XCTAssertEqual(session.activeAnnotations.map(\.note), ["Root note", "Follow up"])
      XCTAssertFalse(session.isSelectedNodeBookmarked)
      XCTAssertTrue(session.isBookmarked(nodeID: 2))
    }

    func testCreateUpdateDeleteAnnotationUpdatesState() {
      let store = ConfigurableAnnotationBookmarkStoreStub()
      let file = URL(fileURLWithPath: "/tmp/example.mp4")
      let session = AnnotationBookmarkSession(store: store)

      session.setFileURL(file)
      session.setSelectedNode(7)

      session.addAnnotation(note: "Initial")
      XCTAssertEqual(session.activeAnnotations.count, 1)
      let record = try! XCTUnwrap(session.activeAnnotations.first)

      store.currentDate = Date(timeIntervalSince1970: 300)
      session.updateAnnotation(id: record.id, note: "Revised")
      XCTAssertEqual(session.activeAnnotations.first?.note, "Revised")
      XCTAssertEqual(session.activeAnnotations.first?.updatedAt, store.currentDate)

      session.deleteAnnotation(id: record.id)
      XCTAssertTrue(session.activeAnnotations.isEmpty)
    }

    func testToggleBookmarkPersistsState() {
      let store = ConfigurableAnnotationBookmarkStoreStub()
      let file = URL(fileURLWithPath: "/tmp/example.mp4")
      let session = AnnotationBookmarkSession(store: store)

      session.setFileURL(file)
      session.setSelectedNode(99)

      session.toggleBookmark()
      XCTAssertTrue(session.isSelectedNodeBookmarked)
      XCTAssertTrue(session.isBookmarked(nodeID: 99))

      session.toggleBookmark()
      XCTAssertFalse(session.isSelectedNodeBookmarked)
      XCTAssertFalse(session.isBookmarked(nodeID: 99))
    }

    func testRecordsErrorWhenStoreOperationFails() {
      let store = ConfigurableAnnotationBookmarkStoreStub()
      let file = URL(fileURLWithPath: "/tmp/example.mp4")
      store.errorToThrow = SampleError.failed
      let session = AnnotationBookmarkSession(store: store)

      session.setFileURL(file)
      session.setSelectedNode(1)

      session.addAnnotation(note: "Should fail")
      XCTAssertEqual(session.lastErrorMessage, SampleError.failed.localizedDescription)
      XCTAssertTrue(session.activeAnnotations.isEmpty)
    }

    func testDisabledSessionReportsUnavailable() {
      let session = AnnotationBookmarkSession(store: nil)
      session.setFileURL(URL(fileURLWithPath: "/tmp/example.mp4"))
      session.setSelectedNode(1)

      XCTAssertFalse(session.isEnabled)
      XCTAssertTrue(session.activeAnnotations.isEmpty)
      XCTAssertFalse(session.isSelectedNodeBookmarked)
    }

    private enum SampleError: Error {
      case failed
    }
  }

  // MARK: - Test doubles

  private final class ConfigurableAnnotationBookmarkStoreStub: AnnotationBookmarkStoring,
    @unchecked Sendable
  {
    var annotationsStorage: [URL: [AnnotationRecord]] = [:]
    var bookmarksStorage: [URL: Set<Int64>] = [:]
    var currentDate: Date = Date(timeIntervalSince1970: 123)
    var errorToThrow: Error?

    func annotations(for file: URL) throws -> [AnnotationRecord] {
      if let errorToThrow { throw errorToThrow }
      return annotationsStorage[file] ?? []
    }

    func bookmarks(for file: URL) throws -> [BookmarkRecord] {
      if let errorToThrow { throw errorToThrow }
      return bookmarksStorage[file, default: []].map {
        BookmarkRecord(nodeID: $0, createdAt: currentDate)
      }
    }

    func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
      if let errorToThrow { throw errorToThrow }
      let record = AnnotationRecord(
        id: UUID(),
        nodeID: nodeID,
        note: note,
        createdAt: currentDate,
        updatedAt: currentDate
      )
      annotationsStorage[file, default: []].append(record)
      return record
    }

    func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws
      -> AnnotationRecord
    {
      if let errorToThrow { throw errorToThrow }
      guard var annotations = annotationsStorage[file],
        let index = annotations.firstIndex(where: { $0.id == annotationID })
      else {
        throw SampleError.failed
      }
      var updated = annotations[index]
      updated.note = note
      updated.updatedAt = currentDate
      annotations[index] = updated
      annotationsStorage[file] = annotations
      return updated
    }

    func deleteAnnotation(for file: URL, annotationID: UUID) throws {
      if let errorToThrow { throw errorToThrow }
      guard var annotations = annotationsStorage[file] else { return }
      annotations.removeAll { $0.id == annotationID }
      annotationsStorage[file] = annotations
    }

    func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {
      if let errorToThrow { throw errorToThrow }
      var set = bookmarksStorage[file] ?? []
      if isBookmarked {
        set.insert(nodeID)
      } else {
        set.remove(nodeID)
      }
      bookmarksStorage[file] = set
    }

    private enum SampleError: Error {
      case failed
    }
  }

  extension AnnotationBookmarkStoreStub: @unchecked Sendable {}
#endif
