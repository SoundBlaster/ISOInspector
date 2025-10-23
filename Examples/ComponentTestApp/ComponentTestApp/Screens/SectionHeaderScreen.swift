/// SectionHeaderScreen - SectionHeader Component Showcase
///
/// Comprehensive demonstration of the SectionHeader component with all variations:
/// - With and without dividers
/// - Different spacing configurations
/// - Uppercase styling demonstration
/// - Accessibility heading levels
///
/// ## Component Features
/// - Uppercase title styling
/// - Optional divider support
/// - Consistent spacing via DS.Spacing tokens
/// - Accessibility heading level

import SwiftUI
import FoundationUI

struct SectionHeaderScreen: View {
    @State private var showDivider = true
    @State private var selectedSpacing: CGFloat = DS.Spacing.m

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Component Description
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("SectionHeader Component")
                        .font(DS.Typography.title)

                    Text("Displays section titles with optional dividers, uppercase styling, and accessibility support.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Controls
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Controls")
                        .font(DS.Typography.subheadline)

                    Toggle("Show Divider", isOn: $showDivider)

                    Picker("Spacing", selection: $selectedSpacing) {
                        Text("Small (8pt)").tag(DS.Spacing.s)
                        Text("Medium (12pt)").tag(DS.Spacing.m)
                        Text("Large (16pt)").tag(DS.Spacing.l)
                        Text("Extra Large (24pt)").tag(DS.Spacing.xl)
                    }
                }

                Divider()

                // Basic Examples
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Basic Section Headers")
                        .font(DS.Typography.subheadline)

                    SectionHeader(title: "General Information", showDivider: showDivider)
                    Text("This is the content under the section header.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Metadata", showDivider: showDivider)
                    Text("Additional metadata content goes here.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    CodeSnippetView(code: """
                        SectionHeader(
                            title: "General Information",
                            showDivider: \\(showDivider)
                        )
                        """)
                }

                Divider()

                // With and Without Dividers
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Divider Comparison")
                        .font(DS.Typography.subheadline)

                    Text("With Divider")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Box Structure", showDivider: true)
                    Text("Content below header with divider")
                        .font(DS.Typography.caption)

                    Text("Without Divider")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, DS.Spacing.m)

                    SectionHeader(title: "Box Structure", showDivider: false)
                    Text("Content below header without divider")
                        .font(DS.Typography.caption)
                }

                Divider()

                // Real-World Use Case
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Real-World Use Case")
                        .font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.l) {
                            SectionHeader(title: "File Information", showDivider: true)

                            KeyValueRow(key: "File Name", value: "sample.mp4")
                            KeyValueRow(key: "File Size", value: "1.2 MB")
                            KeyValueRow(key: "File Type", value: "video/mp4")

                            SectionHeader(title: "Box Details", showDivider: true)

                            KeyValueRow(key: "Box Type", value: "ftyp")
                            KeyValueRow(key: "Box Size", value: "32 bytes")
                            KeyValueRow(key: "Box Offset", value: "0x00000000")

                            SectionHeader(title: "Validation", showDivider: true)

                            HStack {
                                Badge(text: "Valid Structure", level: .success, showIcon: true)
                                Spacer()
                            }
                        }
                        .padding(DS.Spacing.l)
                    }

                    CodeSnippetView(code: """
                        Card {
                            SectionHeader(title: "File Information", showDivider: true)
                            KeyValueRow(key: "File Name", value: "sample.mp4")

                            SectionHeader(title: "Box Details", showDivider: true)
                            KeyValueRow(key: "Box Type", value: "ftyp")
                        }
                        """)
                }

                Divider()

                // Spacing Variations
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Spacing Variations")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: selectedSpacing) {
                        SectionHeader(title: "Section 1", showDivider: showDivider)
                        Text("Content with \(spacingLabel(selectedSpacing)) spacing")
                            .font(DS.Typography.caption)

                        SectionHeader(title: "Section 2", showDivider: showDivider)
                        Text("Content with \(spacingLabel(selectedSpacing)) spacing")
                            .font(DS.Typography.caption)
                    }
                }

                Divider()

                // Accessibility Features
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Accessibility Features")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• VoiceOver announces as heading (semantic role)")
                            .font(DS.Typography.caption)
                        Text("• Uppercase styling for visual consistency")
                            .font(DS.Typography.caption)
                        Text("• Consistent spacing with DS tokens")
                            .font(DS.Typography.caption)
                        Text("• Optional divider for visual separation")
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
                        SectionHeader(
                            title: String,
                            showDivider: Bool   // Default: true
                        )
                        """)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("SectionHeader Component")
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 600)
        #endif
    }

    private func spacingLabel(_ spacing: CGFloat) -> String {
        switch spacing {
        case DS.Spacing.s: return "small"
        case DS.Spacing.m: return "medium"
        case DS.Spacing.l: return "large"
        case DS.Spacing.xl: return "extra large"
        default: return "\(Int(spacing))pt"
        }
    }
}

// MARK: - Previews

#Preview("SectionHeader Screen") {
    NavigationStack {
        SectionHeaderScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        SectionHeaderScreen()
    }
    .preferredColorScheme(.dark)
}
