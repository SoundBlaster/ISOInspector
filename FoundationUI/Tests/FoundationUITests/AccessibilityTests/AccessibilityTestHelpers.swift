// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Helper utilities for accessibility testing
///
/// Provides common functions for testing:
/// - Contrast ratio calculations (WCAG 2.1 compliance)
/// - Touch target size validation
/// - VoiceOver label verification
/// - Dynamic Type size testing
@MainActor
enum AccessibilityTestHelpers {

    // MARK: - Contrast Ratio Testing

    /// Minimum contrast ratio for WCAG 2.1 AA compliance
    static let minimumContrastRatio: CGFloat = 4.5

    /// Calculates the relative luminance of a color component
    ///
    /// Based on WCAG 2.1 specification:
    /// https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
    ///
    /// - Parameter component: Color component value (0.0 to 1.0)
    /// - Returns: Relative luminance value
    private static func relativeLuminance(of component: CGFloat) -> CGFloat {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    /// Calculates the relative luminance of a color
    ///
    /// - Parameter color: SwiftUI Color to analyze
    /// - Returns: Relative luminance value (0.0 to 1.0)
    static func luminance(of color: Color) -> CGFloat {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rL = relativeLuminance(of: red)
        let gL = relativeLuminance(of: green)
        let bL = relativeLuminance(of: blue)

        return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL

        #elseif canImport(AppKit)
        guard let nsColor = NSColor(color).usingColorSpace(.deviceRGB) else {
            return 0.5 // Fallback luminance
        }

        let red = nsColor.redComponent
        let green = nsColor.greenComponent
        let blue = nsColor.blueComponent

        let rL = relativeLuminance(of: red)
        let gL = relativeLuminance(of: green)
        let bL = relativeLuminance(of: blue)

        return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL

        #else
        // Fallback for other platforms
        return 0.5
        #endif
    }

    /// Calculates the contrast ratio between two colors
    ///
    /// Uses WCAG 2.1 formula: (L1 + 0.05) / (L2 + 0.05)
    /// where L1 is the lighter color and L2 is the darker color.
    ///
    /// ## Example
    /// ```swift
    /// let ratio = AccessibilityTestHelpers.contrastRatio(
    ///     foreground: .black,
    ///     background: .white
    /// )
    /// XCTAssertGreaterThanOrEqual(ratio, 4.5, "Should meet WCAG AA")
    /// ```
    ///
    /// - Parameters:
    ///   - foreground: Foreground (text) color
    ///   - background: Background color
    /// - Returns: Contrast ratio (1.0 to 21.0)
    static func contrastRatio(foreground: Color, background: Color) -> CGFloat {
        let l1 = luminance(of: foreground)
        let l2 = luminance(of: background)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Asserts that a color combination meets WCAG 2.1 AA compliance
    ///
    /// - Parameters:
    ///   - foreground: Foreground (text) color
    ///   - background: Background color
    ///   - message: Custom assertion message
    ///   - file: Source file (automatically provided)
    ///   - line: Source line (automatically provided)
    static func assertMeetsWCAGAA(
        foreground: Color,
        background: Color,
        message: String = "Should meet WCAG 2.1 AA contrast ratio (≥4.5:1)",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let ratio = contrastRatio(foreground: foreground, background: background)
        XCTAssertGreaterThanOrEqual(
            ratio,
            minimumContrastRatio,
            "\(message). Actual ratio: \(String(format: "%.2f", ratio)):1",
            file: file,
            line: line
        )
    }

    // MARK: - Touch Target Testing

    /// Minimum touch target size for iOS/iPadOS (44×44 pt per Apple HIG)
    static let minimumTouchTargetSize: CGFloat = 44.0

    /// Validates that a size meets minimum touch target requirements
    ///
    /// - Parameters:
    ///   - size: The size to validate
    ///   - platform: Optional platform identifier for error messages
    /// - Returns: True if size meets minimum requirements
    static func meetsTouchTargetRequirement(size: CGSize, platform: String = "iOS") -> Bool {
        return size.width >= minimumTouchTargetSize && size.height >= minimumTouchTargetSize
    }

    /// Asserts that a size meets minimum touch target requirements
    ///
    /// - Parameters:
    ///   - size: The size to validate
    ///   - message: Custom assertion message
    ///   - file: Source file (automatically provided)
    ///   - line: Source line (automatically provided)
    static func assertMeetsTouchTargetSize(
        size: CGSize,
        message: String = "Should meet minimum touch target size (≥44×44 pt)",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(
            size.width,
            minimumTouchTargetSize,
            "\(message). Width: \(size.width) pt",
            file: file,
            line: line
        )
        XCTAssertGreaterThanOrEqual(
            size.height,
            minimumTouchTargetSize,
            "\(message). Height: \(size.height) pt",
            file: file,
            line: line
        )
    }

    // MARK: - VoiceOver Testing

    /// Validates that an accessibility label is meaningful and not empty
    ///
    /// - Parameter label: The accessibility label to validate
    /// - Returns: True if label is valid
    static func isValidAccessibilityLabel(_ label: String?) -> Bool {
        guard let label = label, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }

    /// Asserts that an accessibility label is meaningful
    ///
    /// - Parameters:
    ///   - label: The accessibility label to validate
    ///   - context: Context for the assertion message
    ///   - file: Source file (automatically provided)
    ///   - line: Source line (automatically provided)
    static func assertValidAccessibilityLabel(
        _ label: String?,
        context: String = "Component",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            isValidAccessibilityLabel(label),
            "\(context) should have a meaningful accessibility label",
            file: file,
            line: line
        )
    }

    // MARK: - Dynamic Type Testing

    /// All standard Dynamic Type content size categories
    static let allContentSizeCategories: [ContentSizeCategory] = [
        .xSmall,
        .small,
        .medium,
        .large,
        .xLarge,
        .xxLarge,
        .xxxLarge,
        .accessibilityMedium,
        .accessibilityLarge,
        .accessibilityXLarge,
        .accessibilityXxLarge,
        .accessibilityXxxLarge
    ]

    /// Common Dynamic Type sizes for testing (subset of all sizes)
    static let commonContentSizeCategories: [ContentSizeCategory] = [
        .xSmall,    // XS
        .medium,        // M (default)
        .xxLarge, // XXL
        .accessibilityXxxLarge // XXXL (largest)
    ]

    /// Creates a test name suffix for a given content size category
    ///
    /// - Parameter category: Content size category
    /// - Returns: Human-readable test name suffix
    static func testNameSuffix(for category: ContentSizeCategory) -> String {
        switch category {
        case .xSmall:
            return "ExtraSmall"
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        case .xLarge:
            return "ExtraLarge"
        case .xxLarge:
            return "ExtraExtraLarge"
        case .xxxLarge:
            return "ExtraExtraExtraLarge"
        case .accessibilityMedium:
            return "AccessibilityMedium"
        case .accessibilityLarge:
            return "AccessibilityLarge"
        case .accessibilityXLarge:
            return "AccessibilityExtraLarge"
        case .accessibilityXxLarge:
            return "AccessibilityExtraExtraLarge"
        case .accessibilityXxxLarge:
            return "AccessibilityExtraExtraExtraLarge"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Platform Detection

    /// Current platform identifier
    static var currentPlatform: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Unknown"
        #endif
    }

    /// Whether the current platform supports touch interactions
    static var supportsTouchInteraction: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform requires keyboard navigation support
    static var requiresKeyboardNavigation: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    /// Helper to test a component with all Dynamic Type sizes
    ///
    /// - Parameters:
    ///   - categories: Content size categories to test (defaults to common sizes)
    ///   - test: Test closure that receives each size category
    @MainActor
    func testWithDynamicType(
        categories: [ContentSizeCategory] = AccessibilityTestHelpers.commonContentSizeCategories,
        test: (ContentSizeCategory) -> Void
    ) {
        for category in categories {
            test(category)
        }
    }
}
