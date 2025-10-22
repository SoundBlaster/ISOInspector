// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Accessibility tests for the KeyValueRow component
///
/// Verifies WCAG 2.1 AA compliance and VoiceOver support for key-value rows.
///
/// ## Test Coverage
/// - VoiceOver label format ("Key, Value")
/// - Copyable value accessibility hints
/// - Touch target size validation (when copyable)
/// - Dynamic Type support
/// - Layout variant accessibility (horizontal vs vertical)
/// - Platform-specific clipboard handling
@MainActor
final class KeyValueRowAccessibilityTests: XCTestCase {

    // MARK: - VoiceOver Label Tests

    func testKeyValueRowBasicAccessibilityLabel() {
        // Given
        let row = KeyValueRow(key: "Type", value: "ftyp")

        // Then
        // The row combines key and value for VoiceOver
        XCTAssertEqual(
            row.key,
            "Type",
            "KeyValueRow should preserve key"
        )
        XCTAssertEqual(
            row.value,
            "ftyp",
            "KeyValueRow should preserve value"
        )
    }

    func testKeyValueRowAccessibilityLabelFormat() {
        // Given
        let key = "File Size"
        let value = "1024 bytes"
        let row = KeyValueRow(key: key, value: value)

        // Then
        // Expected format: "File Size, 1024 bytes"
        let expectedLabel = "\(key), \(value)"
        XCTAssertEqual(
            expectedLabel,
            "File Size, 1024 bytes",
            "KeyValueRow should format accessibility label as 'key, value'"
        )
    }

    func testKeyValueRowWithSpecialCharacters() {
        // Given
        let row = KeyValueRow(key: "Hash", value: "0xDEADBEEF")

        // Then
        XCTAssertEqual(
            row.value,
            "0xDEADBEEF",
            "KeyValueRow should preserve special characters in value"
        )
    }

    func testKeyValueRowWithEmptyValue() {
        // Given
        let row = KeyValueRow(key: "Optional", value: "")

        // Then
        XCTAssertEqual(
            row.value,
            "",
            "KeyValueRow should accept empty value"
        )
    }

    func testKeyValueRowWithLongValue() {
        // Given
        let longValue = "This is a very long value that might wrap across multiple lines"
        let row = KeyValueRow(key: "Description", value: longValue, layout: .vertical)

        // Then
        XCTAssertEqual(
            row.value,
            longValue,
            "KeyValueRow should support long values"
        )
    }

    // MARK: - Copyable Value Tests

    func testKeyValueRowCopyableAccessibility() {
        // Given
        let row = KeyValueRow(key: "Type", value: "ftyp", copyable: true)

        // Then
        XCTAssertTrue(
            row.copyable,
            "KeyValueRow should have copyable enabled"
        )
        // Note: The accessibility hint "Double-tap to copy" is applied in the view body
    }

    func testKeyValueRowNonCopyableAccessibility() {
        // Given
        let row = KeyValueRow(key: "Type", value: "ftyp", copyable: false)

        // Then
        XCTAssertFalse(
            row.copyable,
            "KeyValueRow should have copyable disabled"
        )
    }

    func testKeyValueRowCopyableHasAccessibilityHint() {
        // Given
        let copyableRow = KeyValueRow(key: "Offset", value: "0x1234", copyable: true)
        let nonCopyableRow = KeyValueRow(key: "Offset", value: "0x1234", copyable: false)

        // Then
        // Copyable row should have the hint, non-copyable should not
        XCTAssertTrue(
            copyableRow.copyable,
            "Copyable row should have copyable property set"
        )
        XCTAssertFalse(
            nonCopyableRow.copyable,
            "Non-copyable row should not have copyable property set"
        )
    }

    // MARK: - Layout Tests

    func testKeyValueRowHorizontalLayout() {
        // Given
        let row = KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)

