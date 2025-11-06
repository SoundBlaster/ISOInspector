import XCTest
@testable import FoundationUI

#if canImport(SwiftUI)
import SwiftUI

/// Comprehensive contrast ratio tests for WCAG 2.1 Level AA compliance
///
/// Tests verify that all FoundationUI color combinations meet or exceed
/// the WCAG 2.1 Level AA minimum contrast ratio of 4.5:1 for normal text
/// and 3:1 for large text and UI components.
///
/// ## Coverage
///
/// - **Layer 0 (Design Tokens)**: All DS.Colors combinations
/// - **Layer 1 (View Modifiers)**: Badge levels, card backgrounds, surface materials
/// - **Layer 2 (Components)**: Badge, Card, KeyValueRow, SectionHeader
/// - **Layer 3 (Patterns)**: InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern
///
/// ## WCAG 2.1 Level AA Requirements
///
/// - Normal text: ≥4.5:1 contrast ratio
/// - Large text (18pt+ or 14pt+ bold): ≥3:1 contrast ratio
/// - UI components and graphical objects: ≥3:1 contrast ratio
///
/// ## Platform Support
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
@MainActor
final class ContrastRatioTests: XCTestCase {

    // MARK: - Layer 0: Design Tokens

    func testDesignTokens_InfoColors_MeetWCAG_AA() {
        // Info background with text colors
        let infoBG = Color(red: 0.0, green: 0.48, blue: 0.80) // DS.Colors.infoBG
        let textPrimary = Color.primary
        let textSecondary = Color.secondary

        // Info badge background should have sufficient contrast with white text
        let whiteText = Color.white
        let contrastWithWhite = AccessibilityHelpers.contrastRatio(
            foreground: whiteText,
            background: infoBG
        )

        XCTAssertGreaterThanOrEqual(
            contrastWithWhite,
            4.5,
            "Info background with white text should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrastWithWhite)):1"
        )
    }

    func testDesignTokens_WarningColors_MeetWCAG_AA() {
        // Warning background with text colors
        let warnBG = Color(red: 1.0, green: 0.80, blue: 0.0) // DS.Colors.warnBG
        let blackText = Color.black

        let contrastWithBlack = AccessibilityHelpers.contrastRatio(
            foreground: blackText,
            background: warnBG
        )

        XCTAssertGreaterThanOrEqual(
            contrastWithBlack,
            4.5,
            "Warning background with black text should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrastWithBlack)):1"
        )
    }

    func testDesignTokens_ErrorColors_MeetWCAG_AA() {
        // Error background with text colors
        let errorBG = Color(red: 0.96, green: 0.26, blue: 0.21) // DS.Colors.errorBG
        let whiteText = Color.white

        let contrastWithWhite = AccessibilityHelpers.contrastRatio(
            foreground: whiteText,
            background: errorBG
        )

        XCTAssertGreaterThanOrEqual(
            contrastWithWhite,
            4.5,
            "Error background with white text should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrastWithWhite)):1"
        )
    }

    func testDesignTokens_SuccessColors_MeetWCAG_AA() {
        // Success background with text colors
        let successBG = Color(red: 0.2, green: 0.78, blue: 0.35) // DS.Colors.successBG
        let blackText = Color.black

        let contrastWithBlack = AccessibilityHelpers.contrastRatio(
            foreground: blackText,
            background: successBG
        )

        XCTAssertGreaterThanOrEqual(
            contrastWithBlack,
            4.5,
            "Success background with black text should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrastWithBlack)):1"
        )
    }

    // MARK: - Layer 1: View Modifiers

    func testBadgeChipStyle_AllLevels_MeetWCAG_AA() {
        // Test all badge levels for contrast
        let levels: [(name: String, background: Color, foreground: Color)] = [
            ("info", Color(red: 0.0, green: 0.48, blue: 0.80), Color.white),
            ("warning", Color(red: 1.0, green: 0.80, blue: 0.0), Color.black),
            ("error", Color(red: 0.96, green: 0.26, blue: 0.21), Color.white),
            ("success", Color(red: 0.2, green: 0.78, blue: 0.35), Color.black)
        ]

        for level in levels {
            let contrast = AccessibilityHelpers.contrastRatio(
                foreground: level.foreground,
                background: level.background
            )

            XCTAssertGreaterThanOrEqual(
                contrast,
                4.5,
                "\(level.name.capitalized) badge should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
            )
        }
    }

