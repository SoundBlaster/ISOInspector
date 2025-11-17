#if canImport(SwiftUI) && canImport(Combine)
  import XCTest
  import Combine
  @testable import ISOInspectorApp
  import ISOInspectorKit

  @MainActor
  final class WindowSessionControllerTests: XCTestCase {
    /// Test that two WindowSessionController instances have independent currentDocument state
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

      // Set up test documents (just for state testing, not loading)
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

      // Directly set currentDocument state to test independence
      // (avoid async file loading which would fail on non-existent files)
      window1.currentDocument = recent1
      window2.currentDocument = recent2

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

    /// Test that documentViewModel publishes changes from ParseTreeStore
    /// This test prevents regression of bug #232 where documentViewModel binding was broken
    func testDocumentViewModelPublishesParseTreeStoreChanges() async {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      let windowController = WindowSessionController(appSessionController: appController)

      // Create expectation for issue metrics change
      let expectation = XCTestExpectation(description: "Issue metrics updated")
      var cancellables = Set<AnyCancellable>()

      // Subscribe to issueMetrics through windowController
      windowController.$issueMetrics
        .dropFirst() // Skip initial value
        .sink { metrics in
          if metrics.totalCount > 0 {
            expectation.fulfill()
          }
        }
        .store(in: &cancellables)

      // Simulate parse tree store update with issues
      let mockIssue = ParseIssue(
        severity: .error,
        code: "TEST-001",
        message: "Test issue message",
        byteRange: 0..<10,
        affectedNodeIDs: []
      )

      windowController.parseTreeStore.issueStore.record(mockIssue)

      // Wait for the published change to propagate
      await fulfillment(of: [expectation], timeout: 2.0)

      // Verify that issueMetrics reflects the change
      XCTAssertGreaterThan(windowController.issueMetrics.totalCount, 0)
    }

    /// Test that documentViewModel is accessible and consistent with windowController state
    /// This test prevents regression of bug #232 where documentViewModel was initialized
    /// from a local variable, breaking the binding chain
    func testDocumentViewModelAccessibilityAndConsistency() {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      let windowController = WindowSessionController(appSessionController: appController)

      // Get documentViewModel reference
      let viewModel = windowController.documentViewModel

      // Verify that documentViewModel uses the same parseTreeStore
      XCTAssertEqual(
        ObjectIdentifier(viewModel.store),
        ObjectIdentifier(windowController.parseTreeStore)
      )

      // Verify that documentViewModel uses the same annotations
      XCTAssertEqual(
        ObjectIdentifier(viewModel.annotations),
        ObjectIdentifier(windowController.annotations)
      )

      // Multiple accesses should return the same instance (important for SwiftUI binding)
      let viewModel2 = windowController.documentViewModel
      XCTAssertEqual(ObjectIdentifier(viewModel), ObjectIdentifier(viewModel2))
    }

    /// Test that documentViewModel binding chain remains intact after initialization
    /// This is a regression test for bug #232
    func testDocumentViewModelBindingIntegrity() async throws {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      // Simulate AppShellView initialization pattern:
      // Create windowController, then access documentViewModel
      let windowController = WindowSessionController(appSessionController: appController)

      // Access documentViewModel like AppShellView would (as computed property)
      let documentViewModel = windowController.documentViewModel

      // Create expectation for snapshot change
      let expectation = XCTestExpectation(description: "Snapshot updated")
      var cancellables = Set<AnyCancellable>()

      // Subscribe to snapshot changes through documentViewModel
      documentViewModel.$snapshot
        .dropFirst() // Skip initial value
        .sink { updatedSnapshot in
          if !updatedSnapshot.nodes.isEmpty {
            expectation.fulfill()
          }
        }
        .store(in: &cancellables)

      // Since ParseTreeStore doesn't expose updateSnapshot for testing,
      // we verify the binding by checking that accessing documentViewModel
      // multiple times returns consistent state

      // Get initial snapshot from documentViewModel
      let initialSnapshot = documentViewModel.snapshot

      // Get snapshot again - should be same instance through the binding
      let secondSnapshot = windowController.documentViewModel.snapshot

      // Verify binding integrity: both accesses should reflect the same underlying store state
      XCTAssertEqual(initialSnapshot, secondSnapshot)
      XCTAssertEqual(documentViewModel.snapshot, windowController.parseTreeStore.snapshot)

      // Verify that documentViewModel's store property points to windowController's parseTreeStore
      XCTAssertTrue(documentViewModel.store === windowController.parseTreeStore)
    }

    // MARK: - Test Helpers

    private static func makeHeader(offset: Int64, type: String) throws -> BoxHeader {
      let fourcc = try FourCharCode(type)
      return BoxHeader(
        type: fourcc,
        totalSize: 48,
        headerSize: 8,
        payloadRange: offset + 8..<offset + 16,
        range: offset..<offset + 48,
        uuid: nil
      )
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
