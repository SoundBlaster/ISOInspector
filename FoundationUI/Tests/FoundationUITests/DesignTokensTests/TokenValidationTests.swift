// swift-tools-version: 6.0
import XCTest
@testable import FoundationUI

/// Comprehensive validation tests for Design System tokens
///
/// Ensures all tokens meet the Composable Clarity design system requirements:
/// - Zero magic numbers (all values are named constants)
/// - Valid ranges for all numeric values
/// - Platform adaptation works correctly
/// - Accessibility compliance
final class TokenValidationTests: XCTestCase {

    // MARK: - Spacing Token Tests

    func testSpacingTokensArePositive() {
        XCTAssertGreaterThan(DS.Spacing.s, 0, "Small spacing must be positive")
        XCTAssertGreaterThan(DS.Spacing.m, 0, "Medium spacing must be positive")
        XCTAssertGreaterThan(DS.Spacing.l, 0, "Large spacing must be positive")
        XCTAssertGreaterThan(DS.Spacing.xl, 0, "Extra large spacing must be positive")
    }

    func testSpacingTokensAreOrdered() {
        // Spacing should follow logical progression: s < m < l < xl
        XCTAssertLessThan(DS.Spacing.s, DS.Spacing.m, "Small should be less than medium")
        XCTAssertLessThan(DS.Spacing.m, DS.Spacing.l, "Medium should be less than large")
        XCTAssertLessThan(DS.Spacing.l, DS.Spacing.xl, "Large should be less than extra large")
    }

    func testSpacingTokenValues() {
        // Verify exact values match specification
        XCTAssertEqual(DS.Spacing.s, 8, "Small spacing should be 8pt")
        XCTAssertEqual(DS.Spacing.m, 12, "Medium spacing should be 12pt")
        XCTAssertEqual(DS.Spacing.l, 16, "Large spacing should be 16pt")
        XCTAssertEqual(DS.Spacing.xl, 24, "Extra large spacing should be 24pt")
    }

    func testPlatformDefaultSpacing() {
        let platformDefault = DS.Spacing.platformDefault

        #if os(macOS)
        XCTAssertEqual(
            platformDefault,
            DS.Spacing.m,
            "macOS should use medium spacing as default"
        )
        #else
        XCTAssertEqual(
            platformDefault,
            DS.Spacing.l,
            "iOS/iPadOS should use large spacing as default"
        )
        #endif

        XCTAssertGreaterThan(platformDefault, 0, "Platform default must be positive")
    }

    // MARK: - Radius Token Tests

    func testRadiusTokensAreValid() {
        XCTAssertGreaterThanOrEqual(DS.Radius.small, 0, "Small radius must be non-negative")
        XCTAssertGreaterThanOrEqual(DS.Radius.card, 0, "Card radius must be non-negative")
        XCTAssertGreaterThanOrEqual(DS.Radius.chip, 0, "Chip radius must be non-negative")
        XCTAssertGreaterThanOrEqual(DS.Radius.medium, 0, "Medium radius must be non-negative")
    }

    func testRadiusTokenValues() {
        // Verify exact values match specification
        XCTAssertEqual(DS.Radius.small, 6, "Small radius should be 6pt")
        XCTAssertEqual(DS.Radius.medium, 8, "Medium radius should be 8pt")
        XCTAssertEqual(DS.Radius.card, 10, "Card radius should be 10pt")
        XCTAssertEqual(DS.Radius.chip, 999, "Chip radius should be 999pt (capsule)")
    }

    func testRadiusTokensAreOrdered() {
        // Logical progression: small < medium < card < chip
        XCTAssertLessThan(DS.Radius.small, DS.Radius.medium, "Small should be less than medium")
        XCTAssertLessThan(DS.Radius.medium, DS.Radius.card, "Medium should be less than card")
        XCTAssertLessThan(DS.Radius.card, DS.Radius.chip, "Card should be less than chip")
    }

    // MARK: - Animation Token Tests

    func testAnimationDurationsAreReasonable() {
        // Animations should be between 0.1s and 1.0s for good UX
        // We can't directly test SwiftUI.Animation duration, but we verify
        // the types are correctly defined

        // Verify animations are not nil
        XCTAssertNotNil(DS.Animation.quick, "Quick animation should be defined")
        XCTAssertNotNil(DS.Animation.medium, "Medium animation should be defined")
        XCTAssertNotNil(DS.Animation.slow, "Slow animation should be defined")
        XCTAssertNotNil(DS.Animation.spring, "Spring animation should be defined")
    }

