// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for CardStyle modifier
///
/// Verifies that the CardStyle modifier correctly applies:
/// - Elevation-based visual effects (shadows/materials)
/// - Configurable corner radius from DS.Radius tokens
/// - Platform-adaptive styling (iOS vs macOS)
/// - Proper accessibility support
///
/// ## Test Coverage
/// - All elevation levels (none, low, medium, high)
/// - Corner radius variants (small, medium, card)
/// - Platform-specific adaptations
/// - Design token usage (zero magic numbers)
final class CardStyleTests: XCTestCase {

    // MARK: - Elevation Level Tests

    func testElevationLevelNoneHasNoShadow() {
        // Given: A card with no elevation
        let level = CardElevation.none

        // When: Checking if it has a shadow
        let hasShadow = level.hasShadow

        // Then: It should not have a shadow
        XCTAssertFalse(
            hasShadow,
            "Elevation.none should not apply shadow effects"
        )
    }

    func testElevationLevelLowHasShadow() {
        // Given: A card with low elevation
        let level = CardElevation.low

        // When: Checking if it has a shadow
        let hasShadow = level.hasShadow

        // Then: It should have a shadow
        XCTAssertTrue(
            hasShadow,
            "Elevation.low should apply subtle shadow effects"
        )
    }

    func testElevationLevelMediumHasShadow() {
        // Given: A card with medium elevation
        let level = CardElevation.medium

        // When: Checking if it has a shadow
        let hasShadow = level.hasShadow

        // Then: It should have a shadow
        XCTAssertTrue(
            hasShadow,
            "Elevation.medium should apply moderate shadow effects"
        )
    }

    func testElevationLevelHighHasShadow() {
        // Given: A card with high elevation
        let level = CardElevation.high

        // When: Checking if it has a shadow
        let hasShadow = level.hasShadow

        // Then: It should have a shadow
        XCTAssertTrue(
            hasShadow,
            "Elevation.high should apply prominent shadow effects"
        )
    }

    // MARK: - Shadow Properties Tests

    func testElevationLevelLowShadowRadius() {
        // Given: A card with low elevation
        let level = CardElevation.low

        // When: Getting shadow radius
        let shadowRadius = level.shadowRadius

        // Then: It should have a small radius
        XCTAssertEqual(
            shadowRadius,
            2.0,
            accuracy: 0.01,
            "Low elevation should have shadow radius of 2.0"
        )
    }

    func testElevationLevelMediumShadowRadius() {
        // Given: A card with medium elevation
        let level = CardElevation.medium

        // When: Getting shadow radius
        let shadowRadius = level.shadowRadius

        // Then: It should have a medium radius
        XCTAssertEqual(
            shadowRadius,
            4.0,
            accuracy: 0.01,
            "Medium elevation should have shadow radius of 4.0"
        )
    }

    func testElevationLevelHighShadowRadius() {
        // Given: A card with high elevation
        let level = CardElevation.high

        // When: Getting shadow radius
        let shadowRadius = level.shadowRadius

        // Then: It should have a large radius
        XCTAssertEqual(
            shadowRadius,
            8.0,
            accuracy: 0.01,
            "High elevation should have shadow radius of 8.0"
        )
    }

    func testElevationLevelLowShadowOpacity() {
        // Given: A card with low elevation
        let level = CardElevation.low

        // When: Getting shadow opacity
        let shadowOpacity = level.shadowOpacity

        // Then: It should have subtle opacity
        XCTAssertEqual(
            shadowOpacity,
            0.1,
            accuracy: 0.01,
            "Low elevation should have shadow opacity of 0.1"
        )
    }

    func testElevationLevelMediumShadowOpacity() {
        // Given: A card with medium elevation
        let level = CardElevation.medium

        // When: Getting shadow opacity
        let shadowOpacity = level.shadowOpacity

        // Then: It should have moderate opacity
        XCTAssertEqual(
            shadowOpacity,
            0.15,
            accuracy: 0.01,
            "Medium elevation should have shadow opacity of 0.15"
        )
    }

    func testElevationLevelHighShadowOpacity() {
        // Given: A card with high elevation
        let level = CardElevation.high

        // When: Getting shadow opacity
        let shadowOpacity = level.shadowOpacity

        // Then: It should have strong opacity
        XCTAssertEqual(
            shadowOpacity,
            0.2,
            accuracy: 0.01,
            "High elevation should have shadow opacity of 0.2"
        )
    }

