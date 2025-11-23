#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import ISOInspectorApp

final class InspectorColumnVisibilityTests: XCTestCase {
  func testDefaultsShowInspector() {
    let visibility = InspectorColumnVisibility()

    XCTAssertEqual(visibility.columnVisibility, .doubleColumn)
    XCTAssertTrue(visibility.isInspectorVisible)
  }

  func testToggleHidesAndShowsInspector() {
    var visibility = InspectorColumnVisibility()

    visibility.toggleInspectorVisibility()

    XCTAssertEqual(visibility.columnVisibility, .sidebarOnly)
    XCTAssertFalse(visibility.isInspectorVisible)

    visibility.toggleInspectorVisibility()

    XCTAssertEqual(visibility.columnVisibility, .doubleColumn)
    XCTAssertTrue(visibility.isInspectorVisible)
  }
}
#endif
