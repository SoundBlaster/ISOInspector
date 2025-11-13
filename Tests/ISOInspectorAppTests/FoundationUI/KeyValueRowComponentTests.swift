#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import FoundationUI

/// Comprehensive test suite for the KeyValueRow component
///
/// Tests cover:
/// - Component initialization with various parameters
/// - Layout options (horizontal, vertical)
/// - Copyable functionality
/// - Text content variations
/// - Accessibility features
/// - Platform compatibility
/// - Real-world usage scenarios
///
/// **Phase:** I0.2 - Create Integration Test Suite
/// **Coverage Target:** ≥80% for KeyValueRow component
final class KeyValueRowComponentTests: XCTestCase {

    // MARK: - Initialization Tests

    /// Verifies that KeyValueRow can be initialized with required parameters
    func testKeyValueRowInitialization() {
        let row = KeyValueRow(key: "Type", value: "ftyp")

        XCTAssertEqual(row.key, "Type")
        XCTAssertEqual(row.value, "ftyp")
        XCTAssertEqual(row.layout, .horizontal)
        XCTAssertFalse(row.copyable)
    }

    /// Verifies that KeyValueRow can be initialized with vertical layout
    func testKeyValueRowInitializationWithVerticalLayout() {
        let row = KeyValueRow(key: "Description", value: "Long text", layout: .vertical)

        XCTAssertEqual(row.key, "Description")
        XCTAssertEqual(row.value, "Long text")
        XCTAssertEqual(row.layout, .vertical)
        XCTAssertFalse(row.copyable)
    }

