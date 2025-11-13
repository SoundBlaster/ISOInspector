#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import FoundationUI

/// Comprehensive test suite for the Card component
///
/// Tests cover:
/// - Component initialization with various parameters
/// - Elevation levels (none, low, medium, high)
/// - Corner radius variations
/// - Material backgrounds
/// - Shadow properties
/// - Accessibility features
/// - Platform compatibility
/// - Nested card scenarios
///
/// **Phase:** I0.2 - Create Integration Test Suite
/// **Coverage Target:** ≥80% for Card component
final class CardComponentTests: XCTestCase {

    // MARK: - Initialization Tests

    /// Verifies that Card can be initialized with default parameters
    func testCardInitializationWithDefaults() {
        let card = Card {
            Text("Test Content")
        }

        XCTAssertEqual(card.elevation, .medium)
        XCTAssertEqual(card.cornerRadius, DS.Radius.card)
        XCTAssertNil(card.material)
    }

    /// Verifies that Card can be initialized with custom elevation
    func testCardInitializationWithCustomElevation() {
        let card = Card(elevation: .high) {
            Text("Test Content")
        }

        XCTAssertEqual(card.elevation, .high)
    }

    /// Verifies that Card can be initialized with custom corner radius
    func testCardInitializationWithCustomCornerRadius() {
        let card = Card(cornerRadius: DS.Radius.small) {
            Text("Test Content")
        }

        XCTAssertEqual(card.cornerRadius, DS.Radius.small)
    }

    /// Verifies that Card can be initialized with material background
    func testCardInitializationWithMaterial() {
        let card = Card(material: .regular) {
            Text("Test Content")
        }

        XCTAssertNotNil(card.material)
    }

    /// Verifies that Card can be initialized with all custom parameters
    func testCardInitializationWithAllParameters() {
        let card = Card(
            elevation: .low,
            cornerRadius: DS.Radius.medium,
            material: .thin
        ) {
            Text("Test Content")
        }

        XCTAssertEqual(card.elevation, .low)
        XCTAssertEqual(card.cornerRadius, DS.Radius.medium)
        XCTAssertNotNil(card.material)
    }

    // MARK: - Elevation Level Tests

    /// Verifies that all CardElevation cases are available
    func testCardElevationAllCasesAvailable() {
        let elevations = CardElevation.allCases

        XCTAssertEqual(elevations.count, 4, "Card should have exactly 4 elevation levels")
        XCTAssertTrue(elevations.contains(.none))
        XCTAssertTrue(elevations.contains(.low))
        XCTAssertTrue(elevations.contains(.medium))
        XCTAssertTrue(elevations.contains(.high))
    }

    /// Verifies Card with no elevation
    func testCardWithNoElevation() {
        let card = Card(elevation: .none) {
            Text("No Elevation")
        }

        XCTAssertEqual(card.elevation, .none)
        XCTAssertFalse(card.elevation.hasShadow)
    }

    /// Verifies Card with low elevation
    func testCardWithLowElevation() {
        let card = Card(elevation: .low) {
            Text("Low Elevation")
        }

        XCTAssertEqual(card.elevation, .low)
        XCTAssertTrue(card.elevation.hasShadow)
    }

    /// Verifies Card with medium elevation
    func testCardWithMediumElevation() {
        let card = Card(elevation: .medium) {
            Text("Medium Elevation")
        }

        XCTAssertEqual(card.elevation, .medium)
        XCTAssertTrue(card.elevation.hasShadow)
    }

    /// Verifies Card with high elevation
    func testCardWithHighElevation() {
        let card = Card(elevation: .high) {
            Text("High Elevation")
        }

        XCTAssertEqual(card.elevation, .high)
        XCTAssertTrue(card.elevation.hasShadow)
    }

    // MARK: - CardElevation Properties Tests

