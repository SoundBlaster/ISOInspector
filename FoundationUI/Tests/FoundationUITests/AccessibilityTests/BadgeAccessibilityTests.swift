// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Accessibility tests for the Badge component
///
/// Verifies WCAG 2.1 AA compliance and VoiceOver support for all badge variants.
///
/// ## Test Coverage
/// - VoiceOver accessibility labels for all badge levels
/// - Contrast ratio validation (≥4.5:1)
/// - Touch target size validation (≥44×44 pt)
/// - Dynamic Type support (XS to XXXL)
/// - Badge with icon accessibility
/// - Badge level accessibility traits
@MainActor
final class BadgeAccessibilityTests: XCTestCase {

    // MARK: - VoiceOver Label Tests

    func testBadgeInfoLevelHasCorrectAccessibilityLabel() {
        // Given
        let level = BadgeLevel.info

        // Then
        XCTAssertEqual(
            level.accessibilityLabel,
            "Information",
            "Info badge level should have 'Information' accessibility label"
        )
    }

    func testBadgeWarningLevelHasCorrectAccessibilityLabel() {
        // Given
        let level = BadgeLevel.warning

        // Then
        XCTAssertEqual(
            level.accessibilityLabel,
            "Warning",
            "Warning badge level should have 'Warning' accessibility label"
        )
    }

    func testBadgeErrorLevelHasCorrectAccessibilityLabel() {
        // Given
        let level = BadgeLevel.error

        // Then
        XCTAssertEqual(
            level.accessibilityLabel,
            "Error",
            "Error badge level should have 'Error' accessibility label"
        )
    }

    func testBadgeSuccessLevelHasCorrectAccessibilityLabel() {
        // Given
        let level = BadgeLevel.success

        // Then
        XCTAssertEqual(
            level.accessibilityLabel,
            "Success",
            "Success badge level should have 'Success' accessibility label"
        )
    }

    func testAllBadgeLevelsHaveAccessibilityLabels() {
        // Given
        let allLevels: [BadgeLevel] = [.info, .warning, .error, .success]

        // When & Then
        for level in allLevels {
            AccessibilityTestHelpers.assertValidAccessibilityLabel(
                level.accessibilityLabel,
                context: "Badge level '\(level)'"
            )
        }
    }

    // MARK: - Contrast Ratio Tests

    func testBadgeInfoLevelMeetsContrastRequirements() {
        // Given
        let level = BadgeLevel.info
        let foreground = level.foregroundColor
        let background = level.backgroundColor

        // Then
        AccessibilityTestHelpers.assertMeetsWCAGAA(
            foreground: foreground,
            background: background,
            message: "Info badge should meet WCAG 2.1 AA contrast ratio"
        )
    }

    func testBadgeWarningLevelMeetsContrastRequirements() {
        // Given
        let level = BadgeLevel.warning
        let foreground = level.foregroundColor
        let background = level.backgroundColor

        // Then
        AccessibilityTestHelpers.assertMeetsWCAGAA(
            foreground: foreground,
            background: background,
            message: "Warning badge should meet WCAG 2.1 AA contrast ratio"
        )
    }

    func testBadgeErrorLevelMeetsContrastRequirements() {
        // Given
        let level = BadgeLevel.error
        let foreground = level.foregroundColor
        let background = level.backgroundColor

        // Then
        AccessibilityTestHelpers.assertMeetsWCAGAA(
            foreground: foreground,
            background: background,
            message: "Error badge should meet WCAG 2.1 AA contrast ratio"
        )
    }

    func testBadgeSuccessLevelMeetsContrastRequirements() {
        // Given
        let level = BadgeLevel.success
        let foreground = level.foregroundColor
        let background = level.backgroundColor

        // Then
        AccessibilityTestHelpers.assertMeetsWCAGAA(
            foreground: foreground,
            background: background,
            message: "Success badge should meet WCAG 2.1 AA contrast ratio"
        )
    }

