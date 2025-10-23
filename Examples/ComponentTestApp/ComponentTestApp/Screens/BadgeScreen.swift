/// BadgeScreen - Badge Component Showcase
///
/// Comprehensive demonstration of the Badge component with all variations:
/// - All badge levels (info, warning, error, success)
/// - With and without icons
/// - Different text lengths
/// - Accessibility features
///
/// ## Component Features
/// - Semantic color coding via BadgeLevel
/// - Optional SF Symbol icons
/// - Full VoiceOver support
/// - WCAG 2.1 AA contrast compliance

import SwiftUI
import FoundationUI

struct BadgeScreen: View {
    @State private var showIcons = true
    @State private var selectedLevel: BadgeLevel = .info

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Component Description
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Badge Component")
                        .font(DS.Typography.title)

                    Text("Displays status indicators with semantic color coding and optional icons. Fully accessible with VoiceOver labels.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Controls
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Controls")
                        .font(DS.Typography.subheadline)

                    Toggle("Show Icons", isOn: $showIcons)

                    Picker("Badge Level", selection: $selectedLevel) {
                        Text("Info").tag(BadgeLevel.info)
                        Text("Warning").tag(BadgeLevel.warning)
                        Text("Error").tag(BadgeLevel.error)
                        Text("Success").tag(BadgeLevel.success)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // All Badge Levels
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("All Badge Levels")
                        .font(DS.Typography.subheadline)

                    HStack(spacing: DS.Spacing.m) {
                        Badge(text: "Info", level: .info, showIcon: showIcons)
                        Badge(text: "Warning", level: .warning, showIcon: showIcons)
                        Badge(text: "Error", level: .error, showIcon: showIcons)
                        Badge(text: "Success", level: .success, showIcon: showIcons)
                    }

                    CodeSnippetView(code: """
                        Badge(text: "Info", level: .info, showIcon: \\(showIcons))
                        Badge(text: "Warning", level: .warning, showIcon: \\(showIcons))
                        Badge(text: "Error", level: .error, showIcon: \\(showIcons))
                        Badge(text: "Success", level: .success, showIcon: \\(showIcons))
                        """)
                }

                Divider()

                // Text Length Variations
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Text Length Variations")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Badge(text: "OK", level: selectedLevel, showIcon: showIcons)
                        Badge(text: "Processing", level: selectedLevel, showIcon: showIcons)
                        Badge(text: "Operation Complete", level: selectedLevel, showIcon: showIcons)
                    }

                    CodeSnippetView(code: """
                        Badge(text: "OK", level: .\\(levelString(selectedLevel)))
                        Badge(text: "Processing", level: .\\(levelString(selectedLevel)))
                        Badge(text: "Operation Complete", level: .\\(levelString(selectedLevel)))
                        """)
                }

                Divider()

                // Use Cases
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Common Use Cases")
                        .font(DS.Typography.subheadline)

                    // File Status
                    HStack(spacing: DS.Spacing.m) {
                        Text("File:")
                            .font(DS.Typography.body)
                        Badge(text: "Valid", level: .success, showIcon: true)
                    }

                    // Box Type
                    HStack(spacing: DS.Spacing.m) {
                        Text("Box Type:")
                            .font(DS.Typography.body)
                        Badge(text: "ftyp", level: .info, showIcon: false)
                    }

                    // Parsing Status
                    HStack(spacing: DS.Spacing.m) {
                        Text("Status:")
                            .font(DS.Typography.body)
                        Badge(text: "Incomplete", level: .warning, showIcon: true)
                    }

                    // Error Indicator
                    HStack(spacing: DS.Spacing.m) {
                        Text("Validation:")
                            .font(DS.Typography.body)
                        Badge(text: "Failed", level: .error, showIcon: true)
                    }
                }

                Divider()

                // Accessibility Features
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Accessibility")
                        .font(DS.Typography.subheadline)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• VoiceOver announces level (e.g., 'Info: File Valid')")
                            .font(DS.Typography.caption)
                        Text("• Contrast ratios ≥4.5:1 (WCAG 2.1 AA)")
                            .font(DS.Typography.caption)
                        Text("• Touch targets meet 44×44pt minimum")
                            .font(DS.Typography.caption)
                        Text("• Dynamic Type support (scales with system settings)")
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
                        Badge(
                            text: String,
                            level: BadgeLevel,  // .info, .warning, .error, .success
                            showIcon: Bool      // Default: false
                        )
                        """)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("Badge Component")
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }

    private func levelString(_ level: BadgeLevel) -> String {
        switch level {
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .success: return "success"
        }
    }
}

// MARK: - Previews

#Preview("Badge Screen") {
    NavigationStack {
        BadgeScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        BadgeScreen()
    }
    .preferredColorScheme(.dark)
}
