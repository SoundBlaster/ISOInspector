#if canImport(SwiftUI) && canImport(Combine)
  import XCTest
  import Combine
  @testable import ISOInspectorApp
  import ISOInspectorKit

  @MainActor
  final class WindowSessionControllerTests: XCTestCase {
    /// Test that two WindowSessionController instances have independent state
    func testMultipleWindowsHaveIndependentState() throws {
      // Create a mock app controller (shared across windows)
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil,
        diagnostics: DiagnosticsLogger(subsystem: "test", category: "test")
      )

      // Create two window controllers - each should be independent
      let window1 = WindowSessionController(appSessionController: appController)
      let window2 = WindowSessionController(appSessionController: appController)

      // Set up test documents
      let testURL1 = URL(fileURLWithPath: "/test/document1.mp4")
      let testURL2 = URL(fileURLWithPath: "/test/document2.mp4")

      let recent1 = DocumentRecent(
        url: testURL1,
        bookmarkIdentifier: nil,
        bookmarkData: nil,
        displayName: "Document 1",
        lastOpened: Date()
      )

      let recent2 = DocumentRecent(
        url: testURL2,
        bookmarkIdentifier: nil,
        bookmarkData: nil,
        displayName: "Document 2",
        lastOpened: Date()
      )

      // Open different documents in each window using public API
      window1.openRecent(recent1)
      window2.openRecent(recent2)

      // Verify that each window maintains its own state
      XCTAssertEqual(window1.currentDocument?.url, testURL1)
      XCTAssertEqual(window2.currentDocument?.url, testURL2)

      // Verify that they are independent (different URLs mean different documents)
      XCTAssertNotEqual(window1.currentDocument?.url, window2.currentDocument?.url)
    }

    /// Test that WindowSessionController has independent ParseTreeStore
    func testWindowsHaveIndependentParseTreeStores() {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      let window1 = WindowSessionController(appSessionController: appController)
      let window2 = WindowSessionController(appSessionController: appController)

      // Verify that each window has its own ParseTreeStore instance
      XCTAssertNotEqual(ObjectIdentifier(window1.parseTreeStore), ObjectIdentifier(window2.parseTreeStore))
    }

    /// Test that WindowSessionController has independent DocumentViewModel
    func testWindowsHaveIndependentDocumentViewModels() {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      let window1 = WindowSessionController(appSessionController: appController)
      let window2 = WindowSessionController(appSessionController: appController)

      // Verify that each window has its own DocumentViewModel instance
      XCTAssertNotEqual(ObjectIdentifier(window1.documentViewModel), ObjectIdentifier(window2.documentViewModel))
    }

    /// Test that WindowSessionController has independent AnnotationBookmarkSession
    func testWindowsHaveIndependentAnnotationSessions() {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      let window1 = WindowSessionController(appSessionController: appController)
      let window2 = WindowSessionController(appSessionController: appController)

      // Verify that each window has its own AnnotationBookmarkSession instance
      XCTAssertNotEqual(ObjectIdentifier(window1.annotations), ObjectIdentifier(window2.annotations))
    }
  }

  // MARK: - Test Helpers

  /// In-memory store for testing
  private class InMemoryDocumentRecentsStore: DocumentRecentsStoring {
    private var recents: [DocumentRecent] = []

    func load() throws -> [DocumentRecent] {
      recents
    }

    func save(_ recents: [DocumentRecent]) throws {
      self.recents = recents
    }
  }
#endif
