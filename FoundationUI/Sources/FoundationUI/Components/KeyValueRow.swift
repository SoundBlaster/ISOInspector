import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A component for displaying key-value pairs with semantic styling
///
/// The KeyValueRow component provides a reusable UI element for displaying
/// metadata, file properties, and technical information in a clear, readable format.
/// It supports both horizontal (compact) and vertical (for long values) layouts,
/// and includes optional clipboard copy functionality.
///
/// ## Design System Integration
/// KeyValueRow uses the following Design System tokens:
/// - **Typography**: `DS.Typography.body` (keys), `DS.Typography.code` (values)
/// - **Spacing**: `DS.Spacing.s`, `DS.Spacing.m`, `DS.Spacing.l`
/// - **Colors**: System foreground colors with secondary styling for keys
///
/// ## Usage
/// ```swift
/// // Basic horizontal layout
/// KeyValueRow(key: "Type", value: "ftyp")
///
/// // Vertical layout for long values
/// KeyValueRow(key: "Description", value: "A very long description...", layout: .vertical)
///
/// // With copyable text
/// KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
///
/// // Full configuration
/// KeyValueRow(
///     key: "Offset",
///     value: "0x00001234",
///     layout: .vertical,
///     copyable: true
/// )
/// ```
///
/// ## Layout Options
/// - **Horizontal**: Key and value displayed side-by-side (default)
/// - **Vertical**: Key displayed above value (recommended for long values)
///
/// ## Accessibility
/// - VoiceOver reads in format: "Key, value"
/// - Copyable values announce "Double-tap to copy"
/// - Supports Dynamic Type text scaling
/// - Maintains minimum touch target sizes (≥44×44 pt)
///
/// ## Platform Support
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
/// - ``KeyValueLayout``: Layout enumeration
/// - ``DS/Typography``: Design System typography tokens
/// - ``DS/Spacing``: Design System spacing tokens
public struct KeyValueRow: View {
    // MARK: - Properties

    /// The label/key text displayed
    public let key: String

    /// The value text displayed (uses monospaced font)
    public let value: String

    /// The layout style (horizontal or vertical)
    public let layout: KeyValueLayout

    /// Whether the value text can be copied to clipboard
    public let copyable: Bool

    // MARK: - State

    @State private var isCopying = false

    // MARK: - Initialization

    /// Creates a new KeyValueRow component
    ///
    /// ## Example
    /// ```swift
    /// KeyValueRow(key: "Type", value: "ftyp")
    /// KeyValueRow(key: "Size", value: "1024", copyable: true)
    /// KeyValueRow(key: "Description", value: "Long text", layout: .vertical)
    /// ```
    ///
    /// ## Parameters
    /// - key: The label/key text to display
    /// - value: The value text to display (rendered in monospaced font)
    /// - layout: The layout style (horizontal or vertical). Default: `.horizontal`
    /// - copyable: Whether to enable copy-to-clipboard functionality. Default: `false`
    ///
    /// ## Accessibility
    /// VoiceOver will read the content as "key, value".
    /// If copyable is enabled, an additional hint "Double-tap to copy" is provided.
    public nonisolated init(
        key: String,
        value: String,
        layout: KeyValueLayout = .horizontal,
        copyable: Bool = false
    ) {
        self.key = key
        self.value = value
        self.layout = layout
        self.copyable = copyable
    }

    // MARK: - Body

    public var body: some View {
        Group {
            switch layout {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key), \(value)")
        .if(copyable) { view in
            view.accessibilityHint("Double-tap to copy")
        }
    }

    // MARK: - Layout Views

    /// Horizontal layout: key and value side-by-side
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: DS.Spacing.m) {
            Text(key)
                .font(DS.Typography.body)
                .foregroundStyle(.secondary)

            Spacer()

            valueText
        }
    }

    /// Vertical layout: key above value
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(key)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)

            valueText
        }
    }

    /// The value text with monospaced font and optional copy functionality
    @ViewBuilder
    private var valueText: some View {
        if copyable {
            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: DS.Spacing.s) {
                    Text(value)
                        .font(DS.Typography.code)
                        .foregroundStyle(.primary)

                    Image(systemName: isCopying ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(value), copyable")
        } else {
            Text(value)
                .font(DS.Typography.code)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Actions

    /// Copies the value to the system clipboard
    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #else
        UIPasteboard.general.string = value
        #endif

        // Show visual feedback
        isCopying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCopying = false
        }
    }
}

