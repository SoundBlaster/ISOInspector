#if canImport(SwiftUI) && canImport(Combine)
    import Dispatch
    import Foundation
    import ISOInspectorKit
    import Synchronization
    import XCTest

    @testable import ISOInspectorApp

    @MainActor final class WindowDocumentOpenRaceTests: XCTestCase {
        func testRecentDocumentResolvesBookmarkBeforeOpening() async {
            let originalURL = URL(fileURLWithPath: "/tmp/original.mp4")
            let resolvedURL = URL(fileURLWithPath: "/tmp/resolved.mp4")
            let bookmark = Data("bookmark".utf8)
            let opened = expectation(description: "Resolved document opened")
            let openedURLs = Mutex<[URL]>([])
            let access = FilesystemAccessStub()
            access.resolutions[bookmark] = BookmarkResolution(url: resolvedURL, isStale: false)
            let app = DocumentSessionController(
                recentsStore: DocumentRecentsStoreStub(initialRecents: []),
                filesystemAccess: access.makeAccess())
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    openedURLs.withLock { $0.append(url) }
                    opened.fulfill()
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess())
            window.openRecent(DocumentRecent(
                url: originalURL, bookmarkData: bookmark, displayName: "Original", lastOpened: Date()))
            await fulfillment(of: [opened], timeout: 10)
            XCTAssertEqual(openedURLs.withLock { $0 }, [resolvedURL])
        }

        func testRecentDocumentResolvesBookmarkStoredByIdentifier() async throws {
            let originalURL = URL(fileURLWithPath: "/tmp/stored.mp4")
            let resolvedURL = URL(fileURLWithPath: "/tmp/stored-resolved.mp4")
            let bookmark = Data("stored bookmark".utf8)
            let store = BookmarkPersistenceStoreStub()
            let record = try store.upsertBookmark(for: originalURL, bookmarkData: bookmark)
            let opened = expectation(description: "Stored bookmark resolved")
            let openedURLs = Mutex<[URL]>([])
            let access = FilesystemAccessStub()
            access.resolutions[bookmark] = BookmarkResolution(url: resolvedURL, isStale: false)
            let app = DocumentSessionController(
                recentsStore: DocumentRecentsStoreStub(initialRecents: []),
                bookmarkStore: store, filesystemAccess: access.makeAccess())
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    openedURLs.withLock { $0.append(url) }
                    opened.fulfill()
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess())
            window.openRecent(DocumentRecent(
                url: originalURL, bookmarkIdentifier: record.id, bookmarkData: nil,
                displayName: "Stored", lastOpened: Date()))
            await fulfillment(of: [opened], timeout: 10)
            XCTAssertEqual(openedURLs.withLock { $0 }, [resolvedURL])
        }

        func testSupersededRequestDoesNotStartOpening() async {
            let firstURL = URL(fileURLWithPath: "/tmp/not-started.mp4")
            let secondURL = URL(fileURLWithPath: "/tmp/latest.mp4")
            let openedURLs = Mutex<[URL]>([])
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    openedURLs.withLock { $0.append(url) }
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let first = window.openDocument(at: firstURL)
            let second = window.openDocument(at: secondURL)
            await first.value
            await second.value

            XCTAssertEqual(openedURLs.withLock { $0 }, [secondURL])
            XCTAssertEqual(window.currentDocument?.url, secondURL)
            XCTAssertEqual(access.manager.startedURLs, [secondURL])
        }

        func testOlderOpenCannotReplaceNewerDocument() async {
            let firstURL = URL(fileURLWithPath: "/tmp/older.mp4")
            let secondURL = URL(fileURLWithPath: "/tmp/newer.mp4")
            let firstStarted = expectation(description: "Older reader is being created")
            let releaseFirst = DispatchSemaphore(value: 0)
            defer { releaseFirst.signal() }
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    if url == firstURL {
                        firstStarted.fulfill()
                        guard releaseFirst.wait(timeout: .now() + 20) == .success else {
                            throw OpenTimeout()
                        }
                    }
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let first = window.openDocument(at: firstURL)
            await fulfillment(of: [firstStarted], timeout: 10)
            let second = window.openDocument(at: secondURL)
            await second.value
            XCTAssertEqual(window.currentDocument?.url, secondURL)
            releaseFirst.signal()
            await first.value

            XCTAssertEqual(window.currentDocument?.url, secondURL)
            XCTAssertEqual(window.parseTreeStore.fileURL, secondURL)
            XCTAssertEqual(app.currentDocument?.url, secondURL)
            XCTAssertTrue(access.manager.stoppedURLs.contains(firstURL))
            XCTAssertFalse(access.manager.stoppedURLs.contains(secondURL))
        }

        func testOlderFailureCannotReplaceNewerSuccess() async {
            let firstURL = URL(fileURLWithPath: "/tmp/older-failure.mp4")
            let secondURL = URL(fileURLWithPath: "/tmp/newer-success.mp4")
            let firstStarted = expectation(description: "Older reader is being created")
            let releaseFirst = DispatchSemaphore(value: 0)
            defer { releaseFirst.signal() }
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    if url == firstURL {
                        firstStarted.fulfill()
                        guard releaseFirst.wait(timeout: .now() + 20) == .success else {
                            throw OpenTimeout()
                        }
                        throw OpenFailure()
                    }
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let first = window.openDocument(at: firstURL)
            await fulfillment(of: [firstStarted], timeout: 10)
            let second = window.openDocument(at: secondURL)
            await second.value
            XCTAssertEqual(window.currentDocument?.url, secondURL)
            releaseFirst.signal()
            await first.value

            XCTAssertEqual(window.currentDocument?.url, secondURL)
            XCTAssertEqual(app.currentDocument?.url, secondURL)
            XCTAssertNil(window.loadFailure)
            XCTAssertTrue(access.manager.stoppedURLs.contains(firstURL))
            XCTAssertFalse(access.manager.stoppedURLs.contains(secondURL))
        }

        func testNewerFailureIsNotOverwrittenByOlderSuccess() async {
            let firstURL = URL(fileURLWithPath: "/tmp/older-success.mp4")
            let secondURL = URL(fileURLWithPath: "/tmp/newer-failure.mp4")
            let firstStarted = expectation(description: "Older reader is being created")
            let releaseFirst = DispatchSemaphore(value: 0)
            defer { releaseFirst.signal() }
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    if url == firstURL {
                        firstStarted.fulfill()
                        guard releaseFirst.wait(timeout: .now() + 20) == .success else {
                            throw OpenTimeout()
                        }
                        return StubRandomAccessReader()
                    }
                    throw OpenFailure()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let first = window.openDocument(at: firstURL)
            await fulfillment(of: [firstStarted], timeout: 10)
            let second = window.openDocument(at: secondURL)
            await second.value
            XCTAssertEqual(window.loadFailure?.fileURL, secondURL)
            releaseFirst.signal()
            await first.value

            XCTAssertNil(window.currentDocument)
            XCTAssertNil(app.currentDocument)
            XCTAssertEqual(window.loadFailure?.fileURL, secondURL)
            XCTAssertTrue(access.manager.stoppedURLs.contains(firstURL))
        }

        func testFailedReplacementKeepsCurrentDocumentsSecurityScope() async {
            let firstURL = URL(fileURLWithPath: "/tmp/current.mp4")
            let secondURL = URL(fileURLWithPath: "/tmp/failed-replacement.mp4")
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { url in
                    if url == secondURL { throw OpenFailure() }
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            await window.openDocument(at: firstURL).value
            XCTAssertEqual(window.currentDocument?.url, firstURL)
            await window.openDocument(at: secondURL).value

            XCTAssertEqual(window.currentDocument?.url, firstURL)
            XCTAssertEqual(window.loadFailure?.fileURL, secondURL)
            XCTAssertFalse(access.manager.stoppedURLs.contains(firstURL))
            XCTAssertTrue(access.manager.stoppedURLs.contains(secondURL))
        }

        func testCancellingAnOpenDoesNotStartTheSessionAfterReaderReturns() async {
            let url = URL(fileURLWithPath: "/tmp/cancelled-open.mp4")
            let started = expectation(description: "Reader is being created")
            let releaseReader = DispatchSemaphore(value: 0)
            defer { releaseReader.signal() }
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { _ in
                    started.fulfill()
                    guard releaseReader.wait(timeout: .now() + 20) == .success else {
                        throw OpenTimeout()
                    }
                    return StubRandomAccessReader()
                }, pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let opening = window.openDocument(at: url)
            await fulfillment(of: [started], timeout: 10)
            opening.cancel()
            releaseReader.signal()
            await opening.value

            XCTAssertNil(window.currentDocument)
            XCTAssertNil(window.loadFailure)
            XCTAssertTrue(access.manager.stoppedURLs.contains(url))
        }

        func testCancellingBeforeOpenStartsDoesNotAcquireSecurityScope() async {
            let url = URL(fileURLWithPath: "/tmp/cancelled-before-open.mp4")
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { _ in StubRandomAccessReader() },
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            let opening = window.openDocument(at: url)
            opening.cancel()
            await opening.value

            XCTAssertTrue(access.manager.startedURLs.isEmpty)
            XCTAssertNil(window.currentDocument)
            XCTAssertNil(window.loadFailure)
        }

        func testCancellationErrorFromReaderIsNotShownAsLoadFailure() async {
            let url = URL(fileURLWithPath: "/tmp/cancelled-reader.mp4")
            let access = FilesystemAccessStub()
            let app = DocumentSessionController(recentsStore: DocumentRecentsStoreStub(initialRecents: []))
            let window = WindowSessionController(
                appSessionController: app,
                readerFactory: { _ in throw CancellationError() },
                pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
                filesystemAccess: access.makeAccess(), bookmarkDataProvider: { _ in Data() })

            await window.openDocument(at: url).value

            XCTAssertNil(window.currentDocument)
            XCTAssertNil(window.loadFailure)
            XCTAssertTrue(access.manager.stoppedURLs.contains(url))
        }
    }

    private struct OpenTimeout: Error {}
    private struct OpenFailure: Error {}
#endif
