import Foundation
import XCTest

@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class FilesystemAccessTelemetryTests: XCTestCase {
    func testAuditTrailCapturesBookmarkFlowsWhenTelemetryEnabled() throws {
        let infoCollector = MessageCollector()
        let errorCollector = MessageCollector()
        let auditTrail = FilesystemAccessAuditTrail(limit: 5)
        let scopeManager = TestSecurityScopeManager()
        let fileURL = URL(fileURLWithPath: "/tmp/source.mp4")

        let capturedBookmarkURL = AtomicBox<URL?>(nil)
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in }, auditInfo: { infoCollector.append($0) },
            auditError: { errorCollector.append($0) }, filesystemAccessAuditTrail: auditTrail,
            makeFilesystemAccess: { logger in
                FilesystemAccess(
                    openFileHandler: { _ in fileURL }, saveFileHandler: { _ in fileURL },
                    bookmarkCreator: { url in
                        capturedBookmarkURL.set(url)
                        return Data("bookmark".utf8)
                    }, bookmarkResolver: { _ in BookmarkResolution(url: fileURL, isStale: false) },
                    securityScopeManager: scopeManager, logger: logger)
            })

        let access = environment.makeFilesystemAccess()
        let scoped = SecurityScopedURL(url: fileURL, manager: scopeManager)
        let bookmark = try access.createBookmark(for: scoped)
        XCTAssertEqual(capturedBookmarkURL.value, fileURL)

        let resolved = try access.resolveBookmarkData(bookmark)
        XCTAssertEqual(resolved.url.url, fileURL)
        XCTAssertFalse(resolved.isStale)

        let events = auditTrail.snapshot()
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.first?.category, .bookmarkCreate)
        XCTAssertEqual(events.first?.outcome, .success)
        XCTAssertTrue(events.dropFirst().allSatisfy { $0.category == .bookmarkResolve })
        XCTAssertTrue(scopeManager.started.contains(fileURL))
        resolved.url.revoke()
        XCTAssertTrue(scopeManager.stopped.contains(fileURL))

        XCTAssertFalse(infoCollector.messages.isEmpty)
        XCTAssertTrue(errorCollector.messages.isEmpty)
    }

    func testAuditTrailSuppressedWhenTelemetryDisabled() throws {
        let infoCollector = MessageCollector()
        let errorCollector = MessageCollector()
        let auditTrail = FilesystemAccessAuditTrail(limit: 5)
        let scopeManager = TestSecurityScopeManager()
        let fileURL = URL(fileURLWithPath: "/tmp/source.mp4")

        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in }, telemetryEnabled: false,
            auditInfo: { infoCollector.append($0) }, auditError: { errorCollector.append($0) },
            filesystemAccessAuditTrail: auditTrail,
            makeFilesystemAccess: { logger in
                FilesystemAccess(
                    openFileHandler: { _ in fileURL }, saveFileHandler: { _ in fileURL },
                    bookmarkCreator: { _ in Data("bookmark".utf8) },
                    bookmarkResolver: { _ in BookmarkResolution(url: fileURL, isStale: false) },
                    securityScopeManager: scopeManager, logger: logger)
            })

        let access = environment.makeFilesystemAccess()
        let scoped = SecurityScopedURL(url: fileURL, manager: scopeManager)
        let bookmark = try access.createBookmark(for: scoped)
        XCTAssertFalse(bookmark.isEmpty)

        let resolved = try access.resolveBookmarkData(bookmark)
        XCTAssertEqual(resolved.url.url, fileURL)

        XCTAssertTrue(auditTrail.snapshot().isEmpty)
        XCTAssertTrue(infoCollector.messages.isEmpty)
        XCTAssertTrue(errorCollector.messages.isEmpty)
        XCTAssertTrue(scopeManager.started.contains(fileURL))
    }
}

private final class MessageCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ value: String) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var messages: [String] {
        lock.lock()
        let copy = storage
        lock.unlock()
        return copy
    }
}

private final class AtomicBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) { storage = value }

    func set(_ value: Value) {
        lock.lock()
        storage = value
        lock.unlock()
    }

    var value: Value {
        lock.lock()
        let current = storage
        lock.unlock()
        return current
    }
}

private final class TestSecurityScopeManager: SecurityScopedAccessManaging, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var started: [URL] = []
    private(set) var stopped: [URL] = []

    func startAccessing(_ url: URL) -> Bool {
        lock.lock()
        started.append(url)
        lock.unlock()
        return true
    }

    func stopAccessing(_ url: URL) {
        lock.lock()
        stopped.append(url)
        lock.unlock()
    }
}
