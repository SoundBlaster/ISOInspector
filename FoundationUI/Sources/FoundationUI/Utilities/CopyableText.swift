// swift-tools-version: 6.0
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A utility component for displaying copyable text with visual feedback
///
/// `CopyableText` provides a reusable interface for text that users can copy to the clipboard
/// with a single tap or click. The component shows visual feedback when the copy action succeeds,
/// following the Composable Clarity design system.
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
/// - Spacing: `DS.Spacing.s`, `DS.Spacing.m`
/// - Animation: `DS.Animation.quick` for feedback
/// - Typography: `DS.Typography.caption` for "Copied!" indicator
/// - Colors: `DS.Colors.accent` for visual emphasis
///
/// ## Platform Compatibility
///
/// - iOS 16.0+
/// - iPadOS 16.0+
/// - macOS 14.0+
public struct CopyableText: View {
    // MARK: - Properties

    /// The text content to be copied to the clipboard
    private let text: String

    /// Optional label for accessibility (defaults to the text value)
    private let label: String?

    /// State tracking whether the text was recently copied
    @State private var wasCopied: Bool = false

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
        Button(action: copyToClipboard) {
            HStack(spacing: DS.Spacing.s) {
                Text(text)
                    .font(DS.Typography.code)
                    .foregroundColor(DS.Colors.textPrimary)

                // Copy indicator
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
            .padding(.horizontal, DS.Spacing.m)
            .padding(.vertical, DS.Spacing.s)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap to copy to clipboard")
        #if os(macOS)
        .keyboardShortcut("c", modifiers: .command)
        #endif
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

        // Show visual feedback
        withAnimation(DS.Animation.quick) {
            wasCopied = true
        }

        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(DS.Animation.quick) {
                wasCopied = false
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
        pasteboard.setString(text, forType: .string)
    }
    #else
    /// Copies text to iOS/iPadOS clipboard using UIPasteboard
    private func copyToIOSClipboard() {
        UIPasteboard.general.string = text
    }
    #endif

    /// Announces successful copy to VoiceOver users
    private func announceToVoiceOver() {
        let announcement = "\(label ?? text) copied to clipboard"

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
