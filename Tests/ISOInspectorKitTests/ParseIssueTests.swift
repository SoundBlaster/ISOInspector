import Foundation
import XCTest

@testable import ISOInspectorKit

final class ParseIssueTests: XCTestCase {
  func testInitializerStoresAllProperties() {
    let range: Range<Int64> = 1024..<2048
    let issue = ParseIssue(
      severity: .warning,
      code: "MISSING_REQUIRED",
      message: "Sample description missing",
      byteRange: range,
      affectedNodeIDs: [1, 42]
    )

    XCTAssertEqual(issue.severity, .warning)
    XCTAssertEqual(issue.code, "MISSING_REQUIRED")
    XCTAssertEqual(issue.message, "Sample description missing")
    XCTAssertEqual(issue.byteRange, range)
    XCTAssertEqual(issue.affectedNodeIDs, [1, 42])
  }

  func testCodableRoundTripPreservesData() throws {
    let issue = ParseIssue(
      severity: .error,
      code: "TRUNCATED_PAYLOAD",
      message: "Payload ended before expected size",
      byteRange: 4096..<8192,
      affectedNodeIDs: [100]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(issue)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ParseIssue.self, from: data)

    XCTAssertEqual(decoded, issue)
  }
}
