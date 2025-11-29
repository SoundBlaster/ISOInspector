/// UtilitiesScreen - Utilities Showcase
///
/// Demonstrates all FoundationUI utility components:
/// - CopyableText: Platform-specific clipboard integration with visual feedback
/// - Copyable wrapper: Generic copyable functionality for any view
/// - KeyboardShortcuts: Platform-adaptive keyboard shortcut display
/// - AccessibilityHelpers: Accessibility utilities and validators
///
/// This screen serves as both a reference guide and testing environment
/// for utility components and helper functions.

import FoundationUI
import SwiftUI

/// Utilities showcase screen
struct UtilitiesScreen: View {
    // MARK: - State

    /// Show clipboard feedback
    @State private var showCopiedFeedback: Bool = false

    /// Copied text
    @State private var copiedText: String = ""

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Header
                headerView

                Divider()

                // CopyableText Demo
                copyableTextSection

                Divider()

                // Copyable Wrapper Demo
                copyableWrapperSection

                Divider()

                // KeyboardShortcuts Demo
                keyboardShortcutsSection

                Divider()

                // AccessibilityHelpers Demo
                accessibilityHelpersSection
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("Utilities")
        .alert("Copied!", isPresented: $showCopiedFeedback) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Copied '\(copiedText)' to clipboard")
        }
    }
}

extension UtilitiesScreen {

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Utilities")
                .font(DS.Typography.title)
                .foregroundColor(DS.Colors.textPrimary)

            Text("FoundationUI provides powerful utilities for common UI tasks: clipboard operations, keyboard shortcuts, and accessibility helpers.")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
    }
}

extension UtilitiesScreen {

    // MARK: - CopyableText Section

    private var copyableTextSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "CopyableText", showDivider: true)

            Text("Platform-specific clipboard integration with visual feedback. Click to copy:")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)

            // Examples
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Hex value example
                HStack {
                    Text("Hex Value:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    CopyableText(text: "0xDEADBEEF", label: "0xDEADBEEF")
                        .font(DS.Typography.code)
                }

                // File path example
                HStack {
                    Text("File Path:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    CopyableText(
                        text: "/Users/developer/Documents/sample.mp4",
                        label: "/Users/developer/Documents/sample.mp4"
                    )
                    .font(DS.Typography.code)
                }

                // UUID example
                HStack {
                    Text("UUID:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    CopyableText(
                        text: "550e8400-e29b-41d4-a716-446655440000",
                        label: "550e8400-e29b-41d4-a716-446655440000"
                    )
                    .font(DS.Typography.code)
                }

                // JSON example
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("JSON Data:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    CopyableText(
                        text: """
                        {
                          "name": "ISO Inspector",
                          "version": "1.0.0",
                          "platform": "iOS/macOS"
                        }
                        """,
                        label: """
                        {
                          "name": "ISO Inspector",
                          "version": "1.0.0",
                          "platform": "iOS/macOS"
                        }
                        """
                    )
                    .font(DS.Typography.code)
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.tertiary)
                    .cornerRadius(DS.Radius.small)
                }
            }
            .padding(.horizontal, DS.Spacing.m)
        }
    }
}

extension UtilitiesScreen {

    // MARK: - Copyable Wrapper Section

    private var copyableWrapperSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "Copyable Wrapper", showDivider: true)

            Text("Wrap any view with copyable functionality:")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Badge with copyable wrapper
                HStack {
                    Text("Badge:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    Copyable(text: "ftyp") {
                        Badge(text: "ftyp", level: .info, showIcon: false)
                    }
                }

                // Card with copyable wrapper
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Card (click to copy title):")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    Copyable(text: "Movie Box (moov)") {
                        Card(elevation: .medium, cornerRadius: DS.Radius.medium) {
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                Text("Movie Box (moov)")
                                    .font(DS.Typography.headline)

                                Text("Container for all metadata")
                                    .font(DS.Typography.caption)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            .padding(DS.Spacing.m)
                        }
                    }
                }

                // KeyValueRow with copyable wrapper
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("KeyValueRow (click to copy value):")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    Copyable(text: "1920x1080") {
                        KeyValueRow(key: "Resolution", value: "1920x1080")
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.m)
        }
    }
}

extension UtilitiesScreen {