    /// Verifies that elevation levels have correct shadow properties
    func testCardElevationShadowProperties() {
        // None elevation should not have shadow
        XCTAssertFalse(CardElevation.none.hasShadow)
        XCTAssertEqual(CardElevation.none.shadowRadius, 0)
        XCTAssertEqual(CardElevation.none.shadowYOffset, 0)
        XCTAssertEqual(CardElevation.none.shadowOpacity, 0)

        // Other elevations should have shadows
        XCTAssertTrue(CardElevation.low.hasShadow)
        XCTAssertGreaterThan(CardElevation.low.shadowRadius, 0)

        XCTAssertTrue(CardElevation.medium.hasShadow)
        XCTAssertGreaterThan(CardElevation.medium.shadowRadius, 0)

        XCTAssertTrue(CardElevation.high.hasShadow)
        XCTAssertGreaterThan(CardElevation.high.shadowRadius, 0)
    }

    /// Verifies that elevation levels have increasing shadow intensity
    func testCardElevationShadowIntensity() {
        // Shadow radius should increase with elevation
        XCTAssertLessThan(CardElevation.low.shadowRadius, CardElevation.medium.shadowRadius)
        XCTAssertLessThan(CardElevation.medium.shadowRadius, CardElevation.high.shadowRadius)

        // Shadow Y offset should increase with elevation
        XCTAssertLessThan(CardElevation.low.shadowYOffset, CardElevation.medium.shadowYOffset)
        XCTAssertLessThan(CardElevation.medium.shadowYOffset, CardElevation.high.shadowYOffset)
    }

    /// Verifies that each CardElevation has a string value
    func testCardElevationStringValues() {
        XCTAssertEqual(CardElevation.none.stringValue, "none")
        XCTAssertEqual(CardElevation.low.stringValue, "low")
        XCTAssertEqual(CardElevation.medium.stringValue, "medium")
        XCTAssertEqual(CardElevation.high.stringValue, "high")
    }

    // MARK: - Corner Radius Tests

    /// Verifies Card with small corner radius
    func testCardWithSmallCornerRadius() {
        let card = Card(cornerRadius: DS.Radius.small) {
            Text("Small Radius")
        }

        XCTAssertEqual(card.cornerRadius, DS.Radius.small)
    }

    /// Verifies Card with medium corner radius
    func testCardWithMediumCornerRadius() {
        let card = Card(cornerRadius: DS.Radius.medium) {
            Text("Medium Radius")
        }

        XCTAssertEqual(card.cornerRadius, DS.Radius.medium)
    }

    /// Verifies Card with card corner radius (default)
    func testCardWithCardCornerRadius() {
        let card = Card(cornerRadius: DS.Radius.card) {
            Text("Card Radius")
        }

        XCTAssertEqual(card.cornerRadius, DS.Radius.card)
    }

    /// Verifies that design token radii have expected values
    func testDesignTokenRadii() {
        XCTAssertEqual(DS.Radius.small, 6)
        XCTAssertEqual(DS.Radius.medium, 8)
        XCTAssertEqual(DS.Radius.card, 10)
    }

    // MARK: - Material Background Tests

    /// Verifies Card without material background
    func testCardWithoutMaterial() {
        let card = Card {
            Text("No Material")
        }

        XCTAssertNil(card.material)
    }

    /// Verifies Card with ultraThin material
    func testCardWithUltraThinMaterial() {
        let card = Card(material: .ultraThin) {
            Text("Ultra Thin Material")
        }

        XCTAssertNotNil(card.material)
    }

    /// Verifies Card with thin material
    func testCardWithThinMaterial() {
        let card = Card(material: .thin) {
            Text("Thin Material")
        }

        XCTAssertNotNil(card.material)
    }

    /// Verifies Card with regular material
    func testCardWithRegularMaterial() {
        let card = Card(material: .regular) {
            Text("Regular Material")
        }

        XCTAssertNotNil(card.material)
    }

    /// Verifies Card with thick material
    func testCardWithThickMaterial() {
        let card = Card(material: .thick) {
            Text("Thick Material")
        }

        XCTAssertNotNil(card.material)
    }

    // MARK: - View Rendering Tests

    /// Verifies that Card body is not nil
    func testCardBodyNotNil() {
        let card = Card {
            Text("Test")
        }

        XCTAssertNotNil(card.body)
    }

