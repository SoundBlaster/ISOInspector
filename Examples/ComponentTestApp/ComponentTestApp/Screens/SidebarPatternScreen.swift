/// SidebarPatternScreen - Showcase for SidebarPattern
///
/// Demonstrates the SidebarPattern component with component library navigation.
///
/// Features:
/// - NavigationSplitView with sidebar
/// - Multiple sections (Design Tokens, Modifiers, Components, Patterns)
/// - Selection state management
/// - Detail view showing selected item
/// - Keyboard navigation
/// - Collapse/expand sidebar (macOS)

import SwiftUI
import FoundationUI

struct SidebarPatternScreen: View {
    /// Currently selected item
    @State private var selectedItem: ComponentLibraryItem?

    /// Sample component library data
    private let libraryItems: [ComponentLibrarySection] = [
        ComponentLibrarySection(
            title: "Design Tokens",
            items: [
                ComponentLibraryItem(
                    id: "spacing",
                    title: "Spacing",
                    description: "Consistent spacing values (s, m, l, xl)",
                    icon: "arrow.left.and.right"
                ),
                ComponentLibraryItem(
                    id: "colors",
                    title: "Colors",
                    description: "Semantic color palette with Dark Mode support",
                    icon: "paintpalette.fill"
                ),
                ComponentLibraryItem(
                    id: "typography",
                    title: "Typography",
                    description: "Font styles with Dynamic Type support",
                    icon: "textformat"
                ),
                ComponentLibraryItem(
                    id: "radius",
                    title: "Radius",
                    description: "Corner radius values for different components",
                    icon: "circle.grid.cross"
                ),
                ComponentLibraryItem(
                    id: "animation",
                    title: "Animation",
                    description: "Standard animation durations and curves",
                    icon: "waveform.path"
                )
            ]
        ),
        ComponentLibrarySection(
            title: "View Modifiers",
            items: [
                ComponentLibraryItem(
                    id: "badgeChipStyle",
                    title: "BadgeChipStyle",
                    description: "Badge and chip styling modifier",
                    icon: "tag.fill"
                ),
                ComponentLibraryItem(
                    id: "cardStyle",
                    title: "CardStyle",
                    description: "Card container styling with elevation",
                    icon: "rectangle.fill"
                ),
                ComponentLibraryItem(
                    id: "interactiveStyle",
                    title: "InteractiveStyle",
                    description: "Interactive element styling (hover, press)",
                    icon: "hand.tap.fill"
                ),
                ComponentLibraryItem(
                    id: "surfaceStyle",
                    title: "SurfaceStyle",
                    description: "Surface material backgrounds",
                    icon: "square.3.layers.3d"
                )
            ]
        ),
        ComponentLibrarySection(
            title: "Components",
            items: [
                ComponentLibraryItem(
                    id: "badge",
                    title: "Badge",
                    description: "Status and label badges",
                    icon: "tag.fill"
                ),
                ComponentLibraryItem(
                    id: "card",
                    title: "Card",
                    description: "Container component with elevation",
                    icon: "rectangle.fill"
                ),
                ComponentLibraryItem(
                    id: "keyValueRow",
                    title: "KeyValueRow",
                    description: "Key-value pair display with copy support",
                    icon: "list.bullet.rectangle"
                ),
                ComponentLibraryItem(
                    id: "sectionHeader",
                    title: "SectionHeader",
                    description: "Section titles with optional dividers",
                    icon: "text.justify.leading"
                ),
                ComponentLibraryItem(
                    id: "copyableText",
                    title: "CopyableText",
                    description: "Text with clipboard copy functionality",
                    icon: "doc.on.doc"
                )
            ]
        ),
        ComponentLibrarySection(
            title: "Patterns",
            items: [
                ComponentLibraryItem(
                    id: "inspector",
                    title: "InspectorPattern",
                    description: "Scrollable inspector with sections",
                    icon: "sidebar.right"
                ),
                ComponentLibraryItem(
                    id: "sidebar",
                    title: "SidebarPattern",
                    description: "Navigation sidebar with sections",
                    icon: "sidebar.left"
                ),
                ComponentLibraryItem(
                    id: "toolbar",
                    title: "ToolbarPattern",
                    description: "Platform-adaptive toolbar",
                    icon: "menubar.rectangle"
                ),
                ComponentLibraryItem(
                    id: "boxTree",
                    title: "BoxTreePattern",
                    description: "Hierarchical tree view",
                    icon: "list.tree"
                )
            ]
        )
    ]

