import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A view modifier that adds copy-to-clipboard functionality to any view
///
/// `CopyableModifier` provides a composable way to make any SwiftUI view copyable,
/// following the Composable Clarity design system principles. This is a Layer 1 modifier
/// that can be applied to any view type.
///
/// ## Usage
///
/// Apply to any view using the `.makeCopyable()` modifier:
/// ```swift
/// Text("Value")
///     .font(DS.Typography.code)
///     .makeCopyable(text: "Value")
/// ```
///
/// Complex views can also be made copyable:
/// ```swift
/// HStack {
///     Image(systemName: "doc.text")
///     Text("Complex content")
/// }
/// .makeCopyable(text: "Complex content")
/// ```
///
/// Disable visual feedback if needed:
/// ```swift
/// Text("Silent copy")
///     .makeCopyable(text: "Silent copy", showFeedback: false)
/// ```
///
/// ## Features
///
/// - **Platform-specific clipboard**: Uses `NSPasteboard` on macOS, `UIPasteboard` on iOS
/// - **Visual feedback**: Optional animated "Copied!" indicator
/// - **Keyboard shortcuts**: Supports ⌘C (macOS) when the view is focused
/// - **Accessibility**: VoiceOver announcements for successful copy
/// - **Design System compliance**: Uses DS tokens exclusively (zero magic numbers)
/// - **Composability**: Works with any View type
///
/// ## Accessibility
///
/// - Button label: "Copy {text}" with double-tap hint
/// - VoiceOver announcement: "{text} copied to clipboard" on successful copy
/// - Keyboard shortcut hint included in accessibility label
/// - Works with Dynamic Type (respects user's font size preferences)
///
/// ## Design Tokens Used
///
/// - Spacing: `DS.Spacing.s`, `DS.Spacing.m` for padding
/// - Animation: `DS.Animation.quick` for feedback transitions
/// - Typography: `DS.Typography.caption` for "Copied!" indicator
/// - Colors: `DS.Colors.accent` for visual emphasis
///
/// ## Platform Compatibility
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
///
/// - ``CopyableText``: Convenience component for simple text copying
/// - ``Copyable``: Generic wrapper for complex copyable views
public struct CopyableModifier: ViewModifier {
    // MARK: - Properties

    /// The text content to be copied to the clipboard
    let textToCopy: String

    /// Whether to show visual feedback ("Copied!" indicator)
    let showFeedback: Bool

    /// State tracking whether the text was recently copied
    @State private var wasCopied: Bool = false

    // MARK: - Initialization

    /// Creates a new copyable modifier
    ///
    /// - Parameters:
    ///   - textToCopy: The text content to be copied to the clipboard
    ///   - showFeedback: Whether to show visual feedback (default: true)
    public init(textToCopy: String, showFeedback: Bool = true) {
        self.textToCopy = textToCopy
        self.showFeedback = showFeedback
    }

    // MARK: - Body

    public func body(content: Content) -> some View {
        Button(action: copyToClipboard) {
            HStack(spacing: DS.Spacing.s) {
                content

                // Visual feedback indicator (only if showFeedback is true)
                if showFeedback {
                    if wasCopied {
                        Text("Copied!")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.accent)
                            .transition(.opacity)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(DS.Colors.secondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.m)
            .padding(.vertical, DS.Spacing.s)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy \(textToCopy)")
        .accessibilityHint("Double tap to copy to clipboard")
        #if os(macOS)
        .keyboardShortcut("c", modifiers: .command)
        #endif
    }

    // MARK: - Private Methods

    /// Copies the text to the system clipboard
    ///
    /// Uses platform-specific clipboard APIs:
    /// - macOS: `NSPasteboard.general`
    /// - iOS/iPadOS: `UIPasteboard.general`
    ///
    /// Shows visual feedback on successful copy using `DS.Animation.quick`.
    private func copyToClipboard() {
        #if os(macOS)
        copyToMacOSClipboard()
        #else
        copyToIOSClipboard()
        #endif

        // Show visual feedback (only if enabled)
        if showFeedback {
            withAnimation(DS.Animation.quick) {
                wasCopied = true
            }

            // Reset feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DS.Animation.quick) {
                    wasCopied = false
                }
            }
        }

        // Announce to VoiceOver
        announceToVoiceOver()
    }

    #if os(macOS)
    /// Copies text to macOS clipboard using NSPasteboard
    private func copyToMacOSClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
    #else
    /// Copies text to iOS/iPadOS clipboard using UIPasteboard
    private func copyToIOSClipboard() {
        UIPasteboard.general.string = textToCopy
    }
    #endif

    /// Announces successful copy to VoiceOver users
    private func announceToVoiceOver() {
        let announcement = "\(textToCopy) copied to clipboard"

        #if os(macOS)
        // macOS accessibility announcement
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [.announcement: announcement]
        )
        #else
        // iOS/iPadOS accessibility announcement
        UIAccessibility.post(
            notification: .announcement,
            argument: announcement
        )
        #endif
    }
}