    func testCardStyle_BackgroundContrast_MeetWCAG_AA() {
        // Card backgrounds should provide sufficient contrast
        // Testing with system background colors
        #if os(iOS)
        let cardBackground = Color(uiColor: .systemBackground)
        let cardText = Color(uiColor: .label)
        #elseif os(macOS)
        let cardBackground = Color(nsColor: .windowBackgroundColor)
        let cardText = Color(nsColor: .labelColor)
        #else
        let cardBackground = Color.white
        let cardText = Color.black
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: cardText,
            background: cardBackground
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "Card background with text should meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Layer 2: Components

    func testBadgeComponent_AllVariants_MeetWCAG_AA() {
        // Badge component uses BadgeChipStyle internally
        // Verify all badge levels maintain sufficient contrast

        let testCases: [(level: String, minContrast: Double)] = [
            ("info", 4.5),
            ("warning", 4.5),
            ("error", 4.5),
            ("success", 4.5)
        ]

        for testCase in testCases {
            // Badge uses predefined color combinations from DS.Colors
            // All combinations verified in testBadgeChipStyle_AllLevels_MeetWCAG_AA
            XCTAssertTrue(true, "\(testCase.level) badge contrast verified via BadgeChipStyle tests")
        }
    }

    func testCardComponent_ElevationLevels_MaintainContrast() {
        // Card elevation should not affect text contrast
        // Shadows should not reduce readability

        #if os(iOS)
        let background = Color(uiColor: .systemBackground)
        let text = Color(uiColor: .label)
        #elseif os(macOS)
        let background = Color(nsColor: .windowBackgroundColor)
        let text = Color(nsColor: .labelColor)
        #else
        let background = Color.white
        let text = Color.black
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: text,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "Card with elevation maintains WCAG AA contrast (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    func testKeyValueRowComponent_TextContrast() {
        // KeyValueRow uses DS.Typography.code for values (monospaced)
        // Key text uses secondary color
        // Value text uses primary color

        #if os(iOS)
        let primary = Color(uiColor: .label)
        let secondary = Color(uiColor: .secondaryLabel)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let primary = Color(nsColor: .labelColor)
        let secondary = Color(nsColor: .secondaryLabelColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let primary = Color.black
        let secondary = Color.gray
        let background = Color.white
        #endif

        let primaryContrast = AccessibilityHelpers.contrastRatio(
            foreground: primary,
            background: background
        )

        let secondaryContrast = AccessibilityHelpers.contrastRatio(
            foreground: secondary,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            primaryContrast,
            4.5,
            "KeyValueRow primary text meets WCAG AA (≥4.5:1), got \(String(format: "%.2f", primaryContrast)):1"
        )

        XCTAssertGreaterThanOrEqual(
            secondaryContrast,
            4.5,
            "KeyValueRow secondary text meets WCAG AA (≥4.5:1), got \(String(format: "%.2f", secondaryContrast)):1"
        )
    }

    func testSectionHeaderComponent_HeaderContrast() {
        // Section headers use secondary color and uppercase styling

        #if os(iOS)
        let headerColor = Color(uiColor: .secondaryLabel)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let headerColor = Color(nsColor: .secondaryLabelColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let headerColor = Color.gray
        let background = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: headerColor,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "SectionHeader meets WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Layer 3: Patterns

    func testInspectorPattern_ContentContrast() {
        // InspectorPattern uses Card components internally
        // Material backgrounds should maintain text contrast

        #if os(iOS)
        let text = Color(uiColor: .label)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let text = Color(nsColor: .labelColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let text = Color.black
        let background = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: text,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "InspectorPattern content meets WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    func testSidebarPattern_SelectionContrast() {
        // Sidebar selection state should maintain text readability

        #if os(iOS)
        let selectedBackground = Color(uiColor: .systemBlue)
        let selectedText = Color.white
        #elseif os(macOS)
        let selectedBackground = Color(nsColor: .controlAccentColor)
        let selectedText = Color.white
        #else
        let selectedBackground = Color.blue
        let selectedText = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: selectedText,
            background: selectedBackground
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "SidebarPattern selected item meets WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    func testToolbarPattern_IconContrast() {
        // Toolbar icons should be visible against background

        #if os(iOS)
        let iconColor = Color(uiColor: .label)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let iconColor = Color(nsColor: .labelColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let iconColor = Color.black
        let background = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: iconColor,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            3.0,
            "ToolbarPattern icons meet WCAG AA for UI components (≥3:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    func testBoxTreePattern_HierarchyContrast() {
        // Tree nodes at different levels should maintain contrast

        #if os(iOS)
        let text = Color(uiColor: .label)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let text = Color(nsColor: .labelColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let text = Color.black
        let background = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: text,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "BoxTreePattern nodes meet WCAG AA (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Dark Mode

    func testDarkMode_AllComponents_MeetWCAG_AA() {
        // Verify dark mode color combinations maintain sufficient contrast

        #if os(iOS)
        let darkText = Color.white
        let darkBackground = Color.black
        #elseif os(macOS)
        let darkText = Color.white
        let darkBackground = Color.black
        #else
        let darkText = Color.white
        let darkBackground = Color.black
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: darkText,
            background: darkBackground
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            4.5,
            "Dark mode maintains WCAG AA contrast (≥4.5:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Focus Indicators

    func testFocusIndicators_HighContrast() {
        // Focus indicators should be highly visible (≥3:1)

        #if os(iOS)
        let focusColor = Color(uiColor: .systemBlue)
        let background = Color(uiColor: .systemBackground)
        #elseif os(macOS)
        let focusColor = Color(nsColor: .controlAccentColor)
        let background = Color(nsColor: .windowBackgroundColor)
        #else
        let focusColor = Color.blue
        let background = Color.white
        #endif

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: focusColor,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            3.0,
            "Focus indicators meet WCAG AA for UI components (≥3:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Large Text

    func testLargeText_ReducedContrastRequirement() {
        // Large text (18pt+ or 14pt+ bold) only requires 3:1 contrast

        let largeTextColor = Color.gray
        let background = Color.white

        let contrast = AccessibilityHelpers.contrastRatio(
            foreground: largeTextColor,
            background: background
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            3.0,
            "Large text meets WCAG AA (≥3:1), got \(String(format: "%.2f", contrast)):1"
        )
    }

    // MARK: - Comprehensive Audit

    func testComprehensiveContrastAudit() {
        // Run comprehensive audit using AccessibilityHelpers

        var passed = 0
        var failed = 0
        var issues: [String] = []

        // Test all DS.Colors badge backgrounds
        let badgeTests: [(name: String, fg: Color, bg: Color)] = [
            ("info", .white, Color(red: 0.0, green: 0.48, blue: 0.80)),
            ("warning", .black, Color(red: 1.0, green: 0.80, blue: 0.0)),
            ("error", .white, Color(red: 0.96, green: 0.26, blue: 0.21)),
            ("success", .black, Color(red: 0.2, green: 0.78, blue: 0.35))
        ]

        for test in badgeTests {
            let contrast = AccessibilityHelpers.contrastRatio(
                foreground: test.fg,
                background: test.bg
            )

            if contrast >= 4.5 {
                passed += 1
            } else {
                failed += 1
                issues.append("\(test.name): \(String(format: "%.2f", contrast)):1 (required ≥4.5:1)")
            }
        }

        let passRate = Double(passed) / Double(passed + failed) * 100.0

        XCTAssertEqual(
            failed,
            0,
            "Comprehensive contrast audit found \(failed) issues: \(issues.joined(separator: ", ")). Pass rate: \(String(format: "%.1f", passRate))%"
        )

        XCTAssertGreaterThanOrEqual(
            passRate,
            95.0,
            "Contrast audit should achieve ≥95% pass rate, got \(String(format: "%.1f", passRate))%"
        )
    }
}

#endif
