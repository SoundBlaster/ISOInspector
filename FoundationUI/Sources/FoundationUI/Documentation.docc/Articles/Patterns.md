# Patterns

UI Patterns for complex layouts (Layer 3).

## Overview

FoundationUI Patterns are composite layouts that combine multiple components into reusable UI structures. Patterns solve common layout problems for inspector interfaces, sidebars, toolbars, and hierarchical data visualization.

## Available Patterns

### InspectorPattern

Scrollable inspector with fixed header, ideal for property panels and metadata displays.

```swift
InspectorPattern(title: "File Properties") {
    SectionHeader(title: "Metadata")
    KeyValueRow(key: "Type", value: "ftyp")
    KeyValueRow(key: "Size", value: "32 bytes")

    SectionHeader(title: "Status")
    Badge(text: "Valid", level: .success)
}
.material(.regular)
```

**Features**:
- Fixed title header that stays visible during scroll
- Scrollable content area with LazyVStack support
- Material background support (.thin, .regular, .thick)
- Automatic spacing with DS tokens
- Platform-adaptive padding

**Use Cases**: Property inspectors, detail views, metadata panels, settings screens

### SidebarPattern

Navigation sidebar with sections, built on NavigationSplitView.

```swift
SidebarPattern(
    title: "Navigation",
    sections: [
        SidebarSection(
            title: "Views",
            items: [
                SidebarItem(id: "props", title: "Properties", icon: "doc.text"),
                SidebarItem(id: "tree", title: "Structure", icon: "list.bullet.indent")
            ]
        )
    ],
    selection: $selectedItem
)
```

**Features**:
- Section-based organization with headers
- SF Symbols icon support
- Selection state binding
- Keyboard navigation (arrow keys, Tab)
- VoiceOver labels from item metadata
- Platform-adaptive column width (macOS: wider, iOS: compact)

**Use Cases**: Navigation menus, file browsers, content organization, multi-pane layouts

### ToolbarPattern

Platform-adaptive toolbar with keyboard shortcuts.

```swift
ToolbarPattern(
    items: [
        ToolbarItem(id: "copy", title: "Copy", icon: "doc.on.doc", shortcut: .copy),
        ToolbarItem(id: "export", title: "Export", icon: "square.and.arrow.up")
    ],
    action: handleToolbarAction
)
```

**Features**:
- Platform-adaptive layout (macOS toolbar, iOS compact)
- Keyboard shortcut integration (⌘C, ⌘V, ⌘A)
- SF Symbols icons
- Accessibility labels with shortcut hints
- Overflow menu for many items

**Use Cases**: Command bars, action menus, quick access buttons, editor toolbars

### BoxTreePattern

Hierarchical tree view for nested data with lazy loading.

```swift
BoxTreePattern(
    nodes: [
        BoxTreeNode(id: "ftyp", label: "ftyp", children: []),
        BoxTreeNode(id: "moov", label: "moov", children: [
            BoxTreeNode(id: "mvhd", label: "mvhd", children: []),
            BoxTreeNode(id: "trak", label: "trak", children: [])
        ])
    ],
    selection: $selectedNode
)
```

**Features**:
- Expand/collapse functionality with smooth animations
- Lazy rendering for large trees (1000+ nodes)
- Single and multi-selection support
- Indentation with DS.Spacing.l per level
- Keyboard navigation (arrow keys, Space to toggle)
- VoiceOver support with level announcements
- O(1) selection lookup with Set

**Performance**:
- Flat tree (1000 nodes): ~80ms render
- Deep tree (50 levels): ~60ms render
- Very large tree (5000 nodes): ~150ms render

**Use Cases**: File hierarchies, ISO box structures, folder trees, nested menus

## Pattern Composition

Patterns are designed to work together:

### Three-Column Layout

```swift
NavigationSplitView {
    // Sidebar: Navigation
    SidebarPattern(/* ... */)
} content: {
    // Content: Hierarchical data
    BoxTreePattern(/* ... */)
} detail: {
    // Detail: Properties
    InspectorPattern(/* ... */)
}
```

### Two-Column Layout

```swift
NavigationSplitView {
    SidebarPattern(/* ... */)
} detail: {
    InspectorPattern(/* ... */)
}
```

### Toolbar + Inspector

```swift
VStack {
    ToolbarPattern(/* ... */)
    InspectorPattern(/* ... */)
}
```

## Design Principles

### 1. Zero Magic Numbers

All patterns use Design Tokens:

```swift
// InspectorPattern spacing
DS.Spacing.l    // Content padding
DS.Spacing.m    // Section spacing

// BoxTreePattern indentation
DS.Spacing.l    // Per-level indent
```

### 2. Performance

Patterns are optimized for large datasets:

- **LazyVStack** for large lists (1000+ items)
- **Conditional rendering** for tree nodes
- **O(1) lookups** for selection state
- **Efficient state updates** with minimal re-renders

### 3. Accessibility

All patterns are fully accessible:

- VoiceOver labels and navigation
- Keyboard shortcuts and navigation
- Focus management
- Touch target sizes ≥44×44 pt (iOS)

### 4. Platform Adaptation

Patterns adapt to each platform:

- **macOS**: Keyboard shortcuts, hover effects, wider layouts
- **iOS**: Touch gestures, 44pt touch targets, compact layouts
- **iPadOS**: Size classes, pointer interactions, adaptive layouts

## Complete Example

Full ISO Inspector with all patterns:

```swift
struct ISOInspectorView: View {
    @State private var selectedSection: String = "properties"
    @State private var selectedBox: String?

    var body: some View {
        NavigationSplitView {
            SidebarPattern(
                title: "ISO Inspector",
                sections: [
                    SidebarSection(
                        title: "Views",
                        items: [
                            SidebarItem(id: "properties", title: "Properties", icon: "doc.text"),
                            SidebarItem(id: "structure", title: "Structure", icon: "list.bullet.indent")
                        ]
                    )
                ],
                selection: $selectedSection
            )
        } detail: {
            Group {
                switch selectedSection {
                case "properties":
                    propertiesView
                case "structure":
                    structureView
                default:
                    Text("Select a view")
                }
            }
            .toolbar {
                ToolbarPattern(
                    items: [
                        ToolbarItem(id: "copy", title: "Copy", icon: "doc.on.doc", shortcut: .copy)
                    ],
                    action: handleAction
                )
            }
        }
    }

    private var propertiesView: some View {
        InspectorPattern(title: "File Properties") {
            SectionHeader(title: "Format")
            KeyValueRow(key: "Type", value: "ftyp")
            Badge(text: "Valid", level: .success)
        }
    }

    private var structureView: some View {
        InspectorPattern(title: "Box Structure") {
            BoxTreePattern(nodes: boxHierarchy, selection: $selectedBox)
        }
    }
}
```

## Further Reading

- <doc:CreatingPatterns>
- <doc:Components>
- <doc:Performance>
- ``InspectorPattern``
- ``SidebarPattern``
- ``ToolbarPattern``
- ``BoxTreePattern``

## See Also

- <doc:Components>
- <doc:Architecture>
- <doc:PlatformAdaptation>
- ``InspectorPattern``
- ``SidebarPattern``
- ``ToolbarPattern``
- ``BoxTreePattern``
