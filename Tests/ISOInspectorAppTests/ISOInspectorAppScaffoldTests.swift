import XCTest

@testable import ISOInspectorKit

final class ISOInspectorAppScaffoldTests: XCTestCase {
  func testFocusAreasMatchKitValues() {
    XCTAssertTrue(ISOInspectorKit.initialFocusAreas.contains("Phase A · IO Foundations"))
  }
}
