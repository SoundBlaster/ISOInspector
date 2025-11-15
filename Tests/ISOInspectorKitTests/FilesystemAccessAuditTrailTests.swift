import Foundation
import XCTest

@testable import ISOInspectorKit

final class FilesystemAccessAuditTrailTests: XCTestCase {
  func testAppendsEventsAndPreservesOrder() {
    let trail = FilesystemAccessAuditTrail(limit: 5)
    let baseDate = Date(timeIntervalSinceReferenceDate: 10)
    let events = (0..<3).map { index in
      FilesystemAccessAuditEvent(
        timestamp: baseDate.addingTimeInterval(TimeInterval(index)),
        category: .bookmarkCreate,
        outcome: .success,
        pathHash: "hash-\(index)",
        bookmarkIdentifier: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!,
        errorDescription: nil
      )
    }

    events.forEach { trail.append($0) }

    XCTAssertEqual(trail.snapshot(), events)
  }

  func testRotationDropsOldestEvents() {
    let trail = FilesystemAccessAuditTrail(limit: 2)
    let first = FilesystemAccessAuditEvent(
      timestamp: Date(timeIntervalSinceReferenceDate: 1),
      category: .openFile,
      outcome: .accessGranted,
      pathHash: "first",
      bookmarkIdentifier: nil,
      errorDescription: nil
    )
    let second = FilesystemAccessAuditEvent(
      timestamp: Date(timeIntervalSinceReferenceDate: 2),
      category: .saveFile,
      outcome: .accessGranted,
      pathHash: "second",
      bookmarkIdentifier: nil,
      errorDescription: nil
    )
    let third = FilesystemAccessAuditEvent(
      timestamp: Date(timeIntervalSinceReferenceDate: 3),
      category: .bookmarkResolve,
      outcome: .stale,
      pathHash: "third",
      bookmarkIdentifier: nil,
      errorDescription: nil
    )

    trail.append(first)
    trail.append(second)
    trail.append(third)

    XCTAssertEqual(trail.snapshot(), [second, third])
  }

  func testLimitZeroSkipsStorage() {
    let trail = FilesystemAccessAuditTrail(limit: 0)
    trail.append(
      FilesystemAccessAuditEvent(
        timestamp: Date(),
        category: .bookmarkCreate,
        outcome: .success,
        pathHash: "ignored",
        bookmarkIdentifier: nil,
        errorDescription: nil
      )
    )

    XCTAssertTrue(trail.snapshot().isEmpty)
  }
}
