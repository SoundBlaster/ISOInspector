import Foundation
import XCTest
@testable import ISOInspectorKit

final class FilesystemAccessTests: XCTestCase {
    func testOpenFileStartsSecurityScopeAndLogs() async throws {
        let expectedURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let openDialog = FilesystemAccessTestDialog(result: expectedURL)
        let scopeManager = FilesystemAccessTestSecurityScope()
        let bookmarkManager = FilesystemAccessTestBookmarkManager()
        let logger = FilesystemAccessTestLogger()

        let access = FilesystemAccess(
            openFileHandler: openDialog.open,
            saveFileHandler: { _ in expectedURL },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: scopeManager,
            logger: .init(logger)
        )

        let scopedURL = try await access.openFile()

        XCTAssertEqual(scopedURL.url, expectedURL)
        XCTAssertEqual(scopeManager.startedURLs, [expectedURL])
        XCTAssertTrue(logger.infoMessages.contains { $0.contains("access_granted") })

        scopedURL.revoke()
        XCTAssertEqual(scopeManager.stoppedURLs, [expectedURL])
    }

    func testCreateBookmarkLogsSuccess() throws {
        let expectedURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let scopeManager = FilesystemAccessTestSecurityScope()
        let bookmarkManager = FilesystemAccessTestBookmarkManager()
        let logger = FilesystemAccessTestLogger()

        let access = FilesystemAccess(
            openFileHandler: { _ in expectedURL },
            saveFileHandler: { _ in expectedURL },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: scopeManager,
            logger: .init(logger)
        )

        let scoped = SecurityScopedURL(url: expectedURL, manager: scopeManager)
        let bookmark = try access.createBookmark(for: scoped)

        XCTAssertEqual(bookmark, bookmarkManager.bookmarkData)
        XCTAssertEqual(bookmarkManager.createdURLs, [expectedURL])
        XCTAssertTrue(logger.infoMessages.contains { $0.contains("bookmark.create.success") })
    }

    func testResolveBookmarkDataReturnsStaleState() throws {
        let expectedURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let scopeManager = FilesystemAccessTestSecurityScope()
        let bookmarkManager = FilesystemAccessTestBookmarkManager()
        bookmarkManager.nextResolution = BookmarkResolution(url: expectedURL, isStale: true)
        let logger = FilesystemAccessTestLogger()

        let access = FilesystemAccess(
            openFileHandler: { _ in expectedURL },
            saveFileHandler: { _ in expectedURL },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: scopeManager,
            logger: .init(logger)
        )

        let resolved = try access.resolveBookmarkData(Data("bookmark".utf8))

        XCTAssertEqual(resolved.url.url, expectedURL)
        XCTAssertTrue(resolved.isStale)
        XCTAssertEqual(scopeManager.startedURLs, [expectedURL])
        XCTAssertTrue(logger.errorMessages.contains { $0.contains("bookmark.resolve.stale") })
    }

    func testResolveBookmarkDataPropagatesErrors() {
        struct SampleError: Error {}

        let expectedURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let scopeManager = FilesystemAccessTestSecurityScope()
        let bookmarkManager = FilesystemAccessTestBookmarkManager()
        bookmarkManager.resolveError = SampleError()
        let logger = FilesystemAccessTestLogger()

        let access = FilesystemAccess(
            openFileHandler: { _ in expectedURL },
            saveFileHandler: { _ in expectedURL },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: scopeManager,
            logger: .init(logger)
        )

        XCTAssertThrowsError(try access.resolveBookmarkData(Data())) { error in
            guard case FilesystemAccessError.bookmarkResolutionFailed(let underlying) = error else {
                return XCTFail("Expected bookmarkResolutionFailed")
            }
            XCTAssertTrue(underlying is SampleError)
        }
        XCTAssertTrue(logger.errorMessages.contains { $0.contains("bookmark.resolve.failure") })
    }

