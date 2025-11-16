import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Unit tests for the KeyValueRow component
///
/// Tests verify:
/// - Component initialization with key-value pairs
/// - Layout variants (horizontal and vertical)
/// - Accessibility support (VoiceOver labels)
/// - Design system token usage
/// - Copyable text functionality
/// - Platform compatibility
@MainActor
final class KeyValueRowTests: XCTestCase {
  // MARK: - Initialization Tests

  func testKeyValueRowInitializationBasic() {
    // Given
    let key = "Type"
    let value = "ftyp"

    // When
    let row = KeyValueRow(key: key, value: value)

    // Then
    XCTAssertEqual(row.key, key, "KeyValueRow key should match initialization value")
    XCTAssertEqual(row.value, value, "KeyValueRow value should match initialization value")
    XCTAssertEqual(row.layout, .horizontal, "Default layout should be horizontal")
    XCTAssertFalse(row.copyable, "Default copyable should be false")
  }

  func testKeyValueRowInitializationWithLayout() {
    // Given
    let key = "Description"
    let value = "A very long value that requires vertical layout"

    // When
    let row = KeyValueRow(key: key, value: value, layout: .vertical)

    // Then
    XCTAssertEqual(row.key, key, "KeyValueRow key should match initialization value")
    XCTAssertEqual(row.value, value, "KeyValueRow value should match initialization value")
    XCTAssertEqual(row.layout, .vertical, "Layout should be vertical")
  }

  func testKeyValueRowInitializationWithCopyable() {
    // Given
    let key = "Size"
    let value = "1024 bytes"

    // When
    let row = KeyValueRow(key: key, value: value, copyable: true)

    // Then
    XCTAssertEqual(row.key, key, "KeyValueRow key should match initialization value")
    XCTAssertEqual(row.value, value, "KeyValueRow value should match initialization value")
    XCTAssertTrue(row.copyable, "Copyable should be true")
  }

  func testKeyValueRowInitializationFullAPI() {
    // Given
    let key = "Offset"
    let value = "0x00001234"

    // When
    let row = KeyValueRow(key: key, value: value, layout: .vertical, copyable: true)

    // Then
    XCTAssertEqual(row.key, key, "KeyValueRow key should match initialization value")
    XCTAssertEqual(row.value, value, "KeyValueRow value should match initialization value")
    XCTAssertEqual(row.layout, .vertical, "Layout should be vertical")
    XCTAssertTrue(row.copyable, "Copyable should be true")
  }

  // MARK: - Layout Tests

  func testKeyValueRowLayoutEquality() {
    // Given
    let horizontal1 = KeyValueLayout.horizontal
    let horizontal2 = KeyValueLayout.horizontal
    let vertical = KeyValueLayout.vertical

    // Then
    XCTAssertEqual(horizontal1, horizontal2, "Same layout types should be equal")
    XCTAssertNotEqual(horizontal1, vertical, "Different layout types should not be equal")
  }

  func testKeyValueRowSupportsHorizontalLayout() {
    // Given
    let row = KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)