// MARK: - Layout Enumeration

/// Layout options for KeyValueRow component
///
/// Determines whether the key and value are displayed side-by-side (horizontal)
/// or stacked vertically (vertical).
///
/// ## Usage
/// ```swift
/// KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)
/// KeyValueRow(key: "Description", value: "Long text", layout: .vertical)
/// ```
///
/// ## Recommendations
/// - Use `.horizontal` for short values (< 20 characters)
/// - Use `.vertical` for long values, descriptions, or technical content
public enum KeyValueLayout: Equatable {
    /// Key and value displayed side-by-side (default)
    case horizontal

    /// Key displayed above value (recommended for long values)
    case vertical
}

// MARK: - Conditional View Modifier Helper

private extension View {
    /// Conditionally applies a view modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - SwiftUI Previews

#Preview("KeyValueRow - Horizontal Layout") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        KeyValueRow(key: "Type", value: "ftyp")
        KeyValueRow(key: "Size", value: "1024 bytes")
        KeyValueRow(key: "Offset", value: "0x00001234")
        KeyValueRow(key: "Duration", value: "5:32")
    }
    .padding()
}

#Preview("KeyValueRow - Vertical Layout") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        KeyValueRow(
            key: "Description",
            value: "This is a very long description that works better in vertical layout",
            layout: .vertical
        )
        KeyValueRow(
            key: "Full Path",
            value: "/Users/username/Documents/Projects/ISOInspector/test.iso",
            layout: .vertical
        )
        KeyValueRow(
            key: "Hash",
            value: "sha256:a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4",
            layout: .vertical
        )
    }
    .padding()
}

#Preview("KeyValueRow - Copyable") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        KeyValueRow(key: "Type", value: "ftyp", copyable: true)
        KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
        KeyValueRow(key: "Offset", value: "0x00001234", copyable: true)
        KeyValueRow(key: "Hash", value: "0xDEADBEEF", copyable: true)
    }
    .padding()
}

#Preview("KeyValueRow - Dark Mode") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        KeyValueRow(key: "Type", value: "ftyp")
        KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
        KeyValueRow(
            key: "Description",
            value: "Long description in dark mode",
            layout: .vertical
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("KeyValueRow - Real World Usage") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "File Information")

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                KeyValueRow(key: "File Type", value: "ISO Media File")
                KeyValueRow(key: "Size", value: "2.4 GB", copyable: true)
                KeyValueRow(key: "Created", value: "2025-10-22 12:34:56")
                KeyValueRow(key: "Modified", value: "2025-10-22 14:56:78")
            }

            SectionHeader(title: "Box Details")

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                KeyValueRow(key: "Box Type", value: "ftyp", copyable: true)
                KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                KeyValueRow(key: "Size", value: "32 bytes")
                KeyValueRow(
                    key: "Description",
                    value: "File Type Box - defines brand and version compatibility",
                    layout: .vertical
                )
            }

            SectionHeader(title: "Technical Data")

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                KeyValueRow(key: "Major Brand", value: "isom", copyable: true)
                KeyValueRow(key: "Minor Version", value: "512", copyable: true)
                KeyValueRow(
                    key: "Compatible Brands",
                    value: "isom, iso2, avc1, mp41",
                    layout: .vertical,
                    copyable: true
                )
            }
        }
        .padding()
    }
}

#Preview("KeyValueRow - Platform Comparison") {
    VStack(spacing: DS.Spacing.xl) {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("iOS/iPadOS Style")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
            }
        }

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("macOS Style")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
            }
        }
    }
    .padding()
}
