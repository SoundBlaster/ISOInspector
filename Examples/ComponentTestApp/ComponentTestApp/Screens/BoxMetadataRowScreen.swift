/// BoxMetadataRowScreen - BoxMetadataRow Component Showcase
///
/// Comprehensive demonstration of the BoxMetadataRow component with all variations:
/// - Horizontal and vertical layouts
/// - Copyable metadata examples
/// - ISO box metadata display
/// - Codec and track information
/// - File header details
/// - Real-world metadata scenarios
///
/// ## Component Features
/// - Display consistent metadata rows for ISO inspector
/// - Optional copyable text integration
/// - Automatic dark mode adaptation
/// - WCAG 2.1 AA accessibility compliance
/// - Flexible layouts for different content types

import SwiftUI
import FoundationUI
import ISOInspectorApp

struct BoxMetadataRowScreen: View {
    @State private var layout: KeyValueLayout = .horizontal
    @State private var isCopyable = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Component Description
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("BoxMetadataRow Component")
                        .font(DS.Typography.title)

                    Text("Wrapper around DS.KeyValueRow for consistent metadata display "
                        + "in ISOInspector, with copyable actions and dark mode support.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Controls
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Controls")
                        .font(DS.Typography.subheadline)

                    Picker("Layout", selection: $layout) {
                        Text("Horizontal").tag(KeyValueLayout.horizontal)
                        Text("Vertical").tag(KeyValueLayout.vertical)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Copyable Text", isOn: $isCopyable)
                }

                Divider()

                // Basic Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Basic Metadata Rows")
                        .font(DS.Typography.subheadline)

                    BoxMetadataRow(
                        label: "Box Type",
                        value: "ftyp",
                        layout: layout,
                        copyable: isCopyable
                    )

                    BoxMetadataRow(
                        label: "Size",
                        value: "32 bytes",
                        layout: layout,
                        copyable: isCopyable
                    )

                    BoxMetadataRow(
                        label: "Offset",
                        value: "0x00000000",
                        layout: layout,
                        copyable: isCopyable
                    )

                    CodeSnippetView(code: """
                        BoxMetadataRow(
                            label: "Box Type",
                            value: "ftyp",
                            layout: .\\(layout == .horizontal ? "horizontal" : "vertical"),
                            copyable: \\(isCopyable)
                        )
                        """)
                }

                Divider()

                // Long Text Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Long Text Handling")
                        .font(DS.Typography.subheadline)

                    BoxMetadataRow(
                        label: "Description",
                        value: "Very long description demonstrating text wrapping and layout "
                            + "adjustments for long content",
                        layout: layout,
                        copyable: isCopyable
                    )

