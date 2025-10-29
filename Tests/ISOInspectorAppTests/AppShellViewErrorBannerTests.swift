#if canImport(AppKit) && canImport(Combine) && canImport(SwiftUI)
    import AppKit
    import Combine
    import SwiftUI
    import XCTest
    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    @MainActor
    final class AppShellViewErrorBannerTests: XCTestCase {
        func testBannerAppearsForLoadFailureAndClearsAfterRetry() throws {
            let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
            var shouldFail = true
            let filesystemAccessStub = FilesystemAccessStub()
            let controller = DocumentSessionController(
                parseTreeStore: ParseTreeStore(),
                annotations: AnnotationBookmarkSession(store: nil),
                recentsStore: recentsStore,
                sessionStore: nil,
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                readerFactory: { _ in
                    if shouldFail {
                        shouldFail = false
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

            let view = AppShellView(controller: controller)
            let hostingView = NSHostingView(rootView: view.frame(width: 800, height: 600))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.makeKeyAndOrderFront(nil)

            let url = URL(fileURLWithPath: "/tmp/banner.mp4")
            var cancellables: Set<AnyCancellable> = []
            let finished = expectation(description: "Parsing finished after retry")

            controller.parseTreeStore.$state
                .dropFirst()
                .sink { state in
                    if state == .finished {
                        finished.fulfill()
                    }
                }
                .store(in: &cancellables)

            controller.openDocument(at: url)

            // Allow SwiftUI to update the view hierarchy
            let firstUpdateExpectation = expectation(description: "View updated after error")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                firstUpdateExpectation.fulfill()
            }
            wait(for: [firstUpdateExpectation], timeout: 1.0)

            XCTAssertTrue(hostingView.containsText("Unable to open"))

            controller.retryLastFailure()
            wait(for: [finished], timeout: 1.0)

            // Allow SwiftUI to update the view hierarchy after retry
            let secondUpdateExpectation = expectation(description: "View updated after retry")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                secondUpdateExpectation.fulfill()
            }
            wait(for: [secondUpdateExpectation], timeout: 1.0)

            XCTAssertFalse(hostingView.containsText("Unable to open"))

            // Clean up Combine subscriptions before closing window
            cancellables.removeAll()

            // Allow time for cleanup before closing window
            let cleanupExpectation = expectation(description: "Cleanup complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                cleanupExpectation.fulfill()
            }
            wait(for: [cleanupExpectation], timeout: 1.0)

            window.close()
        }

        func testCorruptionWarningRibbonAppearsForIssueMetrics() throws {
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

            let view = AppShellView(controller: controller)
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