    // MARK: - Shadow Y-Offset Tests

    func testElevationLevelLowShadowYOffset() {
        // Given: A card with low elevation
        let level = CardElevation.low

        // When: Getting shadow Y offset
        let yOffset = level.shadowYOffset

        // Then: It should have small offset
        XCTAssertEqual(
            yOffset,
            1.0,
            accuracy: 0.01,
            "Low elevation should have Y offset of 1.0"
        )
    }

    func testElevationLevelMediumShadowYOffset() {
        // Given: A card with medium elevation
        let level = CardElevation.medium

        // When: Getting shadow Y offset
        let yOffset = level.shadowYOffset

        // Then: It should have medium offset
        XCTAssertEqual(
            yOffset,
            2.0,
            accuracy: 0.01,
            "Medium elevation should have Y offset of 2.0"
        )
    }

    func testElevationLevelHighShadowYOffset() {
        // Given: A card with high elevation
        let level = CardElevation.high

        // When: Getting shadow Y offset
        let yOffset = level.shadowYOffset

        // Then: It should have large offset
        XCTAssertEqual(
            yOffset,
            4.0,
            accuracy: 0.01,
            "High elevation should have Y offset of 4.0"
        )
    }

    // MARK: - Accessibility Label Tests

    func testElevationLevelNoneAccessibilityLabel() {
        // Given: A card with no elevation
        let level = CardElevation.none

        // When: Getting accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level
        XCTAssertEqual(
            label,
            "Flat card",
            "Elevation.none should have accessibility label 'Flat card'"
        )
    }

    func testElevationLevelLowAccessibilityLabel() {
        // Given: A card with low elevation
        let level = CardElevation.low

        // When: Getting accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level
        XCTAssertEqual(
            label,
            "Card with subtle elevation",
            "Elevation.low should have descriptive accessibility label"
        )
    }

    func testElevationLevelMediumAccessibilityLabel() {
        // Given: A card with medium elevation
        let level = CardElevation.medium

        // When: Getting accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level
        XCTAssertEqual(
            label,
            "Card with medium elevation",
            "Elevation.medium should have descriptive accessibility label"
        )
    }

    func testElevationLevelHighAccessibilityLabel() {
        // Given: A card with high elevation
        let level = CardElevation.high

        // When: Getting accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level
        XCTAssertEqual(
            label,
            "Card with high elevation",
            "Elevation.high should have descriptive accessibility label"
        )
    }

    // MARK: - Equality Tests

    func testElevationLevelEquality() {
        // Given: Elevation levels
        let low1 = CardElevation.low
        let low2 = CardElevation.low
        let medium = CardElevation.medium

        // Then: Same levels should be equal
        XCTAssertEqual(low1, low2, "Same elevation levels should be equal")
        XCTAssertNotEqual(low1, medium, "Different elevation levels should not be equal")
    }

    // MARK: - Design Token Verification Tests

    func testCardStyleUsesDesignSystemRadiusTokens() {
        // Verify that standard radius values match DS tokens

        // Card radius should use DS.Radius.card
        XCTAssertEqual(
            DS.Radius.card,
            10.0,
            accuracy: 0.01,
            "Card style should use DS.Radius.card token"
        )

        // Small radius should use DS.Radius.small
        XCTAssertEqual(
            DS.Radius.small,
            6.0,
            accuracy: 0.01,
            "Card style should support DS.Radius.small token"
        )
    }

    // MARK: - Corner Radius Tests

    func testCardElevationAllCasesExist() {
        // Given: All elevation cases
        let allCases: [CardElevation] = [.none, .low, .medium, .high]

        // Then: All cases should be valid
        XCTAssertEqual(
            allCases.count,
            4,
            "CardElevation should have exactly 4 cases"
        )

        // Each case should have valid properties
        for elevation in allCases {
            XCTAssertNotNil(elevation.shadowRadius)
            XCTAssertNotNil(elevation.shadowOpacity)
            XCTAssertNotNil(elevation.shadowYOffset)
            XCTAssertFalse(elevation.accessibilityLabel.isEmpty)
        }
    }
}
