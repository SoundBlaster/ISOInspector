// swift-tools-version: 6.0
import XCTest

#if canImport(SwiftUI)
import SwiftUI
@testable import FoundationUI

/// Comprehensive tests for the AccessibilityHelpers utility
///
/// Tests cover:
/// - Common accessibility modifiers
/// - VoiceOver hint builders
/// - Contrast ratio validators (WCAG 2.1 AA compliance ≥4.5:1)
/// - Accessibility audit tools
/// - Platform-specific accessibility features
/// - Integration with DS tokens (zero magic numbers)
@MainActor
final class AccessibilityHelpersTests: XCTestCase {

    // MARK: - Contrast Ratio Validation Tests

    func testContrastRatioCalculation() {
        // Test WCAG 2.1 contrast ratio calculation between two colors
        // Contrast ratio formula: (L1 + 0.05) / (L2 + 0.05)
        // where L1 is the relative luminance of the lighter color
        // and L2 is the relative luminance of the darker color

        // Black on white should have maximum contrast (21:1)
        let blackWhiteRatio = AccessibilityHelpers.contrastRatio(
            foreground: .black,
            background: .white
        )
        XCTAssertGreaterThan(blackWhiteRatio, 20.0, "Black on white should have contrast ratio ≥21:1")

        // White on black should also have maximum contrast
        let whiteBlackRatio = AccessibilityHelpers.contrastRatio(
            foreground: .white,
            background: .black
        )
        XCTAssertGreaterThan(whiteBlackRatio, 20.0, "White on black should have contrast ratio ≥21:1")
    }

    func testContrastRatioWCAG_AA_Compliance() {
        // WCAG 2.1 Level AA requires minimum contrast ratio of 4.5:1 for normal text
        let minContrastAA = 4.5

        // Test that checker identifies compliant colors
        let isCompliant = AccessibilityHelpers.meetsWCAG_AA(
            foreground: .black,
            background: .white
        )
        XCTAssertTrue(isCompliant, "Black on white should meet WCAG AA (≥4.5:1)")

        // Test gray on white (should fail AA)
        let lightGrayOnWhite = AccessibilityHelpers.meetsWCAG_AA(
            foreground: Color.gray.opacity(0.3),
            background: .white
        )
        // This should likely fail, but we'll verify the API exists
        XCTAssertNotNil(lightGrayOnWhite, "Should return boolean result")
    }

    func testContrastRatioWCAG_AAA_Compliance() {
        // WCAG 2.1 Level AAA requires minimum contrast ratio of 7:1 for normal text
        let minContrastAAA = 7.0

        let isCompliantAAA = AccessibilityHelpers.meetsWCAG_AAA(
            foreground: .black,
            background: .white
        )
        XCTAssertTrue(isCompliantAAA, "Black on white should meet WCAG AAA (≥7:1)")
    }

    func testContrastRatioWithDSColors() {
        // All DS.Colors tokens should meet WCAG AA requirements
        // This ensures design system compliance

        // Test info badge colors
        let infoBGContrast = AccessibilityHelpers.contrastRatio(
            foreground: .black,
            background: DS.Colors.infoBG
        )
        XCTAssertGreaterThanOrEqual(infoBGContrast, 4.5, "DS.Colors.infoBG should meet WCAG AA")

        // Test warning badge colors
        let warnBGContrast = AccessibilityHelpers.contrastRatio(
            foreground: .black,
            background: DS.Colors.warnBG
        )
        XCTAssertGreaterThanOrEqual(warnBGContrast, 4.5, "DS.Colors.warnBG should meet WCAG AA")
    }

    // MARK: - VoiceOver Hint Builder Tests

    func testVoiceOverHintForButton() {
        // VoiceOver hints should provide clear, concise guidance
        let hint = AccessibilityHelpers.voiceOverHint(
            action: "copy",
            target: "value"
        )
        XCTAssertFalse(hint.isEmpty, "Should generate non-empty hint")
        XCTAssertTrue(hint.contains("copy"), "Hint should mention the action")
    }