    func testOpenFileAuthorizationFailureThrows() async {
        let expectedURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let openDialog = FilesystemAccessTestDialog(result: expectedURL)
        let scopeManager = FilesystemAccessTestSecurityScope()
        scopeManager.allowAccess = false
        let bookmarkManager = FilesystemAccessTestBookmarkManager()
        let logger = FilesystemAccessTestLogger()

        let access = FilesystemAccess(
            openFileHandler: openDialog.open,
            saveFileHandler: { _ in expectedURL },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: scopeManager,
            logger: .init(logger)
        )

        do {
            _ = try await access.openFile()
            XCTFail("Expected authorizationDenied error")
        } catch FilesystemAccessError.authorizationDenied(let deniedURL) {
            XCTAssertEqual(deniedURL, expectedURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertTrue(logger.errorMessages.contains { $0.contains("authorization_denied") })
    }
}

private final class FilesystemAccessTestDialog {
    var result: URL
    var callCount = 0

    init(result: URL) {
        self.result = result
    }

    func open(configuration: FilesystemOpenConfiguration) async throws -> URL {
        callCount += 1
        return result
    }
}

extension FilesystemAccessTestDialog: @unchecked Sendable {}

private final class FilesystemAccessTestSecurityScope: SecurityScopedAccessManaging {
    private let lock = NSLock()
    private var startedURLsStorage: [URL] = []
    private var stoppedURLsStorage: [URL] = []
    private var allowAccessStorage: Bool = true

    var startedURLs: [URL] { lock.withLock { startedURLsStorage } }
    var stoppedURLs: [URL] { lock.withLock { stoppedURLsStorage } }
    var allowAccess: Bool {
        get { lock.withLock { allowAccessStorage } }
        set { lock.withLock { allowAccessStorage = newValue } }
    }

    func startAccessing(_ url: URL) -> Bool {
        return lock.withLock {
            startedURLsStorage.append(url)
            return allowAccessStorage
        }
    }

    func stopAccessing(_ url: URL) {
        lock.withLock { stoppedURLsStorage.append(url) }
    }
}

extension FilesystemAccessTestSecurityScope: @unchecked Sendable {}

private final class FilesystemAccessTestBookmarkManager: BookmarkDataManaging {
    private let lock = NSLock()
    private var createdURLsStorage: [URL] = []
    private var nextResolutionStorage: BookmarkResolution?
    private var resolveErrorStorage: Error?
    private var creationErrorStorage: Error?
    var bookmarkData = Data("bookmark".utf8)
    var resolvedURL: URL = URL(fileURLWithPath: "/tmp/example.mp4")

    var createdURLs: [URL] { lock.withLock { createdURLsStorage } }
    var resolveError: Error? {
        get { lock.withLock { resolveErrorStorage } }
        set { lock.withLock { resolveErrorStorage = newValue } }
    }
    var creationError: Error? {
        get { lock.withLock { creationErrorStorage } }
        set { lock.withLock { creationErrorStorage = newValue } }
    }
    var nextResolution: BookmarkResolution? {
        get { lock.withLock { nextResolutionStorage } }
        set { lock.withLock { nextResolutionStorage = newValue } }
    }

    func createBookmark(for url: URL) throws -> Data {
        if let creationError {
            throw creationError
        }
        lock.withLock { createdURLsStorage.append(url) }
        return bookmarkData
    }

    func resolveBookmark(data: Data) throws -> BookmarkResolution {
        if let resolveError {
            throw resolveError
        }
        if let next = nextResolution {
            return next
        }
        return BookmarkResolution(url: resolvedURL, isStale: false)
    }
}

extension FilesystemAccessTestBookmarkManager: @unchecked Sendable {}

private final class FilesystemAccessTestLogger: DiagnosticsLogging {
    private let lock = NSLock()
    private var infoStorage: [String] = []
    private var errorStorage: [String] = []

    var infoMessages: [String] { lock.withLock { infoStorage } }
    var errorMessages: [String] { lock.withLock { errorStorage } }

    func info(_ message: String) {
        lock.withLock { infoStorage.append(message) }
    }

    func error(_ message: String) {
        lock.withLock { errorStorage.append(message) }
    }
}

extension FilesystemAccessTestLogger: @unchecked Sendable {}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
