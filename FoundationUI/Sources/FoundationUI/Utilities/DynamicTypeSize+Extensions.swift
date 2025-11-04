// swift-tools-version: 6.0
import SwiftUI

/// Extensions for DynamicTypeSize to provide semantic naming and comparison support
///
/// ## Overview
/// SwiftUI's `DynamicTypeSize` enum uses non-descriptive names like `.accessibility1`, `.accessibility2`
/// for accessibility text sizes. This extension provides:
/// - **Semantic Names**: Clear, descriptive names like `.accessibilityMedium`, `.accessibilityLarge`
/// - **Comparable Support**: Enables comparison operators (`<`, `<=`, `>=`, `>`) for size checking
/// - **Raw Value Mapping**: Consistent ordering for all Dynamic Type sizes
///
/// ## Usage
/// ```swift
/// // Semantic names instead of .accessibility1
/// let size: DynamicTypeSize = .accessibilityMedium
///
/// // Comparison operators
/// if size >= .accessibilityMedium {
///     print("Using accessibility text size")
/// }
///
/// // Works with all sizes
/// let sizes: [DynamicTypeSize] = [.small, .medium, .large, .accessibilityLarge]
/// let sorted = sizes.sorted() // Automatic ordering
/// ```
extension DynamicTypeSize: Comparable {

    // MARK: - Semantic Accessibility Names

    /// Accessibility Medium size (equivalent to .accessibility1)
    ///
    /// First level of accessibility text sizes, typically 1.5× base size.
    /// Used when user enables larger text for improved readability.
    public static var accessibilityMedium: DynamicTypeSize { .accessibility1 }

    /// Accessibility Large size (equivalent to .accessibility2)
    ///
    /// Second level of accessibility text sizes, typically 1.8× base size.
    /// Provides significantly larger text for vision accessibility.
    public static var accessibilityLarge: DynamicTypeSize { .accessibility2 }

    /// Accessibility XLarge size (equivalent to .accessibility3)
    ///
    /// Third level of accessibility text sizes, typically 2.0× base size.
    /// For users who need very large text.
    /// Consistent naming with base `.xLarge` size.
    public static var accessibilityXLarge: DynamicTypeSize { .accessibility3 }

    /// Accessibility XXLarge size (equivalent to .accessibility4)
    ///
    /// Fourth level of accessibility text sizes, typically 2.3× base size.
    /// For users with significant vision impairments.
    /// Consistent naming with base `.xxLarge` size.
    public static var accessibilityXxLarge: DynamicTypeSize { .accessibility4 }

    /// Accessibility XXXLarge size (equivalent to .accessibility5)
    ///
    /// Maximum accessibility text size, typically 2.5× base size.
    /// Largest possible Dynamic Type size for maximum accessibility.
    /// Consistent naming with base `.xxxLarge` size.
    public static var accessibilityXxxLarge: DynamicTypeSize { .accessibility5 }

    // MARK: - Comparable Conformance

    /// Raw value for ordering Dynamic Type sizes
    ///
    /// Maps each size to an integer for consistent comparison.
    /// Smaller values = smaller text, larger values = larger text.
    private var rawValue: Int {
        switch self {
        case .xSmall: return 0
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        case .xLarge: return 4
        case .xxLarge: return 5
        case .xxxLarge: return 6
        case .accessibility1: return 7
        case .accessibility2: return 8
        case .accessibility3: return 9
        case .accessibility4: return 10
        case .accessibility5: return 11
        @unknown default: return 3 // Default to .large
        }
    }

    /// Compares two Dynamic Type sizes
    ///
    /// - Parameters:
    ///   - lhs: Left-hand size
    ///   - rhs: Right-hand size
    /// - Returns: `true` if lhs is smaller than rhs
    ///
    /// ## Example
    /// ```swift
    /// DynamicTypeSize.small < .large // true
    /// DynamicTypeSize.accessibilityLarge > .xLarge // true
    /// ```
    public static func < (lhs: DynamicTypeSize, rhs: DynamicTypeSize) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
