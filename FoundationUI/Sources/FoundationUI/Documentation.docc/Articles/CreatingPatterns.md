# Creating Patterns

Build complex UI layouts using FoundationUI patterns (Layer 3).

## Overview

This tutorial teaches you how to combine FoundationUI components into complete UI patterns for inspector interfaces, sidebars, toolbars, and hierarchical trees.

## Prerequisites

- Completed <doc:BuildingComponents> tutorial
- Understanding of SwiftUI layouts
- Familiarity with NavigationSplitView

## Available Patterns

### InspectorPattern

Scrollable inspector with fixed header.

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

**Use Cases**: Property inspectors, detail views, metadata panels

### SidebarPattern

Navigation sidebar with sections.

```swift
SidebarPattern(
    title: "Sections",
    sections: [
        SidebarSection(
            title: "Inspector",
            items: [
                SidebarItem(id: "props", title: "Properties", icon: "doc"),
                SidebarItem(id: "tree", title: "Structure", icon: "list.bullet")
            ]
        )
    ],
    selection: $selectedItem
)
```

**Use Cases**: Navigation menus, file browsers, content organization

### ToolbarPattern

Platform-adaptive toolbar with shortcuts.

```swift
ToolbarPattern(
    items: [
        ToolbarItem(id: "copy", title: "Copy", icon: "doc.on.doc", shortcut: .copy),
        ToolbarItem(id: "export", title: "Export", icon: "square.and.arrow.up")
    ],
    action: handleToolbarAction
)
```

**Use Cases**: Command bars, action menus, quick access buttons

### BoxTreePattern

Hierarchical tree view for nested data.

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

**Use Cases**: File hierarchies, ISO box structures, folder trees

## Complete Example: ISO Inspector

Here's a complete inspector using all patterns:

```swift
import SwiftUI
import FoundationUI

struct ISOInspectorView: View {
    @State private var selectedSection: String = "properties"
    @State private var selectedBox: String?

    var body: some View {
        NavigationSplitView {
            // Sidebar: Navigation
            SidebarPattern(
                title: "ISO Inspector",
                sections: [
                    SidebarSection(
                        title: "Views",
                        items: [
                            SidebarItem(id: "properties", title: "Properties", icon: "doc.text"),
                            SidebarItem(id: "structure", title: "Structure", icon: "list.tree"),
                            SidebarItem(id: "hex", title: "Hex Viewer", icon: "01.square")
                        ]
                    )
                ],
                selection: $selectedSection
            )
        } detail: {
            // Detail: Content based on selection
            Group {
                switch selectedSection {
                case "properties":
                    propertiesView
                case "structure":
                    structureView
                case "hex":
                    hexView
                default:
                    Text("Select a view")
                }
            }
            .toolbar {
                ToolbarPattern(
                    items: [
                        ToolbarItem(id: "copy", title: "Copy", icon: "doc.on.doc", shortcut: .copy),
                        ToolbarItem(id: "export", title: "Export", icon: "square.and.arrow.up")
                    ],
                    action: handleToolbarAction
                )
            }
        }
    }

    private var propertiesView: some View {
        InspectorPattern(title: "File Properties") {
            SectionHeader(title: "Basic Information")
            KeyValueRow(key: "File Name", value: "sample.mp4")
            KeyValueRow(key: "File Size", value: "10.5 MB")
            KeyValueRow(key: "Created", value: "2024-01-15")

            SectionHeader(title: "Format")
            KeyValueRow(key: "Brand", value: "isom")
            KeyValueRow(key: "Version", value: "0x00000200")

            SectionHeader(title: "Validation")
            Card {
                HStack(spacing: DS.Spacing.m) {
                    Badge(text: "Structure", level: .success, showIcon: true)
                    Badge(text: "Checksum", level: .success, showIcon: true)
                }
            }
            .elevation(.low)
        }
        .material(.regular)
    }

    private var structureView: some View {
        InspectorPattern(title: "Box Structure") {
            BoxTreePattern(
                nodes: createBoxHierarchy(),
                selection: $selectedBox
            )

            if let selectedBox = selectedBox {
                Divider()
                    .padding(.vertical, DS.Spacing.l)

                SectionHeader(title: "Selected Box")
                KeyValueRow(key: "Type", value: selectedBox)
                KeyValueRow(key: "Size", value: "1,024 bytes")
            }
        }
        .material(.regular)
    }

    private var hexView: some View {
        InspectorPattern(title: "Hex Viewer") {
            Text("Hex viewer content")
                .font(DS.Typography.code)
        }
        .material(.regular)
    }

    private func createBoxHierarchy() -> [BoxTreeNode] {
        [
            BoxTreeNode(id: "ftyp", label: "ftyp (File Type)", children: []),
            BoxTreeNode(id: "mdat", label: "mdat (Media Data)", children: []),
            BoxTreeNode(id: "moov", label: "moov (Movie)", children: [
                BoxTreeNode(id: "mvhd", label: "mvhd (Movie Header)", children: []),
                BoxTreeNode(id: "trak", label: "trak (Track)", children: [
                    BoxTreeNode(id: "tkhd", label: "tkhd (Track Header)", children: []),
                    BoxTreeNode(id: "mdia", label: "mdia (Media)", children: [])
                ])
            ])
        ]
    }

    private func handleToolbarAction(_ id: String) {
        switch id {
        case "copy":
            print("Copy action")
        case "export":
            print("Export action")
        default:
            break
        }
    }
}

#Preview("ISO Inspector") {
    ISOInspectorView()
}
```

