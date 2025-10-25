// swift-tools-version: 6.0
import Foundation

/// Design System Opacity Tokens
///
/// Provides named opacity values to ensure consistent application of transparency
/// throughout the FoundationUI components and patterns.
///
/// ## Usage
/// ```swift
/// Text(subtitle)
///     .opacity(DS.Opacity.subtleText)
/// ```
///
/// ## Accessibility
/// Opacity levels are calibrated to maintain sufficient contrast against
/// background colors while providing clear visual hierarchy.
public extension DS {
    enum Opacity {
        /// Subtle text opacity for secondary labels and metadata
        ///
        /// Designed for subtitles and supporting text that should remain readable
        /// while visually de-emphasised compared to primary content.
        public static let subtleText: Double = 0.7
    }
}