    // MARK: - KeyboardShortcuts Section

    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "Keyboard Shortcuts", showDivider: true)

            Text("Platform-adaptive keyboard shortcut display (⌘ on macOS, Ctrl elsewhere):")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Standard shortcuts
                Group {
                    shortcutRow(action: "Copy", shortcut: "⌘C")
                    shortcutRow(action: "Paste", shortcut: "⌘V")
                    shortcutRow(action: "Cut", shortcut: "⌘X")
                    shortcutRow(action: "Select All", shortcut: "⌘A")
                }

                Divider()

                // Application shortcuts
                Group {
                    shortcutRow(action: "Save", shortcut: "⌘S")
                    shortcutRow(action: "Open", shortcut: "⌘O")
                    shortcutRow(action: "New", shortcut: "⌘N")
                    shortcutRow(action: "Close", shortcut: "⌘W")
                }

                Divider()

                // Custom shortcuts
                Group {
                    shortcutRow(action: "Refresh", shortcut: "⌘R")
                    shortcutRow(action: "Export", shortcut: "⌘E")
                    shortcutRow(action: "Find", shortcut: "⌘F")
                }
            }
            .padding(.horizontal, DS.Spacing.m)
        }
    }
}

extension UtilitiesScreen {

    // MARK: - AccessibilityHelpers Section

    private var accessibilityHelpersSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "Accessibility Helpers", showDivider: true)

            Text("Tools for ensuring WCAG 2.1 compliance:")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Contrast ratio validation
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Contrast Ratio Validation:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    contrastValidatorView
                }

                Divider()

                // Touch target validation
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Touch Target Validation:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    Text("Minimum touch target: 44×44 pt (iOS HIG)")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)

                    HStack(spacing: DS.Spacing.l) {
                        // Valid touch target
                        VStack(spacing: DS.Spacing.s) {
                            Button("Valid") {}
                                .frame(width: 44, height: 44)
                                .background(DS.Colors.successBG)
                                .cornerRadius(DS.Radius.small)

                            Text("44×44 pt ✓")
                                .font(DS.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                        }

                        // Invalid touch target
                        VStack(spacing: DS.Spacing.s) {
                            Button("Too Small") {}
                                .frame(width: 30, height: 30)
                                .background(DS.Colors.errorBG)
                                .cornerRadius(DS.Radius.small)

                            Text("30×30 pt ✗")
                                .font(DS.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                    }
                }

                Divider()

                // VoiceOver labels
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("VoiceOver Labels:")
                        .font(DS.Typography.label)
                        .foregroundColor(DS.Colors.textSecondary)

                    Text("All interactive elements have accessibility labels")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)

                    HStack(spacing: DS.Spacing.m) {
                        Button(action: {}) {
                            Image(systemName: "play.fill")
                        }
                        .accessibilityLabel("Play")

                        Button(action: {}) {
                            Image(systemName: "pause.fill")
                        }
                        .accessibilityLabel("Pause")

                        Button(action: {}) {
                            Image(systemName: "stop.fill")
                        }
                        .accessibilityLabel("Stop")
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.m)
        }
    }
}

extension UtilitiesScreen {

    // MARK: - Contrast Validator View

    private var contrastValidatorView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            // DS Color examples with contrast ratios
            contrastExample(
                name: "Info Background",
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.infoBG,
                expectedRatio: "≥4.5:1"
            )

            contrastExample(
                name: "Warning Background",
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.warnBG,
                expectedRatio: "≥4.5:1"
            )

            contrastExample(
                name: "Error Background",
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.errorBG,
                expectedRatio: "≥4.5:1"
            )

            contrastExample(
                name: "Success Background",
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.successBG,
                expectedRatio: "≥4.5:1"
            )
        }
    }
}

extension UtilitiesScreen {

    // MARK: - Helper Views

    private func shortcutRow(action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()

            Text(shortcut)
                .font(DS.Typography.code)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.s)
                .background(DS.Colors.tertiary)
                .cornerRadius(DS.Radius.small)
        }
    }

    private func contrastExample(
        name: String,
        foreground: Color,
        background: Color,
        expectedRatio: String
    ) -> some View {
        HStack {
            Text(name)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()

            Text("Sample")
                .font(DS.Typography.body)
                .foregroundColor(foreground)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.s)
                .background(background)
                .cornerRadius(DS.Radius.small)

            Text(expectedRatio)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.successBG)
        }
    }
}

// MARK: - Previews

#Preview("Utilities - Light") {
    NavigationStack {
        UtilitiesScreen()
    }
    .preferredColorScheme(.light)
}

#Preview("Utilities - Dark") {
    NavigationStack {
        UtilitiesScreen()
    }
    .preferredColorScheme(.dark)
}
