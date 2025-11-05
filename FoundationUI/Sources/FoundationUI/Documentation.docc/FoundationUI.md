# ``FoundationUI``

A SwiftUI Design System for building accessible, platform-adaptive inspector interfaces with zero magic numbers.

## Overview

FoundationUI is a comprehensive SwiftUI component library designed for the ISO Inspector project, following the **Composable Clarity** architecture. It provides a complete design system with tokens, modifiers, components, and patterns that work seamlessly across iOS 17+, iPadOS 17+, and macOS 14+.

### Key Features

- **Zero Magic Numbers**: 100% Design Token usage across all components
- **Accessibility-First**: WCAG 2.1 AA compliant (≥4.5:1 contrast ratios), full VoiceOver support
- **Platform-Adaptive**: Native experiences on iOS, iPadOS, and macOS
- **Dark Mode Support**: Automatic adaptation with system colors
- **Composable Architecture**: Build complex UIs from simple, reusable components

### Composable Clarity Architecture

FoundationUI follows a layered architecture from foundational tokens to complete UI patterns:

```
Layer 0: Design Tokens (DS)
   ↓ (Modifiers depend on Tokens)
Layer 1: View Modifiers
   ↓ (Components depend on Modifiers)
Layer 2: Components
   ↓ (Patterns depend on Components)
Layer 3: Patterns
   ↓ (Contexts enhance all layers)
Layer 4: Contexts
```

This layered approach ensures consistency, reusability, and zero magic numbers throughout your codebase.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:Accessibility>
- <doc:Performance>

### Design System

- <doc:DesignTokens>
- ``DS``

### Building Blocks

- <doc:Modifiers>
- <doc:Components>
- <doc:Patterns>
- <doc:Contexts>
- <doc:Utilities>

### Tutorials

- <doc:GettingStarted>
- <doc:BuildingComponents>
- <doc:CreatingPatterns>
- <doc:PlatformAdaptation>

### Design Tokens (Layer 0)

- ``DS/Spacing``
- ``DS/Typography``
- ``DS/Colors``
- ``DS/Radius``
- ``DS/Animation``

### View Modifiers (Layer 1)

- ``BadgeChipStyle``
- ``CardStyle``
- ``InteractiveStyle``
- ``SurfaceStyle``
- ``CopyableModifier``

### Components (Layer 2)

- ``Badge``
- ``Card``
- ``KeyValueRow``
- ``SectionHeader``
- ``CopyableText``
- ``Copyable``

### Patterns (Layer 3)

- ``InspectorPattern``
- ``SidebarPattern``
- ``ToolbarPattern``
- ``BoxTreePattern``

### Contexts (Layer 4)

- ``SurfaceStyleKey``
- ``PlatformAdaptation``
- ``ColorSchemeAdapter``
- ``AccessibilityContext``

### Utilities

- ``CopyableText``
- ``KeyboardShortcuts``
- ``AccessibilityHelpers``

## Getting Started

Add FoundationUI to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/YourOrg/FoundationUI.git", from: "1.0.0")
]
```

Import FoundationUI in your SwiftUI views:

```swift
import SwiftUI
import FoundationUI

struct ContentView: View {
    var body: some View {
        Card {
            VStack(spacing: DS.Spacing.l) {
                SectionHeader(title: "ISO File Properties")
                KeyValueRow(key: "Type", value: "ftyp")
                Badge(text: "Valid", level: .success)
            }
        }
        .elevation(.medium)
    }
}
```

## Minimum Requirements

- **iOS**: 17.0+
- **iPadOS**: 17.0+
- **macOS**: 14.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+

## Design Principles

### 1. Zero Magic Numbers

All spacing, colors, typography, and animations use Design Tokens from the `DS` namespace:

```swift
// ❌ Bad: Magic numbers
Text("Hello").padding(8).font(.system(size: 14))