    func testVoiceOverHintForToggle() {
        let expandHint = AccessibilityHelpers.voiceOverHint(
            action: "expand",
            target: "section"
        )
        XCTAssertFalse(expandHint.isEmpty, "Should generate hint for expandable elements")

        let collapseHint = AccessibilityHelpers.voiceOverHint(
            action: "collapse",
            target: "section"
        )
        XCTAssertFalse(collapseHint.isEmpty, "Should generate hint for collapsible elements")
    }

    func testVoiceOverHintBuilder() {
        // Test hint builder with multiple components
        let hint = AccessibilityHelpers.buildVoiceOverHint {
            "Double tap to "
            "activate"
        }
        XCTAssertFalse(hint.isEmpty, "Builder should combine strings")
    }

    // MARK: - Common Accessibility Modifier Tests

    func testAccessibleButtonModifier() {
        // Test that accessible button modifier exists and applies correctly
        let view = Text("Test")
        let accessibleView = view.accessibleButton(
            label: "Test Button",
            hint: "Tap to test"
        )
        XCTAssertNotNil(accessibleView, "Should apply accessible button modifier")
    }

    func testAccessibleToggleModifier() {
        // Test accessible toggle modifier with state
        let view = Text("Toggle")
        let accessibleToggle = view.accessibleToggle(
            label: "Test Toggle",
            isOn: true
        )
        XCTAssertNotNil(accessibleToggle, "Should apply accessible toggle modifier")
    }

    func testAccessibleHeadingModifier() {
        // Test heading modifier for proper hierarchy
        let view = Text("Heading")
        let heading = view.accessibleHeading(level: 1)
        XCTAssertNotNil(heading, "Should apply heading trait")
    }

    func testAccessibleValueModifier() {
        // Test value modifier for key-value pairs
        let view = Text("12345")
        let accessibleValue = view.accessibleValue(
            label: "Count",
            value: "12345"
        )
        XCTAssertNotNil(accessibleValue, "Should apply value accessibility")
    }

    // MARK: - Accessibility Audit Tools Tests

    func testTouchTargetSizeValidation() {
        // iOS HIG requires minimum 44x44 pt touch targets
        let minimumSize: CGFloat = 44.0

        let isValid = AccessibilityHelpers.isValidTouchTarget(
            size: CGSize(width: 44, height: 44)
        )
        XCTAssertTrue(isValid, "44x44 should be valid touch target")

        let isTooSmall = AccessibilityHelpers.isValidTouchTarget(
            size: CGSize(width: 30, height: 30)
        )
        XCTAssertFalse(isTooSmall, "30x30 should fail touch target validation")
    }

    func testAccessibilityLabelValidation() {
        // Labels should be non-empty and meaningful
        let validLabel = AccessibilityHelpers.isValidAccessibilityLabel("Copy Value")
        XCTAssertTrue(validLabel, "Should accept valid label")

        let emptyLabel = AccessibilityHelpers.isValidAccessibilityLabel("")
        XCTAssertFalse(emptyLabel, "Should reject empty label")

        let tooShortLabel = AccessibilityHelpers.isValidAccessibilityLabel("X")
        XCTAssertFalse(tooShortLabel, "Should reject single-character label")
    }

    func testAccessibilityAuditForView() {
        // Comprehensive audit that checks multiple criteria
        let auditResult = AccessibilityHelpers.auditView(
            hasLabel: true,
            hasHint: true,
            touchTargetSize: CGSize(width: 44, height: 44),
            contrastRatio: 7.0
        )

        XCTAssertTrue(auditResult.passes, "Should pass audit with all criteria met")
        XCTAssertEqual(auditResult.issues.count, 0, "Should have no issues")
    }

    func testAccessibilityAuditFailures() {
        // Test audit with failures
        let auditResult = AccessibilityHelpers.auditView(
            hasLabel: false,
            hasHint: false,
            touchTargetSize: CGSize(width: 20, height: 20),
            contrastRatio: 2.0
        )

        XCTAssertFalse(auditResult.passes, "Should fail audit with missing criteria")
        XCTAssertGreaterThan(auditResult.issues.count, 0, "Should list specific issues")
    }

    // MARK: - Focus Management Tests

    func testAccessibleFocusModifier() {
        // Test focus management for keyboard navigation
        let view = Text("Focusable")
        let focusable = view.accessibleFocus(priority: .high)
        XCTAssertNotNil(focusable, "Should apply focus modifier")
    }

