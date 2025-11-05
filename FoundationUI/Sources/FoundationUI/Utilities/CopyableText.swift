// swift-tools-version: 6.0
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A convenience component for displaying copyable text with visual feedback
///
/// `CopyableText` provides a reusable interface for text that users can copy to the clipboard
/// with a single tap or click. The component shows visual feedback when the copy action succeeds,
/// following the Composable Clarity design system.
///
/// **Note**: This component is a convenience wrapper around the more flexible ``CopyableModifier``.
/// For applying copy functionality to complex views, consider using the `.makeCopyable()` modifier directly
/// or the generic ``Copyable`` wrapper.
///
/// ## Usage
///
/// Basic usage with text only:
/// ```swift
/// CopyableText(text: "0x1234ABCD")
/// ```
///
/// With custom label for accessibility:
/// ```swift
/// CopyableText(text: "0xDEADBEEF", label: "Memory Address")
/// ```
///
/// ## Features
///
/// - **Platform-specific clipboard**: Uses `NSPasteboard` on macOS, `UIPasteboard` on iOS
/// - **Visual feedback**: Animated "Copied!" indicator appears on successful copy
/// - **Keyboard shortcuts**: Supports ⌘C (macOS) / Ctrl+C (iOS) when focused
/// - **Accessibility**: VoiceOver labels and announcements for successful copy
/// - **Design System compliance**: Uses DS tokens exclusively (zero magic numbers)
///
/// ## Accessibility
///
/// - Button label: "Copy {value}" or custom label if provided
/// - VoiceOver announcement: "{value} copied to clipboard" on successful copy
/// - Keyboard shortcut hint included in accessibility label
/// - Works with Dynamic Type (respects user's font size preferences)
///
/// ## Design Tokens Used
///
/// - Spacing: `DS.Spacing.s`, `DS.Spacing.m` (via CopyableModifier)
/// - Animation: `DS.Animation.quick` for feedback (via CopyableModifier)
/// - Typography: `DS.Typography.code` for text, `DS.Typography.caption` for indicator
/// - Colors: `DS.Colors.accent`, `DS.Colors.textPrimary` for visual emphasis
///
/// ## Platform Compatibility
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## Architecture
///
/// This component uses the ``CopyableModifier`` internally, following the Composable Clarity
/// design system's layered architecture:
/// - Layer 1: ``CopyableModifier`` (base functionality)
/// - Layer 2: ``CopyableText`` (convenience component) ← You are here
///
/// ## See Also
///
/// - ``CopyableModifier``: The underlying view modifier for any view
/// - ``Copyable``: Generic wrapper for complex copyable views
/// - `.makeCopyable(text:showFeedback:)`: View extension for applying copy functionality
public struct CopyableText: View {
    // MARK: - Properties

    /// The text content to be copied to the clipboard
    private let text: String

    /// Optional label for accessibility (defaults to the text value)
    private let label: String?

    // MARK: - Initialization

    /// Creates a new copyable text component
    ///
    /// - Parameters:
    ///   - text: The text content to be copied to the clipboard
    ///   - label: Optional accessibility label (defaults to text value if not provided)
    ///
    /// ## Example
    /// ```swift
    /// // Basic usage
    /// CopyableText(text: "0x1234ABCD")
    ///
    /// // With custom accessibility label
    /// CopyableText(text: "0xDEADBEEF", label: "Memory Address")
    /// ```
    public init(text: String, label: String? = nil) {
        self.text = text
        self.label = label
    }

    // MARK: - Body

    public var body: some View {
        // Refactored to use CopyableModifier for consistency and maintainability
        Text(text)
            .font(DS.Typography.code)
            .foregroundColor(DS.Colors.textPrimary)
            .makeCopyable(text: text)
            .accessibilityLabel(accessibilityLabelText)
    }

    // MARK: - Private Computed Properties

    /// Accessibility label for the copy button
    private var accessibilityLabelText: String {
        if let label = label {
            return "Copy \(label): \(text)"
        } else {
            return "Copy \(text)"
        }
    }
}

// MARK: - SwiftUI Previews

#Preview("Basic Copyable Text") {
    VStack(spacing: DS.Spacing.l) {
        CopyableText(text: "0x1234ABCD")
        CopyableText(text: "DEADBEEF", label: "Hex Value")
        CopyableText(text: "192.168.1.1", label: "IP Address")
    }
    .padding(DS.Spacing.xl)
}

#Preview("Copyable Text in Card") {
    Card {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "Technical Details")

            CopyableText(text: "0xFFFFFFFF", label: "Memory Address")
            CopyableText(text: "com.example.app", label: "Bundle ID")
        }
        .padding(DS.Spacing.l)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        CopyableText(text: "Dark Mode Test")
        CopyableText(text: "0xABCDEF", label: "Hex Value")
    }
    .padding(DS.Spacing.xl)
    .preferredColorScheme(.dark)
}
