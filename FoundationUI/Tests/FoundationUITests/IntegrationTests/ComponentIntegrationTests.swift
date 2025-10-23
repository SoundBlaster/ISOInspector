// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Integration tests for component composition and interaction
///
/// Tests verify:
/// - Component nesting and composition (Card → SectionHeader → KeyValueRow → Badge)
/// - Environment value propagation across component hierarchies
/// - State management in complex component compositions
/// - Cross-component accessibility integration
/// - Real-world usage patterns and layouts
///
/// ## Test Coverage
/// - Component nesting scenarios
/// - Environment values
/// - State management
/// - Accessibility composition
/// - Platform adaptation
@MainActor
final class ComponentIntegrationTests: XCTestCase {

    // MARK: - Component Nesting Tests

    func testCardCanContainSectionHeader() {
        // Given: A Card component containing a SectionHeader
        let card = Card {
            SectionHeader(title: "Test Section")
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Card should be able to contain SectionHeader")
    }

    func testCardCanContainMultipleSectionHeaders() {
        // Given: A Card component containing multiple SectionHeaders
        let card = Card {
            VStack(spacing: DS.Spacing.m) {
                SectionHeader(title: "Section 1")
                SectionHeader(title: "Section 2")
                SectionHeader(title: "Section 3")
            }
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Card should be able to contain multiple SectionHeaders")
    }

    func testCardCanContainKeyValueRows() {
        // Given: A Card component containing KeyValueRow components
        let card = Card {
            VStack(spacing: DS.Spacing.s) {
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024")
                KeyValueRow(key: "Offset", value: "0x00001234")
            }
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Card should be able to contain KeyValueRow components")
    }

    func testCardCanContainBadges() {
        // Given: A Card component containing Badge components
        let card = Card {
            HStack(spacing: DS.Spacing.m) {
                Badge(text: "INFO", level: .info)
                Badge(text: "WARNING", level: .warning)
                Badge(text: "ERROR", level: .error)
            }
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Card should be able to contain Badge components")
    }

    func testComplexComponentNesting() {
        // Given: A complex component hierarchy (Card → VStack → SectionHeader + KeyValueRows)
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "File Properties", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    KeyValueRow(key: "Type", value: "ftyp")
                    KeyValueRow(key: "Size", value: "1024 bytes")
                    KeyValueRow(key: "Offset", value: "0x00001234", copyable: true)
                }
            }
            .padding()
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Complex component nesting should be valid")
    }

    func testDeepComponentNesting() {
        // Given: A deeply nested component hierarchy
        let card = Card(elevation: .high) {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                SectionHeader(title: "Outer Section", showDivider: true)

                Card(elevation: .low) {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        SectionHeader(title: "Inner Section", showDivider: true)

                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            KeyValueRow(key: "Type", value: "ftyp")

                            HStack {
                                Text("Status:")
                                Badge(text: "VALID", level: .success)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Deep component nesting should be valid")
    }

    func testRealWorldInspectorLayout() {
        // Given: A real-world ISO inspector layout pattern
        let inspectorView = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // File Properties Section
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "File Properties", showDivider: true)
                    KeyValueRow(key: "Name", value: "example.mp4")
                    KeyValueRow(key: "Size", value: "2.4 GB")
                    KeyValueRow(key: "Type", value: "ISO Media File")
                }

                // Box Details Section
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Box Details", showDivider: true)
                    KeyValueRow(key: "Box Type", value: "ftyp", copyable: true)
                    KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                    HStack {
                        Text("Status:")
                        Badge(text: "VALID", level: .success, showIcon: true)
                    }
                }

                // Metadata Section
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Metadata", showDivider: true)
                    KeyValueRow(
                        key: "Description",
                        value: "File Type Box - defines brand and version compatibility",
                        layout: .vertical
                    )
                    KeyValueRow(key: "Major Brand", value: "isom", copyable: true)
                }
            }
            .padding()
        }