    /// Verifies that KeyValueRow can be initialized with copyable functionality
    func testKeyValueRowInitializationWithCopyable() {
        let row = KeyValueRow(key: "Size", value: "1024", copyable: true)

        XCTAssertEqual(row.key, "Size")
        XCTAssertEqual(row.value, "1024")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that KeyValueRow can be initialized with all parameters
    func testKeyValueRowInitializationWithAllParameters() {
        let row = KeyValueRow(
            key: "Full Path",
            value: "/path/to/file",
            layout: .vertical,
            copyable: true
        )

        XCTAssertEqual(row.key, "Full Path")
        XCTAssertEqual(row.value, "/path/to/file")
        XCTAssertEqual(row.layout, .vertical)
        XCTAssertTrue(row.copyable)
    }

    // MARK: - Layout Tests

    /// Verifies KeyValueRow with horizontal layout (default)
    func testKeyValueRowHorizontalLayout() {
        let row = KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)

        XCTAssertEqual(row.layout, .horizontal)
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with vertical layout
    func testKeyValueRowVerticalLayout() {
        let row = KeyValueRow(key: "Description", value: "Long text", layout: .vertical)

        XCTAssertEqual(row.layout, .vertical)
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueLayout enum cases
    func testKeyValueLayoutCases() {
        let horizontal = KeyValueLayout.horizontal
        let vertical = KeyValueLayout.vertical

        XCTAssertEqual(horizontal, .horizontal)
        XCTAssertEqual(vertical, .vertical)
        XCTAssertNotEqual(horizontal, vertical)
    }

    // MARK: - Text Content Tests

    /// Verifies KeyValueRow with short text
    func testKeyValueRowWithShortText() {
        let row = KeyValueRow(key: "ID", value: "42")

        XCTAssertEqual(row.key, "ID")
        XCTAssertEqual(row.value, "42")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with medium-length text
    func testKeyValueRowWithMediumText() {
        let row = KeyValueRow(key: "File Type", value: "ISO Media File")

        XCTAssertEqual(row.key, "File Type")
        XCTAssertEqual(row.value, "ISO Media File")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with long text
    func testKeyValueRowWithLongText() {
        let longValue = "This is a very long description that should wrap properly in the UI"
        let row = KeyValueRow(key: "Description", value: longValue, layout: .vertical)

        XCTAssertEqual(row.key, "Description")
        XCTAssertEqual(row.value, longValue)
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with empty key
    func testKeyValueRowWithEmptyKey() {
        let row = KeyValueRow(key: "", value: "value")

        XCTAssertEqual(row.key, "")
        XCTAssertEqual(row.value, "value")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with empty value
    func testKeyValueRowWithEmptyValue() {
        let row = KeyValueRow(key: "Empty", value: "")

        XCTAssertEqual(row.key, "Empty")
        XCTAssertEqual(row.value, "")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with both empty strings
    func testKeyValueRowWithBothEmpty() {
        let row = KeyValueRow(key: "", value: "")

        XCTAssertEqual(row.key, "")
        XCTAssertEqual(row.value, "")
        XCTAssertNotNil(row.body)
    }

    // MARK: - Copyable Functionality Tests

    /// Verifies KeyValueRow with copyable disabled (default)
    func testKeyValueRowNonCopyable() {
        let row = KeyValueRow(key: "Type", value: "ftyp")

        XCTAssertFalse(row.copyable)
    }

    /// Verifies KeyValueRow with copyable enabled
    func testKeyValueRowCopyable() {
        let row = KeyValueRow(key: "Size", value: "1024", copyable: true)

        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    /// Verifies multiple KeyValueRows with different copyable settings
    func testKeyValueRowMultipleCopyableSettings() {
        let nonCopyable = KeyValueRow(key: "Label", value: "Value")
        let copyable = KeyValueRow(key: "Hash", value: "0xDEADBEEF", copyable: true)

        XCTAssertFalse(nonCopyable.copyable)
        XCTAssertTrue(copyable.copyable)
    }

    // MARK: - View Rendering Tests

    /// Verifies that KeyValueRow body is not nil
    func testKeyValueRowBodyNotNil() {
        let row = KeyValueRow(key: "Test", value: "Value")

        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow renders with horizontal layout
    func testKeyValueRowRendersHorizontal() {
        let row = KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)

        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow renders with vertical layout
    func testKeyValueRowRendersVertical() {
        let row = KeyValueRow(key: "Description", value: "Text", layout: .vertical)

        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow renders with copyable button
    func testKeyValueRowRendersWithCopyable() {
        let row = KeyValueRow(key: "Value", value: "Copy me", copyable: true)

        XCTAssertNotNil(row.body)
    }

    // MARK: - Platform Compatibility Tests

    /// Verifies KeyValueRow works on current platform
    func testKeyValueRowPlatformCompatibility() {
        #if os(iOS)
        let row = KeyValueRow(key: "Platform", value: "iOS")
        XCTAssertNotNil(row.body, "KeyValueRow should work on iOS")
        #elseif os(macOS)
        let row = KeyValueRow(key: "Platform", value: "macOS")
        XCTAssertNotNil(row.body, "KeyValueRow should work on macOS")
        #else
        XCTFail("Unsupported platform")
        #endif
    }

    // MARK: - AgentDescribable Tests (iOS 17+/macOS 14+)

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    func testKeyValueRowAgentDescribableComponentType() {
        let row = KeyValueRow(key: "Type", value: "ftyp")

        XCTAssertEqual(row.componentType, "KeyValueRow")
    }

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    func testKeyValueRowAgentDescribableProperties() {
        let row = KeyValueRow(key: "Size", value: "1024", layout: .horizontal, copyable: true)
        let properties = row.properties

        XCTAssertEqual(properties["key"] as? String, "Size")
        XCTAssertEqual(properties["value"] as? String, "1024")
        XCTAssertEqual(properties["layout"] as? String, "horizontal")
        XCTAssertEqual(properties["isCopyable"] as? Bool, true)
    }

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    func testKeyValueRowAgentDescribablePropertiesVertical() {
        let row = KeyValueRow(key: "Path", value: "/home/user", layout: .vertical)
        let properties = row.properties

        XCTAssertEqual(properties["layout"] as? String, "vertical")
        XCTAssertEqual(properties["isCopyable"] as? Bool, false)
    }

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    func testKeyValueRowAgentDescribableSemantics() {
        let row = KeyValueRow(key: "Type", value: "ftyp", copyable: true)
        let semantics = row.semantics

        XCTAssertTrue(semantics.contains("Type"))
        XCTAssertTrue(semantics.contains("ftyp"))
        XCTAssertTrue(semantics.contains("copyable") || semantics.contains("with copyable"))
    }

    // MARK: - Real-World Usage Tests

    /// Verifies KeyValueRow as file metadata display
    func testKeyValueRowAsFileMetadata() {
        let typeRow = KeyValueRow(key: "File Type", value: "ISO Media File")
        let sizeRow = KeyValueRow(key: "Size", value: "2.4 GB", copyable: true)
        let createdRow = KeyValueRow(key: "Created", value: "2025-10-22 12:34:56")

        XCTAssertEqual(typeRow.key, "File Type")
        XCTAssertEqual(sizeRow.copyable, true)
        XCTAssertEqual(createdRow.value, "2025-10-22 12:34:56")
    }

    /// Verifies KeyValueRow as box details display
    func testKeyValueRowAsBoxDetails() {
        let boxTypeRow = KeyValueRow(key: "Box Type", value: "ftyp", copyable: true)
        let offsetRow = KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
        let descRow = KeyValueRow(
            key: "Description",
            value: "File Type Box - defines brand and version compatibility",
            layout: .vertical
        )

        XCTAssertTrue(boxTypeRow.copyable)
        XCTAssertTrue(offsetRow.copyable)
        XCTAssertEqual(descRow.layout, .vertical)
    }

    /// Verifies KeyValueRow as technical data display
    func testKeyValueRowAsTechnicalData() {
        let brandRow = KeyValueRow(key: "Major Brand", value: "isom", copyable: true)
        let versionRow = KeyValueRow(key: "Minor Version", value: "512", copyable: true)
        let brandsRow = KeyValueRow(
            key: "Compatible Brands",
            value: "isom, iso2, avc1, mp41",
            layout: .vertical,
            copyable: true
        )

        XCTAssertTrue(brandRow.copyable)
        XCTAssertTrue(versionRow.copyable)
        XCTAssertEqual(brandsRow.layout, .vertical)
        XCTAssertTrue(brandsRow.copyable)
    }

    /// Verifies KeyValueRow in list context
    func testKeyValueRowInList() {
        let rows = [
            KeyValueRow(key: "Type", value: "ftyp"),
            KeyValueRow(key: "Size", value: "1024 bytes"),
            KeyValueRow(key: "Offset", value: "0x00001234"),
        ]

        XCTAssertEqual(rows.count, 3)
        rows.forEach { row in
            XCTAssertNotNil(row.body)
        }
    }

    // MARK: - KeyValueLayout Equatable Tests

    /// Verifies that KeyValueLayout conforms to Equatable
    func testKeyValueLayoutEquatable() {
        XCTAssertEqual(KeyValueLayout.horizontal, KeyValueLayout.horizontal)
        XCTAssertEqual(KeyValueLayout.vertical, KeyValueLayout.vertical)
        XCTAssertNotEqual(KeyValueLayout.horizontal, KeyValueLayout.vertical)
    }

    // MARK: - Edge Case Tests

    /// Verifies KeyValueRow with special characters in key
    func testKeyValueRowWithSpecialCharactersInKey() {
        let row = KeyValueRow(key: "Size (bytes)", value: "1024")

        XCTAssertEqual(row.key, "Size (bytes)")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with special characters in value
    func testKeyValueRowWithSpecialCharactersInValue() {
        let row = KeyValueRow(key: "Path", value: "/usr/local/bin")

        XCTAssertEqual(row.value, "/usr/local/bin")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with hexadecimal value
    func testKeyValueRowWithHexValue() {
        let row = KeyValueRow(key: "Offset", value: "0x00001234", copyable: true)

        XCTAssertEqual(row.value, "0x00001234")
        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with hash value
    func testKeyValueRowWithHashValue() {
        let hash = "sha256:a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4"
        let row = KeyValueRow(key: "Hash", value: hash, layout: .vertical, copyable: true)

        XCTAssertEqual(row.value, hash)
        XCTAssertEqual(row.layout, .vertical)
        XCTAssertTrue(row.copyable)
    }

    /// Verifies KeyValueRow with numeric value
    func testKeyValueRowWithNumericValue() {
        let row = KeyValueRow(key: "Count", value: "42")

        XCTAssertEqual(row.value, "42")
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with multiline value
    func testKeyValueRowWithMultilineValue() {
        let multiline = "Line 1\nLine 2\nLine 3"
        let row = KeyValueRow(key: "Content", value: multiline, layout: .vertical)

        XCTAssertEqual(row.value, multiline)
        XCTAssertEqual(row.layout, .vertical)
        XCTAssertNotNil(row.body)
    }

    /// Verifies KeyValueRow with Unicode characters
    func testKeyValueRowWithUnicode() {
        let row = KeyValueRow(key: "Emoji", value: "🎬 Video")

        XCTAssertEqual(row.value, "🎬 Video")
        XCTAssertNotNil(row.body)
    }

    // MARK: - Layout Recommendation Tests

    /// Verifies recommended layout for short values
    func testKeyValueRowShortValueRecommendation() {
        // Short values (< 20 characters) should use horizontal layout
        let row = KeyValueRow(key: "Type", value: "ftyp")

        XCTAssertEqual(row.layout, .horizontal)
    }

    /// Verifies recommended layout for long values
    func testKeyValueRowLongValueRecommendation() {
        // Long values should use vertical layout
        let longValue = "This is a very long value that exceeds twenty characters"
        let row = KeyValueRow(key: "Description", value: longValue, layout: .vertical)

        XCTAssertEqual(row.layout, .vertical)
    }

    // MARK: - Combination Tests

    /// Verifies all combinations of layout and copyable
    func testKeyValueRowLayoutCopyableCombinations() {
        let combos = [
            KeyValueRow(key: "A", value: "1", layout: .horizontal, copyable: false),
            KeyValueRow(key: "B", value: "2", layout: .horizontal, copyable: true),
            KeyValueRow(key: "C", value: "3", layout: .vertical, copyable: false),
            KeyValueRow(key: "D", value: "4", layout: .vertical, copyable: true),
        ]

        XCTAssertEqual(combos[0].layout, .horizontal)
        XCTAssertFalse(combos[0].copyable)

        XCTAssertEqual(combos[1].layout, .horizontal)
        XCTAssertTrue(combos[1].copyable)

        XCTAssertEqual(combos[2].layout, .vertical)
        XCTAssertFalse(combos[2].copyable)

        XCTAssertEqual(combos[3].layout, .vertical)
        XCTAssertTrue(combos[3].copyable)
    }
}

// MARK: - Test Documentation

/*
 ## KeyValueRow Component Test Coverage for I0.2

 This comprehensive test suite covers:

 ### Initialization & Parameters (4 tests)
 - Basic initialization with defaults
 - Vertical layout initialization
 - Copyable functionality initialization
 - All parameters combined

 ### Layout Options (3 tests)
 - Horizontal layout (default)
 - Vertical layout
 - KeyValueLayout enum cases and Equatable

 ### Text Content (7 tests)
 - Short, medium, and long text
 - Empty key and value
 - Both empty strings
 - Multiline content
 - Unicode characters

 ### Copyable Functionality (3 tests)
 - Non-copyable (default)
 - Copyable enabled
 - Multiple rows with different settings

 ### View Rendering (4 tests)
 - Body rendering for horizontal layout
 - Body rendering for vertical layout
 - Body rendering with copyable
 - Non-nil body verification

 ### Platform Compatibility (1 test)
 - iOS and macOS support

 ### AgentDescribable Protocol (4 tests, iOS 17+/macOS 14+)
 - Component type identification
 - Properties serialization (horizontal)
 - Properties serialization (vertical)
 - Semantic description generation

 ### Real-World Usage (4 tests)
 - File metadata display
 - Box details display
 - Technical data display
 - List context usage

 ### Edge Cases (7 tests)
 - Special characters in key/value
 - Hexadecimal values
 - Hash values
 - Numeric values
 - Multiline values
 - Unicode support

 ### Layout Recommendations (2 tests)
 - Short values with horizontal layout
 - Long values with vertical layout

 ### Combinations (1 test)
 - All layout × copyable combinations

 **Total Tests:** 40
 **Coverage Target:** ≥80% of KeyValueRow component code paths
 **Phase:** I0.2 - Create Integration Test Suite

 ## Related Files
 - FoundationUI/Sources/FoundationUI/Components/KeyValueRow.swift
 - DOCS/INPROGRESS/212_I0_2_Create_Integration_Test_Suite.md
 */
#endif