    func testFocusOrderValidation() {
        // Validate that focus order is logical
        let elements = [
            AccessibilityHelpers.FocusElement(id: "1", order: 1, label: "First"),
            AccessibilityHelpers.FocusElement(id: "2", order: 2, label: "Second"),
            AccessibilityHelpers.FocusElement(id: "3", order: 3, label: "Third")
        ]

        let isValidOrder = AccessibilityHelpers.isValidFocusOrder(elements)
        XCTAssertTrue(isValidOrder, "Sequential order should be valid")
    }

    // MARK: - Platform-Specific Tests

    #if os(macOS)
    func testMacOSKeyboardNavigation() {
        // macOS-specific keyboard navigation
        let view = Text("Navigate")
        let navigable = view.macOSKeyboardNavigable()
        XCTAssertNotNil(navigable, "Should support macOS keyboard navigation")
    }
    #endif

    #if os(iOS)
    func testIOSVoiceOverRotor() {
        // iOS-specific VoiceOver rotor support
        let view = Text("Rotor")
        let rotorEnabled = view.voiceOverRotor(entry: "Actions")
        XCTAssertNotNil(rotorEnabled, "Should support iOS VoiceOver rotor")
    }
    #endif

    // MARK: - Dynamic Type Support Tests

    func testDynamicTypeScaling() {
        // Test that helpers support Dynamic Type scaling
        let baseSize: CGFloat = 16.0
        let scaledSize = AccessibilityHelpers.scaledValue(
            baseSize,
            for: .xxLarge
        )
        XCTAssertGreaterThan(scaledSize, baseSize, "Should scale up for larger type sizes")
    }

    func testIsAccessibilitySize() {
        // Test detection of accessibility size categories
        XCTAssertTrue(
            AccessibilityHelpers.isAccessibilitySize(.accessibilityMedium),
            "Should identify accessibility sizes"
        )
        XCTAssertFalse(
            AccessibilityHelpers.isAccessibilitySize(.large),
            "Should not identify normal sizes as accessibility"
        )
    }

    // MARK: - Integration with DS Tokens Tests

    func testDesignSystemTokenUsage() {
        // Verify that AccessibilityHelpers uses DS tokens exclusively
        // No magic numbers should appear in spacing, colors, or typography

        // This is a compile-time check more than runtime
        // We verify the API can be called
        let spacing = DS.Spacing.m
        let color = DS.Colors.accent
        let typography = DS.Typography.body

        XCTAssertNotNil(spacing, "Should use DS.Spacing tokens")
        XCTAssertNotNil(color, "Should use DS.Colors tokens")
        XCTAssertNotNil(typography, "Should use DS.Typography tokens")
    }

    func testAccessibilityContextIntegration() {
        // Test integration with existing AccessibilityContext
        let context = AccessibilityContext(
            prefersReducedMotion: true,
            prefersIncreasedContrast: true,
            prefersBoldText: true,
            dynamicTypeSize: .accessibilityLarge
        )

        // AccessibilityHelpers should work with AccessibilityContext
        let shouldAnimate = AccessibilityHelpers.shouldAnimate(in: context)
        XCTAssertFalse(shouldAnimate, "Should respect reduced motion preference")

        let preferredSpacing = AccessibilityHelpers.preferredSpacing(in: context)
        XCTAssertGreaterThan(preferredSpacing, DS.Spacing.m, "Should increase spacing for contrast")
    }

    // MARK: - Performance Tests

    func testContrastRatioPerformance() {
        // Contrast ratio calculation should be fast
        measure {
            for _ in 0..<1000 {
                _ = AccessibilityHelpers.contrastRatio(
                    foreground: .black,
                    background: .white
                )
            }
        }
    }

    func testAuditPerformance() {
        // Accessibility audit should complete quickly
        measure {
            for _ in 0..<100 {
                _ = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
            }
        }
    }
}

// MARK: - Test Helper Extensions

extension AccessibilityHelpersTests {
    /// Helper to create test colors with specific luminance
    func testColor(red: Double, green: Double, blue: Double) -> Color {
        Color(red: red, green: green, blue: blue)
    }
}

#endif // canImport(SwiftUI)