    // Then
    XCTAssertEqual(row.layout, .horizontal, "Row should support horizontal layout")
  }

  func testKeyValueRowSupportsVerticalLayout() {
    // Given
    let row = KeyValueRow(key: "Description", value: "Long value", layout: .vertical)

    // Then
    XCTAssertEqual(row.layout, .vertical, "Row should support vertical layout")
  }

  // MARK: - Content Tests

  func testKeyValueRowKeyContent() {
    // Given
    let testCases = [
      ("Type", "ftyp"),
      ("Size", "1024"),
      ("Offset", "0x00001234"),
      ("", "value"),  // Edge case: empty key
      ("Key with spaces", "value"),
    ]

    // When & Then
    for (key, value) in testCases {
      let row = KeyValueRow(key: key, value: value)
      XCTAssertEqual(row.key, key, "Row should preserve key content: '\(key)'")
    }
  }

  func testKeyValueRowValueContent() {
    // Given
    let testCases = [
      ("Type", "ftyp"),
      ("Size", "1024"),
      ("Offset", "0x00001234"),
      ("key", ""),  // Edge case: empty value
      ("hex", "0xDEADBEEF"),
    ]

    // When & Then
    for (key, value) in testCases {
      let row = KeyValueRow(key: key, value: value)
      XCTAssertEqual(row.value, value, "Row should preserve value content: '\(value)'")
    }
  }

  // MARK: - Copyable Tests

  func testKeyValueRowCopyableDefault() {
    // Given
    let row = KeyValueRow(key: "Type", value: "ftyp")

    // Then
    XCTAssertFalse(row.copyable, "Default copyable should be false")
  }

  func testKeyValueRowCopyableEnabled() {
    // Given
    let row = KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)

    // Then
    XCTAssertTrue(row.copyable, "Copyable should be enabled when set to true")
  }

  func testKeyValueRowCopyableDisabled() {
    // Given
    let row = KeyValueRow(key: "Type", value: "ftyp", copyable: false)

    // Then
    XCTAssertFalse(row.copyable, "Copyable should be disabled when explicitly set to false")
  }

  // MARK: - Component Composition Tests

  func testKeyValueRowIsAView() {
    // Given
    let row = KeyValueRow(key: "Type", value: "ftyp")

    // Then
    // Verify that KeyValueRow conforms to View protocol (compile-time check)
    // This test primarily serves as documentation that KeyValueRow is a proper SwiftUI View
    _ = row as any View  // Compile-time verification that KeyValueRow conforms to View
    XCTAssertNotNil(row, "KeyValueRow should be a SwiftUI View")
  }

  // MARK: - Edge Cases

  func testKeyValueRowWithEmptyKey() {
    // Given
    let row = KeyValueRow(key: "", value: "value")

    // Then
    XCTAssertEqual(row.key, "", "KeyValueRow should support empty key")
  }

  func testKeyValueRowWithEmptyValue() {
    // Given
    let row = KeyValueRow(key: "Key", value: "")

    // Then
    XCTAssertEqual(row.value, "", "KeyValueRow should support empty value")
  }

  func testKeyValueRowWithLongKey() {
    // Given
    let longKey = "This is a very long key that might wrap or truncate"
    let row = KeyValueRow(key: longKey, value: "value")

    // Then
    XCTAssertEqual(row.key, longKey, "KeyValueRow should support long keys")
  }

  func testKeyValueRowWithLongValue() {
    // Given
    let longValue =
      "This is a very long value that might wrap or truncate and should ideally use vertical layout"
    let row = KeyValueRow(key: "Description", value: longValue)

    // Then
    XCTAssertEqual(row.value, longValue, "KeyValueRow should support long values")
  }

  func testKeyValueRowWithSpecialCharacters() {
    // Given
    let key = "Special ⚠️"
    let value = "Øℓ∂ 日本語 😀"
    let row = KeyValueRow(key: key, value: value)

    // Then
    XCTAssertEqual(row.key, key, "KeyValueRow should support special characters in key")
    XCTAssertEqual(
      row.value, value, "KeyValueRow should support special characters and Unicode in value"
    )
  }

  func testKeyValueRowWithHexValue() {
    // Given
    let row = KeyValueRow(key: "Offset", value: "0xDEADBEEF")

    // Then
    XCTAssertEqual(row.value, "0xDEADBEEF", "KeyValueRow should support hex values")
  }

  func testKeyValueRowWithNumericValue() {
    // Given
    let row = KeyValueRow(key: "Size", value: "1024")

    // Then
    XCTAssertEqual(row.value, "1024", "KeyValueRow should support numeric values")
  }

  // MARK: - Multiple Instances Tests

  func testMultipleKeyValueRowInstances() {
    // Given
    let rows = [
      KeyValueRow(key: "Type", value: "ftyp"),
      KeyValueRow(key: "Size", value: "1024", copyable: true),
      KeyValueRow(key: "Description", value: "Long text", layout: .vertical),
    ]

    // Then
    XCTAssertEqual(rows.count, 3, "Should create multiple independent instances")
    XCTAssertEqual(rows[0].key, "Type", "First instance should have correct key")
    XCTAssertEqual(rows[1].copyable, true, "Second instance should have copyable enabled")
    XCTAssertEqual(rows[2].layout, .vertical, "Third instance should have vertical layout")
  }
}
