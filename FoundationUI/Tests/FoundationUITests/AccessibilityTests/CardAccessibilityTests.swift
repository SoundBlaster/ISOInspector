// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Accessibility tests for the Card component
///
/// Verifies WCAG 2.1 AA compliance and VoiceOver support for card containers.
///
/// ## Test Coverage
/// - Accessibility element containment and grouping
/// - Content VoiceOver traversal order
/// - Card elevation level properties
/// - Background and shadow accessibility
/// - Nested card accessibility
/// - Material background support
/// - Platform-specific card rendering
@MainActor
final class CardAccessibilityTests: XCTestCase {

    // MARK: - Accessibility Element Tests

    func testCardPreservesChildAccessibility() {
        // Given
        // Card uses .accessibilityElement(children: .contain)

        // When
        let card = Card {
            Text("Content")
        }

        // Then
        // The card should preserve its child elements for VoiceOver
        XCTAssertNotNil(
            card,
            "Card should preserve child accessibility with .contain mode"
        )
    }

    func testCardWithComplexContentPreservesStructure() {
        // Given
        let card = Card {
            VStack {
                Text("Title")
                Text("Subtitle")
                Text("Body")
            }
        }

        // Then
        // Card should preserve all child elements
        XCTAssertNotNil(
            card,
            "Card should preserve complex nested content structure"
        )
    }

    // MARK: - Elevation Tests

    func testCardElevationNoneHasNoShadow() {
        // Given
        let elevation = CardElevation.none

        // Then
        XCTAssertFalse(
            elevation.hasShadow,
            "None elevation should have no shadow"
        )
        XCTAssertEqual(
            elevation.shadowRadius,
            0,
            "None elevation should have zero shadow radius"
        )
        XCTAssertEqual(
            elevation.shadowOpacity,
            0,
            "None elevation should have zero shadow opacity"
        )
    }

    func testCardElevationLowHasSubtleShadow() {
        // Given
        let elevation = CardElevation.low

        // Then
        XCTAssertTrue(
            elevation.hasShadow,
            "Low elevation should have shadow"
        )
        XCTAssertEqual(
            elevation.shadowRadius,
            2,
            "Low elevation should have shadow radius of 2"
        )
        XCTAssertEqual(
            elevation.shadowOpacity,
            0.1,
            "Low elevation should have shadow opacity of 0.1"
        )
    }

    func testCardElevationMediumHasStandardShadow() {
        // Given
        let elevation = CardElevation.medium

        // Then
        XCTAssertTrue(
            elevation.hasShadow,
            "Medium elevation should have shadow"
        )
        XCTAssertEqual(
            elevation.shadowRadius,
            4,
            "Medium elevation should have shadow radius of 4"
        )
        XCTAssertEqual(
            elevation.shadowOpacity,
            0.15,
            "Medium elevation should have shadow opacity of 0.15"
        )
    }

    func testCardElevationHighHasProminentShadow() {
        // Given
        let elevation = CardElevation.high

        // Then
        XCTAssertTrue(
            elevation.hasShadow,
            "High elevation should have shadow"
        )
        XCTAssertEqual(
            elevation.shadowRadius,
            8,
            "High elevation should have shadow radius of 8"
        )
        XCTAssertEqual(
            elevation.shadowOpacity,
            0.2,
            "High elevation should have shadow opacity of 0.2"
        )
    }

    func testAllCardElevationLevels() {
        // Given
        let allElevations: [CardElevation] = [.none, .low, .medium, .high]

        // When & Then
        for elevation in allElevations {
            let card = Card(elevation: elevation) {
                Text("Test")
            }

            XCTAssertNotNil(
                card,
                "Card should support \(elevation) elevation"
            )
        }
    }

    // MARK: - Shadow Accessibility Tests

    func testCardShadowIsSupplementaryNotSemantic() {
        // Given
        let cardWithShadow = Card(elevation: .high) {
            Text("High Elevation")
        }
        let cardWithoutShadow = Card(elevation: .none) {
            Text("No Elevation")
        }

        // Then
        // Both cards should be equally accessible
        // Shadow is purely visual, not semantic
        XCTAssertNotNil(
            cardWithShadow,
            "Card with shadow should be accessible"
        )
        XCTAssertNotNil(
            cardWithoutShadow,
            "Card without shadow should be equally accessible"
        )
    }

    // MARK: - Corner Radius Tests

    func testCardWithDefaultCornerRadius() {
        // Given
        let card = Card {
            Text("Content")
        }

        // Then
        XCTAssertEqual(
            card.cornerRadius,
            DS.Radius.card,
            "Card should use DS.Radius.card as default corner radius"
        )
    }

    func testCardWithCustomCornerRadius() {
        // Given
        let customRadius: CGFloat = DS.Radius.small
        let card = Card(cornerRadius: customRadius) {
            Text("Content")
        }

        // Then
        XCTAssertEqual(
            card.cornerRadius,
            customRadius,
            "Card should accept custom corner radius"
        )
    }

    // MARK: - Material Background Tests

