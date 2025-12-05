/// KeyValueRowScreen - KeyValueRow Component Showcase
///
/// Comprehensive demonstration of the KeyValueRow component with all variations:
/// - Horizontal and vertical layouts
/// - Copyable text examples
/// - Long keys and values
/// - Monospaced value display
/// - Platform-specific clipboard handling
///
/// ## Component Features
/// - Display key-value pairs with semantic styling
/// - Optional copyable text integration
/// - Monospaced font for values
/// - Platform-specific clipboard

import FoundationUI
import SwiftUI

struct KeyValueRowScreen: View {
    @State private var layout: KeyValueLayout = .horizontal
    @State private var isCopyable = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Component Description
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("KeyValueRow Component").font(DS.Typography.title)

                    Text(
                        "Displays key-value pairs with optional copyable text, monospaced values, and flexible layouts."
                    ).font(DS.Typography.body).foregroundStyle(.secondary)
                }

                Divider()

                // Controls
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Controls").font(DS.Typography.subheadline)

                    Picker("Layout", selection: $layout) {
                        Text("Horizontal").tag(KeyValueLayout.horizontal)
                        Text("Vertical").tag(KeyValueLayout.vertical)
                    }.pickerStyle(.segmented)

                    Toggle("Copyable Text", isOn: $isCopyable)
                }

                Divider()

                // Basic Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Basic Key-Value Pairs").font(DS.Typography.subheadline)

                    KeyValueRow(
                        key: "Box Type", value: "ftyp", layout: layout, copyable: isCopyable)

                    KeyValueRow(
                        key: "Size", value: "32 bytes", layout: layout, copyable: isCopyable)

                    KeyValueRow(
                        key: "Offset", value: "0x00000000", layout: layout, copyable: isCopyable)

                    CodeSnippetView(
                        code: """
                            KeyValueRow(
                                key: "Box Type",
                                value: "ftyp",
                                layout: .\\(layout == .horizontal ? "horizontal" : "vertical"),
                                copyable: \\(isCopyable)
                            )
                            """)
                }

                Divider()

                // Long Text Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Long Text Handling").font(DS.Typography.subheadline)

                    KeyValueRow(
                        key: "Description",
                        value:
                            "This is a very long description that demonstrates how the component handles text wrapping and layout adjustments.",
                        layout: layout, copyable: isCopyable)

                    KeyValueRow(
                        key: "Hex Data",
                        value: "0x00 0x00 0x00 0x20 0x66 0x74 0x79 0x70 0x69 0x73 0x6F 0x6D",
                        layout: layout, copyable: isCopyable)
                }

                Divider()

                // Layout Comparison
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Layout Comparison").font(DS.Typography.subheadline)

                    Text("Horizontal Layout").font(DS.Typography.caption).foregroundStyle(
                        .secondary)

                    KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)
                    KeyValueRow(key: "Size", value: "32 bytes", layout: .horizontal)

                    Text("Vertical Layout").font(DS.Typography.caption).foregroundStyle(.secondary)
                        .padding(.top, DS.Spacing.m)

                    KeyValueRow(key: "Type", value: "ftyp", layout: .vertical)
                    KeyValueRow(key: "Size", value: "32 bytes", layout: .vertical)
                }

                Divider()

                // Real-World Use Cases
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Real-World Use Cases").font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            SectionHeader(title: "ISO Box Metadata", showDivider: false)

                            KeyValueRow(key: "Box Type", value: "ftyp", copyable: true)
                            KeyValueRow(key: "Size", value: "32 bytes", copyable: false)
                            KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                            KeyValueRow(key: "Major Brand", value: "isom", copyable: true)
                            KeyValueRow(key: "Minor Version", value: "512", copyable: false)

                            HStack {
                                Badge(text: "Valid", level: .success, showIcon: true)
                                Spacer()
                            }
                        }.padding(DS.Spacing.l)
                    }
                }

                Divider()

                // Copyable Text Feature
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Copyable Text Feature").font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• Click value to copy to clipboard").font(DS.Typography.caption)
                        Text("• Visual feedback on copy (animation)").font(DS.Typography.caption)
                        Text("• Platform-specific clipboard handling").font(DS.Typography.caption)
                        Text("• VoiceOver announces 'Copied'").font(DS.Typography.caption)
                    }.foregroundStyle(.secondary)
                }

                Divider()

                // Component API
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Component API").font(DS.Typography.subheadline)

                    CodeSnippetView(
                        code: """
                            KeyValueRow(
                                key: String,
                                value: String,
                                layout: KeyValueLayout,     // .horizontal, .vertical
                                copyable: Bool              // Default: false
                            )
                            """)
                }
            }.padding(DS.Spacing.l)
        }.navigationTitle("KeyValueRow Component")
        #if os(macOS)
            .frame(minWidth: 700, minHeight: 600)
            #endif
    }
}

// MARK: - Previews

#Preview("KeyValueRow Screen") { NavigationStack { KeyValueRowScreen() } }

#Preview("Dark Mode") { NavigationStack { KeyValueRowScreen() }.preferredColorScheme(.dark) }
