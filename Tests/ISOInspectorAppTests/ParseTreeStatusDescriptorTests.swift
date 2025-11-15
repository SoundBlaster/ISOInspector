import ISOInspectorKit
import XCTest

@testable import ISOInspectorApp

final class ParseTreeStatusDescriptorTests: XCTestCase {
  func testDescriptorForPartialStatus() {
    let descriptor = ParseTreeStatusDescriptor(status: .partial)

    XCTAssertNotNil(descriptor)
    XCTAssertEqual(descriptor?.text, "Partial")
    XCTAssertEqual(descriptor?.level, .warning)
    XCTAssertEqual(descriptor?.accessibilityLabel, "Partial status")
  }

  func testDescriptorForCorruptedStatus() {
    let descriptor = ParseTreeStatusDescriptor(status: .corrupt)

    XCTAssertNotNil(descriptor)
    XCTAssertEqual(descriptor?.text, "Corrupted")
    XCTAssertEqual(descriptor?.level, .error)
    XCTAssertEqual(descriptor?.accessibilityLabel, "Corrupted status")
  }

  func testDescriptorForTrimmedStatus() {
    let descriptor = ParseTreeStatusDescriptor(status: .trimmed)

    XCTAssertNotNil(descriptor)
    XCTAssertEqual(descriptor?.text, "Trimmed")
    XCTAssertEqual(descriptor?.level, .warning)
    XCTAssertEqual(descriptor?.accessibilityLabel, "Trimmed status")
  }

  func testDescriptorOmittedForValidStatus() {
    let descriptor = ParseTreeStatusDescriptor(status: .valid)

    XCTAssertNil(descriptor)
  }
}
