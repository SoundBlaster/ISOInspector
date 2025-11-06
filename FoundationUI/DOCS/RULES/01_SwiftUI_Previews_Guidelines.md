# SwiftUI Previews Guidelines for FoundationUI

**Version:** 1.0
**Last Updated:** 2025-11-03
**Swift Version:** 6.0+
**Minimum Deployment:** iOS 17.0+

## Table of Contents

1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Preview Syntax and Structure](#preview-syntax-and-structure)
4. [State Management in Previews](#state-management-in-previews)
5. [Preview Organization](#preview-organization)
6. [Common Patterns](#common-patterns)
7. [Error Prevention](#error-prevention)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

---

## Overview

SwiftUI Previews are essential development tools that enable rapid iteration and visual validation of UI components. This document establishes standards for writing maintainable, reliable previews in the FoundationUI package.

### Purpose

- Provide rapid visual feedback during development
- Document component variations and states
- Demonstrate proper usage of FoundationUI components
- Support design system consistency validation
- Enable non-runtime visual regression testing

### Scope

This guideline applies to:

- All FoundationUI source files containing SwiftUI views
- Design system tokens (Colors, Typography, Spacing, etc.)
- Patterns (BoxTreePattern, SidebarPattern, etc.)
- Components (Badge, Card, KeyValueRow, etc.)
- Contexts (Surface styles, accessibility, etc.)

---

## Core Principles

### 1. Every Public View Must Have Previews

**Rule:** All public SwiftUI views, patterns, and components MUST include at least one preview demonstrating basic usage.

**Rationale:** Previews serve as living documentation and ensure components render correctly.

### 2. Previews Must Be Compilable

**Rule:** All previews must compile without errors in Swift 6.0+ with strict concurrency checking enabled.

**Rationale:** Broken previews provide no value and create noise in build output.

### 3. Previews Should Be Comprehensive

**Rule:** Include previews for:

- Default state
- Edge cases (empty, maximum content, error states)
- Platform variations (iOS, macOS, iPadOS when applicable)
- Accessibility variations (Dynamic Type, color schemes)
- Interactive states (hover, pressed, disabled)

### 4. Previews Must Be Isolated

**Rule:** Previews should not depend on external state, network calls, or file system access.

**Rationale:** Previews must be deterministic and work in Xcode's preview canvas environment.

---

## Preview Syntax and Structure

### Modern Preview Macro (Swift 6.0+)

#### ✅ CORRECT: Use `#Preview` macro

```swift
#Preview("Default State") {
    Badge(text: "Beta", level: .info)
}
```

#### ❌ INCORRECT: Don't use legacy PreviewProvider

```swift
// Don't use this pattern in new code
struct Badge_Previews: PreviewProvider {
    static var previews: some View {
        Badge(text: "Beta", level: .info)
    }
}
```

### Preview Naming Convention

**Format:** `#Preview("Descriptive Name")`

**Guidelines:**

- Use clear, descriptive names that explain what the preview demonstrates
- Follow sentence case (e.g., "Dark Mode", "Large Content", "Error State")
- Be specific about the variation being shown

**Examples:**

```swift
#Preview("Default Badge") { ... }
#Preview("Badge with Success Level") { ... }
#Preview("Badge in Dark Mode") { ... }
#Preview("Badge with Maximum Length Text") { ... }
```

---

## State Management in Previews

### The @Previewable Requirement

**CRITICAL RULE:** All `@State`, `@Binding`, and other property wrappers used inline in `#Preview` blocks MUST be prefixed with `@Previewable`.

**Why:** Swift 6.0 strict concurrency requires explicit marking of state used in preview contexts.

### Correct State Declaration

**✅ CORRECT:**

```swift
#Preview("Interactive Tree") {
    @Previewable @State var expandedNodes: Set<UUID> = []
    @Previewable @State var selection: UUID? = nil

    return BoxTreePattern(
        data: sampleNodes,
        children: { $0.children },
        expandedNodes: $expandedNodes,
        selection: $selection
    ) { node in
        Text(node.title)
    }
}
```

**❌ INCORRECT:**

```swift
#Preview("Interactive Tree") {
    // Missing @Previewable - will cause compiler warnings
    @State var expandedNodes: Set<UUID> = []
    @State var selection: UUID? = nil

    return BoxTreePattern(...)
}
```

### Common Property Wrappers Requiring @Previewable

All of these require `@Previewable` when used inline in previews:

- `@State`
- `@Binding` (when creating test bindings)
- `@StateObject`
- `@ObservedObject`
- `@Environment`
- `@EnvironmentObject`

### Creating Test Bindings

#### Pattern 1: Using @Previewable @State

```swift
#Preview("With Binding") {
    @Previewable @State var isExpanded = false

    DisclosureGroup("Details", isExpanded: $isExpanded) {
        Text("Content")
    }
}
```

#### Pattern 2: Using .constant() for Read-Only

```swift
#Preview("Constant Binding") {
    // For non-interactive previews, use .constant()
    Toggle("Enable", isOn: .constant(true))
}
```

### Preview Container Views

For complex state management, use a container view:

```swift
#Preview("Complex State") {
    struct PreviewContainer: View {
        @State private var items: [Item] = sampleItems
        @State private var selection: Item.ID? = nil
        @State private var isEditing = false

        var body: some View {
            ComplexComponent(
                items: $items,
                selection: $selection,
                isEditing: $isEditing
            )
        }
    }

    return PreviewContainer()
}
```

**When to use container views:**

- Multiple related state variables
- Complex state logic or computed properties
- Lifecycle methods needed (onAppear, etc.)
- Reusable preview logic across multiple previews

---

## Preview Organization

### File Location

**Rule:** Previews MUST be in the same file as the component they preview.

**Location in file:**

```swift
// 1. Imports
import SwiftUI

// 2. Main component implementation
public struct Badge: View {
    // ... component code ...
}

// 3. Supporting types (if any)
private struct BadgeBackground: View { ... }

// 4. Previews section
// MARK: - SwiftUI Previews

#Preview("Default") { ... }
#Preview("Dark Mode") { ... }
#Preview("All Levels") { ... }
```

### Preview Section Marker

**Required marker:**

```swift
// MARK: - SwiftUI Previews
```

This separator:

- Clearly delineates preview code from production code
- Appears in Xcode's source navigator
- Makes previews easy to locate and collapse

### Number of Previews

**Guidelines:**

- **Minimum:** 1 preview showing default usage
- **Recommended:** 3-7 previews covering key variations
- **Maximum:** No hard limit, but keep organized and purposeful

**Suggested preview set for components:**

1. Default state
2. Dark mode variant
3. Accessibility variant (Dynamic Type)
4. Edge case (empty, error, maximum content)
5. Platform-specific behavior (if applicable)
6. Interactive state demonstration
7. Integration with other components

---

## Common Patterns

### Pattern 1: Basic Component Preview

```swift
#Preview("Default Badge") {
    Badge(text: "New", level: .info)
}
```

### Pattern 2: Dark Mode Preview

```swift
#Preview("Dark Mode") {
    Badge(text: "Error", level: .error)
        .preferredColorScheme(.dark)
        .padding()
}
```

### Pattern 3: Multiple Variations in One Preview

```swift
#Preview("All Badge Levels") {
    VStack(spacing: DS.Spacing.m) {
        Badge(text: "Info", level: .info)
        Badge(text: "Success", level: .success)
        Badge(text: "Warning", level: .warning)
        Badge(text: "Error", level: .error)
    }
    .padding()
}
```

### Pattern 4: Dynamic Type Testing

```swift
#Preview("Large Accessibility Text") {
    Badge(text: "Important", level: .warning)
        .environment(\.dynamicTypeSize, .xxxLarge)
        .padding()
}

#Preview("Small Text") {
    Badge(text: "Compact", level: .info)
        .environment(\.dynamicTypeSize, .xSmall)
        .padding()
}
```

### Pattern 5: Platform-Specific Previews

```swift
#Preview("macOS Layout") {
    ToolbarPattern(items: sampleItems)
        .frame(minWidth: 600, minHeight: 400)
}

#Preview("iOS Compact") {
    ToolbarPattern(items: sampleItems)
        .environment(\.horizontalSizeClass, .compact)
}
```

### Pattern 6: With Mock Data

```swift
#Preview("With Sample Data") {
    let sampleNodes = [
        TreeNode(id: UUID(), title: "Root", children: [
            TreeNode(id: UUID(), title: "Child 1", children: []),
            TreeNode(id: UUID(), title: "Child 2", children: [])
        ])
    ]

    @Previewable @State var expanded: Set<UUID> = []

    return BoxTreePattern(
        data: sampleNodes,
        children: { $0.children },
        expandedNodes: $expanded
    ) { node in
        Text(node.title)
    }
}
```

### Pattern 7: Edge Cases

```swift
#Preview("Empty State") {
    List([], id: \.self) { item in
        Text(item)
    }
    .overlay {
        ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add items to get started")
        )
    }
}

#Preview("Maximum Content") {
    let longText = String(repeating: "Very long badge text ", count: 10)
    Badge(text: longText, level: .info)
        .frame(width: 200)
}

#Preview("Error State") {
    Card {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Failed to load content")
        }
    }
}
```

---

## Error Prevention

### Common Issues and Solutions

#### Issue 1: Missing @Previewable

**Problem:**

```swift
#Preview("Example") {
    @State var value = false  // ⚠️ Warning
    Toggle("Option", isOn: $value)
}
```

**Solution:**

```swift
#Preview("Example") {
    @Previewable @State var value = false  // ✅ Correct
    Toggle("Option", isOn: $value)
}
```

#### Issue 2: Complex Generic Type Mismatches

**Problem:**

```swift
#Preview("Sidebar") {
    let items = [SidebarPattern<Int, Text>.Item(...)]  // Type mismatch

    SidebarPattern<Int, AnyView>(sections: [.init(items: items)]) { id in
        if let id { AnyView(Text("Item \(id)")) }
        else { AnyView(Text("None")) }
    }
}
```

**Solution:**

```swift
#Preview("Sidebar") {
    // Ensure Item type matches Pattern type
    let items = [SidebarPattern<Int, AnyView>.Item(...)]

    SidebarPattern<Int, AnyView>(sections: [.init(items: items)]) { id in
        AnyView(
            Group {
                if let id { Text("Item \(id)") }
                else { Text("None") }
            }
        )
    }
}
```

#### Issue 3: Platform Availability

**Problem:**

```swift
#Preview("Using New API") {
    Text("Hello")
        .someNewModifier()  // Available only in iOS 18+
}
```

**Solution:**

```swift
#Preview("Using New API") {
    if #available(iOS 18.0, *) {
        Text("Hello")
            .someNewModifier()
    } else {
        Text("Hello")
            .fallbackModifier()
    }
}
```

#### Issue 4: Return Statement Confusion

**Problem:**

```swift
#Preview("Example") {
    @Previewable @State var value = false
    Toggle("Option", isOn: $value)  // Implicit return - might confuse reader
}
```

**Solution:**

```swift
#Preview("Example") {
    @Previewable @State var value = false

    return Toggle("Option", isOn: $value)  // Explicit return for clarity
}
```

---

## Examples

### Example 1: Simple Component (Badge)

```swift
// MARK: - SwiftUI Previews

#Preview("Default Badge") {
    Badge(text: "New", level: .info)
}

#Preview("All Badge Levels") {
    VStack(spacing: DS.Spacing.m) {
        Badge(text: "Info", level: .info)
        Badge(text: "Success", level: .success)
        Badge(text: "Warning", level: .warning)
        Badge(text: "Error", level: .error)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.m) {
        Badge(text: "Info", level: .info)
        Badge(text: "Error", level: .error)
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type - Large") {
    Badge(text: "Important", level: .warning)
        .environment(\.dynamicTypeSize, .xxxLarge)
        .padding()
}
```

### Example 2: Pattern with State (BoxTreePattern)

```swift
// MARK: - SwiftUI Previews

#Preview("Basic Tree") {
    @Previewable @State var expandedNodes: Set<UUID> = []

    let sampleData = [
        TreeNode(id: UUID(), title: "Parent", children: [
            TreeNode(id: UUID(), title: "Child 1", children: []),
            TreeNode(id: UUID(), title: "Child 2", children: [])
        ])
    ]

    return BoxTreePattern(
        data: sampleData,
        children: { $0.children },
        expandedNodes: $expandedNodes
    ) { node in
        Text(node.title)
    }
}

#Preview("Tree with Selection") {
    @Previewable @State var expandedNodes: Set<UUID> = []
    @Previewable @State var selection: UUID? = nil

    return BoxTreePattern(
        data: generateSampleTree(depth: 3),
        children: { $0.children },
        expandedNodes: $expandedNodes,
        selection: $selection
    ) { node in
        Label(node.title, systemImage: node.icon)
    }
}
```

### Example 3: Complex Pattern with Container (SidebarPattern)

```swift
// MARK: - SwiftUI Previews

#Preview("ISO Inspector Workflow") {
    struct PreviewContainer: View {
        @State private var selection: String? = "overview"

        private let sections: [SidebarPattern<String, AnyView>.Section] = [
            .init(
                title: "File Analysis",
                items: [
                    .init(id: "overview", title: "Overview", iconSystemName: "doc.text"),
                    .init(id: "structure", title: "Box Structure", iconSystemName: "square.stack.3d.up")
                ]
            )
        ]

        var body: some View {
            SidebarPattern(
                sections: sections,
                selection: $selection
            ) { currentSelection in
                AnyView(
                    Group {
                        switch currentSelection {
                        case "overview":
                            InspectorPattern(title: "File Overview") {
                                KeyValueRow(key: "File Name", value: "sample.mp4")
                                KeyValueRow(key: "Size", value: "125.4 MB")
                            }
                        case "structure":
                            InspectorPattern(title: "Box Structure") {
                                Text("Box structure content")
                            }
                        default:
                            Text("Select an item")
                        }
                    }
                )
            }
        }
    }

    return PreviewContainer()
        .frame(minWidth: 800, minHeight: 600)
}
```

---

## Troubleshooting

### Preview Not Appearing in Canvas

**Possible causes:**

1. Compilation errors in the file
2. Missing `#Preview` macro or incorrect syntax
3. Xcode preview canvas cache issues
4. Deployment target mismatch

**Solutions:**

1. Check for compilation errors in the Issue Navigator
2. Verify preview syntax matches guidelines
3. Clean build folder (Cmd+Shift+K) and restart Xcode
4. Verify deployment target is iOS 17.0+ for `#Preview` macro

### Preview Shows Warnings

**Common warning:** "@State used inline will not work unless tagged with @Previewable"

**Solution:** Add `@Previewable` before `@State`:

```swift
@Previewable @State var value = initialValue
```

### Preview Crashes or Shows Error

**Common causes:**

1. Force-unwrapping nil values
2. Missing required dependencies
3. Platform-specific code running on wrong platform
4. Resource not found (images, fonts, etc.)

**Solutions:**

1. Use optional binding or provide default values
2. Mock all dependencies with sample data
3. Use `#if os(...)` checks
4. Ensure resources are in preview target or use system resources

### Generic Type Errors in Previews

**Issue:** Generic type parameters don't match between data and pattern

**Solution:** Ensure consistency:

```swift
// Consistent types throughout
let items: [SidebarPattern<String, AnyView>.Item] = [...]
let sections: [SidebarPattern<String, AnyView>.Section] = [
    .init(items: items)
]
SidebarPattern<String, AnyView>(sections: sections) { id in ... }
```

---

## Checklist for Preview Implementation

Use this checklist when adding or reviewing previews:

- [ ] File has `// MARK: - SwiftUI Previews` separator
- [ ] At least one preview shows default usage
- [ ] All `@State` properties use `@Previewable` prefix
- [ ] Preview names are descriptive and follow naming convention
- [ ] Dark mode variant included (if component has color)
- [ ] Accessibility variant included (if component has text)
- [ ] All previews compile without warnings or errors
- [ ] Complex state uses container view pattern
- [ ] Mock data is realistic and representative
- [ ] Edge cases are demonstrated (empty, error, maximum)
- [ ] Platform-specific code has appropriate conditional checks

---

## References

- [Apple SwiftUI Previews Documentation](https://developer.apple.com/documentation/swiftui/previews)
- [Swift Evolution: SE-0395 - @Previewable](https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md)
- [FoundationUI Architecture Overview](../ARCHITECTURE.md)
- [FoundationUI Component Guidelines](./Component_Guidelines.md)

---

**Document Owner:** FoundationUI Team
**Review Cycle:** Quarterly
**Next Review:** 2025-02-03
