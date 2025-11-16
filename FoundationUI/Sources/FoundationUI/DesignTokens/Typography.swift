import SwiftUI

/// Design System Typography Tokens
///
/// Provides a semantic typography scale for the FoundationUI framework.
/// All font styles support Dynamic Type for accessibility.
///
/// ## Usage
/// ```swift
/// Text("Section Title")
///     .font(DS.Typography.title)
///
/// Text("Body content")
///     .font(DS.Typography.body)
///
/// Badge(text: "INFO", level: .info)
///     .font(DS.Typography.label)
/// ```
///
/// ## Accessibility
/// All typography tokens use SwiftUI's built-in fonts which automatically:
/// - Support Dynamic Type size adjustments
/// - Scale correctly from accessibility size XS to XXXL
/// - Maintain readability across all platforms
/// - Respect user's preferred reading size
///
/// ## Tokens
/// - `label`
/// - `body`
/// - `title`
/// - `caption`
/// - `code`
///
/// ## Platform Considerations
/// Typography scales slightly differently between platforms:
/// - iOS: Larger default sizes for touch readability
/// - macOS: Smaller default sizes for dense information display
/// - Both platforms support the full Dynamic Type range
public extension DS {
    enum Typography {
        /// Label font for badges, chips, and small indicators
        ///
        /// Uses caption2 with semibold weight for emphasis.
        /// Typically displayed in uppercase for visual consistency.
        ///
        /// **Usage**: Status badges, category labels, metadata tags
        public static let label = Font.caption2.weight(.semibold)

        /// Standard body text font
        ///
        /// Uses the system body font which provides optimal readability
        /// for paragraphs and content text.
        ///
        /// **Usage**: Descriptions, content text, general UI copy
        public static let body = Font.body

        /// Title font for sections and components
        ///
        /// Uses title3 with semibold weight for visual hierarchy.
        ///
        /// **Usage**: Section headers, panel titles, screen titles
        public static let title = Font.title3.weight(.semibold)

        /// Caption font for small descriptive text
        ///
        /// Uses the system caption font for secondary information.
        ///
        /// **Usage**: Footnotes, helper text, timestamps
        public static let caption = Font.caption

        /// Monospaced font for technical content
        ///
        /// Uses system monospaced body font for code, hex values,
        /// and other technical content requiring alignment.
        ///
        /// **Usage**: Hex dumps, box offsets, byte sequences, technical IDs
        public static let code = Font.body.monospaced()

        /// Headline font for prominent content
        ///
        /// Uses headline font for important, attention-grabbing text.
        ///
        /// **Usage**: Alert titles, dialog headers, important notices
        public static let headline = Font.headline

        /// Subheadline font for secondary headers
        ///
        /// Uses subheadline font for less prominent but still important headers.
        ///
        /// **Usage**: Subsection titles, grouped list headers
        public static let subheadline = Font.subheadline
    }
}