                    BoxMetadataRow(
                        label: "Specification",
                        value: "ISO/IEC 14496-12:2022 – MP4 file format specification",
                        layout: layout,
                        copyable: isCopyable
                    )
                }

                Divider()

                // Layout Comparison
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Layout Comparison")
                        .font(DS.Typography.subheadline)

                    Text("Horizontal Layout")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)

                    BoxMetadataRow(label: "Type", value: "ftyp", layout: .horizontal)
                    BoxMetadataRow(label: "Size", value: "32 bytes", layout: .horizontal)

                    Text("Vertical Layout")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, DS.Spacing.m)

                    BoxMetadataRow(label: "Type", value: "ftyp", layout: .vertical)
                    BoxMetadataRow(label: "Size", value: "32 bytes", layout: .vertical)
                }

                Divider()

                // ISO Box Metadata Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("ISO Box Metadata")
                        .font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            SectionHeader(title: "ftyp Box Details", showDivider: false)

                            BoxMetadataRow(label: "Box Type", value: "ftyp", copyable: true)
                            BoxMetadataRow(label: "Size", value: "32 bytes", copyable: true)
                            BoxMetadataRow(label: "Offset", value: "0x00000000", copyable: true)
                            BoxMetadataRow(label: "Major Brand", value: "isom", copyable: true)
                            BoxMetadataRow(label: "Minor Version", value: "512", copyable: true)
                            BoxMetadataRow(
                                label: "Compatible Brands",
                                value: "isom, iso2, avc1, mp41",
                                layout: .vertical,
                                copyable: true
                            )

                            HStack {
                                Badge(text: "Valid", level: .success, showIcon: true)
                                Spacer()
                            }
                        }
                        .padding(DS.Spacing.l)
                    }
                }

                Divider()

                // Codec and Track Information
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Codec & Track Information")
                        .font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            SectionHeader(title: "Video Track", showDivider: false)

                            BoxMetadataRow(label: "Codec", value: "avc1", copyable: true)
                            BoxMetadataRow(label: "Resolution", value: "1920 x 1080", copyable: false)
                            BoxMetadataRow(label: "Frame Rate", value: "29.97 fps", copyable: false)
                            BoxMetadataRow(label: "Bit Rate", value: "5000 kbps", copyable: false)

                            HStack {
                                Badge(text: "H.264", level: .info)
                                Spacer()
                            }
                        }
                        .padding(DS.Spacing.l)
                    }
                }

                Divider()

                // File Header Details
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("File Header Details")
                        .font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            SectionHeader(title: "File Information", showDivider: false)

                            BoxMetadataRow(label: "File Type", value: "ISO Media File", copyable: false)
                            BoxMetadataRow(label: "File Size", value: "2.4 GB", copyable: true)
                            BoxMetadataRow(label: "Created", value: "2025-10-22 12:34:56", copyable: false)
                            BoxMetadataRow(label: "Modified", value: "2025-10-22 14:56:78", copyable: false)

                            HStack {
                                Badge(text: "Complete", level: .success, showIcon: true)
                                Spacer()
                            }
                        }
                        .padding(DS.Spacing.l)
                    }
                }

                Divider()

                // Copyable Feature
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Copyable Text Feature")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• Click value to copy to clipboard")
                            .font(DS.Typography.caption)
                        Text("• Visual feedback on copy (checkmark animation)")
                            .font(DS.Typography.caption)
                        Text("• Platform-specific clipboard handling (macOS/iOS)")
                            .font(DS.Typography.caption)
                        Text("• VoiceOver announces copy status")
                            .font(DS.Typography.caption)
                        Text("• Keyboard shortcut: ⌘C (macOS)")
                            .font(DS.Typography.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Divider()

                // Dark Mode Support
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Dark Mode Support")
                        .font(DS.Typography.subheadline)

                    Text("BoxMetadataRow automatically inherits dark mode adaptation "
                        + "from FoundationUI's Design System tokens.")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            BoxMetadataRow(label: "Current Mode", value: "Automatic", copyable: false)
                            BoxMetadataRow(label: "Color Scheme", value: "System", copyable: false)
                        }
                        .padding(DS.Spacing.l)
                    }
                }

                Divider()

                // Accessibility
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Accessibility Features")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• WCAG 2.1 AA compliant")
                            .font(DS.Typography.caption)
                        Text("• VoiceOver support with combined labels")
                            .font(DS.Typography.caption)
                        Text("• Dynamic Type text scaling (XS–XXXL)")
                            .font(DS.Typography.caption)
                        Text("• High contrast mode support")
                            .font(DS.Typography.caption)
                        Text("• Reduce Motion compatibility")
                            .font(DS.Typography.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Divider()

                // Component API
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Component API")
                        .font(DS.Typography.subheadline)

                    CodeSnippetView(code: """
                        BoxMetadataRow(
                            label: String,
                            value: String,
                            layout: KeyValueLayout,     // .horizontal, .vertical
                            copyable: Bool              // Default: false
                        )
                        """)
                }

                // Component Structure
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Component Structure")
                        .font(DS.Typography.subheadline)

                    CodeSnippetView(code: """
                        // Wrapper around DS.KeyValueRow
                        public struct BoxMetadataRow: View {
                            public let label: String
                            public let value: String
                            public let layout: KeyValueLayout
                            public let copyable: Bool
                        }
                        """)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("BoxMetadataRow Component")
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 600)
        #endif
    }
}

// MARK: - Previews

#Preview("BoxMetadataRow Screen") {
    NavigationStack {
        BoxMetadataRowScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        BoxMetadataRowScreen()
    }
    .preferredColorScheme(.dark)
}
