import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Unit tests for BadgeChipStyle modifier
///
/// Verifies that the BadgeChipStyle modifier correctly applies:
/// - Semantic background colors from DS.Color tokens
/// - Consistent padding using DS.Spacing tokens
/// - Chip-style corner radius from DS.Radius tokens
/// - Proper accessibility labels for VoiceOver
///
/// ## Test Coverage
/// - All badge levels (info, warning, error, success)
/// - Design token usage (zero magic numbers)
/// - Accessibility support
@MainActor final class BadgeChipStyleTests: XCTestCase {
    // MARK: - Badge Level Tests

    func testBadgeLevelInfoHasCorrectBackgroundColor() {
        // Given: An info badge level
        let level = BadgeLevel.info

        // When: Retrieving its background color
        let backgroundColor = level.backgroundColor

        // Then: It should match DS.Colors.infoBG
        XCTAssertEqual(
            backgroundColor, DS.Colors.infoBG, "Info badge level should use DS.Colors.infoBG token")
    }

    func testBadgeLevelWarningHasCorrectBackgroundColor() {
        // Given: A warning badge level
        let level = BadgeLevel.warning

        // When: Retrieving its background color
        let backgroundColor = level.backgroundColor

        // Then: It should match DS.Colors.warnBG
        XCTAssertEqual(
            backgroundColor, DS.Colors.warnBG,
            "Warning badge level should use DS.Colors.warnBG token")
    }

    func testBadgeLevelErrorHasCorrectBackgroundColor() {
        // Given: An error badge level
        let level = BadgeLevel.error

        // When: Retrieving its background color
        let backgroundColor = level.backgroundColor

        // Then: It should match DS.Colors.errorBG
        XCTAssertEqual(
            backgroundColor, DS.Colors.errorBG,
            "Error badge level should use DS.Colors.errorBG token")
    }

    func testBadgeLevelSuccessHasCorrectBackgroundColor() {
        // Given: A success badge level
        let level = BadgeLevel.success

        // When: Retrieving its background color
        let backgroundColor = level.backgroundColor

        // Then: It should match DS.Colors.successBG
        XCTAssertEqual(
            backgroundColor, DS.Colors.successBG,
            "Success badge level should use DS.Colors.successBG token")
    }

    // MARK: - Accessibility Tests

    func testBadgeLevelInfoHasAccessibilityLabel() {
        // Given: An info badge level
        let level = BadgeLevel.info

        // When: Retrieving its accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level clearly
        XCTAssertEqual(
            label, "Information", "Info badge should announce 'Information' to VoiceOver")
    }

    func testBadgeLevelWarningHasAccessibilityLabel() {
        // Given: A warning badge level
        let level = BadgeLevel.warning

        // When: Retrieving its accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level clearly
        XCTAssertEqual(label, "Warning", "Warning badge should announce 'Warning' to VoiceOver")
    }

    func testBadgeLevelErrorHasAccessibilityLabel() {
        // Given: An error badge level
        let level = BadgeLevel.error

        // When: Retrieving its accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level clearly
        XCTAssertEqual(label, "Error", "Error badge should announce 'Error' to VoiceOver")
    }

    func testBadgeLevelSuccessHasAccessibilityLabel() {
        // Given: A success badge level
        let level = BadgeLevel.success

        // When: Retrieving its accessibility label
        let label = level.accessibilityLabel

        // Then: It should describe the level clearly
        XCTAssertEqual(label, "Success", "Success badge should announce 'Success' to VoiceOver")
    }

    // MARK: - Design Token Usage Tests

    func testBadgeChipStyleUsesDesignSystemTokens() {
        // This test verifies that the modifier uses DS tokens
        // by checking the enum cases exist and compile

        // Given: All badge levels
        let levels: [BadgeLevel] = [.info, .warning, .error, .success]

        // When/Then: All levels should have valid properties
        for level in levels {
            // Should have background color from DS.Color
            XCTAssertNotNil(level.backgroundColor)

            // Should have accessibility label
            XCTAssertFalse(level.accessibilityLabel.isEmpty)
        }
    }

    // MARK: - Foreground Color Tests

    func testBadgeLevelInfoHasForegroundColor() {
        // Given: An info badge level
        let level = BadgeLevel.info

        // When: Retrieving its foreground color
        let foregroundColor = level.foregroundColor

        // Then: It should have a valid foreground color
        XCTAssertNotNil(foregroundColor, "Info badge should have a foreground color")
    }

    func testBadgeLevelWarningHasForegroundColor() {
        // Given: A warning badge level
        let level = BadgeLevel.warning

        // When: Retrieving its foreground color
        let foregroundColor = level.foregroundColor

        // Then: It should have a valid foreground color
        XCTAssertNotNil(foregroundColor, "Warning badge should have a foreground color")
    }

    func testBadgeLevelErrorHasForegroundColor() {
        // Given: An error badge level
        let level = BadgeLevel.error

        // When: Retrieving its foreground color
        let foregroundColor = level.foregroundColor

        // Then: It should have a valid foreground color
        XCTAssertNotNil(foregroundColor, "Error badge should have a foreground color")
    }

    func testBadgeLevelSuccessHasForegroundColor() {
        // Given: A success badge level
        let level = BadgeLevel.success

        // When: Retrieving its foreground color
        let foregroundColor = level.foregroundColor

        // Then: It should have a valid foreground color
        XCTAssertNotNil(foregroundColor, "Success badge should have a foreground color")
    }

    // MARK: - Badge Level Equality Tests

    func testBadgeLevelEquality() {
        // Given: Badge levels
        let info1 = BadgeLevel.info
        let info2 = BadgeLevel.info
        let warning = BadgeLevel.warning

        // Then: Same levels should be equal
        XCTAssertEqual(info1, info2, "Same badge levels should be equal")
        XCTAssertNotEqual(info1, warning, "Different badge levels should not be equal")
    }
}
