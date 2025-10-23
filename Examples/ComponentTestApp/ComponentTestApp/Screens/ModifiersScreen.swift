/// ModifiersScreen - Interactive View Modifiers Showcase
///
/// Demonstrates all FoundationUI view modifiers with interactive examples.
/// Shows side-by-side comparisons of different modifier variations.
///
/// ## Modifiers
/// - BadgeChipStyle: Style badges with semantic levels (info, warning, error, success)
/// - CardStyle: Apply elevation and corner radius to cards
/// - InteractiveStyle: Add hover/touch effects
/// - SurfaceStyle: Material-based backgrounds

import SwiftUI
import FoundationUI

struct ModifiersScreen: View {
    @State private var selectedBadgeLevel: BadgeLevel = .info
    @State private var selectedCardElevation: CardElevation = .medium
    @State private var isInteractive = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // BadgeChipStyle Modifier
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("BadgeChipStyle")
                        .font(DS.Typography.title)

                    Text("Applies semantic styling to badges and chips with level-based colors.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    // Badge level selector
                    Picker("Badge Level", selection: $selectedBadgeLevel) {
                        ForEach(BadgeLevel.allCases, id: \.self) { level in
                            Text(levelLabel(for: level))
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Badge examples
                    HStack(spacing: DS.Spacing.m) {
                        ForEach(BadgeLevel.allCases, id: \.self) { level in
                            Text(levelLabel(for: level))
                                .font(DS.Typography.label)
                                .textCase(.uppercase)
                                .badgeChipStyle(level: level)
                        }
                    }

                    // Code snippet
                    CodeSnippetView(code: """
                        Text("\\(levelLabel(for: selectedBadgeLevel))")
                            .badgeChipStyle(level: .\\(levelLabel(for: selectedBadgeLevel).lowercased()))
                        """)
                }

                Divider()

                // CardStyle Modifier
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("CardStyle")
                        .font(DS.Typography.title)

                    Text("Applies elevation levels and corner radius to card-like containers.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    // Elevation selector
                    Picker("Elevation", selection: $selectedCardElevation) {
                        ForEach(CardElevation.allCases, id: \.self) { elevation in
                            Text(elevationLabel(for: elevation))
                                .tag(elevation)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Card examples
                    HStack(spacing: DS.Spacing.m) {
                        ForEach(CardElevation.allCases, id: \.self) { elevation in
                            VStack {
                                Text(elevationLabel(for: elevation))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(.secondary)

                                Text("Card")
                                    .font(DS.Typography.body)
                                    .padding(DS.Spacing.l)
                                    .cardStyle(elevation: elevation, cornerRadius: DS.Radius.card)
                            }
                        }
                    }

                    // Code snippet
                    CodeSnippetView(code: """
                        VStack {
                            Text("Content")
                        }
                        .cardStyle(
                            elevation: .\\(elevationLabel(for: selectedCardElevation).lowercased()),
                            cornerRadius: DS.Radius.card
                        )
                        """)
                }

                Divider()

                // InteractiveStyle Modifier
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("InteractiveStyle")
                        .font(DS.Typography.title)

                    Text("Adds hover effects (macOS) and touch feedback (iOS) to interactive elements.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    Toggle("Interactive", isOn: $isInteractive)
                        .padding(.vertical, DS.Spacing.s)

                    // Interactive examples
                    HStack(spacing: DS.Spacing.m) {
                        Text("Hover Me")
                            .font(DS.Typography.body)
                            .padding(DS.Spacing.l)
                            .background(DS.Color.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                            .interactiveStyle(isEnabled: isInteractive)

                        Text("Click Me")
                            .font(DS.Typography.body)
                            .padding(DS.Spacing.l)
                            .background(DS.Color.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                            .interactiveStyle(isEnabled: isInteractive)
                    }

                    // Code snippet
                    CodeSnippetView(code: """
                        Text("Interactive")
                            .padding(DS.Spacing.l)
                            .background(DS.Color.accent.opacity(0.1))
                            .interactiveStyle(isEnabled: \\(isInteractive))
                        """)
                }

                Divider()

                // SurfaceStyle Modifier
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("SurfaceStyle")
                        .font(DS.Typography.title)

                    Text("Applies material-based backgrounds with platform-adaptive appearance.")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)

                    // Surface examples
                    HStack(spacing: DS.Spacing.m) {
                        VStack {
                            Text("Thin")
                                .font(DS.Typography.caption)
                                .foregroundStyle(.secondary)

                            Text("Content")
                                .font(DS.Typography.body)
                                .padding(DS.Spacing.l)
                                .surfaceStyle(material: .thin)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                        }

                        VStack {
                            Text("Regular")
                                .font(DS.Typography.caption)
                                .foregroundStyle(.secondary)

                            Text("Content")
                                .font(DS.Typography.body)
                                .padding(DS.Spacing.l)
                                .surfaceStyle(material: .regular)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                        }

                        VStack {
                            Text("Thick")
                                .font(DS.Typography.caption)
                                .foregroundStyle(.secondary)

                            Text("Content")
                                .font(DS.Typography.body)
                                .padding(DS.Spacing.l)
                                .surfaceStyle(material: .thick)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                        }
                    }

                    // Code snippet
                    CodeSnippetView(code: """
                        Text("Content")
                            .surfaceStyle(material: .regular)
                        """)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("View Modifiers")
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 600)
        #endif
    }

    // MARK: - Helpers

    private func levelLabel(for level: BadgeLevel) -> String {
        switch level {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .success: return "Success"
        }
    }

    private func elevationLabel(for elevation: CardElevation) -> String {
        switch elevation {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - Code Snippet View

/// Displays a formatted code snippet
struct CodeSnippetView: View {
    let code: String

    var body: some View {
        Text(code)
            .font(DS.Typography.code)
            .padding(DS.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

// MARK: - Previews

#Preview("Modifiers Screen") {
    NavigationStack {
        ModifiersScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ModifiersScreen()
    }
    .preferredColorScheme(.dark)
}