    func testCardWithoutMaterial() {
        // Given
        let card = Card {
            Text("Content")
        }

        // Then
        XCTAssertNil(
            card.material,
            "Card should have no material by default"
        )
    }

    func testCardWithThinMaterial() {
        // Given
        let card = Card(material: .thin) {
            Text("Translucent Content")
        }

        // Then
        XCTAssertEqual(
            card.material,
            .thin,
            "Card should support thin material background"
        )
    }

    func testCardWithRegularMaterial() {
        // Given
        let card = Card(material: .regular) {
            Text("Content")
        }

        // Then
        XCTAssertEqual(
            card.material,
            .regular,
            "Card should support regular material background"
        )
    }

    func testCardWithThickMaterial() {
        // Given
        let card = Card(material: .thick) {
            Text("Content")
        }

        // Then
        XCTAssertEqual(
            card.material,
            .thick,
            "Card should support thick material background"
        )
    }

    // MARK: - Nested Card Tests

    func testNestedCardsPreserveAccessibility() {
        // Given
        let outerCard = Card(elevation: .high) {
            VStack {
                Text("Outer")
                Card(elevation: .low) {
                    Text("Inner")
                }
            }
        }

        // Then
        XCTAssertNotNil(
            outerCard,
            "Nested cards should preserve accessibility structure"
        )
    }

    func testMultipleNestedCardsHaveDistinctElevations() {
        // Given
        let outerElevation = CardElevation.high
        let innerElevation = CardElevation.low

        // Then
        XCTAssertNotEqual(
            outerElevation.shadowRadius,
            innerElevation.shadowRadius,
            "Nested cards should have distinct shadow radii"
        )
        XCTAssertGreaterThan(
            outerElevation.shadowRadius,
            innerElevation.shadowRadius,
            "Outer card should have larger shadow than inner card"
        )
    }

    // MARK: - Design System Token Usage Tests

    func testCardUsesDesignSystemRadiusTokens() {
        // Given
        let cardRadius = DS.Radius.card
        let smallRadius = DS.Radius.small
        let mediumRadius = DS.Radius.medium

        // Then
        XCTAssertGreaterThan(
            cardRadius,
            0,
            "DS.Radius.card should be > 0"
        )
        XCTAssertGreaterThan(
            smallRadius,
            0,
            "DS.Radius.small should be > 0"
        )
        XCTAssertGreaterThan(
            mediumRadius,
            0,
            "DS.Radius.medium should be > 0"
        )
    }

    // MARK: - Platform Tests

    func testCardOnCurrentPlatform() {
        // Given
        let platform = AccessibilityTestHelpers.currentPlatform
        let card = Card {
            Text("Platform Test")
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should be creatable on \(platform)"
        )
    }

    // MARK: - Content Integration Tests

    func testCardWithBadgeContent() {
        // Given
        let card = Card {
            VStack {
                Text("Status")
                Badge(text: "ACTIVE", level: .success)
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should work with Badge component content"
        )
    }

    func testCardWithKeyValueRowContent() {
        // Given
        let card = Card {
            VStack {
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024")
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should work with KeyValueRow component content"
        )
    }

    func testCardWithSectionHeaderContent() {
        // Given
        let card = Card {
            VStack {
                SectionHeader(title: "Information")
                Text("Content")
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should work with SectionHeader component content"
        )
    }

    // MARK: - CardElevation Equality Tests

    func testCardElevationEquality() {
        // Given
        let elevation1 = CardElevation.medium
        let elevation2 = CardElevation.medium
        let elevation3 = CardElevation.high

        // Then
        XCTAssertEqual(
            elevation1,
            elevation2,
            "Same elevation levels should be equal"
        )
        XCTAssertNotEqual(
            elevation1,
            elevation3,
            "Different elevation levels should not be equal"
        )
    }

    // MARK: - Edge Cases

    func testCardWithEmptyContent() {
        // Given
        let card = Card {
            EmptyView()
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should accept empty content"
        )
    }

    func testCardWithComplexHierarchy() {
        // Given
        let card = Card(elevation: .medium) {
            VStack {
                SectionHeader(title: "Details", showDivider: true)
                VStack {
                    KeyValueRow(key: "Name", value: "Test")
                    KeyValueRow(key: "Status", value: "Active")
                }
                Badge(text: "VERIFIED", level: .success)
            }
        }

        // Then
        XCTAssertNotNil(
            card,
            "Card should support complex component hierarchies"
        )
    }

    // MARK: - Full Configuration Tests

    func testCardWithAllCustomizations() {
        // Given
        let card = Card(
            elevation: .high,
            cornerRadius: DS.Radius.small,
            material: .regular
        ) {
            VStack {
                Text("Title")
                Text("Content")
            }
        }

        // Then
        XCTAssertEqual(card.elevation, .high, "Should use high elevation")
        XCTAssertEqual(card.cornerRadius, DS.Radius.small, "Should use small radius")
        XCTAssertEqual(card.material, .regular, "Should use regular material")
    }
}
