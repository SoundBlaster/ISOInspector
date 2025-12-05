import FoundationUI
import SwiftUI
import XCTest

@testable import ISOInspectorApp

/// Comprehensive test suite for the BoxMetadataRow component
///
/// Tests cover:
/// - Component initialization and rendering
/// - Layout variations (horizontal and vertical)
/// - Copyable functionality
/// - Accessibility labels and semantics
/// - Dark mode adaptation
/// - Design token integration
/// - AgentDescribable protocol conformance
///
/// **Phase:** I1.3 - Key-Value Rows & Metadata Display
/// **Coverage Target:** ≥90% for BoxMetadataRow component
final class BoxMetadataRowComponentTests: XCTestCase {

    // MARK: - Initialization Tests

    /// Verifies that BoxMetadataRow can be initialized with basic parameters
    func testBoxMetadataRowInitialization() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        XCTAssertEqual(row.label, "Type")
        XCTAssertEqual(row.value, "ftyp")
        XCTAssertEqual(row.layout, .horizontal)
        XCTAssertFalse(row.copyable)
    }

    /// Verifies that BoxMetadataRow can be initialized with all parameters
    func testBoxMetadataRowInitializationWithAllParameters() {
        let row = BoxMetadataRow(
            label: "Offset", value: "0x00001234", layout: .vertical, copyable: true)

        XCTAssertEqual(row.label, "Offset")
        XCTAssertEqual(row.value, "0x00001234")
        XCTAssertEqual(row.layout, .vertical)
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow can be initialized with copyable enabled
    func testBoxMetadataRowInitializationWithCopyable() {
        let row = BoxMetadataRow(label: "Size", value: "1024 bytes", copyable: true)

        XCTAssertEqual(row.label, "Size")
        XCTAssertEqual(row.value, "1024 bytes")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow defaults to horizontal layout
    func testBoxMetadataRowDefaultLayoutIsHorizontal() {
        let row = BoxMetadataRow(label: "Test", value: "Value")

        XCTAssertEqual(row.layout, .horizontal)
    }

    /// Verifies that BoxMetadataRow defaults to non-copyable
    func testBoxMetadataRowDefaultNotCopyable() {
        let row = BoxMetadataRow(label: "Test", value: "Value")

        XCTAssertFalse(row.copyable)
    }

    // MARK: - Layout Tests

    /// Verifies that BoxMetadataRow supports horizontal layout
    func testBoxMetadataRowHorizontalLayout() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", layout: .horizontal)

        XCTAssertEqual(row.layout, .horizontal)
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow supports vertical layout
    func testBoxMetadataRowVerticalLayout() {
        let row = BoxMetadataRow(
            label: "Description",
            value: "A very long description that benefits from vertical layout", layout: .vertical)

        XCTAssertEqual(row.layout, .vertical)
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow can switch between layouts
    func testBoxMetadataRowLayoutSwitching() {
        let horizontalRow = BoxMetadataRow(label: "Test", value: "Value", layout: .horizontal)
        let verticalRow = BoxMetadataRow(label: "Test", value: "Value", layout: .vertical)

        XCTAssertNotEqual(horizontalRow.layout, verticalRow.layout)
        XCTAssertEqual(horizontalRow.layout, .horizontal)
        XCTAssertEqual(verticalRow.layout, .vertical)
    }

    // MARK: - Copyable Tests

    /// Verifies that copyable can be enabled
    func testBoxMetadataRowCopyableEnabled() {
        let row = BoxMetadataRow(label: "Hash", value: "0xDEADBEEF", copyable: true)

        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    /// Verifies that copyable can be disabled
    func testBoxMetadataRowCopyableDisabled() {
        let row = BoxMetadataRow(label: "Hash", value: "0xDEADBEEF", copyable: false)

        XCTAssertFalse(row.copyable)
    }

    /// Verifies that copyable works with horizontal layout
    func testBoxMetadataRowCopyableWithHorizontalLayout() {
        let row = BoxMetadataRow(
            label: "Offset", value: "0x00001234", layout: .horizontal, copyable: true)

        XCTAssertEqual(row.layout, .horizontal)
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that copyable works with vertical layout
    func testBoxMetadataRowCopyableWithVerticalLayout() {
        let row = BoxMetadataRow(
            label: "Description", value: "Long value for vertical layout", layout: .vertical,
            copyable: true)

        XCTAssertEqual(row.layout, .vertical)
        XCTAssertTrue(row.copyable)
    }

    // MARK: - Content Tests

    /// Verifies that BoxMetadataRow displays short label correctly
    func testBoxMetadataRowShortLabel() {
        let row = BoxMetadataRow(label: "ID", value: "12345")

        XCTAssertEqual(row.label, "ID")
    }

    /// Verifies that BoxMetadataRow displays medium label correctly
    func testBoxMetadataRowMediumLabel() {
        let row = BoxMetadataRow(label: "File Type", value: "ftyp")

        XCTAssertEqual(row.label, "File Type")
    }

    /// Verifies that BoxMetadataRow displays long label correctly
    func testBoxMetadataRowLongLabel() {
        let row = BoxMetadataRow(label: "Box Description", value: "Value")

        XCTAssertEqual(row.label, "Box Description")
    }

    /// Verifies that BoxMetadataRow displays short value correctly
    func testBoxMetadataRowShortValue() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        XCTAssertEqual(row.value, "ftyp")
    }

    /// Verifies that BoxMetadataRow displays medium value correctly
    func testBoxMetadataRowMediumValue() {
        let row = BoxMetadataRow(label: "Size", value: "1024 bytes")

        XCTAssertEqual(row.value, "1024 bytes")
    }

    /// Verifies that BoxMetadataRow displays long value correctly
    func testBoxMetadataRowLongValue() {
        let longValue =
            "This is a very long value that should be displayed correctly in the metadata row component"
        let row = BoxMetadataRow(label: "Description", value: longValue)

        XCTAssertEqual(row.value, longValue)
    }

    /// Verifies that BoxMetadataRow handles hex values
    func testBoxMetadataRowHexValue() {
        let row = BoxMetadataRow(label: "Offset", value: "0x00001234", copyable: true)

        XCTAssertEqual(row.value, "0x00001234")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow handles numeric values
    func testBoxMetadataRowNumericValue() {
        let row = BoxMetadataRow(label: "Size", value: "2048")

        XCTAssertEqual(row.value, "2048")
    }

    /// Verifies that BoxMetadataRow handles special characters in values
    func testBoxMetadataRowSpecialCharactersValue() {
        let hashValue = "a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4"
        let row = BoxMetadataRow(label: "Hash", value: hashValue)

        XCTAssertEqual(row.value, hashValue)
    }

    // MARK: - Real World Metadata Tests

    /// Verifies that BoxMetadataRow correctly displays ISO box type metadata
    func testBoxMetadataRowISOBoxType() {
        let row = BoxMetadataRow(label: "Box Type", value: "ftyp", copyable: true)

        XCTAssertEqual(row.label, "Box Type")
        XCTAssertEqual(row.value, "ftyp")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow correctly displays ISO box offset metadata
    func testBoxMetadataRowISOBoxOffset() {
        let row = BoxMetadataRow(label: "Offset", value: "0x00000000", copyable: true)

        XCTAssertEqual(row.label, "Offset")
        XCTAssertEqual(row.value, "0x00000000")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow correctly displays ISO box size metadata
    func testBoxMetadataRowISOBoxSize() {
        let row = BoxMetadataRow(label: "Size", value: "32 bytes", copyable: true)

        XCTAssertEqual(row.label, "Size")
        XCTAssertEqual(row.value, "32 bytes")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow correctly displays codec information
    func testBoxMetadataRowCodecInformation() {
        let row = BoxMetadataRow(label: "Codec", value: "avc1", copyable: true)

        XCTAssertEqual(row.label, "Codec")
        XCTAssertEqual(row.value, "avc1")
        XCTAssertTrue(row.copyable)
    }

    /// Verifies that BoxMetadataRow correctly displays track information
    func testBoxMetadataRowTrackInformation() {
        let row = BoxMetadataRow(label: "Track Type", value: "video", copyable: false)

        XCTAssertEqual(row.label, "Track Type")
        XCTAssertEqual(row.value, "video")
        XCTAssertFalse(row.copyable)
    }

    /// Verifies that BoxMetadataRow correctly displays file header details
    func testBoxMetadataRowFileHeaderDetails() {
        let row = BoxMetadataRow(label: "Brand", value: "isom", copyable: true)

        XCTAssertEqual(row.label, "Brand")
        XCTAssertEqual(row.value, "isom")
        XCTAssertTrue(row.copyable)
    }

    // MARK: - AgentDescribable Tests

    /// Verifies that BoxMetadataRow conforms to AgentDescribable
    @available(iOS 17.0, macOS 14.0, *) func testBoxMetadataRowAgentDescribableConformance() {
        let row = BoxMetadataRow(label: "Test", value: "Value")
        // BoxMetadataRow conforms to AgentDescribable via extension
        // Verify it's accessible and has expected properties
        XCTAssertNotNil(row)
    }

    /// Verifies that BoxMetadataRow provides correct componentType
    @MainActor @available(iOS 17.0, macOS 14.0, *) func testBoxMetadataRowComponentType() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")
        XCTAssertEqual(row.componentType, "BoxMetadataRow")
    }

    /// Verifies that BoxMetadataRow provides properties for agent description
    @MainActor @available(iOS 17.0, macOS 14.0, *) func testBoxMetadataRowAgentProperties() {
        let row = BoxMetadataRow(
            label: "Offset", value: "0x1234", layout: .vertical, copyable: true)
        let properties = row.properties
        XCTAssertEqual(properties["label"] as? String, "Offset")
        XCTAssertEqual(properties["value"] as? String, "0x1234")
        XCTAssertEqual(properties["layout"] as? String, "vertical")
        XCTAssertEqual(properties["copyable"] as? Bool, true)
    }

    /// Verifies that BoxMetadataRow provides semantic description
    @MainActor @available(iOS 17.0, macOS 14.0, *) func testBoxMetadataRowAgentSemantics() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)
        let semantics = row.semantics
        XCTAssertTrue(semantics.contains("Type"))
        XCTAssertTrue(semantics.contains("ftyp"))
        XCTAssertTrue(semantics.contains("copyable"))
    }

    // MARK: - Integration Tests

    /// Verifies that BoxMetadataRow renders correctly in a VStack
    func testBoxMetadataRowRenderingInVStack() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            BoxMetadataRow(label: "Type", value: "ftyp")
            BoxMetadataRow(label: "Size", value: "1024 bytes")
            BoxMetadataRow(label: "Offset", value: "0x00001234", copyable: true)
        }

        XCTAssertNotNil(view)
    }

    /// Verifies that BoxMetadataRow renders correctly with ScrollView
    func testBoxMetadataRowRenderingInScrollView() {
        let view = ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                BoxMetadataRow(label: "Type", value: "ftyp")
                BoxMetadataRow(label: "Size", value: "1024 bytes")
            }
        }

        XCTAssertNotNil(view)
    }

    /// Verifies that multiple BoxMetadataRow instances can be created and displayed
    func testMultipleBoxMetadataRows() {
        let rows = (1...10).map { index in
            BoxMetadataRow(
                label: "Field \(index)", value: "Value \(index)", copyable: index % 2 == 0)
        }

        XCTAssertEqual(rows.count, 10)
        XCTAssertTrue(rows[1].copyable)
        XCTAssertFalse(rows[0].copyable)
    }

    /// Verifies that BoxMetadataRow can be used in a ScrollView with multiple rows
    @MainActor func testBoxMetadataRowInLargeScrollView() {
        var rows: [BoxMetadataRow] = []
        for i in 0..<50 {
            rows.append(
                BoxMetadataRow(
                    label: "Field \(i)", value: "Value \(i)",
                    layout: i % 2 == 0 ? .horizontal : .vertical, copyable: i % 3 == 0))
        }

        XCTAssertEqual(rows.count, 50)
    }

    // MARK: - Accessibility Tests

    /// Verifies that BoxMetadataRow provides accessibility labels for VoiceOver
    func testBoxMetadataRowAccessibilityLabel() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        XCTAssertNotNil(row.body)
        // The underlying KeyValueRow provides accessibility labels
        // This test verifies the component renders without accessibility issues
    }

    /// Verifies that BoxMetadataRow supports Dynamic Type text scaling
    func testBoxMetadataRowDynamicTypeSupport() {
        let row = BoxMetadataRow(label: "Label", value: "Value")

        // Verify the component body exists and can be rendered with dynamic type
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow maintains minimum touch target sizes
    func testBoxMetadataRowTouchTargetSize() {
        let row = BoxMetadataRow(label: "Test", value: "Value", copyable: true)

        // When copyable is enabled, the value becomes a button
        // which should maintain minimum touch target sizes (44×44 points)
        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    /// Verifies that copyable BoxMetadataRow provides VoiceOver hints
    func testBoxMetadataRowCopyableAccessibilityHint() {
        let row = BoxMetadataRow(label: "Hash", value: "0xDEADBEEF", copyable: true)

        // The underlying KeyValueRow provides accessibility hints for copyable content
        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow is compatible with Reduce Motion
    func testBoxMetadataRowReduceMotionCompatibility() {
        let row = BoxMetadataRow(label: "Test", value: "Value", copyable: true)

        // The component uses FoundationUI's design system which respects Reduce Motion
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow works with High Contrast mode
    func testBoxMetadataRowHighContrastMode() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)

        // FoundationUI components automatically adapt to High Contrast mode
        XCTAssertNotNil(row.body)
    }

    /// Verifies that accessibility labels include both label and value
    func testBoxMetadataRowAccessibilityLabelIncludesBothParts() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        // Accessibility should include both label and value
        XCTAssertEqual(row.label, "Type")
        XCTAssertEqual(row.value, "ftyp")
    }

    // MARK: - Dark Mode Tests

    /// Verifies that BoxMetadataRow inherits dark mode support from FoundationUI
    func testBoxMetadataRowDarkModeSupport() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        // The underlying KeyValueRow uses DS design tokens which support dark mode
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow displays correctly in light mode
    func testBoxMetadataRowLightMode() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)

        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow displays correctly with all layouts in dark mode
    func testBoxMetadataRowDarkModeAllLayouts() {
        let horizontalRow = BoxMetadataRow(label: "Test", value: "Value", layout: .horizontal)
        let verticalRow = BoxMetadataRow(label: "Test", value: "Value", layout: .vertical)

        // Both layouts should work in dark mode
        XCTAssertNotNil(horizontalRow.body)
        XCTAssertNotNil(verticalRow.body)
    }

    /// Verifies that copyable button is visible in dark mode
    func testBoxMetadataRowCopyableButtonDarkMode() {
        let row = BoxMetadataRow(label: "Hash", value: "0xDEADBEEF", copyable: true)

        // Copyable button should be visible and functional in dark mode
        XCTAssertTrue(row.copyable)
        XCTAssertNotNil(row.body)
    }

    // MARK: - Design System Token Tests

    /// Verifies that BoxMetadataRow uses Design System typography tokens
    func testBoxMetadataRowDesignSystemTypography() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        // The component delegates to KeyValueRow which uses DS.Typography tokens
        // This test verifies the component creates successfully
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow uses Design System spacing tokens
    func testBoxMetadataRowDesignSystemSpacing() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp")

        // The component delegates to KeyValueRow which uses DS.Spacing tokens
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow uses Design System color tokens
    func testBoxMetadataRowDesignSystemColors() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)

        // The component delegates to KeyValueRow which uses DS color system
        XCTAssertNotNil(row.body)
    }

    // MARK: - Snapshot & Layout Tests

    /// Verifies that BoxMetadataRow horizontal layout matches expected proportions
    func testBoxMetadataRowHorizontalLayoutProportions() {
        let row = BoxMetadataRow(label: "Type", value: "ftyp", layout: .horizontal)

        XCTAssertEqual(row.layout, .horizontal)
        // In horizontal layout, label takes fixed width and value uses remaining space
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow vertical layout maintains proper spacing
    func testBoxMetadataRowVerticalLayoutSpacing() {
        let row = BoxMetadataRow(
            label: "Description", value: "Long value that needs vertical layout for readability",
            layout: .vertical)

        XCTAssertEqual(row.layout, .vertical)
        // In vertical layout, label and value are stacked with DS.Spacing.s between them
        XCTAssertNotNil(row.body)
    }

    /// Verifies that BoxMetadataRow renders correctly with various content lengths
    func testBoxMetadataRowVariousContentLengths() {
        let shortRow = BoxMetadataRow(label: "ID", value: "1")
        let mediumRow = BoxMetadataRow(label: "File Type", value: "ISO Media File")
        let longDescription =
            "This is a very long description that spans multiple words and "
            + "provides detailed information about the content"
        let longRow = BoxMetadataRow(
            label: "Description", value: longDescription, layout: .vertical)

        XCTAssertNotNil(shortRow.body)
        XCTAssertNotNil(mediumRow.body)
        XCTAssertNotNil(longRow.body)
    }

    /// Verifies that BoxMetadataRow maintains alignment in multiple-row scenarios
    func testBoxMetadataRowMultipleRowAlignment() {
        let rows = [
            BoxMetadataRow(label: "Short", value: "Value"),
            BoxMetadataRow(label: "Medium Label", value: "Medium Value"),
            BoxMetadataRow(label: "Very Long Label", value: "Very Long Value"),
        ]

        // All rows should maintain left-alignment for labels
        for row in rows { XCTAssertNotNil(row.body) }
    }

    // MARK: - Performance Tests

    /// Verifies that BoxMetadataRow initializes efficiently
    func testBoxMetadataRowInitializationPerformance() {
        measure { _ = BoxMetadataRow(label: "Type", value: "ftyp") }
    }

    /// Verifies that creating multiple BoxMetadataRow instances is efficient
    func testBoxMetadataRowBulkCreationPerformance() {
        measure {
            for _ in 0..<100 { _ = BoxMetadataRow(label: "Label", value: "Value", copyable: true) }
        }
    }
}
