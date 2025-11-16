# Architecture

Understanding the Composable Clarity architecture behind FoundationUI.

## Overview

FoundationUI follows the **Composable Clarity** architecture, a layered design system approach that ensures consistency, reusability, and maintainability across all components. This architecture eliminates magic numbers and promotes a systematic approach to UI development.

## The Five Layers

### Layer 0: Design Tokens (DS)

The foundation of the design system. All constants for spacing, colors, typography, radii, and animations are defined in the `DS` namespace.

**Purpose**: Single source of truth for all design values.

**Example**:
```swift
// Spacing tokens
DS.Spacing.s   // 8pt
DS.Spacing.m   // 12pt
DS.Spacing.l   // 16pt
DS.Spacing.xl  // 24pt

// Color tokens
DS.Colors.infoBG
DS.Colors.warnBG
DS.Colors.errorBG
DS.Colors.successBG

// Typography tokens
DS.Typography.body
DS.Typography.label
DS.Typography.title
```

**Key Principle**: Zero magic numbers. Every numeric value comes from a Design Token.

### Layer 1: View Modifiers (Atoms)

Reusable style modifiers that apply Design Tokens to SwiftUI views. These are the smallest building blocks.

**Purpose**: Consistent styling patterns using tokens.

**Examples**:
- `BadgeChipStyle`
- `CardStyle`
- `InteractiveStyle`
- `SurfaceStyle`
- `CopyableModifier`

**Usage**:
```swift
Text("Error")
    .badgeChipStyle(level: .error)

VStack { /* content */ }
    .cardStyle(elevation: .medium, radius: DS.Radius.card)
```

**Key Principle**: Modifiers compose well with other modifiers and use only DS tokens.

### Layer 2: Components (Molecules)

Building blocks that combine modifiers and basic SwiftUI views into reusable components.

**Purpose**: Consistent UI elements with standard APIs.

**Examples**:
- `Badge`
- `Card`
- `KeyValueRow`
- `SectionHeader`
- `CopyableText`
- `Copyable`

**Usage**:
```swift
Badge(text: "Error", level: .error, showIcon: true)

Card {
    SectionHeader(title: "Properties")
    KeyValueRow(key: "Type", value: "ftyp")
}
.elevation(.medium)
```

**Key Principle**: Components use modifiers internally and expose semantic APIs.

### Layer 3: Patterns (Organisms)

Composite layouts that combine multiple components into common UI patterns.

**Purpose**: Reusable layouts for complex scenarios.

**Examples**:
- `InspectorPattern`
- `SidebarPattern`
- `ToolbarPattern`
- `BoxTreePattern`

**Usage**:
```swift
InspectorPattern(title: "File Properties") {
    SectionHeader(title: "Metadata")
    KeyValueRow(key: "Size", value: "1024 bytes")
    KeyValueRow(key: "Type", value: "ftyp")

    SectionHeader(title: "Status")
    Badge(text: "Valid", level: .success)
}
```

**Key Principle**: Patterns handle layout and composition, components handle presentation.

### Layer 4: Contexts (Environment)

Environment values and platform adaptation that enhance all other layers.

**Purpose**: Platform-specific behavior and adaptive layouts.

**Examples**:
- `SurfaceStyleKey`
- `PlatformAdaptation`
- `ColorSchemeAdapter`
- `AccessibilityContext`

**Usage**:
```swift
VStack { /* content */ }
    .environment(\.surfaceStyle, .thick)
    .platformAdaptive()
    .adaptiveColorScheme()
```

**Key Principle**: Contexts are orthogonal to components and provide cross-cutting concerns.

## Dependency Flow

The architecture enforces strict dependency rules:

```
Layer 4: Contexts
   ↓ (can enhance any layer)
Layer 3: Patterns ← depends on Components
   ↓
Layer 2: Components ← depends on Modifiers
   ↓
Layer 1: Modifiers ← depends on Tokens
   ↓
Layer 0: Design Tokens (no dependencies)
```

**Rules**:
1. Lower layers never depend on higher layers
2. Each layer can only depend on the layer directly below it
3. Contexts can enhance any layer but are optional
4. All layers ultimately depend on Design Tokens (Layer 0)

## Composability Example

Building a complete inspector UI by composing layers:

```swift
// Layer 3: Pattern (top-level layout)
InspectorPattern(title: "ISO Box Details") {

    // Layer 2: Components (building blocks)
    SectionHeader(title: "Properties")

    KeyValueRow(key: "Type", value: "ftyp")
        // Layer 1: Modifiers can be added
        .interactiveStyle()

    KeyValueRow(key: "Size", value: "32 bytes")

    Card {
        // Layer 2: Badge component
        Badge(text: "Valid", level: .success)
    }
    // Layer 1: Card modifier
    .cardStyle(elevation: .low)
}
// Layer 4: Context (environment)
.environment(\.surfaceStyle, .regular)
// Layer 4: Platform adaptation
.platformAdaptive()

// All layers use Layer 0: Design Tokens internally
// Result: Zero magic numbers, fully composable, platform-adaptive
```

## Benefits of Composable Clarity

### 1. Zero Magic Numbers

Every numeric value comes from a Design Token:

```swift
// ❌ Bad: Magic numbers scattered everywhere
VStack(spacing: 16) {
    Text("Title")
        .font(.system(size: 18, weight: .bold))
        .padding(12)
}
.background(Color(red: 0.2, green: 0.5, blue: 0.8))
.cornerRadius(8)

// ✅ Good: All values from Design Tokens
VStack(spacing: DS.Spacing.l) {
    Text("Title")
        .font(DS.Typography.title)
        .padding(DS.Spacing.m)
}
.background(DS.Colors.infoBG)
.cornerRadius(DS.Radius.small)
```