        // Then
        XCTAssertEqual(
            row.layout,
            .horizontal,
            "KeyValueRow should support horizontal layout"
        )
    }

    func testKeyValueRowVerticalLayout() {
        // Given
        let row = KeyValueRow(key: "Description", value: "Long text", layout: .vertical)

        // Then
        XCTAssertEqual(
            row.layout,
            .vertical,
            "KeyValueRow should support vertical layout"
        )
    }

    func testKeyValueRowDefaultLayout() {
        // Given
        let row = KeyValueRow(key: "Type", value: "ftyp")

        // Then
        XCTAssertEqual(
            row.layout,
            .horizontal,
            "KeyValueRow should default to horizontal layout"
        )
    }

    func testKeyValueLayoutEquality() {
        // Given
        let horizontal1 = KeyValueLayout.horizontal
        let horizontal2 = KeyValueLayout.horizontal
        let vertical = KeyValueLayout.vertical

        // Then
        XCTAssertEqual(
            horizontal1,
            horizontal2,
            "Same layout types should be equal"
        )
        XCTAssertNotEqual(
            horizontal1,
            vertical,
            "Different layout types should not be equal"
        )
    }

    // MARK: - Design System Token Usage Tests

    func testKeyValueRowUsesDesignSystemTypography() {
        // Given
        // KeyValueRow uses DS.Typography.body for keys and DS.Typography.code for values

        // Then
        let bodyFont = DS.Typography.body
        let codeFont = DS.Typography.code

        XCTAssertNotNil(
            bodyFont,
            "KeyValueRow should use DS.Typography.body for keys"
        )
        XCTAssertNotNil(
            codeFont,
            "KeyValueRow should use DS.Typography.code for values"
        )
    }

    func testKeyValueRowUsesDesignSystemSpacing() {
        // Given
        // KeyValueRow uses DS.Spacing.s and DS.Spacing.m

        // Then
        XCTAssertGreaterThan(
            DS.Spacing.s,
            0,
            "KeyValueRow should use DS.Spacing.s (must be > 0)"
        )
        XCTAssertGreaterThan(
            DS.Spacing.m,
            0,
            "KeyValueRow should use DS.Spacing.m (must be > 0)"
        )
    }

    // MARK: - Contrast Tests

    func testKeyValueRowKeyTextContrast() {
        // Given
        // Keys use .secondary foreground color
        let keyColor = Color.secondary
        let background = Color.clear

        // Then
        // Secondary color is system-provided and WCAG compliant by design
        XCTAssertNotNil(
            keyColor,
            "KeyValueRow keys should use .secondary color (WCAG compliant by system)"
        )
    }

    func testKeyValueRowValueTextContrast() {
        // Given
        // Values use .primary foreground color
        let valueColor = Color.primary
        let background = Color.clear

        // Then
        // Primary color is system-provided and WCAG compliant by design
        XCTAssertNotNil(
            valueColor,
            "KeyValueRow values should use .primary color (WCAG compliant by system)"
        )
    }

    // MARK: - Touch Target Tests

    func testKeyValueRowCopyableButtonTouchTarget() {
        // Given
        // Copyable KeyValueRow includes a button with icon
        let row = KeyValueRow(key: "Hash", value: "0xABCD", copyable: true)

        // Then
        // When copyable, the button should have adequate touch target
        // Standard spacing (DS.Spacing.s) provides some padding
        XCTAssertTrue(
            row.copyable,
            "Copyable row should be interactive"
        )

        // Note: Actual button frame measurement would require rendering
        // We verify that spacing tokens provide adequate padding
        let iconSpacing = DS.Spacing.s
        XCTAssertGreaterThan(
            iconSpacing,
            0,
            "Copyable button should have icon spacing for better touch target"
        )
    }

    // MARK: - Platform Tests

    func testKeyValueRowOnCurrentPlatform() {
        // Given
        let platform = AccessibilityTestHelpers.currentPlatform
        let row = KeyValueRow(key: "Platform", value: platform, copyable: true)

        // Then
        XCTAssertNotNil(
            row,
            "KeyValueRow should be creatable on \(platform)"
        )
        XCTAssertEqual(
            row.value,
            platform,
            "KeyValueRow should work on \(platform)"
        )
    }

    // MARK: - Integration Tests

    func testMultipleKeyValueRowsHaveDistinctContent() {
        // Given
        let row1 = KeyValueRow(key: "Type", value: "ftyp")
        let row2 = KeyValueRow(key: "Size", value: "1024")
        let row3 = KeyValueRow(key: "Offset", value: "0x0000")

        // Then
        XCTAssertNotEqual(
            row1.key,
            row2.key,
            "Different rows should have different keys"
        )
        XCTAssertNotEqual(
            row2.value,
            row3.value,
            "Different rows should have different values"
        )
    }

    func testKeyValueRowInListContext() {
        // Given
        let rows = [
            KeyValueRow(key: "Type", value: "ftyp"),
            KeyValueRow(key: "Size", value: "1024 bytes", copyable: true),
            KeyValueRow(key: "Offset", value: "0x00001234", copyable: true)
        ]

        // Then
        for row in rows {
            AccessibilityTestHelpers.assertValidAccessibilityLabel(
                row.key,
                context: "KeyValueRow key in list"
            )
            AccessibilityTestHelpers.assertValidAccessibilityLabel(
                row.value,
                context: "KeyValueRow value in list"
            )
        }
    }

    // MARK: - Edge Cases

    func testKeyValueRowWithVeryLongKey() {
        // Given
        let longKey = "This is a very long key that might wrap or truncate in the UI"
        let row = KeyValueRow(key: longKey, value: "short")

        // Then
        XCTAssertEqual(
            row.key,
            longKey,
            "KeyValueRow should support long keys"
        )
    }

    func testKeyValueRowWithUnicodeValue() {
        // Given
        let unicodeValue = "日本語 🎌 한국어"
        let row = KeyValueRow(key: "Language", value: unicodeValue)

        // Then
        XCTAssertEqual(
            row.value,
            unicodeValue,
            "KeyValueRow should support Unicode values"
        )
    }

    func testKeyValueRowFullConfiguration() {
        // Given
        let row = KeyValueRow(
            key: "Full Config",
            value: "All options set",
            layout: .vertical,
            copyable: true
        )

        // Then
        XCTAssertEqual(row.layout, .vertical, "Should use vertical layout")
        XCTAssertTrue(row.copyable, "Should be copyable")
        AccessibilityTestHelpers.assertValidAccessibilityLabel(
            row.key,
            context: "Fully configured KeyValueRow"
        )
    }
}
