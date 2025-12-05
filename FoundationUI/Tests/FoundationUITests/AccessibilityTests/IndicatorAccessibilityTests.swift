import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Accessibility validation for the Indicator component.
///
/// Validates VoiceOver semantics, touch targets, and tooltip fallbacks
/// to ensure WCAG 2.1 AA compliance and Apple HIG alignment.
@MainActor final class IndicatorAccessibilityTests: XCTestCase {
    func testVoiceOverLabelsForEachLevel() {
        // Given
        let levels: [BadgeLevel] = [.info, .warning, .error, .success]

        for level in levels {
            // When
            let configuration = Indicator.AccessibilityConfiguration.make(
                level: level, reason: "Status update", tooltip: nil)

            // Then
            XCTAssertTrue(
                configuration.label.contains(level.accessibilityLabel),
                "VoiceOver label should include the badge accessibility label")
        }
    }

    func testAccessibilityHintFallsBackToTooltipContent() {
        // Given
        let tooltip = Indicator.Tooltip.text("Checksum mismatch")

        // When
        let configuration = Indicator.AccessibilityConfiguration.make(
            level: .warning, reason: nil, tooltip: tooltip)

        // Then
        XCTAssertEqual(configuration.hint, "Checksum mismatch")
    }

    func testAccessibilityHintUsesBadgeTooltipWhenAvailable() {
        // Given
        let tooltip = Indicator.Tooltip.badge(text: "Checksum mismatch", level: .warning)

        // When
        let configuration = Indicator.AccessibilityConfiguration.make(
            level: .warning, reason: nil, tooltip: tooltip)

        // Then
        XCTAssertEqual(configuration.hint, "Checksum mismatch")
    }

    func testTouchTargetMeetsMinimumSizeRequirements() {
        // Given
        let sizes = Indicator.Size.allCases

        for size in sizes {
            // When
            let hitArea = size.minimumHitTarget

            // Then
            AccessibilityTestHelpers.assertMeetsTouchTargetSize(size: hitArea)
        }
    }
}