## Pattern Composition Guidelines

### 1. Use InspectorPattern for Details

```swift
// ✅ Good: Inspector for properties
InspectorPattern(title: "Details") {
    // Content sections
}

// ❌ Bad: ScrollView with manual layout
ScrollView {
    VStack {
        Text(title)  // Manual header
        // Content
    }
}
```

### 2. Use SidebarPattern for Navigation

```swift
// ✅ Good: Sidebar for navigation
NavigationSplitView {
    SidebarPattern(/* ... */)
} detail: {
    // Detail view
}

// ❌ Bad: Custom navigation list
List {
    // Manual navigation items
}
```

### 3. Combine Patterns Naturally

```swift
// Three-column layout
NavigationSplitView {
    SidebarPattern(/* navigation */)
} content: {
    BoxTreePattern(/* hierarchy */)
} detail: {
    InspectorPattern(/* details */)
}
```

## Performance Optimization

### LazyVStack for Large Content

```swift
InspectorPattern(title: "Large Dataset") {
    LazyVStack {  // ✅ Lazy loading
        ForEach(0..<1000) { i in
            KeyValueRow(key: "Item \(i)", value: "Value")
        }
    }
}
```

### Efficient State Updates

```swift
@State private var selectedNode: String?  // ✅ Optional for efficient updates

BoxTreePattern(
    nodes: nodes,
    selection: $selectedNode  // O(1) lookup with Set internally
)
```

## Accessibility

All patterns are fully accessible:

- **VoiceOver**: Proper labels and navigation
- **Keyboard Navigation**: Full keyboard support
- **Focus Management**: Logical focus order
- **Dynamic Type**: Text scales correctly

Test with VoiceOver:

```swift
#Preview("VoiceOver Test") {
    ISOInspectorView()
        .accessibilityShowsLargeContentViewer()
}
```

## Next Steps

- <doc:PlatformAdaptation> — Optimize for each platform
- <doc:Performance> — Performance best practices
- ``InspectorPattern`` — Inspector API
- ``SidebarPattern`` — Sidebar API
- ``BoxTreePattern`` — Tree API

## See Also

- ``InspectorPattern``
- ``SidebarPattern``
- ``ToolbarPattern``
- ``BoxTreePattern``
- <doc:Components>
