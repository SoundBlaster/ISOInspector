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
    /// Currently selected item ID
    @State private var selectedItemID: String?
    
    /// Sample component library data using SidebarPattern types
    private let libraryItems: [SidebarPattern<String, AnyView>.Section] = [
        SidebarPattern.Section(
            title: "Design Tokens",
            items: [
                SidebarPattern.Item(
                    id: "spacing",
                    title: "Spacing",
                    iconSystemName: "arrow.left.and.right"
                ),
                SidebarPattern.Item(
                    id: "colors",
                    title: "Colors",
                    iconSystemName: "paintpalette.fill"
                ),
                SidebarPattern.Item(
                    id: "typography",
                    title: "Typography",
                    iconSystemName: "textformat"
                ),
                SidebarPattern.Item(
                    id: "radius",
                    title: "Radius",
                    iconSystemName: "circle.grid.cross"
                ),
                SidebarPattern.Item(
                    id: "animation",
                    title: "Animation",
                    iconSystemName: "waveform.path"
                )
            ]
        ),
        SidebarPattern.Section(
            title: "View Modifiers",
            items: [
                SidebarPattern.Item(
                    id: "badgeChipStyle",
                    title: "BadgeChipStyle",
                    iconSystemName: "tag.fill"
                ),
                SidebarPattern.Item(
                    id: "cardStyle",
                    title: "CardStyle",
                    iconSystemName: "rectangle.fill"
                ),
                SidebarPattern.Item(
                    id: "interactiveStyle",
                    title: "InteractiveStyle",
                    iconSystemName: "hand.tap.fill"
                ),
                SidebarPattern.Item(
                    id: "surfaceStyle",
                    title: "SurfaceStyle",
                    iconSystemName: "square.3.layers.3d"
                )
            ]
        ),
        SidebarPattern.Section(
            title: "Components",
            items: [
                SidebarPattern.Item(
                    id: "badge",
                    title: "Badge",
                    iconSystemName: "tag.fill"
                ),
                SidebarPattern.Item(
                    id: "card",
                    title: "Card",
                    iconSystemName: "rectangle.fill"
                ),
                SidebarPattern.Item(
                    id: "keyValueRow",
                    title: "KeyValueRow",
                    iconSystemName: "list.bullet.rectangle"
                ),
                SidebarPattern.Item(
                    id: "sectionHeader",
                    title: "SectionHeader",
                    iconSystemName: "text.justify.leading"
                ),
                SidebarPattern.Item(
                    id: "copyableText",
                    title: "CopyableText",
                    iconSystemName: "doc.on.doc"
                )
            ]
        ),
        SidebarPattern.Section(
            title: "Patterns",
            items: [
                SidebarPattern.Item(
                    id: "inspector",
                    title: "InspectorPattern",
                    iconSystemName: "sidebar.right"
                ),
                SidebarPattern.Item(
                    id: "sidebar",
                    title: "SidebarPattern",
                    iconSystemName: "sidebar.left"
                ),
                SidebarPattern.Item(
                    id: "toolbar",
                    title: "ToolbarPattern",
                    iconSystemName: "menubar.rectangle"
                ),
                SidebarPattern.Item(
                    id: "boxTree",
                    title: "BoxTreePattern",
                    iconSystemName: "list.bullet.indent"
                )
            ]
        )
    ]
    
    var body: some View {
        SidebarPattern(
            sections: libraryItems,
            selection: $selectedItemID
        ) { itemID in
            // Detail view builder - handles optional selection
            AnyView(detailView(for: itemID))
        }
        .navigationTitle("SidebarPattern")
    }
}

extension SidebarPatternScreen {
    
