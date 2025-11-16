import SwiftUI

/// Extensions for DynamicTypeSize to provide semantic naming for accessibility sizes
///
/// ## Overview
/// SwiftUI's `DynamicTypeSize` enum uses non-descriptive names like `.accessibility1`, `.accessibility2`
/// for accessibility text sizes. This extension provides semantic static properties that map to
/// the numeric cases, making code more readable and self-documenting.
///
/// Note: DynamicTypeSize already conforms to Comparable in SwiftUI, so comparison operators
/// (`<`, `<=`, `>=`, `>`) work out of the box.
///
/// ## Usage
/// ```swift
/// // Semantic names instead of .accessibility1
/// let size: DynamicTypeSize = .accessibilityMedium
///
/// // Comparison operators (already available from SwiftUI)
/// if size >= .accessibilityMedium {
///     print("Using accessibility text size")
/// }
///
/// // Works with all sizes
/// let sizes: [DynamicTypeSize] = [.small, .medium, .large, .accessibilityLarge]
/// let sorted = sizes.sorted() // Automatic ordering
/// ```
public extension DynamicTypeSize {
    // MARK: - Semantic Accessibility Names

    /// Accessibility Medium size (equivalent to .accessibility1)
    ///
    /// First level of accessibility text sizes, typically 1.5× base size.
    /// Used when user enables larger text for improved readability.
    static var accessibilityMedium: DynamicTypeSize { .accessibility1 }

    /// Accessibility Large size (equivalent to .accessibility2)
    ///
    /// Second level of accessibility text sizes, typically 1.8× base size.
    /// Provides significantly larger text for vision accessibility.
    static var accessibilityLarge: DynamicTypeSize { .accessibility2 }

    /// Accessibility XLarge size (equivalent to .accessibility3)
    ///
    /// Third level of accessibility text sizes, typically 2.0× base size.
    /// For users who need very large text.
    /// Consistent naming with base `.xLarge` size.
    static var accessibilityXLarge: DynamicTypeSize { .accessibility3 }

    /// Accessibility XXLarge size (equivalent to .accessibility4)
    ///
    /// Fourth level of accessibility text sizes, typically 2.3× base size.
    /// For users with significant vision impairments.
    /// Consistent naming with base `.xxLarge` size.
    static var accessibilityXxLarge: DynamicTypeSize { .accessibility4 }

    /// Accessibility XXXLarge size (equivalent to .accessibility5)
    ///
    /// Maximum accessibility text size, typically 2.5× base size.
    /// Largest possible Dynamic Type size for maximum accessibility.
    /// Consistent naming with base `.xxxLarge` size.
    static var accessibilityXxxLarge: DynamicTypeSize { .accessibility5 }
}
