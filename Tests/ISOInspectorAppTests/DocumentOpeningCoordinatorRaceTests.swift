#if canImport(Combine) && canImport(SwiftUI)
    import Combine
    import Dispatch
    import Foundation
    import ISOInspectorKit
    import Synchronization
    import XCTest

    @testable import ISOInspectorApp

    @MainActor final class DocumentOpeningCoordinatorRaceTests: XCTestCase {
        func testFailedNewerAccessDoesNotAllowOlderOpenToStartSession() async {
            let olderURL = URL(fileURLWithPath: "/tmp/coordinator-older.mp4")
            let newerURL = URL(fileURLWithPath: "/tmp/coordinator-denied.mp4")
            let readerStarted = expectation(description: "Older reader started")
            let olderHandled = expectation(description: "Older open was handled")
            olderHandled.assertForOverFulfill = false
            let releaseReader = DispatchSemaphore(value: 0)
            defer { releaseReader.signal() }

            let manager = RaceScopeManager(deniedURL: newerURL) { url in
                if url == olderURL { olderHandled.fulfill() }
            }
            let access = FilesystemAccess(
                openFileHandler: { _ in olderURL },
                saveFileHandler: { _ in olderURL },
                bookmarkCreator: { Data($0.path.utf8) },
                bookmarkResolver: { _ in BookmarkResolution(url: olderURL, isStale: false) },
                securityScopeManager: manager, logger: .disabled)
            let controller = DocumentSessionController(
                recentsStore: DocumentRecentsStoreStub(initialRecents: []),
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                readerFactory: { _ in
                    readerStarted.fulfill()
                    guard releaseReader.wait(timeout: .now() + 20) == .success else {
                        throw ReaderTimeout()
                    }
                    return StubRandomAccessReader()
                }, filesystemAccess: access, bookmarkDataProvider: { _ in Data() })
            let observation = controller.$currentDocument.dropFirst().sink { document in
                if document?.url == olderURL { olderHandled.fulfill() }
            }

            controller.openDocument(at: olderURL)
            await fulfillment(of: [readerStarted], timeout: 10)
            controller.openDocument(at: newerURL)
            XCTAssertEqual(controller.loadFailure?.fileURL, newerURL)

            releaseReader.signal()
            await fulfillment(of: [olderHandled], timeout: 10)

            XCTAssertNil(controller.currentDocument)
            XCTAssertNil(controller.parseTreeStore.fileURL)
            XCTAssertEqual(controller.loadFailure?.fileURL, newerURL)
            XCTAssertEqual(manager.stoppedURLs, [olderURL])
            withExtendedLifetime(observation) {}
        }

        func testWindowOpenSupersedesPendingAppSessionOpen() async {
            let olderURL = URL(fileURLWithPath: "/tmp/coordinator-pending.mp4")
            let newerURL = URL(fileURLWithPath: "/tmp/window-current.mp4")
            let readerStarted = expectation(description: "App session reader started")
            let olderHandled = expectation(description: "Pending app session open was handled")
            olderHandled.assertForOverFulfill = false
            let releaseReader = DispatchSemaphore(value: 0)
            defer { releaseReader.signal() }
            let manager = RaceScopeManager(deniedURL: newerURL) { url in
                if url == olderURL { olderHandled.fulfill() }
            }
            let access = FilesystemAccess(
                openFileHandler: { _ in olderURL }, saveFileHandler: { _ in olderURL },
                bookmarkCreator: { Data($0.path.utf8) },
                bookmarkResolver: { _ in BookmarkResolution(url: olderURL, isStale: false) },
                securityScopeManager: manager, logger: .disabled)
            let controller = DocumentSessionController(
                recentsStore: DocumentRecentsStoreStub(initialRecents: []),
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                readerFactory: { _ in
                    readerStarted.fulfill()
                    guard releaseReader.wait(timeout: .now() + 20) == .success else {
                        throw ReaderTimeout()
                    }
                    return StubRandomAccessReader()
                }, filesystemAccess: access, bookmarkDataProvider: { _ in Data() })
            let observation = controller.$currentDocument.dropFirst().sink { document in
                if document?.url == olderURL { olderHandled.fulfill() }
            }
            let windowAccess = FilesystemAccessStub()
            let window = WindowSessionController(
                appSessionController: controller, readerFactory: { _ in StubRandomAccessReader() },
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: windowAccess.makeAccess(), bookmarkDataProvider: { _ in Data() })

            controller.openDocument(at: olderURL)
            await fulfillment(of: [readerStarted], timeout: 10)
            await window.openDocument(at: newerURL).value
            XCTAssertEqual(controller.currentDocument?.url, newerURL)

            releaseReader.signal()
            await fulfillment(of: [olderHandled], timeout: 10)

            XCTAssertEqual(controller.currentDocument?.url, newerURL)
            XCTAssertEqual(controller.parseTreeStore.fileURL, newerURL)
            XCTAssertEqual(window.currentDocument?.url, newerURL)
            XCTAssertNil(controller.loadFailure)
            XCTAssertEqual(manager.stoppedURLs, [olderURL])
            withExtendedLifetime(observation) {}
        }

        func testFailedReplacementEndsSessionRestoration() async {
            let olderURL = URL(fileURLWithPath: "/tmp/restore-pending.mp4")
            let newerURL = URL(fileURLWithPath: "/tmp/restore-denied.mp4")
            let readerStarted = expectation(description: "Restored document reader started")
            let olderHandled = expectation(description: "Restored document scope released")
            let releaseReader = DispatchSemaphore(value: 0)
            defer { releaseReader.signal() }
            let manager = RaceScopeManager(deniedURL: newerURL) { url in
                if url == olderURL { olderHandled.fulfill() }
            }
            let access = FilesystemAccess(
                openFileHandler: { _ in olderURL }, saveFileHandler: { _ in olderURL },
                bookmarkCreator: { Data($0.path.utf8) },
                bookmarkResolver: { _ in BookmarkResolution(url: olderURL, isStale: false) },
                securityScopeManager: manager, logger: .disabled)
            let recent = DocumentRecent(
                url: olderURL, bookmarkData: nil, displayName: "Restored", lastOpened: Date())
            let sessionStore = WorkspaceSessionStoreStub()
            sessionStore.loadedSnapshot = WorkspaceSessionSnapshot(
                id: UUID(), createdAt: Date(), updatedAt: Date(), appVersion: "1.0",
                files: [WorkspaceSessionFileSnapshot(
                    id: UUID(), recent: recent, orderIndex: 0, lastSelectionNodeID: nil,
                    isPinned: false, scrollOffset: nil, bookmarkIdentifier: nil,
                    bookmarkDiffs: [], validationConfiguration: nil)],
                focusedFileURL: olderURL, lastSceneIdentifier: nil, windowLayouts: [])
            let controller = DocumentSessionController(
                recentsStore: DocumentRecentsStoreStub(initialRecents: []), sessionStore: sessionStore,
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                readerFactory: { _ in
                    readerStarted.fulfill()
                    guard releaseReader.wait(timeout: .now() + 20) == .success else {
                        throw ReaderTimeout()
                    }
                    return StubRandomAccessReader()
                }, filesystemAccess: access, bookmarkDataProvider: { _ in Data() })

            await fulfillment(of: [readerStarted], timeout: 10)
            controller.openDocument(at: newerURL)
            XCTAssertEqual(controller.loadFailure?.fileURL, newerURL)
            controller.annotations.setSelectedNode(123)
            XCTAssertEqual(sessionStore.savedSnapshots.count, 1)

            releaseReader.signal()
            await fulfillment(of: [olderHandled], timeout: 10)
            XCTAssertEqual(controller.loadFailure?.fileURL, newerURL)
        }
    }

    private struct ReaderTimeout: Error {}

    private final class RaceScopeManager: SecurityScopedAccessManaging, Sendable {
        private let deniedURL: URL
        private let onStop: @Sendable (URL) -> Void
        private let stopped = Mutex<[URL]>([])

        init(deniedURL: URL, onStop: @escaping @Sendable (URL) -> Void) {
            self.deniedURL = deniedURL
            self.onStop = onStop
        }

        var stoppedURLs: [URL] { stopped.withLock { $0 } }

        func startAccessing(_ url: URL) -> Bool { url != deniedURL }

        func stopAccessing(_ url: URL) {
            stopped.withLock { $0.append(url) }
            onStop(url)
        }
    }
#endif