    /// Returns the detail view for the given item ID
    @ViewBuilder
    private func detailView(for itemID: String?) -> some View {
        if let itemID = itemID {
            ComponentDetailView(
                itemID: itemID,
                title: itemTitle(for: itemID),
                description: itemDescription(for: itemID),
                icon: itemIcon(for: itemID)
            )
        } else {
            // No selection - show placeholder
            VStack(spacing: DS.Spacing.xl) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    .padding(.top, DS.Spacing.xl)
                
                Text("Select an item from the sidebar")
                    .font(DS.Typography.title)
                    .foregroundStyle(.secondary)
                
                Text("Browse Design Tokens, Modifiers, Components, and Patterns")
                    .font(DS.Typography.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension SidebarPatternScreen {
    // Helper functions to get item metadata
    private func itemTitle(for id: String) -> String {
        for section in libraryItems {
            if let item = section.items.first(where: { $0.id == id }) {
                return item.title
            }
        }
        return "Unknown"
    }

    private func itemDescription(for id: String) -> String {
        switch id {
        case "spacing": return "Consistent spacing values (s, m, l, xl)"
        case "colors": return "Semantic color palette with Dark Mode support"
        case "typography": return "Font styles with Dynamic Type support"
        case "radius": return "Corner radius values for different components"
        case "animation": return "Standard animation durations and curves"
        case "badgeChipStyle": return "Badge and chip styling modifier"
        case "cardStyle": return "Card container styling with elevation"
        case "interactiveStyle": return "Interactive element styling (hover, press)"
        case "surfaceStyle": return "Surface material backgrounds"
        case "badge": return "Status and label badges"
        case "card": return "Container component with elevation"
        case "keyValueRow": return "Key-value pair display with copy support"
        case "sectionHeader": return "Section titles with optional dividers"
        case "copyableText": return "Text with clipboard copy functionality"
        case "inspector": return "Scrollable inspector with sections"
        case "sidebar": return "Navigation sidebar with sections"
        case "toolbar": return "Platform-adaptive toolbar"
        case "boxTree": return "Hierarchical tree view"
        default: return "Component description"
        }
    }

    private func itemIcon(for id: String) -> String {
        for section in libraryItems {
            if let item = section.items.first(where: { $0.id == id }) {
                return item.iconSystemName ?? "square"
            }
        }
        return "square"
    }
}

// MARK: - Component Detail View

struct ComponentDetailView: View {
    let itemID: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(DS.Colors.accent)
                .padding(.top, DS.Spacing.xl)
            
            // Title
            Text(title)
                .font(DS.Typography.title)
                .fontWeight(.semibold)
            
            // Description
            Text(description)
                .font(DS.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
            
            metadataCard
            
            Spacer()
            
            // Usage Hint
            Text("This is a demonstration of SidebarPattern")
                .font(DS.Typography.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, DS.Spacing.l)
        }
        .frame(maxWidth: .infinity)
    }
}

extension ComponentDetailView {
    @ViewBuilder
    private var metadataCard: some View {
        Card(elevation: .low, cornerRadius: DS.Radius.card) {
            VStack(spacing: DS.Spacing.m) {
                SectionHeader(title: "Details", showDivider: false)
                
                KeyValueRow(
                    key: "Component ID",
                    value: itemID,
                    copyable: true
                )
                
                KeyValueRow(
                    key: "Type",
                    value: componentType(for: itemID),
                    copyable: false
                )
                
                KeyValueRow(
                    key: "Layer",
                    value: componentLayer(for: itemID),
                    copyable: false
                )
            }
            .padding(DS.Spacing.l)
        }
        .padding(.horizontal, DS.Spacing.l)
    }
}

extension ComponentDetailView {

    private func componentType(for id: String) -> String {
        if ["spacing", "colors", "typography", "radius", "animation"].contains(id) {
            return "Design Token"
        } else if id.hasSuffix("Style") {
            return "View Modifier"
        } else if ["badge", "card", "keyValueRow", "sectionHeader", "copyableText"].contains(id) {
            return "Component"
        } else if ["inspector", "sidebar", "toolbar", "boxTree"].contains(id) {
            return "Pattern"
        }
        return "Unknown"
    }

    private func componentLayer(for id: String) -> String {
        if ["spacing", "colors", "typography", "radius", "animation"].contains(id) {
            return "Layer 0 (Foundation)"
        } else if id.hasSuffix("Style") {
            return "Layer 1 (Modifiers)"
        } else if ["badge", "card", "keyValueRow", "sectionHeader", "copyableText"].contains(id) {
            return "Layer 2 (Components)"
        } else if ["inspector", "sidebar", "toolbar", "boxTree"].contains(id) {
            return "Layer 3 (Patterns)"
        }
        return "Unknown"
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
        @State private var selection: String? = "badge"

        var body: some View {
            NavigationStack {
                SidebarPatternScreen()
            }
        }
    }

    return PreviewWrapper()
}
