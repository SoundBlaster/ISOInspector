import XCTest

@testable import ISOInspectorApp

final class InspectorFocusShortcutCatalogTests: XCTestCase {
  func testDefaultShortcutsProvideExpectedTargetsAndKeys() {
    let catalog = InspectorFocusShortcutCatalog.default
    let descriptors = catalog.shortcuts
    XCTAssertEqual(descriptors.map(\.target), [.outline, .detail, .notes, .hex])
    XCTAssertEqual(descriptors.map(\.key), ["1", "2", "3", "4"])
    XCTAssertEqual(
      descriptors.map(\.title),
      [
        "Focus Outline Pane",
        "Focus Detail Pane",
        "Focus Notes Pane",
        "Focus Hex Pane",
      ])
  }

  func testLookupReturnsDescriptorForTarget() {
    let catalog = InspectorFocusShortcutCatalog.default
    let descriptor = catalog.descriptor(for: .notes)
    XCTAssertEqual(descriptor?.paneName, "Notes")
    XCTAssertEqual(descriptor?.discoverabilityTitle, "Focus Notes Pane")
  }
}
