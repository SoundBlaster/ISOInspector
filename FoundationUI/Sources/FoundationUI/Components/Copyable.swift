import SwiftUI

/// A generic wrapper that makes any content copyable
///
/// `Copyable` provides a flexible way to wrap any SwiftUI view and add copy-to-clipboard functionality.
/// Unlike ``CopyableText`` which only works with simple text, this generic wrapper supports complex
/// view hierarchies while maintaining the same copy behavior.
///
/// ## Usage
///
/// Wrap simple content:
/// ```swift
/// Copyable(text: "Simple Value") {
///     Text("Simple Value")
/// }
/// ```
///
/// Wrap complex view hierarchies:
/// ```swift
/// Copyable(text: "Document.pdf") {
///     HStack {
///         Image(systemName: "doc.text")
///         Text("Document.pdf")
///         Badge(text: "New", level: .info)
///     }
/// }
/// ```
///
/// Disable visual feedback:
/// ```swift
/// Copyable(text: "Silent copy", showFeedback: false) {
///     Text("Silent copy")
/// }
/// ```
///
/// ## Features
///
/// - **Generic content**: Works with any View type via ViewBuilder
/// - **Platform-specific clipboard**: Uses `NSPasteboard` on macOS, `UIPasteboard` on iOS
/// - **Visual feedback**: Optional animated "Copied!" indicator
/// - **Keyboard shortcuts**: Supports ⌘C (macOS) when focused
/// - **Accessibility**: VoiceOver announcements for successful copy
/// - **Design System compliance**: Uses DS tokens exclusively (zero magic numbers)
/// - **Composability**: Built on top of ``CopyableModifier``
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
/// All design tokens are inherited from ``CopyableModifier``:
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
/// ## Architecture
///
/// This component follows the Composable Clarity design system's layered architecture:
/// - Layer 1: ``CopyableModifier`` (base functionality)
/// - Layer 2: ``Copyable`` (generic wrapper) ← You are here
///
/// The `Copyable` wrapper simply applies the ``CopyableModifier`` to the provided content,
/// ensuring consistency and reusability across the design system.
///
/// ## See Also
///
/// - ``CopyableModifier``: The underlying view modifier
/// - ``CopyableText``: Convenience component for simple text
/// - `.copyable(text:showFeedback:)`: View extension for direct modifier application
public struct Copyable<Content: View>: View {
    // MARK: - Properties

    /// The content to display and make copyable
    private let content: Content

    /// The text content to be copied to the clipboard
    private let textToCopy: String

    /// Whether to show visual feedback ("Copied!" indicator)
    private let showFeedback: Bool

    // MARK: - Initialization

    /// Creates a new copyable wrapper with custom content
    ///
    /// - Parameters:
    ///   - text: The text content to be copied to the clipboard
    ///   - showFeedback: Whether to show visual feedback (default: true)
    ///   - content: The view content to display (supports ViewBuilder)
    ///
    /// ## Example
    ///
    /// Simple usage:
    /// ```swift
    /// Copyable(text: "Value") {
    ///     Text("Value")
    /// }
    /// ```
    ///
    /// Complex content:
    /// ```swift
    /// Copyable(text: "0x1A2B3C") {
    ///     HStack {
    ///         Image(systemName: "number")
    ///         Text("0x1A2B3C")
    ///         Badge(text: "Hex", level: .info)
    ///     }
    /// }
    /// ```
    ///
    /// Without feedback:
    /// ```swift
    /// Copyable(text: "Silent", showFeedback: false) {
    ///     Text("Silent copy")
    /// }
    /// ```
    public nonisolated init(
        text: String,
        showFeedback: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.textToCopy = text
        self.showFeedback = showFeedback
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        // Using .copyable() extension method for consistency
        // The View extension is defined in Modifiers/CopyableModifier.swift
        content.copyable(text: textToCopy, showFeedback: showFeedback)
    }
}

// MARK: - SwiftUI Previews

#Preview("Basic Copyable Wrapper") {
    VStack(spacing: DS.Spacing.l) {
        Copyable(text: "Simple Value") {
            Text("Simple Value")
                .font(DS.Typography.code)
        }

        Copyable(text: "Styled Value") {
            Text("Styled Value")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.accent)
        }

        Copyable(text: "No Feedback", showFeedback: false) {
            Text("No Feedback")
                .font(DS.Typography.code)
        }
    }
    .padding(DS.Spacing.xl)
}

#Preview("Complex Content") {
    VStack(spacing: DS.Spacing.l) {
        Copyable(text: "Document.pdf") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(DS.Colors.accent)
                Text("Document.pdf")
                    .font(DS.Typography.code)
            }
        }

        Copyable(text: "0x1A2B3C4D") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "number")
                    .foregroundColor(DS.Colors.secondary)
                Text("0x1A2B3C4D")
                    .font(DS.Typography.code)
                Badge(text: "Hex", level: .info)
            }
        }

        Copyable(text: "192.168.1.1") {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("IP Address")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                Text("192.168.1.1")
                    .font(DS.Typography.code)
            }
        }
    }
    .padding(DS.Spacing.xl)
}

#Preview("With FoundationUI Components") {
    VStack(spacing: DS.Spacing.l) {
        Copyable(text: "Info Badge") {
            Badge(text: "Info", level: .info)
        }

        Copyable(text: "Warning Badge") {
            Badge(text: "Warning", level: .warning)
        }

        Copyable(text: "Key-Value Pair") {
            KeyValueRow(key: "File ID", value: "ABC123")
        }
    }
    .padding(DS.Spacing.xl)
}

#Preview("In Card Context") {
    Card {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "File Details")

            Copyable(text: "Document.pdf") {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(DS.Colors.accent)
                    Text("Document.pdf")
                        .font(DS.Typography.code)
                }
            }

            Divider()

            Copyable(text: "0xDEADBEEF") {
                HStack {
                    Text("Checksum:")
                        .font(DS.Typography.body)
                    Spacer()
                    Text("0xDEADBEEF")
                        .font(DS.Typography.code)
                }
            }

            Divider()

            Copyable(text: "Active") {
                HStack {
                    Text("Status:")
                        .font(DS.Typography.body)
                    Spacer()
                    Badge(text: "Active", level: .success)
                }
            }
        }
        .padding(DS.Spacing.l)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Copyable(text: "Dark Mode Value") {
            Text("Dark Mode Value")
                .font(DS.Typography.code)
        }

        Copyable(text: "0xABCDEF") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "moon.fill")
                Text("0xABCDEF")
                    .font(DS.Typography.code)
            }
        }

        Copyable(text: "Complex Dark") {
            HStack {
                Image(systemName: "doc.text")
                Text("Document")
                Badge(text: "New", level: .info)
            }
        }
    }
    .padding(DS.Spacing.xl)
    .preferredColorScheme(.dark)
}

#Preview("Real-World: ISO Inspector") {
    Card {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "Box Information")

            Copyable(text: "ftyp") {
                HStack {
                    Text("Type:")
                        .font(DS.Typography.body)
                    Spacer()
                    Text("ftyp")
                        .font(DS.Typography.code)
                    Badge(text: "Container", level: .info)
                }
            }

            Divider()

            Copyable(text: "0x00000018") {
                KeyValueRow(key: "Size", value: "0x00000018")
            }

            Divider()

            Copyable(text: "0x00000000") {
                KeyValueRow(key: "Offset", value: "0x00000000")
            }
        }
        .padding(DS.Spacing.l)
    }
    .padding(DS.Spacing.xl)
}
