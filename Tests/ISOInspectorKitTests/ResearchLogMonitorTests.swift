import Foundation
import XCTest

@testable import ISOInspectorKit

final class ResearchLogMonitorTests: XCTestCase {
  func testAuditReportsSchemaDetailsForPersistedEntries() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let logURL = directory.appendingPathComponent("research-log.json")
    let writer = try ResearchLogWriter(fileURL: logURL)
    writer.record(
      ResearchLogEntry(
        boxType: "zzzz",
        filePath: "/tmp/sample.mp4",
        startOffset: 0,
        endOffset: 16
      )
    )

    let audit = try ResearchLogMonitor.audit(logURL: logURL)

    XCTAssertEqual(audit.schemaVersion, ResearchLogSchema.version)
    XCTAssertEqual(audit.fieldNames, ResearchLogSchema.fieldNames)
    XCTAssertEqual(audit.entryCount, 1)
    XCTAssertTrue(audit.logExists)
  }
}