// ✅ Good: Design Tokens
Text("Hello").padding(DS.Spacing.s).font(DS.Typography.body)
```

### 2. Accessibility-First

Every component includes:
- VoiceOver labels and hints
- Keyboard navigation support
- Touch target sizes ≥44×44 pt (iOS)
- WCAG 2.1 AA contrast ratios (≥4.5:1)
- Dynamic Type support

### 3. Platform Adaptation

Components automatically adapt to each platform:
- **macOS**: 12pt spacing, keyboard shortcuts (⌘C, ⌘V)
- **iOS**: 16pt spacing, touch gestures, 44pt minimum touch targets
- **iPadOS**: Size class adaptation, pointer interactions

### 4. Composability

Build complex UIs by composing simple components:

```swift
InspectorPattern(title: "Box Details") {
    SectionHeader(title: "Metadata")

    KeyValueRow(key: "Type", value: "ftyp")
    KeyValueRow(key: "Size", value: "32 bytes")

    SectionHeader(title: "Status")

    Badge(text: "Valid", level: .success)
}
```

## Architecture Overview

### Design Tokens (Layer 0)

Foundation constants for spacing, colors, typography, radii, and animations. Accessed via the `DS` namespace:

- **Spacing**: `DS.Spacing.s` (8pt), `.m` (12pt), `.l` (16pt), `.xl` (24pt)
- **Colors**: `DS.Colors.infoBG`, `.warnBG`, `.errorBG`, `.successBG`
- **Typography**: `DS.Typography.body`, `.label`, `.title`, `.code`
- **Radius**: `DS.Radius.small` (6pt), `.card` (10pt), `.chip` (999pt)
- **Animation**: `DS.Animation.quick`, `.medium`, `.slow`, `.spring`

### View Modifiers (Layer 1)

Reusable style modifiers that apply Design Tokens to views:

- **BadgeChipStyle**: Semantic badge backgrounds with rounded corners
- **CardStyle**: Elevation and shadows for card containers
- **InteractiveStyle**: Hover and touch feedback
- **SurfaceStyle**: Material-based backgrounds (.thin, .regular, .thick)
- **CopyableModifier**: Universal `.copyable(text:)` modifier

### Components (Layer 2)

Building blocks for inspector UIs:

- **Badge**: Status indicators with semantic colors
- **Card**: Container with elevation and materials
- **KeyValueRow**: Key-value pair display with copyable text
- **SectionHeader**: Section titles with optional dividers
- **CopyableText**: Copyable text with visual feedback
- **Copyable**: Generic wrapper for making any view copyable

### Patterns (Layer 3)

Composite layouts for common use cases:

- **InspectorPattern**: Scrollable inspector with fixed header
- **SidebarPattern**: Navigation sidebar with sections
- **ToolbarPattern**: Platform-adaptive toolbar with shortcuts
- **BoxTreePattern**: Hierarchical tree view with lazy loading

### Contexts (Layer 4)

Environment and platform adaptation:

- **SurfaceStyleKey**: Environment key for surface materials
- **PlatformAdaptation**: Platform-specific spacing and layout
- **ColorSchemeAdapter**: Dark Mode adaptation
- **AccessibilityContext**: Reduce Motion, Dynamic Type, contrast

## Quality Standards

FoundationUI maintains high quality standards:

- **Test Coverage**: ≥80% code coverage
- **Documentation**: 100% DocC coverage for all public APIs
- **SwiftLint**: 0 violations (strict mode)
- **Magic Numbers**: 0 (100% DS token usage)
- **Accessibility**: ≥95% score (WCAG 2.1 AA)
- **Performance**: <5MB memory footprint, 60 FPS rendering

## Example: Building an ISO Inspector

```swift
import SwiftUI
import FoundationUI

struct ISOInspectorView: View {
    @State private var selectedBox: String?

    var body: some View {
        NavigationSplitView {
            // Sidebar with box hierarchy
            SidebarPattern(
                title: "ISO Structure",
                sections: [
                    SidebarSection(
                        title: "Boxes",
                        items: [
                            SidebarItem(id: "ftyp", title: "ftyp", icon: "doc"),
                            SidebarItem(id: "mdat", title: "mdat", icon: "film"),
                            SidebarItem(id: "moov", title: "moov", icon: "folder")
                        ]
                    )
                ],
                selection: $selectedBox
            )
        } detail: {
            // Inspector panel with metadata
            InspectorPattern(title: "Box Details") {
                SectionHeader(title: "Properties")

                KeyValueRow(key: "Type", value: selectedBox ?? "None")
                KeyValueRow(key: "Size", value: "1,024 bytes")
                KeyValueRow(key: "Offset", value: "0x00000000")

                SectionHeader(title: "Status")

                Badge(text: "Valid", level: .success, showIcon: true)
            }
            .material(.regular)
        }
    }
}
```

## Performance Optimization

FoundationUI is optimized for performance:

- **Lazy Loading**: BoxTreePattern uses LazyVStack for 1000+ nodes
- **Efficient State**: Minimal state updates, O(1) lookups
- **Conditional Rendering**: Platform-specific views with `#if` directives
- **Memory Management**: Weak references, no retain cycles
- **Build Time**: <10s clean build
- **Binary Size**: <500KB release build

## Accessibility Features

FoundationUI provides comprehensive accessibility support:

- **VoiceOver**: All components have descriptive labels and hints
- **Keyboard Navigation**: Full keyboard support with visible focus indicators
- **Dynamic Type**: Text scales from XS to XXXL
- **Reduce Motion**: Animations disabled when requested
- **Increase Contrast**: High-contrast colors for better visibility
- **Bold Text**: Adaptive font weights on iOS
- **Touch Targets**: ≥44×44 pt minimum size (iOS guidelines)
- **WCAG Compliance**: All colors meet ≥4.5:1 contrast ratios

## Contributing

FoundationUI follows strict development practices:

1. **Test-Driven Development (TDD)**: Write tests before implementation
2. **Zero Magic Numbers**: Use DS tokens exclusively
3. **100% Documentation**: All public APIs documented with DocC
4. **SwiftLint Compliance**: 0 violations required
5. **Accessibility-First**: WCAG 2.1 AA compliance mandatory

See the [contributing guide](https://github.com/YourOrg/FoundationUI/CONTRIBUTING.md) for details.

## License

FoundationUI is available under the MIT license. See the LICENSE file for more info.

## Resources

- [GitHub Repository](https://github.com/YourOrg/FoundationUI)
- [API Reference](https://docs.foundationui.dev/api)
- [Tutorials](https://docs.foundationui.dev/tutorials)
- [ISO Inspector Project](https://github.com/YourOrg/ISOInspector)

---

**FoundationUI** — Build accessible, platform-adaptive UIs with zero magic numbers.
