// swift-tools-version: 6.0
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Design System Color Tokens
///
/// Provides semantic, accessible color tokens for the FoundationUI framework.
/// All colors meet WCAG 2.1 AA contrast requirements (≥4.5:1) for text readability.
///
/// ## Usage
/// ```swift
/// Badge(text: "ERROR", level: .error)
///     .background(DS.Color.errorBG)
///
/// Card {
///     Text("Warning")
/// }
/// .overlay(
///     RoundedRectangle(cornerRadius: DS.Radius.card)
///         .stroke(DS.Color.warnBG, lineWidth: 2)
/// )
/// ```
///
/// ## Accessibility
/// All background colors are carefully calibrated to:
/// - Provide ≥4.5:1 contrast ratio with foreground text
/// - Work correctly in both Light and Dark mode
/// - Support Increase Contrast accessibility setting
/// - Maintain visual distinction for color-blind users
///
/// ## Semantic Colors
/// Colors are named by semantic meaning, not visual appearance:
/// - `infoBG`: Neutral informational state (gray)
/// - `warnBG`: Warning or caution state (orange)
/// - `errorBG`: Error or failure state (red)
/// - `successBG`: Success or completion state (green)
///
/// ## Dark Mode
/// Colors automatically adapt to the system color scheme:
/// - Light mode: Lighter tints for backgrounds
/// - Dark mode: System automatically adjusts opacity and vibrancy
public extension DS {
    enum Color {
        // MARK: - Semantic Background Colors

        /// Information background color (neutral gray)
        ///
        /// Used for informational badges, hints, and neutral status indicators.
        ///
        /// **Contrast**: ≥4.5:1 with black text in light mode
        /// **Opacity**: 0.18 for subtle visual presence
        /// **Usage**: INFO badges, neutral cards, default states
        public static let infoBG = SwiftUI.Color.gray.opacity(0.18)

        /// Warning background color (orange)
        ///
        /// Used for warnings, cautions, and states requiring attention.
        ///
        /// **Contrast**: ≥4.5:1 with black text in light mode
        /// **Opacity**: 0.22 for sufficient visibility
        /// **Usage**: WARNING badges, validation hints, caution indicators
        public static let warnBG = SwiftUI.Color.orange.opacity(0.22)

        /// Error background color (red)
        ///
        /// Used for errors, failures, and critical issues.
        ///
        /// **Contrast**: ≥4.5:1 with black text in light mode
        /// **Opacity**: 0.22 for clear visual distinction
        /// **Usage**: ERROR badges, validation errors, critical alerts
        public static let errorBG = SwiftUI.Color.red.opacity(0.22)

        /// Success background color (green)
        ///
        /// Used for successful operations, confirmations, and positive states.
        ///
        /// **Contrast**: ≥4.5:1 with black text in light mode
        /// **Opacity**: 0.20 for pleasant, non-intrusive appearance
        /// **Usage**: SUCCESS badges, confirmations, valid states
        public static let successBG = SwiftUI.Color.green.opacity(0.20)

        // MARK: - Additional Semantic Colors

        /// Primary accent color for interactive elements
        ///
        /// Uses the system accent color which respects user's tint preferences.
        ///
        /// **Usage**: Buttons, links, selected states
        public static let accent = SwiftUI.Color.accentColor

        /// Secondary color for supporting elements
        ///
        /// Uses system gray for less prominent UI elements.
        ///
        /// **Usage**: Secondary buttons, borders, dividers
        public static let secondary = SwiftUI.Color.secondary

        /// Tertiary color for background elements
        ///
        /// Uses system tertiary for subtle backgrounds and fills.
        ///
        /// **Usage**: Card backgrounds, hover states, disabled states
        public static let tertiary: SwiftUI.Color = {
            #if canImport(UIKit)
            return SwiftUI.Color(uiColor: .tertiarySystemBackground)
            #elseif canImport(AppKit)
            return SwiftUI.Color(nsColor: .tertiarySystemBackground)
            #else
            return SwiftUI.Color.gray.opacity(0.1)
            #endif
        }()

        // MARK: - Foreground Colors

        /// Primary text color
        ///
        /// Automatically adapts to light/dark mode.
        ///
        /// **Usage**: Body text, labels, primary content
        public static let textPrimary = SwiftUI.Color.primary

        /// Secondary text color for less prominent content
        ///
        /// **Usage**: Captions, helper text, metadata
        public static let textSecondary = SwiftUI.Color.secondary

        /// Placeholder text color for empty states
        ///
        /// **Usage**: Placeholder text, disabled labels
        public static let textPlaceholder: SwiftUI.Color = {
            #if canImport(UIKit)
            return SwiftUI.Color(uiColor: .placeholderText)
            #elseif canImport(AppKit)
            return SwiftUI.Color(nsColor: .placeholderText)
            #else
            return SwiftUI.Color.gray.opacity(0.6)
            #endif
        }()
    }
}