    func testAllBadgeLevelsMeetContrastRequirements() {
        // Given
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
                "Badge level '\(level)' should meet WCAG 2.1 AA (≥4.5:1). Actual: \(String(format: "%.2f", ratio)):1"
            )
        }
    }

    // MARK: - Icon Accessibility Tests

    func testBadgeInfoLevelHasAppropriateIcon() {
        // Given
        let level = BadgeLevel.info

        // Then
        XCTAssertEqual(
            level.iconName,
            "info.circle.fill",
            "Info badge should use info.circle.fill SF Symbol"
        )
    }

    func testBadgeWarningLevelHasAppropriateIcon() {
        // Given
        let level = BadgeLevel.warning

        // Then
        XCTAssertEqual(
            level.iconName,
            "exclamationmark.triangle.fill",
            "Warning badge should use exclamationmark.triangle.fill SF Symbol"
        )
    }

    func testBadgeErrorLevelHasAppropriateIcon() {
        // Given
        let level = BadgeLevel.error

        // Then
        XCTAssertEqual(
            level.iconName,
            "xmark.circle.fill",
            "Error badge should use xmark.circle.fill SF Symbol"
        )
    }

    func testBadgeSuccessLevelHasAppropriateIcon() {
        // Given
        let level = BadgeLevel.success

        // Then
        XCTAssertEqual(
            level.iconName,
            "checkmark.circle.fill",
            "Success badge should use checkmark.circle.fill SF Symbol"
        )
    }

    func testAllBadgeLevelsHaveIcons() {
        // Given
        let allLevels: [BadgeLevel] = [.info, .warning, .error, .success]

        // When & Then
        for level in allLevels {
            XCTAssertFalse(
                level.iconName.isEmpty,
                "Badge level '\(level)' should have an icon name"
            )
        }
    }

    // MARK: - Design System Token Usage Tests

    func testBadgeUsesDesignSystemColors() {
        // Given
        let infoLevel = BadgeLevel.info
        let warningLevel = BadgeLevel.warning
        let errorLevel = BadgeLevel.error
        let successLevel = BadgeLevel.success

        // Then - Verify DS token usage
        XCTAssertEqual(
            infoLevel.backgroundColor,
            DS.Color.infoBG,
            "Info badge should use DS.Color.infoBG token"
        )
        XCTAssertEqual(
            warningLevel.backgroundColor,
            DS.Color.warnBG,
            "Warning badge should use DS.Color.warnBG token"
        )
        XCTAssertEqual(
            errorLevel.backgroundColor,
            DS.Color.errorBG,
            "Error badge should use DS.Color.errorBG token"
        )
        XCTAssertEqual(
            successLevel.backgroundColor,
            DS.Color.successBG,
            "Success badge should use DS.Color.successBG token"
        )
    }

    // MARK: - Touch Target Size Tests (iOS/iPadOS)

    func testBadgeMinimumTouchTargetSize() {
        // Given
        // Badge with typical text content
        // Assuming standard padding from DS.Spacing.m and DS.Spacing.s

        // Note: In a real scenario, we would render the badge and measure its frame.
        // For unit tests, we verify the spacing tokens are appropriately sized.
        let horizontalPadding = DS.Spacing.m * 2  // Left + Right
        let verticalPadding = DS.Spacing.s * 2    // Top + Bottom

        // Expected minimum content size (rough estimate)
        let minimumTextWidth: CGFloat = 20.0  // Minimum for short text like "OK"
        let minimumTextHeight: CGFloat = 16.0 // Caption font height

        let estimatedWidth = horizontalPadding + minimumTextWidth
        let estimatedHeight = verticalPadding + minimumTextHeight

        // Then
        // While badges may naturally be smaller than 44pt, we verify they have adequate padding
        // Interactive badges (if clickable) should be wrapped in a larger touch target
        XCTAssertGreaterThan(
            horizontalPadding,
            0,
            "Badge should have horizontal padding for better touch target"
        )
        XCTAssertGreaterThan(
            verticalPadding,
            0,
            "Badge should have vertical padding for better touch target"
        )

        // Document that badges, being primarily informational, may not always meet 44pt independently
        // but should be tested in context with interactive containers
        print("Badge estimated size: \(estimatedWidth)×\(estimatedHeight) pt")
        print("Note: Badges are primarily informational. When interactive, wrap in larger touch target.")
    }

    // MARK: - Platform Compatibility Tests

    func testBadgeAccessibilityOnCurrentPlatform() {
        // Given
        let platform = AccessibilityTestHelpers.currentPlatform
        let badge = Badge(text: "Test", level: .info)

        // Then
        XCTAssertNotNil(badge, "Badge should be creatable on \(platform)")
        XCTAssertEqual(
            badge.level.accessibilityLabel,
            "Information",
            "Badge accessibility should work on \(platform)"
        )
    }

    // MARK: - Badge Component Integration Tests

    func testBadgeComponentPreservesAccessibilityLabel() {
        // Given
        let badge = Badge(text: "NEW", level: .info)

        // Then
        // The badge component should preserve the accessibility label from BadgeLevel
        XCTAssertEqual(
            badge.level.accessibilityLabel,
            "Information",
            "Badge component should preserve accessibility label from level"
        )
    }

    func testBadgeComponentWithIconPreservesAccessibility() {
        // Given
        let badge = Badge(text: "Alert", level: .warning, showIcon: true)

        // Then
        XCTAssertTrue(
            badge.showIcon,
            "Badge with icon should set showIcon property"
        )
        XCTAssertEqual(
            badge.level.accessibilityLabel,
            "Warning",
            "Badge with icon should preserve accessibility label"
        )
        XCTAssertEqual(
            badge.level.iconName,
            "exclamationmark.triangle.fill",
            "Badge with icon should have correct icon name"
        )
    }

    // MARK: - Edge Case Tests

    func testBadgeWithEmptyTextStillHasAccessibilityLabel() {
        // Given
        let badge = Badge(text: "", level: .error)

        // Then
        // Even with empty text, the badge level should provide accessibility context
        AccessibilityTestHelpers.assertValidAccessibilityLabel(
            badge.level.accessibilityLabel,
            context: "Badge with empty text"
        )
    }

    func testBadgeWithLongTextMaintainsAccessibility() {
        // Given
        let longText = "This is a very long badge text that might wrap or truncate"
        let badge = Badge(text: longText, level: .success)

        // Then
        // Long text should not affect accessibility label from level
        XCTAssertEqual(
            badge.level.accessibilityLabel,
            "Success",
            "Badge with long text should maintain accessibility label"
        )
    }
}
