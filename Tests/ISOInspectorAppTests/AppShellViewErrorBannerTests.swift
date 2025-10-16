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
        let controller = DocumentSessionController(
            parseTreeStore: ParseTreeStore(bridge: ParsePipelineEventBridge()),
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
            workQueue: ImmediateWorkQueue()
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
        defer { window.close() }

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
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertTrue(hostingView.containsText("Unable to open"))

        controller.retryLastFailure()
        wait(for: [finished], timeout: 1.0)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertFalse(hostingView.containsText("Unable to open"))
    }
}

private extension NSView {
    func containsText(_ substring: String) -> Bool {
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
