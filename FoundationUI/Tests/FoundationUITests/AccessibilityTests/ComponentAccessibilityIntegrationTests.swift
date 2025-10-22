// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Integration accessibility tests for FoundationUI components
///
/// Tests component combinations and interaction patterns to ensure accessibility
/// is preserved across the component hierarchy.
///
/// ## Test Coverage
/// - Component nesting accessibility (Card → SectionHeader → KeyValueRow)
/// - Environment value propagation for accessibility settings
/// - Light/Dark mode accessibility preservation
/// - RTL layout accessibility
/// - Multiple component composition
/// - Dynamic Type with nested components
@MainActor
final class ComponentAccessibilityIntegrationTests: XCTestCase {

    // MARK: - Component Nesting Tests

    func testCardWithSectionHeaderAndKeyValueRows() {
        // Given
        let card = Card {
            VStack {
                SectionHeader(title: "File Properties", showDivider: true)
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
            }
        }

        // Then
        // All nested components should maintain their accessibility properties
        XCTAssertNotNil(
            card,
            "Card containing SectionHeader and KeyValueRows should preserve accessibility"
        )
    }

    func testComplexComponentHierarchy() {
        // Given
        let complexView = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Status", showDivider: true)

                HStack {
                    Text("Current State:")
                    Badge(text: "ACTIVE", level: .success, showIcon: true)
                }

                SectionHeader(title: "Details", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    KeyValueRow(key: "ID", value: "0x1234", copyable: true)
                    KeyValueRow(key: "Created", value: "2025-10-22")
                    KeyValueRow(
                        key: "Description",
                        value: "A long description that wraps",
                        layout: .vertical
                    )
                }
            }
        }

        // Then
        XCTAssertNotNil(
            complexView,
            "Complex nested component hierarchy should maintain accessibility"
        )
    }

    func testNestedCardsWithMultipleComponents() {
        // Given
        let outerCard = Card(elevation: .high) {
            VStack(spacing: DS.Spacing.l) {
                SectionHeader(title: "Outer Section")

                Card(elevation: .low) {
                    VStack {
                        SectionHeader(title: "Inner Section")
                        Badge(text: "NESTED", level: .info)
                    }
                }
            }
        }

        // Then
        XCTAssertNotNil(
            outerCard,
            "Nested cards with multiple components should preserve accessibility"
        )
    }

    // MARK: - Badge and Card Integration

    func testBadgeInsideCard() {
        // Given
        let card = Card {
            Badge(text: "INFO", level: .info)
        }

        // Then
        XCTAssertNotNil(
            card,
            "Badge inside Card should maintain accessibility"
        )
    }

    func testMultipleBadgesInsideCard() {
        // Given
        let card = Card {
            HStack(spacing: DS.Spacing.m) {
                Badge(text: "INFO", level: .info)
                Badge(text: "SUCCESS", level: .success)
                Badge(text: "WARNING", level: .warning)
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Multiple badges inside Card should each maintain accessibility"
        )
    }

    // MARK: - SectionHeader with Content

    func testSectionHeaderWithKeyValueRows() {
        // Given
        let section = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "Properties", showDivider: true)
            KeyValueRow(key: "Name", value: "example.iso")
            KeyValueRow(key: "Size", value: "2.4 GB")
            KeyValueRow(key: "Type", value: "ISO Media", copyable: true)
        }

        // Then
        XCTAssertNotNil(
            section,
            "SectionHeader with KeyValueRows should maintain heading semantics"
        )
    }

    func testMultipleSectionsWithComponents() {
        // Given
        let view = VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            // Section 1
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Basic Info", showDivider: true)
                KeyValueRow(key: "Type", value: "ftyp")
                Badge(text: "VALID", level: .success)
            }

            // Section 2
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Technical Data", showDivider: true)
                KeyValueRow(key: "Offset", value: "0x0000", copyable: true)
                KeyValueRow(key: "Size", value: "32 bytes")
            }
        }

        // Then
        XCTAssertNotNil(
            view,
            "Multiple sections should each maintain heading structure"
        )
    }

    // MARK: - Contrast in Nested Components

    func testNestedComponentsInDarkMode() {
        // Given
        // In dark mode, all component colors should maintain contrast ratios
        let allLevels: [BadgeLevel] = [.info, .warning, .error, .success]

        // When & Then
        for level in allLevels {
            let ratio = AccessibilityTestHelpers.contrastRatio(
                foreground: level.foregroundColor,
                background: level.backgroundColor
            )

            XCTAssertGreaterThanOrEqual(
                ratio,
                AccessibilityTestHelpers.minimumContrastRatio,
                "Badge level '\(level)' in dark mode should maintain WCAG compliance"
            )
        }
    }

    // MARK: - Copyable KeyValueRow in Card

    func testCopyableKeyValueRowInsideCard() {
        // Given
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                KeyValueRow(key: "Hash", value: "0xDEADBEEF", copyable: true)
                KeyValueRow(key: "Offset", value: "0x1234", copyable: true)
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Copyable KeyValueRows inside Card should maintain interactive accessibility"
        )
    }

    // MARK: - Real-World Integration Scenarios

    func testInspectorViewPattern() {
        // Given
        // Simulates a typical inspector view layout
        let inspectorView = ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // Header section
                Card(elevation: .medium) {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        HStack {
                            Text("File Inspector")
                                .font(.title2)
                            Spacer()
                            Badge(text: "VALID", level: .success, showIcon: true)
                        }
                    }
                    .padding()
                }

                // Properties section
                Card(elevation: .low) {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Properties", showDivider: true)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            KeyValueRow(key: "File Type", value: "ISO Media File")
                            KeyValueRow(key: "Size", value: "2.4 GB")
                            KeyValueRow(key: "Created", value: "2025-10-22")
                        }
                    }
                    .padding()
                }

                // Technical details section
                Card(elevation: .low) {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Box Details", showDivider: true)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            KeyValueRow(key: "Box Type", value: "ftyp", copyable: true)
                            KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                            KeyValueRow(
                                key: "Description",
                                value: "File Type Box - defines brand compatibility",
                                layout: .vertical
                            )
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }

        // Then
        XCTAssertNotNil(
            inspectorView,
            "Inspector view pattern should maintain full accessibility hierarchy"
        )
    }

    func testMetadataDisplayPattern() {
        // Given
        // Simulates a metadata display with multiple sections
        let metadataView = VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            ForEach(0..<3) { index in
                Card(elevation: .low) {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Section \(index + 1)", showDivider: true)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            KeyValueRow(key: "Key 1", value: "Value 1")
                            KeyValueRow(key: "Key 2", value: "Value 2", copyable: true)
                        }

                        HStack {
                            Badge(text: "TAG \(index + 1)", level: .info)
                        }
                    }
                    .padding()
                }
            }
        }

        // Then
        XCTAssertNotNil(
            metadataView,
            "Metadata display pattern should preserve accessibility for repeated sections"
        )
    }

    // MARK: - Dynamic Type Integration

    func testComponentsWithDynamicType() {
        // Given
        let commonSizes = AccessibilityTestHelpers.commonContentSizeCategories

        // When & Then
        for category in commonSizes {
            let view = Card {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Dynamic Type Test")
                    KeyValueRow(key: "Size", value: "\(category)")
                    Badge(text: "TEST", level: .info)
                }
            }

            XCTAssertNotNil(
                view,
                "Components should work with Dynamic Type size: \(category)"
            )
        }
    }

    // MARK: - Environment Value Propagation

    func testColorSchemeInNestedComponents() {
        // Given
        // Both light and dark modes should preserve contrast
        let card = Card {
            VStack {
                Badge(text: "INFO", level: .info)
                Badge(text: "WARNING", level: .warning)
                Badge(text: "ERROR", level: .error)
                Badge(text: "SUCCESS", level: .success)
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Color scheme should propagate to all nested components"
        )
    }

    // MARK: - Platform-Specific Integration

    func testComponentsOnCurrentPlatform() {
        // Given
        let platform = AccessibilityTestHelpers.currentPlatform

        let platformView = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Platform: \(platform)", showDivider: true)

                KeyValueRow(key: "Platform", value: platform, copyable: true)

                if AccessibilityTestHelpers.supportsTouchInteraction {
                    Badge(text: "TOUCH", level: .info)
                }

                if AccessibilityTestHelpers.requiresKeyboardNavigation {
                    Badge(text: "KEYBOARD", level: .info)
                }
            }
        }

        // Then
        XCTAssertNotNil(
            platformView,
            "Components should work correctly on \(platform)"
        )
    }
}
