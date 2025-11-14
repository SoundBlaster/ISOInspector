/// ContentView - Root Navigation View
///
/// Main navigation interface for the ComponentTestApp.
/// Provides access to all component showcase screens organized by category.
///
/// Categories:
/// - Design Tokens: Visual reference for spacing, colors, typography, etc.
/// - View Modifiers: Interactive examples of style modifiers
/// - Components: Individual component showcases (Badge, Card, KeyValueRow, SectionHeader)

import FoundationUI
import SwiftUI

/// Navigation destination for component screens
enum ScreenDestination: Hashable, Identifiable {
    case designTokens
    case modifiers
    case badge
    case indicator
    case card
    case keyValueRow
    case boxMetadataRow
    case sectionHeader
    case inspectorPattern
    case sidebarPattern
    case toolbarPattern
    case boxTreePattern
    case isoInspectorDemo
    case utilities
    case accessibilityTesting
    case performanceMonitoring

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
        case .indicator:
            return "Indicator Component"
        case .keyValueRow:
            return "KeyValueRow Component"
        case .boxMetadataRow:
            return "BoxMetadataRow Component"
        case .sectionHeader:
            return "SectionHeader Component"
        case .inspectorPattern:
            return "InspectorPattern"
        case .sidebarPattern:
            return "SidebarPattern"
        case .toolbarPattern:
            return "ToolbarPattern"
        case .boxTreePattern:
            return "BoxTreePattern"
        case .isoInspectorDemo:
            return "ISO Inspector Demo"
        case .utilities:
            return "Utilities"
        case .accessibilityTesting:
            return "Accessibility Testing"
        case .performanceMonitoring:
            return "Performance Monitoring"
        }
    }
}

struct ContentView: View {
    /// Current color scheme preference
    @AppStorage("themePreference") private var themePreference: ThemePreference = .system

    /// Whether to override system Dynamic Type with custom setting
    @AppStorage("overrideSystemDynamicType") private var overrideSystemDynamicType: Bool = true

    /// Current Dynamic Type size preference (used when override is enabled)
    @AppStorage("dynamicTypeSizePreference") private var dynamicTypeSizePreference:
        DynamicTypeSizePreference = .medium

    /// System color scheme (for detecting actual system appearance)
    @Environment(\.colorScheme) private var systemColorScheme

    /// Current system Dynamic Type size (for display purposes)
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    /// Computed color scheme based on preference
    private var effectiveColorScheme: ColorScheme? {
        switch themePreference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// ID for forcing view refresh - includes system theme when in system mode
    private var viewID: String {
        switch themePreference {
        case .system:
            return "system-\(systemColorScheme == .dark ? "dark" : "light")"
        case .light:
            return "light"
        case .dark:
            return "dark"
        }
    }

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
                    NavigationLink(value: ScreenDestination.indicator) {
                        Label("Indicator", systemImage: "circle.inset.filled")
                    }
                    NavigationLink(value: ScreenDestination.card) {
                        Label("Card", systemImage: "rectangle.fill")
                    }
                    NavigationLink(value: ScreenDestination.keyValueRow) {
                        Label("KeyValueRow", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: ScreenDestination.boxMetadataRow) {
                        Label("BoxMetadataRow", systemImage: "list.bullet.rectangle.fill")
                    }
                    NavigationLink(value: ScreenDestination.sectionHeader) {
                        Label("SectionHeader", systemImage: "text.justify.leading")
                    }
                }

                // UI Patterns
                Section("Patterns") {
                    NavigationLink(value: ScreenDestination.inspectorPattern) {
                        Label("InspectorPattern", systemImage: "sidebar.right")
                    }
                    NavigationLink(value: ScreenDestination.sidebarPattern) {
                        Label("SidebarPattern", systemImage: "sidebar.left")
                    }
                    NavigationLink(value: ScreenDestination.toolbarPattern) {
                        Label("ToolbarPattern", systemImage: "menubar.rectangle")
                    }
                    NavigationLink(value: ScreenDestination.boxTreePattern) {
                        Label("BoxTreePattern", systemImage: "list.bullet.indent")
                    }
                }

                // Demo
                Section("Demo") {
                    NavigationLink(value: ScreenDestination.isoInspectorDemo) {
                        Label("ISO Inspector Demo", systemImage: "doc.text.magnifyingglass")
                    }
                }

                // Utilities
                Section("Utilities") {
                    NavigationLink(value: ScreenDestination.utilities) {
                        Label("Utilities", systemImage: "wrench.and.screwdriver.fill")
                    }
                }

                // Testing
                Section("Testing") {
                    NavigationLink(value: ScreenDestination.accessibilityTesting) {
                        Label("Accessibility Testing", systemImage: "person.fill.checkmark")
                    }
                    NavigationLink(value: ScreenDestination.performanceMonitoring) {
                        Label("Performance Monitoring", systemImage: "chart.xyaxis.line")
                    }
                }

                // App Controls
                Section("Controls") {
                    // Theme Picker
                    Picker(selection: $themePreference) {
                        Label("System", systemImage: "circle.lefthalf.filled")
                            .tag(ThemePreference.system)
                        Label("Light", systemImage: "sun.max.fill")
                            .tag(ThemePreference.light)
                        Label("Dark", systemImage: "moon.fill")
                            .tag(ThemePreference.dark)
                    } label: {
                        Label("Theme", systemImage: "paintbrush.fill")
                    }
                }
            }
            .navigationTitle("FoundationUI Components")
            .navigationDestination(for: ScreenDestination.self) { destination in
                destinationView(for: destination)
            }
            .preferredColorScheme(effectiveColorScheme)
        }
        .if(overrideSystemDynamicType) { view in
            view.dynamicTypeSize(dynamicTypeSizePreference.dynamicTypeSize)
        }
        .id(viewID)
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
        case .indicator:
            IndicatorScreen()
        case .card:
            CardScreen()
        case .keyValueRow:
            KeyValueRowScreen()
        case .boxMetadataRow:
            BoxMetadataRowScreen()
        case .sectionHeader:
            SectionHeaderScreen()
        case .inspectorPattern:
            InspectorPatternScreen()
        case .sidebarPattern:
            SidebarPatternScreen()
        case .toolbarPattern:
            ToolbarPatternScreen()
        case .boxTreePattern:
            BoxTreePatternScreen()
        case .isoInspectorDemo:
            ISOInspectorDemoScreen()
        case .utilities:
            UtilitiesScreen()
        case .accessibilityTesting:
            AccessibilityTestingScreen()
        case .performanceMonitoring:
            PerformanceMonitoringScreen()
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

// MARK: - View Extensions

extension View {
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
