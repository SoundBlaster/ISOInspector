// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for the Badge component
///
/// Tests verify:
/// - Component initialization with all badge levels
/// - Proper text rendering
/// - Accessibility support (VoiceOver labels)
/// - Design system token usage
/// - Platform compatibility
final class BadgeTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBadgeInitializationWithInfoLevel() {
        // Given
        let text = "INFO"
        let level = BadgeLevel.info

        // When
        let badge = Badge(text: text, level: level)

        // Then
        XCTAssertEqual(badge.text, text, "Badge text should match initialization value")
        XCTAssertEqual(badge.level, level, "Badge level should match initialization value")
    }

    func testBadgeInitializationWithWarningLevel() {
        // Given
        let text = "WARNING"
        let level = BadgeLevel.warning

        // When
        let badge = Badge(text: text, level: level)

        // Then
        XCTAssertEqual(badge.text, text, "Badge text should match initialization value")
        XCTAssertEqual(badge.level, level, "Badge level should match initialization value")
    }

    func testBadgeInitializationWithErrorLevel() {
        // Given
        let text = "ERROR"
        let level = BadgeLevel.error

        // When
        let badge = Badge(text: text, level: level)

        // Then
        XCTAssertEqual(badge.text, text, "Badge text should match initialization value")
        XCTAssertEqual(badge.level, level, "Badge level should match initialization value")
    }

    func testBadgeInitializationWithSuccessLevel() {
        // Given
        let text = "SUCCESS"
        let level = BadgeLevel.success

        // When
        let badge = Badge(text: text, level: level)

        // Then
        XCTAssertEqual(badge.text, text, "Badge text should match initialization value")
        XCTAssertEqual(badge.level, level, "Badge level should match initialization value")
    }

    // MARK: - Badge Level Tests

    func testBadgeSupportsAllBadgeLevels() {
        // Given
        let levels: [BadgeLevel] = [.info, .warning, .error, .success]

        // When & Then
        for level in levels {
            let badge = Badge(text: "Test", level: level)
            XCTAssertEqual(badge.level, level, "Badge should support \(level) level")
        }
    }

    // MARK: - Text Content Tests

    func testBadgeTextContent() {
        // Given
        let testCases = [
            ("INFO", BadgeLevel.info),
            ("WARNING", BadgeLevel.warning),
            ("ERROR", BadgeLevel.error),
            ("SUCCESS", BadgeLevel.success),
            ("Custom Text", BadgeLevel.info),
            ("", BadgeLevel.warning) // Edge case: empty text
        ]

        // When & Then
        for (text, level) in testCases {
            let badge = Badge(text: text, level: level)
            XCTAssertEqual(badge.text, text, "Badge should preserve text content: '\(text)'")
        }
    }

    // MARK: - Accessibility Tests

    func testBadgeAccessibilityLabelForInfo() {
        // Given
        let badge = Badge(text: "New", level: .info)

        // Then
        // The accessibility label should combine the level semantic meaning with the text
        // Expected format: "Information: New" or similar
        XCTAssertNotNil(badge.level.accessibilityLabel, "Badge should have accessibility label")
        XCTAssertEqual(badge.level.accessibilityLabel, "Information", "Info level should have 'Information' accessibility label")
    }

    func testBadgeAccessibilityLabelForWarning() {
        // Given
        let badge = Badge(text: "Caution", level: .warning)

        // Then
        XCTAssertEqual(badge.level.accessibilityLabel, "Warning", "Warning level should have 'Warning' accessibility label")
    }

    func testBadgeAccessibilityLabelForError() {
        // Given
        let badge = Badge(text: "Failed", level: .error)

        // Then
        XCTAssertEqual(badge.level.accessibilityLabel, "Error", "Error level should have 'Error' accessibility label")
    }

    func testBadgeAccessibilityLabelForSuccess() {
        // Given
        let badge = Badge(text: "Complete", level: .success)

        // Then
        XCTAssertEqual(badge.level.accessibilityLabel, "Success", "Success level should have 'Success' accessibility label")
    }

    // MARK: - Design System Integration Tests

    func testBadgeLevelUsesDesignSystemColors() {
        // Given
        let infoBadge = Badge(text: "Info", level: .info)
        let warnBadge = Badge(text: "Warn", level: .warning)
        let errorBadge = Badge(text: "Error", level: .error)
        let successBadge = Badge(text: "Success", level: .success)

        // Then - Verify that BadgeLevel provides DS colors (tested via BadgeLevel enum)
        XCTAssertEqual(infoBadge.level.backgroundColor, DS.Color.infoBG, "Info badge should use DS.Color.infoBG")
        XCTAssertEqual(warnBadge.level.backgroundColor, DS.Color.warnBG, "Warning badge should use DS.Color.warnBG")
        XCTAssertEqual(errorBadge.level.backgroundColor, DS.Color.errorBG, "Error badge should use DS.Color.errorBG")
        XCTAssertEqual(successBadge.level.backgroundColor, DS.Color.successBG, "Success badge should use DS.Color.successBG")
    }

    // MARK: - Component Composition Tests

    func testBadgeIsAView() {
        // Given
        let badge = Badge(text: "Test", level: .info)

        // Then
        // Verify that Badge conforms to View protocol (compile-time check)
        // This test primarily serves as documentation that Badge is a proper SwiftUI View
        XCTAssertTrue(type(of: badge) is any View.Type, "Badge should be a SwiftUI View")
    }

    // MARK: - Edge Cases

    func testBadgeWithEmptyText() {
        // Given
        let badge = Badge(text: "", level: .info)

        // Then
        XCTAssertEqual(badge.text, "", "Badge should support empty text")
    }

    func testBadgeWithLongText() {
        // Given
        let longText = "This is a very long badge text that might wrap or truncate"
        let badge = Badge(text: longText, level: .warning)

        // Then
        XCTAssertEqual(badge.text, longText, "Badge should support long text")
    }

    func testBadgeWithSpecialCharacters() {
        // Given
        let specialText = "⚠️ Øℓ∂ 日本語"
        let badge = Badge(text: specialText, level: .error)

        // Then
        XCTAssertEqual(badge.text, specialText, "Badge should support special characters and Unicode")
    }

    // MARK: - Equatable Tests

    func testBadgeLevelEquality() {
        // Given
        let level1 = BadgeLevel.info
        let level2 = BadgeLevel.info
        let level3 = BadgeLevel.warning

        // Then
        XCTAssertEqual(level1, level2, "Same badge levels should be equal")
        XCTAssertNotEqual(level1, level3, "Different badge levels should not be equal")
    }
}
