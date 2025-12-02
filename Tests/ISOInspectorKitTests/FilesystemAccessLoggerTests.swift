import Foundation
import XCTest

@testable import ISOInspectorKit

final class FilesystemAccessLoggerTests: XCTestCase {
    func testLogsInfoEventAndStoresAuditEntry() {
        let infoCollector = ThreadSafeCollector()
        let errorCollector = ThreadSafeCollector()
        let auditTrail = FilesystemAccessAuditTrail(limit: 5)
        let timestamp = Date(timeIntervalSinceReferenceDate: 42)
        let logger = FilesystemAccessLogger(
            info: { infoCollector.append($0) }, error: { errorCollector.append($0) },
            auditTrail: auditTrail, makeDate: { timestamp })

        let bookmarkID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        logger.log(
            category: .bookmarkCreate, outcome: .success, pathHash: "abcd1234",
            bookmarkIdentifier: bookmarkID, errorDescription: nil)

        XCTAssertEqual(
            infoCollector.messages,
            [
                "bookmark.create.success path_hash=abcd1234 bookmark_id=AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE timestamp=2001-01-01T00:00:42Z"
            ])
        XCTAssertTrue(errorCollector.messages.isEmpty)

        let events = auditTrail.snapshot()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.timestamp, timestamp)
        XCTAssertEqual(events.first?.category, .bookmarkCreate)
        XCTAssertEqual(events.first?.outcome, .success)
        XCTAssertEqual(events.first?.pathHash, "abcd1234")
        XCTAssertEqual(events.first?.bookmarkIdentifier, bookmarkID)
        XCTAssertNil(events.first?.errorDescription)
    }

    func testLogsErrorEventWhenAuthorizationDenied() {
        let infoCollector = ThreadSafeCollector()
        let errorCollector = ThreadSafeCollector()
        let auditTrail = FilesystemAccessAuditTrail(limit: 5)
        let logger = FilesystemAccessLogger(
            info: { infoCollector.append($0) }, error: { errorCollector.append($0) },
            auditTrail: auditTrail, makeDate: { Date(timeIntervalSinceReferenceDate: 5) })

        logger.log(
            category: .openFile, outcome: .authorizationDenied, pathHash: "denied",
            bookmarkIdentifier: nil, errorDescription: "CocoaError.256")

        XCTAssertTrue(infoCollector.messages.isEmpty)
        XCTAssertEqual(
            errorCollector.messages,
            [
                "open_file.authorization_denied path_hash=denied error=CocoaError.256 timestamp=2001-01-01T00:00:05Z"
            ])
        XCTAssertEqual(auditTrail.snapshot().first?.outcome, .authorizationDenied)
    }

    func testOmitsPathHashAndBookmarkWhenUnavailable() {
        let infoCollector = ThreadSafeCollector()
        let errorCollector = ThreadSafeCollector()
        let auditTrail = FilesystemAccessAuditTrail(limit: 5)
        let logger = FilesystemAccessLogger(
            info: { infoCollector.append($0) }, error: { errorCollector.append($0) },
            auditTrail: auditTrail, makeDate: { Date(timeIntervalSinceReferenceDate: 10) })

        logger.log(
            category: .bookmarkResolve, outcome: .failure, pathHash: nil, bookmarkIdentifier: nil,
            errorDescription: "SampleError")

        XCTAssertEqual(
            errorCollector.messages,
            ["bookmark.resolve.failure error=SampleError timestamp=2001-01-01T00:00:10Z"])
        XCTAssertTrue(infoCollector.messages.isEmpty)

        XCTAssertNil(auditTrail.snapshot().first?.pathHash)
    }
}

private final class ThreadSafeCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ value: String) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var messages: [String] {
        lock.lock()
        let values = storage
        lock.unlock()
        return values
    }
}