    var body: some View {
        SidebarPattern(
            sections: libraryItems,
            selection: $selectedItem
        ) { item in
            // Detail view
            ComponentDetailView(item: item)
        }
        .navigationTitle("SidebarPattern")
    }
}

// MARK: - Supporting Types

/// Component library section
struct ComponentLibrarySection: Identifiable {
    let id = UUID()
    let title: String
    let items: [ComponentLibraryItem]
}

/// Component library item
struct ComponentLibraryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

// MARK: - Component Detail View

struct ComponentDetailView: View {
    let item: ComponentLibraryItem

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 64))
                .foregroundStyle(DS.Colors.accent)
                .padding(.top, DS.Spacing.xl)

            // Title
            Text(item.title)
                .font(DS.Typography.title)
                .fontWeight(.semibold)

            // Description
            Text(item.description)
                .font(DS.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)

            // Metadata Card
            Card(elevation: .low, cornerRadius: DS.Radius.card) {
                VStack(spacing: DS.Spacing.m) {
                    SectionHeader(title: "Details", showDivider: false)

                    KeyValueRow(
                        key: "Component ID",
                        value: item.id,
                        isCopyable: true
                    )

                    KeyValueRow(
                        key: "Type",
                        value: componentType(for: item.id),
                        isCopyable: false
                    )

                    KeyValueRow(
                        key: "Layer",
                        value: componentLayer(for: item.id),
                        isCopyable: false
                    )
                }
                .padding(DS.Spacing.l)
            }
            .padding(.horizontal, DS.Spacing.l)

            Spacer()

            // Usage Hint
            Text("Select items from the sidebar to view details")
                .font(DS.Typography.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, DS.Spacing.l)
        }
        .frame(maxWidth: .infinity)
    }

    private func componentType(for id: String) -> String {
        if libraryItemIsIn(id, section: "Design Tokens") {
            return "Design Token"
        } else if libraryItemIsIn(id, section: "View Modifiers") {
            return "View Modifier"
        } else if libraryItemIsIn(id, section: "Components") {
            return "Component"
        } else if libraryItemIsIn(id, section: "Patterns") {
            return "Pattern"
        }
        return "Unknown"
    }

    private func componentLayer(for id: String) -> String {
        if libraryItemIsIn(id, section: "Design Tokens") {
            return "Layer 0 (Foundation)"
        } else if libraryItemIsIn(id, section: "View Modifiers") {
            return "Layer 1 (Modifiers)"
        } else if libraryItemIsIn(id, section: "Components") {
            return "Layer 2 (Components)"
        } else if libraryItemIsIn(id, section: "Patterns") {
            return "Layer 3 (Patterns)"
        }
        return "Unknown"
    }

    private func libraryItemIsIn(_ id: String, section: String) -> Bool {
        // Simple check based on ID prefixes
        switch section {
        case "Design Tokens":
            return ["spacing", "colors", "typography", "radius", "animation"].contains(id)
        case "View Modifiers":
            return id.hasSuffix("Style")
        case "Components":
            return ["badge", "card", "keyValueRow", "sectionHeader", "copyableText"].contains(id)
        case "Patterns":
            return ["inspector", "sidebar", "toolbar", "boxTree"].contains(id)
        default:
            return false
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    NavigationStack {
        SidebarPatternScreen()
            .preferredColorScheme(.light)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        SidebarPatternScreen()
            .preferredColorScheme(.dark)
    }
}

#Preview("With Selection") {
    struct PreviewWrapper: View {
        @State private var selection: ComponentLibraryItem? = ComponentLibraryItem(
            id: "badge",
            title: "Badge",
            description: "Status and label badges",
            icon: "tag.fill"
        )

        var body: some View {
            NavigationStack {
                SidebarPatternScreen()
            }
        }
    }

    return PreviewWrapper()
}
