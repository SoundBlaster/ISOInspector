# Getting Started

A 5-minute quick start guide to using FoundationUI in your SwiftUI project.

## Overview

This tutorial will guide you through adding FoundationUI to your project and creating your first accessible, platform-adaptive UI with zero magic numbers.

## Prerequisites

- Xcode 15.0 or later
- iOS 17+, iPadOS 17+, or macOS 14+
- Basic SwiftUI knowledge

## Step 1: Add FoundationUI to Your Project

### Using Swift Package Manager

1. Open your project in Xcode
2. Select **File > Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/YourOrg/FoundationUI.git
   ```
4. Select version **1.0.0** or later
5. Click **Add Package**

### Or Add to Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/YourOrg/FoundationUI.git", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["FoundationUI"]
)
```

## Step 2: Import FoundationUI

In your SwiftUI file, import FoundationUI:

```swift
import SwiftUI
import FoundationUI

struct ContentView: View {
    var body: some View {
        Text("Hello, FoundationUI!")
    }
}
```

## Step 3: Use Your First Design Token

Replace magic numbers with Design Tokens:

```swift
import SwiftUI
import FoundationUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.l) {  // ✅ 16pt spacing token
            Text("Hello, FoundationUI!")
                .font(DS.Typography.title)  // ✅ Semantic font
                .padding(DS.Spacing.m)      // ✅ 12pt padding token
        }
    }
}
```

**Why Design Tokens?**
- No magic numbers (100% semantic values)
- Consistent spacing across all components
- Automatic platform adaptation
- Easy to update globally

## Step 4: Create Your First Component

Use the `Badge` component to display status:

```swift
import SwiftUI
import FoundationUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            Text("ISO File Status")
                .font(DS.Typography.title)

            // Badge with semantic colors
            Badge(text: "Valid", level: .success, showIcon: true)
            Badge(text: "Warning", level: .warning)
            Badge(text: "Error", level: .error, showIcon: true)
        }
        .padding(DS.Spacing.xl)
    }
}
```

**Result**: Three badges with semantic colors (green, yellow, red), automatic VoiceOver labels, and zero magic numbers.

## Step 5: Build a Card Layout

Compose components to build complex UIs:

```swift
import SwiftUI
import FoundationUI

struct ContentView: View {
    var body: some View {
        Card {
            VStack(spacing: DS.Spacing.l) {
                SectionHeader(title: "File Properties")

                KeyValueRow(key: "Type", value: "ftyp")
                KeyValueRow(key: "Size", value: "1,024 bytes")
                KeyValueRow(key: "Offset", value: "0x00000000")

                SectionHeader(title: "Status")

                Badge(text: "Valid", level: .success, showIcon: true)
            }
        }
        .elevation(.medium)
        .padding(DS.Spacing.xl)
    }
}
```

**Result**: A card with elevated shadow, structured content using SectionHeader and KeyValueRow, and a success badge.

## Step 6: Add Copyable Text

Make values copyable with a single modifier:

```swift
KeyValueRow(key: "UUID", value: "550e8400-e29b-41d4-a716-446655440000")
    .makeCopyable(text: "550e8400-e29b-41d4-a716-446655440000")
```

Or use the `CopyableText` component:

```swift
CopyableText(
    text: "550e8400-e29b-41d4-a716-446655440000",
    label: "UUID"
)
```

**Result**: Click to copy value to clipboard, visual "Copied!" feedback, keyboard shortcut (⌘C on macOS), VoiceOver announcement.

## Step 7: Build an Inspector Pattern

Create a complete inspector UI:

```swift
import SwiftUI
import FoundationUI

struct FileInspectorView: View {
    var body: some View {
        InspectorPattern(title: "ISO File Inspector") {
            SectionHeader(title: "Box Structure")

            KeyValueRow(key: "Type", value: "ftyp")
            KeyValueRow(key: "Brand", value: "isom")
            KeyValueRow(key: "Version", value: "0x00000200")

            SectionHeader(title: "Size Information")

            KeyValueRow(key: "Header Size", value: "8 bytes")
            KeyValueRow(key: "Data Size", value: "24 bytes")
            KeyValueRow(key: "Total Size", value: "32 bytes")

            SectionHeader(title: "Validation")

            Card {
                HStack(spacing: DS.Spacing.m) {
                    Badge(text: "Structure", level: .success, showIcon: true)
                    Badge(text: "Checksum", level: .success, showIcon: true)
                    Badge(text: "Compatibility", level: .success, showIcon: true)
                }
            }
            .elevation(.low)
        }
        .material(.regular)
    }
}
```

**Result**: A complete scrollable inspector with fixed header, organized sections, key-value rows, and status badges.

## Step 8: Add Platform Adaptation

Make your UI adapt to macOS, iOS, and iPadOS:

```swift
InspectorPattern(title: "ISO File Inspector") {
    // Content...
}
.material(.regular)
.platformAdaptive()  // ✅ Adapts spacing and behavior to platform
```

**Platform Differences**:
- **macOS**: 12pt default spacing, keyboard shortcuts (⌘C, ⌘V), hover effects
- **iOS**: 16pt default spacing, touch gestures, 44pt minimum touch targets
- **iPadOS**: Size class adaptation, pointer interactions on hover

## Step 9: Test Accessibility

FoundationUI components are accessible by default:

### VoiceOver

Enable VoiceOver (macOS: ⌥⌘F5, iOS: Triple-click Home):

```swift
Badge(text: "Error", level: .error)
// VoiceOver: "Error badge, error"

KeyValueRow(key: "Type", value: "ftyp")
// VoiceOver: "Type: ftyp"
```

### Keyboard Navigation

Tab through interactive elements:

