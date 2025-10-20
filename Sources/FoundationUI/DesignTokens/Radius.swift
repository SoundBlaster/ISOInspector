// swift-tools-version: 6.0
import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Design System Corner Radius Tokens
///
/// Provides consistent corner radius values for UI components across all platforms.
/// Follows the Composable Clarity principle of semantic naming and zero magic numbers.
///
/// ## Usage
/// ```swift
/// Card {
///     Text("Content")
/// }
/// .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
///
/// Badge(text: "NEW", level: .info)
///     .background(.blue, in: Capsule()) // Uses DS.Radius.chip internally
/// ```
///
/// ## Tokens
/// - `small`: Subtle rounding for compact UI elements (6pt)
/// - `card`: Standard rounding for cards and panels (10pt)
/// - `chip`: Fully rounded capsule shape (999pt = infinite radius)
///
/// ## Design Rationale
/// - **small**: Used for tight spaces where less rounding maintains visual density
/// - **card**: Balanced radius that feels modern without being overly rounded
/// - **chip**: Maximum radius for pill-shaped badges and chips
///
/// ## Platform Consistency
/// These radius values are intentionally platform-agnostic and work
/// identically on iOS, iPadOS, and macOS.
public extension DS {
    enum Radius {
        /// Small corner radius (6pt)
        ///
        /// Used for compact UI elements where subtle rounding is preferred.
        ///
        /// **Usage**:
        /// - Small buttons
        /// - Compact cards
        /// - Input fields
        /// - Toolbar items
        ///
        /// **Visual Effect**: Subtle softening of corners while maintaining density
        public static let small: CGFloat = 6

        /// Card corner radius (10pt)
        ///
        /// Standard radius for cards, panels, and container elements.
        ///
        /// **Usage**:
        /// - Content cards
        /// - Inspector panels
        /// - Modal sheets
        /// - Alert dialogs
        ///
        /// **Visual Effect**: Modern, approachable appearance without excessive rounding
        public static let card: CGFloat = 10

        /// Chip/capsule corner radius (999pt)
        ///
        /// Extremely large radius that creates a perfect capsule/pill shape.
        /// SwiftUI will automatically clamp this to half the view's height,
        /// creating fully rounded ends.
        ///
        /// **Usage**:
        /// - Status badges
        /// - Category chips
        /// - Pills and tags
        /// - Toggle buttons
        ///
        /// **Visual Effect**: Fully rounded pill shape regardless of content size
        ///
        /// **Note**: The value 999 is intentionally large to ensure the shape
        /// is always fully rounded. SwiftUI's Capsule shape achieves the same
        /// effect but this token provides consistency with other radius values.
        public static let chip: CGFloat = 999

        /// Medium corner radius (8pt)
        ///
        /// Optional intermediate radius for elements between small and card.
        ///
        /// **Usage**:
        /// - Medium buttons
        /// - List rows
        /// - Grouped sections
        ///
        /// **Visual Effect**: Balanced rounding for mid-size elements
        public static let medium: CGFloat = 8
    }
}
