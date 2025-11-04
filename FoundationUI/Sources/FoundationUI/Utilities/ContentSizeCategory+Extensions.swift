// swift-tools-version: 6.0
#if canImport(UIKit)
import UIKit

/// Extensions for UIKit's ContentSizeCategory to provide consistent naming with SwiftUI
///
/// ## Overview
/// UIKit's `ContentSizeCategory` uses verbose names like `.extraSmall`, `.extraLarge`.
/// This extension provides shorter, SwiftUI-style aliases for consistency:
/// - `.xSmall` instead of `.extraSmall`
/// - `.xLarge` instead of `.extraLarge`
/// - `.xxLarge` instead of `.extraExtraLarge`
/// - `.xxxLarge` instead of `.extraExtraExtraLarge`
///
/// ## Usage
/// ```swift
/// // Old style (still works):
/// let size: UIContentSizeCategory = .extraLarge
///
/// // New style (more concise):
/// let size: UIContentSizeCategory = .xLarge
/// ```
public extension UIContentSizeCategory {

    // MARK: - Base Size Aliases

    /// Extra Small size (alias for .extraSmall)
    static var xSmall: UIContentSizeCategory { .extraSmall }

    /// Extra Large size (alias for .extraLarge)
    static var xLarge: UIContentSizeCategory { .extraLarge }

    /// Extra Extra Large size (alias for .extraExtraLarge)
    static var xxLarge: UIContentSizeCategory { .extraExtraLarge }

    /// Extra Extra Extra Large size (alias for .extraExtraExtraLarge)
    static var xxxLarge: UIContentSizeCategory { .extraExtraExtraLarge }

    // MARK: - Accessibility Size Aliases

    /// Accessibility XLarge size (alias for .accessibilityExtraLarge)
    static var accessibilityXLarge: UIContentSizeCategory { .accessibilityExtraLarge }

    /// Accessibility XXLarge size (alias for .accessibilityExtraExtraLarge)
    static var accessibilityXxLarge: UIContentSizeCategory { .accessibilityExtraExtraLarge }

    /// Accessibility XXXLarge size (alias for .accessibilityExtraExtraExtraLarge)
    static var accessibilityXxxLarge: UIContentSizeCategory { .accessibilityExtraExtraExtraLarge }
}
#endif