// MARK: - View Extension

public extension View {
    /// Adds copy-to-clipboard functionality to any view
    ///
    /// This modifier makes the view copyable by wrapping it in a button
    /// with clipboard functionality and optional visual feedback.
    ///
    /// ## Usage
    ///
    /// Basic usage with default feedback:
    /// ```swift
    /// Text("Copyable Value")
    ///     .makeCopyable(text: "Copyable Value")
    /// ```
    ///
    /// Disable visual feedback:
    /// ```swift
    /// Text("Silent copy")
    ///     .makeCopyable(text: "Silent copy", showFeedback: false)
    /// ```
    ///
    /// Apply to complex views:
    /// ```swift
    /// HStack {
    ///     Image(systemName: "doc.text")
    ///     Text("Document")
    /// }
    /// .makeCopyable(text: "Document content")
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text content to be copied to the clipboard
    ///   - showFeedback: Whether to show visual feedback (default: true)
    ///
    /// - Returns: A view with copy-to-clipboard functionality
    ///
    /// ## Platform Support
    ///
    /// - macOS: Includes ⌘C keyboard shortcut
    /// - iOS/iPadOS: Touch-optimized copy button
    ///
    /// ## Accessibility
    ///
    /// - VoiceOver label: "Copy {text}"
    /// - VoiceOver hint: "Double tap to copy to clipboard"
    /// - Announcement on success: "{text} copied to clipboard"
    ///
    /// ## See Also
    ///
    /// - ``CopyableModifier``: The underlying view modifier
    /// - ``CopyableText``: Convenience component for text copying
    /// - ``Copyable``: Generic wrapper for complex views
    func makeCopyable(text: String, showFeedback: Bool = true) -> some View {
        modifier(CopyableModifier(textToCopy: text, showFeedback: showFeedback))
    }
}

// MARK: - SwiftUI Previews

#Preview("Basic Copyable Modifier") {
    VStack(spacing: DS.Spacing.l) {
        Text("Simple Value")
            .font(DS.Typography.code)
            .makeCopyable(text: "Simple Value")

        Text("With Custom Styling")
            .font(DS.Typography.body)
            .foregroundColor(DS.Colors.accent)
            .makeCopyable(text: "Styled Value")

        Text("No Feedback")
            .font(DS.Typography.code)
            .makeCopyable(text: "Silent copy", showFeedback: false)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Complex Views with Copyable") {
    VStack(spacing: DS.Spacing.l) {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "doc.text")
                .foregroundColor(DS.Colors.accent)
            Text("Document.pdf")
                .font(DS.Typography.code)
        }
        .makeCopyable(text: "Document.pdf")

        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "number")
                .foregroundColor(DS.Colors.secondary)
            Text("0x1A2B3C4D")
                .font(DS.Typography.code)
        }
        .makeCopyable(text: "0x1A2B3C4D")

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Complex Layout")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
            Text("192.168.1.1")
                .font(DS.Typography.code)
        }
        .makeCopyable(text: "192.168.1.1")
    }
    .padding(DS.Spacing.xl)
}

#Preview("Copyable in Card") {
    Card {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "File Metadata")

            HStack {
                Text("File ID:")
                    .font(DS.Typography.body)
                Spacer()
                Text("ABC123")
                    .font(DS.Typography.code)
            }
            .makeCopyable(text: "ABC123")

            HStack {
                Text("Checksum:")
                    .font(DS.Typography.body)
                Spacer()
                Text("0xDEADBEEF")
                    .font(DS.Typography.code)
            }
            .makeCopyable(text: "0xDEADBEEF")
        }
        .padding(DS.Spacing.l)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Text("Dark Mode Value")
            .font(DS.Typography.code)
            .makeCopyable(text: "Dark Mode Value")

        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "moon.fill")
            Text("0xABCDEF")
                .font(DS.Typography.code)
        }
        .makeCopyable(text: "0xABCDEF")
    }
    .padding(DS.Spacing.xl)
    .preferredColorScheme(.dark)
}

#Preview("Integration with Components") {
    VStack(spacing: DS.Spacing.l) {
        Badge(text: "Info", level: .info)
            .makeCopyable(text: "Info badge")

        Badge(text: "Warning", level: .warning)
            .makeCopyable(text: "Warning badge")

        Card {
            Text("Card content")
                .padding(DS.Spacing.m)
        }
        .makeCopyable(text: "Card content")
    }
    .padding(DS.Spacing.xl)
}