    /// Verifies that Card body renders for all elevation levels
    func testCardBodyRendersForAllElevations() {
        for elevation in CardElevation.allCases {
            let card = Card(elevation: elevation) {
                Text("Test")
            }
            XCTAssertNotNil(card.body, "Card body should render for elevation: \(elevation)")
        }
    }

    /// Verifies that Card body renders with all material types
    func testCardBodyRendersForAllMaterials() {
        let materials: [Material] = [.ultraThin, .thin, .regular, .thick]

        for material in materials {
            let card = Card(material: material) {
                Text("Test")
            }
            XCTAssertNotNil(card.body, "Card body should render with material")
        }
    }

    // MARK: - Content Tests

    /// Verifies Card with simple text content
    func testCardWithSimpleTextContent() {
        let card = Card {
            Text("Simple Text")
        }

        XCTAssertNotNil(card.body)
    }

    /// Verifies Card with VStack content
    func testCardWithVStackContent() {
        let card = Card {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }

        XCTAssertNotNil(card.body)
    }

    /// Verifies Card with HStack content
    func testCardWithHStackContent() {
        let card = Card {
            HStack {
                Text("Left")
                Text("Right")
            }
        }

        XCTAssertNotNil(card.body)
    }

    /// Verifies Card with complex nested content
    func testCardWithComplexContent() {
        let card = Card {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Divider()
                Text("Content")
                    .font(.body)
            }
        }

        XCTAssertNotNil(card.body)
    }

    // MARK: - Platform Compatibility Tests

    /// Verifies Card works on current platform
    func testCardPlatformCompatibility() {
        #if os(iOS)
        let card = Card {
            Text("iOS Card")
        }
        XCTAssertNotNil(card.body, "Card should work on iOS")
        #elseif os(macOS)
        let card = Card {
            Text("macOS Card")
        }
        XCTAssertNotNil(card.body, "Card should work on macOS")
        #else
        XCTFail("Unsupported platform")
        #endif
    }

    // MARK: - AgentDescribable Tests (iOS 17+/macOS 14+)

    @available(iOS 17.0, macOS 14.0, *)
    func testCardAgentDescribableComponentType() {
        let card = Card {
            Text("Test")
        }

        XCTAssertEqual(card.componentType, "Card")
    }

    @available(iOS 17.0, macOS 14.0, *)
    func testCardAgentDescribableProperties() {
        let card = Card(elevation: .high, cornerRadius: DS.Radius.card) {
            Text("Test")
        }
        let properties = card.properties

        XCTAssertEqual(properties["elevation"] as? String, "high")
        XCTAssertEqual(properties["cornerRadius"] as? CGFloat, DS.Radius.card)
    }

    @available(iOS 17.0, macOS 14.0, *)
    func testCardAgentDescribablePropertiesWithMaterial() {
        let card = Card(elevation: .medium, material: .regular) {
            Text("Test")
        }
        let properties = card.properties

        XCTAssertNotNil(properties["material"])
        XCTAssertEqual(properties["elevation"] as? String, "medium")
    }

    @available(iOS 17.0, macOS 14.0, *)
    func testCardAgentDescribableSemantics() {
        let card = Card(elevation: .high, cornerRadius: 10) {
            Text("Test")
        }
        let semantics = card.semantics

        XCTAssertTrue(semantics.contains("high"))
        XCTAssertTrue(semantics.contains("10"))
    }

    // MARK: - Nested Card Tests

    /// Verifies that Cards can be nested
    func testNestedCards() {
        let outerCard = Card(elevation: .high) {
            VStack {
                Text("Outer Card")
                Card(elevation: .low) {
                    Text("Inner Card")
                }
            }
        }

        XCTAssertNotNil(outerCard.body)
    }

    /// Verifies nested cards with different elevations
    func testNestedCardsWithDifferentElevations() {
        let card = Card(elevation: .high) {
            VStack {
                Card(elevation: .medium) {
                    Text("Medium")
                }
                Card(elevation: .low) {
                    Text("Low")
                }
            }
        }

        XCTAssertNotNil(card.body)
    }

    // MARK: - Real-World Usage Tests

    /// Verifies Card usage in feature display
    func testCardAsFeatureDisplay() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading) {
                Text("Feature Card")
                    .font(.headline)
                Text("Description")
                    .font(.body)
            }
        }

        XCTAssertEqual(card.elevation, .medium)
        XCTAssertNotNil(card.body)
    }

    /// Verifies Card usage with badge integration
    func testCardWithBadgeIntegration() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Status Card")
                    Badge(text: "ACTIVE", level: .success)
                }
            }
        }

        XCTAssertNotNil(card.body)
    }

    /// Verifies Card usage as container for metadata
    func testCardAsMetadataContainer() {
        let card = Card(elevation: .low) {
            VStack(alignment: .leading) {
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024")
            }
        }

        XCTAssertNotNil(card.body)
    }

    // MARK: - CardElevation Equatable Tests

    /// Verifies that CardElevation conforms to Equatable
    func testCardElevationEquatable() {
        XCTAssertEqual(CardElevation.none, CardElevation.none)
        XCTAssertEqual(CardElevation.low, CardElevation.low)
        XCTAssertEqual(CardElevation.medium, CardElevation.medium)
        XCTAssertEqual(CardElevation.high, CardElevation.high)

        XCTAssertNotEqual(CardElevation.none, CardElevation.low)
        XCTAssertNotEqual(CardElevation.medium, CardElevation.high)
    }

    // MARK: - Edge Case Tests

    /// Verifies Card with zero corner radius
    func testCardWithZeroCornerRadius() {
        let card = Card(cornerRadius: 0) {
            Text("No Rounding")
        }

        XCTAssertEqual(card.cornerRadius, 0)
        XCTAssertNotNil(card.body)
    }

    /// Verifies Card with large corner radius
    func testCardWithLargeCornerRadius() {
        let card = Card(cornerRadius: 50) {
            Text("Very Rounded")
        }

        XCTAssertEqual(card.cornerRadius, 50)
        XCTAssertNotNil(card.body)
    }

    /// Verifies Card with both material and elevation
    func testCardWithMaterialAndElevation() {
        let card = Card(elevation: .high, material: .regular) {
            Text("Material + Elevation")
        }

        XCTAssertEqual(card.elevation, .high)
        XCTAssertNotNil(card.material)
        XCTAssertNotNil(card.body)
    }
}

