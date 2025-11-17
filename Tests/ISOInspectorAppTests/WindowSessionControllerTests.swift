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
        id: UUID(),
        affectedNodeIDs: [],
        category: .structural,
        severity: .error,
        title: "Test Issue",
        message: "Test issue message",
        details: nil,
        specification: nil,
        context: ParseIssue.Context(
          sourceFileURL: URL(fileURLWithPath: "/test.mp4"),
          boxPath: [],
          byteRange: 0..<10
        )
      )

      windowController.parseTreeStore.issueStore.insert(mockIssue)

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
        ObjectIdentifier(viewModel.nodeViewModel.store),
        ObjectIdentifier(windowController.parseTreeStore)
      )

      // Verify that documentViewModel uses the same annotations
      XCTAssertEqual(
        ObjectIdentifier(viewModel.annotationViewModel.session),
        ObjectIdentifier(windowController.annotations)
      )

      // Multiple accesses should return the same instance (important for SwiftUI binding)
      let viewModel2 = windowController.documentViewModel
      XCTAssertEqual(ObjectIdentifier(viewModel), ObjectIdentifier(viewModel2))
    }

    /// Test that documentViewModel binding chain remains intact after initialization
    /// This is a regression test for bug #232
    func testDocumentViewModelBindingIntegrity() async {
      let recentsStore = InMemoryDocumentRecentsStore()
      let appController = DocumentSessionController(
        recentsStore: recentsStore,
        sessionStore: nil
      )

      // Simulate AppShellView initialization pattern
      let windowController = WindowSessionController(appSessionController: appController)

      // Access documentViewModel like AppShellView would (as computed property)
      let documentViewModel = windowController.documentViewModel

      // Create expectation for node count change
      let expectation = XCTestExpectation(description: "Node count updated")
      var cancellables = Set<AnyCancellable>()

      // Subscribe to nodeCount changes through documentViewModel
      documentViewModel.nodeViewModel.$nodeCount
        .dropFirst() // Skip initial value
        .sink { count in
          if count > 0 {
            expectation.fulfill()
          }
        }
        .store(in: &cancellables)

      // Create a minimal parse tree
      let rootNode = ParseTreeNode(
        id: UUID(),
        boxType: "test",
        offset: 0,
        size: 100,
        depth: 0,
        children: [],
        properties: []
      )

      let snapshot = ParseTreeStore.Snapshot(
        rootNodeID: rootNode.id,
        nodes: [rootNode.id: rootNode],
        nodeChildren: [rootNode.id: []],
        nodeParents: [:],
        nodeDepths: [rootNode.id: 0],
        expandedNodeIDs: Set([rootNode.id])
      )

      // Update parseTreeStore - this should propagate through documentViewModel
      windowController.parseTreeStore.updateSnapshot(snapshot)

      // Wait for the change to propagate through the binding chain
      await fulfillment(of: [expectation], timeout: 2.0)

      // Verify that the change is visible through documentViewModel
      XCTAssertGreaterThan(documentViewModel.nodeViewModel.nodeCount, 0)
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
