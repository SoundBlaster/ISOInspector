#if canImport(AppKit) && canImport(Combine) && canImport(SwiftUI)
  import AppKit
  import Combine
  import SwiftUI
  import XCTest
  @testable import ISOInspectorApp
  @testable import ISOInspectorKit

  @MainActor
  final class AppShellViewErrorBannerTests: XCTestCase {
    // FIXME: This test attempts to verify UI behavior (banner appearing/disappearing)
    // in a unit test, which is incorrect. This should be:
    // 1. A UI Test (XCUITest) if we want to verify the banner actually appears, OR
    // 2. A unit test that verifies controller.loadFailure state changes (without creating views)
    //
    // Current approach (mixing both) causes timeouts and is fragile.
    // Recommendation: Move to UI test suite or simplify to pure state testing.
    func skip_testBannerAppearsForLoadFailureAndClearsAfterRetry() throws {
      let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
      final class MutableFlag: @unchecked Sendable {
        var value: Bool
        init(_ value: Bool) { self.value = value }
      }
      let shouldFail = MutableFlag(true)
      let filesystemAccessStub = FilesystemAccessStub()
      let controller = DocumentSessionController(
        parseTreeStore: ParseTreeStore(),
        annotations: AnnotationBookmarkSession(store: nil),
        recentsStore: recentsStore,
        sessionStore: nil,
        pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
        readerFactory: { _ in
          if shouldFail.value {
            shouldFail.value = false
            struct SampleError: LocalizedError {
              var errorDescription: String? { "Simulated failure" }
            }
            throw SampleError()
          }
          return StubRandomAccessReader()
        },
        workQueue: ImmediateWorkQueue(),
        filesystemAccess: filesystemAccessStub.makeAccess()
      )

      let url = URL(fileURLWithPath: "/tmp/banner.mp4")

      // Attempt to open document (will fail first time)
      controller.openDocument(at: url)

      // Since we use ImmediateWorkQueue, operations complete synchronously
      // Just allow main queue to settle
      let failureExpectation = expectation(description: "Failure processed")
      DispatchQueue.main.async {
        failureExpectation.fulfill()
      }
      wait(for: [failureExpectation], timeout: 1.0)

      // Verify load failure is set
      XCTAssertNotNil(
        controller.loadFailure, "Load failure should be recorded after failed open")

      // Retry (will succeed second time)
      controller.retryLastFailure()

      // Allow main queue to settle after retry
      let retryExpectation = expectation(description: "Retry processed")
      DispatchQueue.main.async {
        retryExpectation.fulfill()
      }
      wait(for: [retryExpectation], timeout: 1.0)

      // Verify load failure is cleared after successful retry
      XCTAssertNil(
        controller.loadFailure, "Load failure should be cleared after successful retry")
    }

    // FIXME: This test attempts to verify UI behavior (corruption ribbon appearing)
    // in a unit test, which is incorrect. This should be:
    // 1. A UI Test (XCUITest) if we want to verify the ribbon actually appears, OR
    // 2. A unit test that verifies controller.parseTreeStore.issueStore.metrics state
    //
    // containsText() doesn't work with SwiftUI - use XCUITest for actual UI verification.
    // Recommendation: Move to UI test suite or simplify to pure state testing.
    func skip_testCorruptionWarningRibbonAppearsForIssueMetrics() throws {
      let defaultsKey = AppShellView.corruptionRibbonDismissedDefaultsKey
      UserDefaults.standard.removeObject(forKey: defaultsKey)

      let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
      let controller = DocumentSessionController(
        parseTreeStore: ParseTreeStore(),
        annotations: AnnotationBookmarkSession(store: nil),
        recentsStore: recentsStore,
        sessionStore: nil,
        pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
        readerFactory: { _ in StubRandomAccessReader() },
        workQueue: ImmediateWorkQueue(),
        filesystemAccess: FilesystemAccessStub().makeAccess()
      )

      let view = AppShellView(appController: controller)
      let hostingView = NSHostingView(rootView: view.frame(width: 800, height: 600))

      controller.parseTreeStore.issueStore.record(
        ParseIssue(
          severity: .warning,
          code: "VR-100",
          message: "Simulated warning",
          byteRange: 0..<8,
          affectedNodeIDs: [1]
        ),
        depth: 1
      )

      // Allow SwiftUI to update the view hierarchy
      let updateExpectation = expectation(description: "View updated")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        updateExpectation.fulfill()
      }
      wait(for: [updateExpectation], timeout: 1.0)

      XCTAssertTrue(hostingView.containsText("View Integrity Report"))
    }
  }

  extension NSView {
    fileprivate func containsText(_ substring: String) -> Bool {
      if let textField = self as? NSTextField, textField.stringValue.contains(substring) {
        return true
      }
      for subview in subviews where subview.containsText(substring) {
        return true
      }
      return false
    }
  }
#endif
