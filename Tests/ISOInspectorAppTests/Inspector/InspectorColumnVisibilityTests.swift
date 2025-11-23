#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import ISOInspectorApp

final class InspectorColumnVisibilityTests: XCTestCase {
  func testDefaultsShowInspector() {
    let visibility = InspectorColumnVisibility()

    XCTAssertEqual(visibility.columnVisibility, .all)
    XCTAssertTrue(visibility.isInspectorVisible)
  }

  func testToggleHidesAndShowsInspector() {
    var visibility = InspectorColumnVisibility()

    visibility.toggleInspectorVisibility()

    XCTAssertEqual(visibility.columnVisibility, .doubleColumn)
    XCTAssertFalse(visibility.isInspectorVisible)

    visibility.toggleInspectorVisibility()

    XCTAssertEqual(visibility.columnVisibility, .all)
    XCTAssertTrue(visibility.isInspectorVisible)
  }
}
#endif
