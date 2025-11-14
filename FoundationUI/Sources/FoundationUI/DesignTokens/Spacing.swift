import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Design System Spacing Tokens
///
/// Provides a unified, platform-adaptive spacing scale for the FoundationUI framework.
/// All spacing values follow the Composable Clarity design system principle of **zero magic numbers**.
///
/// ## Usage
/// ```swift
/// VStack(spacing: DS.Spacing.m) {
///     Text("Title")
///     Text("Content")
/// }
/// .padding(DS.Spacing.l)
/// ```
///
/// ## Platform Adaptation
/// The `platformDefault` computed property automatically selects appropriate spacing
/// based on the target platform:
/// - macOS: Uses `m` (12pt) for denser UI
/// - iOS/iPadOS: Uses `l` (16pt) for touch-friendly spacing
///
/// ## Tokens
/// - `xxs` (4pt): Extra tight spacing for inline elements
/// - `xs` (6pt): Very tight spacing for dense UI
/// - `s` (8pt): Tight spacing for compact layouts
/// - `m` (12pt): Standard spacing for macOS
/// - `l` (16pt): Standard spacing for iOS/iPadOS
/// - `xl` (24pt): Large spacing for section separators
///
/// ## Accessibility
/// All spacing tokens work correctly with Dynamic Type and maintain
/// minimum touch target sizes of 44×44pt on iOS.
public extension DS {
    enum Spacing {
        /// Extra extra small spacing (4pt) - for inline elements and very tight grouping
        public static let xxs: CGFloat = 4

        /// Extra small spacing (6pt) - for dense UI and small padding
        public static let xs: CGFloat = 6

        /// Small spacing (8pt) - for compact layouts and tight grouping
        public static let s: CGFloat = 8

        /// Medium spacing (12pt) - standard for macOS UI
        public static let m: CGFloat = 12

        /// Large spacing (16pt) - standard for iOS/iPadOS UI
        public static let l: CGFloat = 16

        /// Extra large spacing (24pt) - for section separators and visual breathing room
        public static let xl: CGFloat = 24

        /// Platform-adaptive default spacing
        ///
        /// Returns the appropriate default spacing for the current platform:
        /// - macOS: `m` (12pt) for denser desktop UI
        /// - iOS/iPadOS: `l` (16pt) for touch-optimized spacing
        public static var platformDefault: CGFloat {
            #if os(macOS)
            return m
            #else
            return l
            #endif
        }
    }
}

/// Design System namespace
///
/// Root namespace for all FoundationUI design tokens, providing a unified
/// and type-safe API for design constants across all platforms.
///
/// ## Architecture
/// The DS namespace follows a 4-layer design system:
/// - **Layer 0 (Tokens)**: Design constants (Spacing, Colors, Typography, etc.)
/// - **Layer 1 (Modifiers)**: Reusable view modifiers
/// - **Layer 2 (Components)**: Semantic UI components
/// - **Layer 3 (Patterns)**: Complex UI patterns
///
/// ## Design Principles
/// - **Zero magic numbers**: All values are named constants
/// - **Semantic naming**: Names reflect meaning, not values
/// - **Platform adaptation**: Automatic adjustment for iOS/macOS
/// - **Accessibility first**: WCAG 2.1 AA compliance minimum
///
/// ## See Also
/// - ``DS/Spacing``
/// - ``DS/Typography``
/// - ``DS/Color``
/// - ``DS/Radius``
/// - ``DS/Animation``
public enum DS {}
