/// ContentView - Root Navigation View
///
/// Main navigation interface for the ComponentTestApp.
/// Provides access to all component showcase screens organized by category.
///
/// Categories:
/// - Design Tokens: Visual reference for spacing, colors, typography, etc.
/// - View Modifiers: Interactive examples of style modifiers
/// - Components: Individual component showcases (Badge, Card, KeyValueRow, SectionHeader)

import SwiftUI
import FoundationUI

/// Navigation destination for component screens
enum ScreenDestination: Hashable, Identifiable {
    case designTokens
    case modifiers
    case badge
    case card
    case keyValueRow
    case sectionHeader

    var id: Self { self }

    var title: String {
        switch self {
        case .designTokens:
            return "Design Tokens"
        case .modifiers:
            return "View Modifiers"
        case .badge:
            return "Badge Component"
        case .card:
            return "Card Component"
        case .keyValueRow:
            return "KeyValueRow Component"
        case .sectionHeader:
            return "SectionHeader Component"
        }
    }
}

struct ContentView: View {
    /// Current color scheme preference
    @AppStorage("colorScheme") private var isDarkMode = false

    /// Current Dynamic Type size
    @State private var dynamicTypeSize: DynamicTypeSize = .medium

    var body: some View {
        NavigationStack {
            List {
                // Design System Foundation
                Section("Foundation") {
                    NavigationLink(value: ScreenDestination.designTokens) {
                        Label("Design Tokens", systemImage: "paintpalette.fill")
                    }
                    NavigationLink(value: ScreenDestination.modifiers) {
                        Label("View Modifiers", systemImage: "wand.and.stars")
                    }
                }

                // Core Components
                Section("Components") {
                    NavigationLink(value: ScreenDestination.badge) {
                        Label("Badge", systemImage: "tag.fill")
                    }
                    NavigationLink(value: ScreenDestination.card) {
                        Label("Card", systemImage: "rectangle.fill")
                    }
                    NavigationLink(value: ScreenDestination.keyValueRow) {
                        Label("KeyValueRow", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: ScreenDestination.sectionHeader) {
                        Label("SectionHeader", systemImage: "text.justify.leading")
                    }
                }

                // App Controls
                Section("Controls") {
                    // Theme Toggle
                    HStack {
                        Label("Dark Mode", systemImage: "moon.fill")
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }

                    // Dynamic Type Size Indicator
                    HStack {
                        Label("Text Size", systemImage: "textformat.size")
                        Spacer()
                        Text(dynamicTypeSizeLabel(dynamicTypeSize))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("FoundationUI Components")
            .navigationDestination(for: ScreenDestination.self) { destination in
                destinationView(for: destination)
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }

    /// Returns the appropriate view for the given destination
    @ViewBuilder
    private func destinationView(for destination: ScreenDestination) -> some View {
        switch destination {
        case .designTokens:
            DesignTokensScreen()
        case .modifiers:
            ModifiersScreen()
        case .badge:
            BadgeScreen()
        case .card:
            CardScreen()
        case .keyValueRow:
            KeyValueRowScreen()
        case .sectionHeader:
            SectionHeaderScreen()
        }
    }

    /// Returns human-readable label for Dynamic Type size
    private func dynamicTypeSizeLabel(_ size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .xLarge: return "XL"
        case .xxLarge: return "XXL"
        case .xxxLarge: return "XXXL"
        case .accessibility1: return "A1"
        case .accessibility2: return "A2"
        case .accessibility3: return "A3"
        case .accessibility4: return "A4"
        case .accessibility5: return "A5"
        @unknown default: return "M"
        }
    }
}

#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