### 2. Consistency

Components automatically stay consistent because they share Design Tokens:

```swift
// Both use the same spacing token
Badge(text: "Error", level: .error)  // Uses DS.Spacing.s internally
Card { /* content */ }               // Uses DS.Spacing.s internally

// Changing DS.Spacing.s updates both components automatically
```

### 3. Platform Adaptation

Platform-specific behavior is encapsulated in Contexts:

```swift
// Same code, different behavior on each platform
VStack { /* content */ }
    .platformAdaptive()
    // macOS: 12pt spacing, keyboard shortcuts
    // iOS: 16pt spacing, touch gestures, 44pt touch targets
    // iPadOS: Size class adaptation, pointer interactions
```

### 4. Accessibility

Accessibility is built into every layer:

- **Layer 0**: High-contrast colors, readable font sizes
- **Layer 1**: VoiceOver labels, keyboard focus
- **Layer 2**: Touch target sizes, semantic labels
- **Layer 3**: Keyboard navigation, focus management
- **Layer 4**: Reduce Motion, Dynamic Type scaling

### 5. Testability

Each layer can be tested independently:

- **Design Tokens**: Validate values, ratios, consistency
- **Modifiers**: Test style application, token usage
- **Components**: Test API, state management, rendering
- **Patterns**: Test composition, navigation, performance
- **Contexts**: Test environment propagation, adaptation

### 6. Maintainability

Changes cascade predictably:

1. Update Design Token → all layers update automatically
2. Update Modifier → all components using it update
3. Update Component → all patterns using it update
4. Update Pattern → only views using that pattern update

### 7. Reusability

Components compose naturally:

```swift
// Reuse components in different contexts
let badgeView = Badge(text: "Error", level: .error)

// In a Card
Card {
    badgeView
}

// In an Inspector
InspectorPattern(title: "Status") {
    badgeView
}

// In a List
List {
    ForEach(items) { item in
        HStack {
            badgeView
            Text(item.name)
        }
    }
}
```

## Design Decisions

### Why Five Layers?

- **Layer 0 (Tokens)**: Required for zero magic numbers
- **Layer 1 (Modifiers)**: Enables reusable styling patterns
- **Layer 2 (Components)**: Standard building blocks for all UIs
- **Layer 3 (Patterns)**: Solves common layout problems
- **Layer 4 (Contexts)**: Platform adaptation and cross-cutting concerns

Fewer layers would require repeating code. More layers would add complexity without benefit.

### Why Strict Dependencies?

Strict dependency rules prevent:
- Circular dependencies
- Tight coupling between layers
- Unexpected side effects from changes
- Difficulty understanding code flow

### Why Design Tokens First?

Starting with Design Tokens ensures:
- Consistent values from day one
- No magic numbers accumulate
- Design system is documented upfront
- Changes are systematic, not ad-hoc

## Migration Strategy

If you have existing SwiftUI code with magic numbers, migrate incrementally:

### Step 1: Extract Design Tokens
```swift
// Before
.padding(8)
.font(.system(size: 14))

// After
.padding(DS.Spacing.s)
.font(DS.Typography.body)
```

### Step 2: Create Modifiers
```swift
// Before
Text("Error")
    .padding(DS.Spacing.s)
    .background(DS.Colors.errorBG)
    .cornerRadius(DS.Radius.chip)

// After
Text("Error")
    .badgeChipStyle(level: .error)
```

### Step 3: Extract Components
```swift
// Before
HStack(spacing: DS.Spacing.m) {
    Text("Type:")
        .font(DS.Typography.label)
    Text("ftyp")
        .font(DS.Typography.code)
}

// After
KeyValueRow(key: "Type", value: "ftyp")
```

### Step 4: Build Patterns
```swift
// Before: Repeated layout code in every view
VStack {
    Text(title).font(DS.Typography.title)
    Divider()
    ScrollView {
        // content
    }
}

// After: Reusable pattern
InspectorPattern(title: title) {
    // content
}
```

## Best Practices

### 1. Always Use Design Tokens

```swift
// ❌ Never use magic numbers
.padding(12)

// ✅ Always use tokens
.padding(DS.Spacing.m)
```

### 2. Compose Components, Don't Inherit

```swift
// ❌ Don't create component hierarchies
class MyBadge: Badge { }

// ✅ Compose components
struct MyView: View {
    var body: some View {
        Badge(text: "Error", level: .error)
    }
}
```

### 3. Keep Modifiers Simple

```swift
// ❌ Don't create complex modifier chains
.modifier(ComplexModifier(param1: x, param2: y, param3: z))

// ✅ Compose simple modifiers
.badgeChipStyle(level: .error)
.interactiveStyle()
```

### 4. Use Patterns for Layouts

```swift
// ❌ Don't repeat layout code
VStack {
    Text(title)
    Divider()
    ScrollView { content }
}

// ✅ Use patterns
InspectorPattern(title: title) {
    content
}
```

### 5. Let Contexts Handle Platform Differences

```swift
// ❌ Don't write platform-specific code everywhere
#if os(macOS)
    .padding(12)
#else
    .padding(16)
#endif

// ✅ Use platform adaptation
.platformAdaptive()
```

## Further Reading

- <doc:DesignTokens>
- <doc:Components>
- <doc:Patterns>
- <doc:Accessibility>
- <doc:Performance>

## See Also

- ``DS``
- ``BadgeChipStyle``
- ``Badge``
- ``InspectorPattern``
- ``PlatformAdaptation``