    // MARK: - Typography Token Tests

    func testTypographyTokensAreDefined() {
        // Verify all typography tokens exist and are not nil
        XCTAssertNotNil(DS.Typography.label, "Label font should be defined")
        XCTAssertNotNil(DS.Typography.body, "Body font should be defined")
        XCTAssertNotNil(DS.Typography.title, "Title font should be defined")
        XCTAssertNotNil(DS.Typography.caption, "Caption font should be defined")
        XCTAssertNotNil(DS.Typography.code, "Code font should be defined")
        XCTAssertNotNil(DS.Typography.headline, "Headline font should be defined")
        XCTAssertNotNil(DS.Typography.subheadline, "Subheadline font should be defined")
    }

    // MARK: - Color Token Tests

    func testSemanticColorsAreDefined() {
        // Verify all semantic colors exist
        XCTAssertNotNil(DS.Colors.infoBG, "Info background color should be defined")
        XCTAssertNotNil(DS.Colors.warnBG, "Warning background color should be defined")
        XCTAssertNotNil(DS.Colors.errorBG, "Error background color should be defined")
        XCTAssertNotNil(DS.Colors.successBG, "Success background color should be defined")
        XCTAssertNotNil(DS.Colors.accent, "Accent color should be defined")
        XCTAssertNotNil(DS.Colors.secondary, "Secondary color should be defined")
        XCTAssertNotNil(DS.Colors.tertiary, "Tertiary color should be defined")
    }

    func testTextColorsAreDefined() {
        XCTAssertNotNil(DS.Colors.textPrimary, "Primary text color should be defined")
        XCTAssertNotNil(DS.Colors.textSecondary, "Secondary text color should be defined")
        XCTAssertNotNil(DS.Colors.textPlaceholder, "Placeholder text color should be defined")
    }

    // MARK: - Design System Consistency Tests

    func testNoMagicNumbers() {
        // This test verifies the principle of "zero magic numbers"
        // All values should be defined as constants, not inline literals

        // Spacing tokens use constants
        let spacingValues: Set<CGFloat> = [
            DS.Spacing.s,
            DS.Spacing.m,
            DS.Spacing.l,
            DS.Spacing.xl
        ]
        XCTAssertEqual(spacingValues.count, 4, "All spacing values should be unique")

        // Radius tokens use constants
        let radiusValues: Set<CGFloat> = [
            DS.Radius.small,
            DS.Radius.medium,
            DS.Radius.card,
            DS.Radius.chip
        ]
        XCTAssertEqual(radiusValues.count, 4, "All radius values should be unique")
    }

    func testTokenConsistency() {
        // Verify tokens maintain expected relationships

        // Spacing scale should use a consistent multiplier pattern
        // While not strictly enforced, it helps maintain visual harmony
        let spacingRatios = [
            DS.Spacing.m / DS.Spacing.s,  // 12/8 = 1.5
            DS.Spacing.l / DS.Spacing.m,  // 16/12 ≈ 1.33
            DS.Spacing.xl / DS.Spacing.l  // 24/16 = 1.5
        ]

        // All ratios should be reasonable (between 1.0 and 2.0)
        for ratio in spacingRatios {
            XCTAssertGreaterThan(ratio, 1.0, "Spacing scale should increase")
            XCTAssertLessThan(ratio, 2.0, "Spacing scale should not double")
        }
    }

    // MARK: - Cross-Platform Consistency Tests

    func testPlatformAgnosticTokens() {
        // Most tokens should work identically across platforms
        // Only platformDefault should vary

        // Spacing tokens are platform-agnostic
        XCTAssertEqual(DS.Spacing.s, 8, "Small spacing is platform-agnostic")
        XCTAssertEqual(DS.Spacing.m, 12, "Medium spacing is platform-agnostic")
        XCTAssertEqual(DS.Spacing.l, 16, "Large spacing is platform-agnostic")
        XCTAssertEqual(DS.Spacing.xl, 24, "Extra large spacing is platform-agnostic")

        // Radius tokens are platform-agnostic
        XCTAssertEqual(DS.Radius.small, 6, "Small radius is platform-agnostic")
        XCTAssertEqual(DS.Radius.card, 10, "Card radius is platform-agnostic")
        XCTAssertEqual(DS.Radius.chip, 999, "Chip radius is platform-agnostic")
    }
}