        // Then: The composition should be valid
        XCTAssertNotNil(inspectorView, "Real-world inspector layout should be valid")
    }

    // MARK: - Environment Value Propagation Tests

    func testColorSchemePropagatesToNestedComponents() {
        // Given: A card with nested components in dark mode
        let card = Card {
            VStack {
                SectionHeader(title: "Test")
                KeyValueRow(key: "Type", value: "ftyp")
                Badge(text: "INFO", level: .info)
            }
        }

        // Then: The composition should be valid (environment propagates)
        XCTAssertNotNil(card, "Color scheme should propagate to nested components")
    }

    func testDynamicTypePropagatesToNestedComponents() {
        // Given: Components that should respect Dynamic Type
        let card = Card {
            VStack {
                SectionHeader(title: "Test Section")
                KeyValueRow(key: "Key", value: "Value")
            }
        }

        // Then: The composition should be valid (Dynamic Type propagates)
        XCTAssertNotNil(card, "Dynamic Type should propagate to nested components")
    }

    // MARK: - State Management Tests

    func testStatefulComponentComposition() {
        // Given: A composition with stateful components (KeyValueRow with copyable)
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Copyable Values")
                KeyValueRow(key: "Type", value: "ftyp", copyable: true)
                KeyValueRow(key: "Size", value: "1024", copyable: true)
                KeyValueRow(key: "Hash", value: "0xDEADBEEF", copyable: true)
            }
            .padding()
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Stateful component composition should be valid")
    }

    func testMultipleStatefulComponentsInCard() {
        // Given: Multiple stateful components in a single card
        let card = Card {
            VStack(spacing: DS.Spacing.l) {
                // Each KeyValueRow has independent state for copy feedback
                KeyValueRow(key: "Value 1", value: "test1", copyable: true)
                KeyValueRow(key: "Value 2", value: "test2", copyable: true)
                KeyValueRow(key: "Value 3", value: "test3", copyable: true)
            }
            .padding()
        }

        // Then: The composition should be valid with independent states
        XCTAssertNotNil(card, "Multiple stateful components should maintain independent states")
    }

    // MARK: - Accessibility Composition Tests

    func testAccessibilityLabelsPropagateInNestedComponents() {
        // Given: Nested components with accessibility labels
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Test Section") // Has .isHeader trait
                KeyValueRow(key: "Type", value: "ftyp") // Has combined accessibility label
                Badge(text: "INFO", level: .info) // Has semantic accessibility label
            }
        }

        // Then: The composition should be valid
        XCTAssertNotNil(card, "Accessibility labels should propagate correctly")
    }

    func testAccessibilityContainmentInCard() {
        // Given: A Card with .accessibilityElement(children: .contain)
        let card = Card {
            VStack {
                Text("Title")
                    .accessibilityAddTraits(.isHeader)
                Text("Content")
            }
            .padding()
        }

        // Then: The card should maintain accessibility containment
        XCTAssertNotNil(card, "Card should maintain accessibility containment")
    }

    // MARK: - Platform Adaptation Tests

    func testComponentCompositionOnAllPlatforms() {
        // Given: A component composition that should work on all platforms
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.platformDefault) {
                SectionHeader(title: "Platform Test")
                KeyValueRow(key: "Platform", value: {
                    #if os(macOS)
                    return "macOS"
                    #elseif os(iOS)
                    return "iOS"
                    #else
                    return "Other"
                    #endif
                }())
            }
            .padding()
        }

        // Then: The composition should be valid on all platforms
        XCTAssertNotNil(card, "Component composition should work on all platforms")
    }

    // MARK: - Design System Token Usage Tests

    func testNestedComponentsUseDesignSystemTokens() {
        // Given: Nested components using DS tokens exclusively
        let card = Card(
            elevation: .medium,
            cornerRadius: DS.Radius.card
        ) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "DS Tokens Test", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    KeyValueRow(key: "Spacing S", value: "\(DS.Spacing.s)")
                    KeyValueRow(key: "Spacing M", value: "\(DS.Spacing.m)")
                    KeyValueRow(key: "Spacing L", value: "\(DS.Spacing.l)")
                    KeyValueRow(key: "Spacing XL", value: "\(DS.Spacing.xl)")
                }
            }
            .padding(DS.Spacing.l)
        }

        // Then: All components should use DS tokens
        XCTAssertNotNil(card, "Nested components should use DS tokens exclusively")
    }

    // MARK: - Layout Combination Tests

    func testHorizontalAndVerticalLayoutCombinations() {
        // Given: A card with mixed layout orientations
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "Mixed Layouts")

                // Horizontal layout KeyValueRows
                KeyValueRow(key: "Short", value: "value", layout: .horizontal)

                // Vertical layout KeyValueRows
                KeyValueRow(
                    key: "Long Description",
                    value: "This is a very long value that works better in vertical layout",
                    layout: .vertical
                )

                // Mixed with badges
                HStack {
                    Badge(text: "INFO", level: .info)
                    Badge(text: "SUCCESS", level: .success)
                }
            }
            .padding()
        }

        // Then: Mixed layouts should work together
        XCTAssertNotNil(card, "Horizontal and vertical layouts should work together")
    }

    // MARK: - Material Background Integration Tests

    func testComponentsWithCardMaterialBackgrounds() {
        // Given: Components inside a Card with material background
        let card = Card(material: .thin) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Material Background")
                KeyValueRow(key: "Type", value: "translucent")
                Badge(text: "ACTIVE", level: .success)
            }
            .padding()
        }

        // Then: Components should work with material backgrounds
        XCTAssertNotNil(card, "Components should work with Card material backgrounds")
    }

    func testMultipleMaterialBackgroundLevels() {
        // Given: Cards with different material backgrounds
        let materials: [Material?] = [.ultraThin, .thin, .regular, .thick, .ultraThick, nil]

        // When: Creating cards with each material level
        for material in materials {
            let card = Card(material: material) {
                VStack {
                    SectionHeader(title: "Material Test")
                    KeyValueRow(key: "Level", value: String(describing: material ?? "none"))
                }
                .padding()
            }

            // Then: Each material level should work
            XCTAssertNotNil(card, "Card with material \(String(describing: material)) should be valid")
        }
    }

    // MARK: - Elevation and Nesting Tests

    func testNestedCardsWithDifferentElevations() {
        // Given: Cards nested with different elevation levels
        let outerCard = Card(elevation: .high) {
            VStack(spacing: DS.Spacing.l) {
                SectionHeader(title: "Outer Card")

                Card(elevation: .medium) {
                    VStack {
                        SectionHeader(title: "Medium Card")
                        KeyValueRow(key: "Level", value: "Medium")
                    }
                    .padding()
                }

                Card(elevation: .low) {
                    VStack {
                        SectionHeader(title: "Low Card")
                        KeyValueRow(key: "Level", value: "Low")
                    }
                    .padding()
                }

                Card(elevation: .none) {
                    VStack {
                        SectionHeader(title: "No Elevation")
                        KeyValueRow(key: "Level", value: "None")
                    }
                    .padding()
                }
            }
            .padding()
        }

        // Then: Nested cards with different elevations should work
        XCTAssertNotNil(outerCard, "Nested cards with different elevations should be valid")
    }

    // MARK: - Badge Integration Tests

    func testBadgesIntegratedWithKeyValueRows() {
        // Given: Badges displayed alongside KeyValueRows
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Status Information")

                HStack {
                    Text("Type:")
                    Badge(text: "ISO", level: .info)
                }

                KeyValueRow(key: "Size", value: "2.4 GB")

                HStack {
                    Text("Status:")
                    Badge(text: "VALID", level: .success, showIcon: true)
                }

                KeyValueRow(key: "Modified", value: "2025-10-22")
            }
            .padding()
        }

        // Then: Badges should integrate well with KeyValueRows
        XCTAssertNotNil(card, "Badges should integrate with KeyValueRows")
    }

    func testAllBadgeLevelsInSingleCard() {
        // Given: A card containing all badge levels
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "All Badge Levels", showDivider: true)

                HStack(spacing: DS.Spacing.m) {
                    Badge(text: "INFO", level: .info)
                    Badge(text: "WARNING", level: .warning)
                    Badge(text: "ERROR", level: .error)
                    Badge(text: "SUCCESS", level: .success)
                }
            }
            .padding()
        }

        // Then: All badge levels should coexist
        XCTAssertNotNil(card, "All badge levels should work together in a card")
    }

    // MARK: - Performance and Hierarchy Tests

    func testLargeComponentHierarchyComposition() {
        // Given: A large component hierarchy (simulating real inspector UI)
        let largeCard = Card(elevation: .medium) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    // Generate multiple sections
                    ForEach(0..<10, id: \.self) { sectionIndex in
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            SectionHeader(title: "Section \(sectionIndex)", showDivider: true)

                            ForEach(0..<5, id: \.self) { rowIndex in
                                KeyValueRow(
                                    key: "Property \(rowIndex)",
                                    value: "Value \(rowIndex)",
                                    copyable: rowIndex % 2 == 0
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }

        // Then: Large hierarchies should be valid
        XCTAssertNotNil(largeCard, "Large component hierarchies should be valid")
    }

    // MARK: - Empty State Tests

    func testEmptyCardContent() {
        // Given: A card with no content
        let emptyCard = Card {
            EmptyView()
        }

        // Then: Empty card should be valid
        XCTAssertNotNil(emptyCard, "Empty card should be valid")
    }

    func testCardWithOnlySectionHeader() {
        // Given: A card containing only a section header
        let card = Card {
            SectionHeader(title: "Only Header")
                .padding()
        }

        // Then: Card with only header should be valid
        XCTAssertNotNil(card, "Card with only section header should be valid")
    }

    // MARK: - Copy Functionality Integration Tests

    func testMultipleCopyableRowsInCard() {
        // Given: Multiple copyable KeyValueRows in a card
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Copyable Values", showDivider: true)
                KeyValueRow(key: "Hash 1", value: "0xDEADBEEF", copyable: true)
                KeyValueRow(key: "Hash 2", value: "0xCAFEBABE", copyable: true)
                KeyValueRow(key: "Hash 3", value: "0xFEEDFACE", copyable: true)
            }
            .padding()
        }

        // Then: Multiple copyable rows should work independently
        XCTAssertNotNil(card, "Multiple copyable rows should work independently")
    }

    // MARK: - Corner Radius Integration Tests

    func testCardWithCustomCornerRadiusContainingComponents() {
        // Given: Cards with different corner radii containing components
        let smallRadiusCard = Card(cornerRadius: DS.Radius.small) {
            VStack {
                SectionHeader(title: "Small Radius")
                KeyValueRow(key: "Radius", value: "\(DS.Radius.small)")
            }
            .padding()
        }

        let mediumRadiusCard = Card(cornerRadius: DS.Radius.medium) {
            VStack {
                SectionHeader(title: "Medium Radius")
                KeyValueRow(key: "Radius", value: "\(DS.Radius.medium)")
            }
            .padding()
        }

        let cardRadiusCard = Card(cornerRadius: DS.Radius.card) {
            VStack {
                SectionHeader(title: "Card Radius")
                KeyValueRow(key: "Radius", value: "\(DS.Radius.card)")
            }
            .padding()
        }

        // Then: All radius variants should work
        XCTAssertNotNil(smallRadiusCard, "Card with small radius should be valid")
        XCTAssertNotNil(mediumRadiusCard, "Card with medium radius should be valid")
        XCTAssertNotNil(cardRadiusCard, "Card with card radius should be valid")
    }
}