// MARK: - Test Documentation

/*
 ## Card Component Test Coverage for I0.2

 This comprehensive test suite covers:

 ### Initialization & Parameters (5 tests)
 - Default initialization
 - Custom elevation
 - Custom corner radius
 - Material background
 - All parameters combined

 ### Elevation Levels (9 tests)
 - All four elevation cases (none, low, medium, high)
 - Shadow properties for each level
 - Shadow intensity progression
 - String values for serialization
 - Has shadow flag verification
 - Equatable conformance

 ### Corner Radius (4 tests)
 - Small, medium, and card radius tokens
 - Design token value verification
 - Zero and large radius edge cases

 ### Material Backgrounds (6 tests)
 - No material
 - UltraThin, thin, regular, and thick materials
 - Material with elevation combination

 ### View Rendering (4 tests)
 - Body rendering for all elevations
 - Body rendering with all materials
 - Non-nil body verification

 ### Content Types (4 tests)
 - Simple text content
 - VStack and HStack layouts
 - Complex nested content

 ### Platform Compatibility (1 test)
 - iOS and macOS support

 ### AgentDescribable Protocol (4 tests, iOS 17+/macOS 14+)
 - Component type identification
 - Properties serialization
 - Material properties handling
 - Semantic description generation

 ### Nested Cards (2 tests)
 - Basic nesting
 - Multiple nested cards with different elevations

 ### Real-World Usage (3 tests)
 - Feature display cards
 - Badge integration
 - Metadata container

 **Total Tests:** 42
 **Coverage Target:** ≥80% of Card component code paths
 **Phase:** I0.2 - Create Integration Test Suite

 ## Related Files
 - FoundationUI/Sources/FoundationUI/Components/Card.swift
 - FoundationUI/Sources/FoundationUI/Modifiers/CardStyle.swift
 - DOCS/INPROGRESS/212_I0_2_Create_Integration_Test_Suite.md
 */
#endif