```swift
VStack(spacing: DS.Spacing.l) {
    Button("Copy") { }  // Tab to focus, Space to activate
    CopyableText(text: "Value")  // Tab to focus, ⌘C to copy
}
```

### Dynamic Type

Test with different text sizes (Settings > Accessibility > Display & Text Size):

```swift
// All typography scales automatically
Text("Hello")
    .font(DS.Typography.body)
// Scales from XS to XXXL
```

## Step 10: Preview Your UI

Use Xcode previews to iterate quickly:

```swift
#Preview("Light Mode") {
    FileInspectorView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    FileInspectorView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    FileInspectorView()
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}
```

## Complete Example

Here's a complete example combining everything:

```swift
import SwiftUI
import FoundationUI

struct ISOFileInspectorApp: App {
    var body: some Scene {
        WindowGroup {
            FileInspectorView()
        }
    }
}

struct FileInspectorView: View {
    @State private var selectedSection: String = "properties"

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarPattern(
                title: "Sections",
                sections: [
                    SidebarSection(
                        title: "Inspector",
                        items: [
                            SidebarItem(id: "properties", title: "Properties", icon: "doc.text"),
                            SidebarItem(id: "structure", title: "Structure", icon: "list.bullet"),
                            SidebarItem(id: "validation", title: "Validation", icon: "checkmark.shield")
                        ]
                    )
                ],
                selection: $selectedSection
            )
        } detail: {
            // Inspector
            InspectorPattern(title: sectionTitle) {
                switch selectedSection {
                case "properties":
                    PropertiesSection()
                case "structure":
                    StructureSection()
                case "validation":
                    ValidationSection()
                default:
                    Text("Select a section")
                }
            }
            .material(.regular)
        }
        .platformAdaptive()
    }

    private var sectionTitle: String {
        switch selectedSection {
        case "properties": return "File Properties"
        case "structure": return "Box Structure"
        case "validation": return "Validation Results"
        default: return "ISO Inspector"
        }
    }
}

struct PropertiesSection: View {
    var body: some View {
        SectionHeader(title: "Basic Information")
        KeyValueRow(key: "File Name", value: "sample.mp4")
        KeyValueRow(key: "File Size", value: "10.5 MB")
        KeyValueRow(key: "Created", value: "2024-01-15")

        SectionHeader(title: "Format")
        KeyValueRow(key: "Brand", value: "isom")
        KeyValueRow(key: "Version", value: "0x00000200")
    }
}

struct StructureSection: View {
    @State private var selectedBox: String?

    var body: some View {
        SectionHeader(title: "Box Hierarchy")

        BoxTreePattern(
            nodes: [
                BoxTreeNode(id: "ftyp", label: "ftyp", children: []),
                BoxTreeNode(id: "mdat", label: "mdat", children: []),
                BoxTreeNode(id: "moov", label: "moov", children: [
                    BoxTreeNode(id: "mvhd", label: "mvhd", children: []),
                    BoxTreeNode(id: "trak", label: "trak", children: [])
                ])
            ],
            selection: $selectedBox
        )
    }
}

struct ValidationSection: View {
    var body: some View {
        SectionHeader(title: "Validation Results")

        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack(spacing: DS.Spacing.m) {
                    Badge(text: "Structure", level: .success, showIcon: true)
                    Badge(text: "Checksum", level: .success, showIcon: true)
                }

                Text("All validation checks passed")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .elevation(.low)
    }
}

#Preview("Inspector App") {
    FileInspectorView()
}
```

## Next Steps

Now that you've built your first FoundationUI app, explore more advanced topics:

- <doc:BuildingComponents> — Create custom components
- <doc:CreatingPatterns> — Build complex layouts
- <doc:PlatformAdaptation> — Optimize for each platform
- <doc:Accessibility> — Accessibility best practices
- <doc:Performance> — Performance optimization

## Common Patterns

### Key-Value Pairs with Copyable Text

```swift
KeyValueRow(key: "UUID", value: uuid)
    .makeCopyable(text: uuid)
```

### Semantic Badges

```swift
HStack(spacing: DS.Spacing.m) {
    Badge(text: "Info", level: .info)
    Badge(text: "Success", level: .success, showIcon: true)
    Badge(text: "Warning", level: .warning)
    Badge(text: "Error", level: .error, showIcon: true)
}
```

### Cards with Elevation

```swift
Card {
    // Content
}
.elevation(.medium)
.material(.regular)
```

### Scrollable Inspector

```swift
InspectorPattern(title: "Details") {
    // Sections and content
}
.material(.regular)
```

### Hierarchical Tree

```swift
BoxTreePattern(
    nodes: treeNodes,
    selection: $selectedNode
)
```

## Troubleshooting

### Import Errors

If you see "No such module 'FoundationUI'":
1. Ensure the package is added to your project
2. Build the project (⌘B)
3. Restart Xcode if needed

### Preview Not Updating

If previews don't update:
1. Press ⌥⌘P to refresh
2. Clean build folder (⇧⌘K)
3. Rebuild (⌘B)

### Magic Number Warnings

If SwiftLint warns about magic numbers:
- Replace hardcoded values with DS tokens
- Use `DS.Spacing`, `DS.Colors`, `DS.Typography`, etc.

## Resources

- [API Reference](https://docs.foundationui.dev/api) — Complete API documentation
- [Component Catalog](https://docs.foundationui.dev/components) — All components
- [GitHub Repository](https://github.com/YourOrg/FoundationUI) — Source code and examples
- [ISO Inspector Demo](https://github.com/YourOrg/ISOInspector) — Full app example

## See Also

- <doc:Architecture> — Understanding Composable Clarity
- <doc:DesignTokens> — Complete token reference
- ``DS`` — Design Tokens namespace
- ``Badge`` — Badge component API
- ``Card`` — Card component API
- ``InspectorPattern`` — Inspector pattern API
