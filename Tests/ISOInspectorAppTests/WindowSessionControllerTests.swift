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
        id: UUID(),
        displayName: "Document 1",
        url: testURL1,
        lastOpened: Date()
      )

      let recent2 = DocumentRecent(
        id: UUID(),
        displayName: "Document 2",
        url: testURL2,
        lastOpened: Date()
      )

      // Set different documents in each window
      window1.currentDocument = recent1
      window2.currentDocument = recent2

      // Verify that each window maintains its own state
      XCTAssertEqual(window1.currentDocument?.url, testURL1)
      XCTAssertEqual(window2.currentDocument?.url, testURL2)

      // Verify that they are independent
      XCTAssertNotEqual(window1.currentDocument?.id, window2.currentDocument?.id)
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

    func loadRecents() throws -> [DocumentRecent] {
      recents
    }

    func saveRecents(_ recents: [DocumentRecent]) throws {
      self.recents = recents
    }
  }
#endif
