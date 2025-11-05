# Modifiers

View Modifiers for consistent styling (Layer 1).

## Overview

FoundationUI View Modifiers provide reusable styling patterns that apply Design Tokens to SwiftUI views. These modifiers form the foundation for all component styling, ensuring consistency and zero magic numbers.

## Available Modifiers

### BadgeChipStyle

Applies semantic badge styling with rounded corners and semantic colors.

```swift
Text("ERROR")
    .badgeChipStyle(level: .error)
```

**Levels**:
- `.info` — Neutral informational (gray)
- `.warning` — Warning or caution (orange)
- `.error` — Error or failure (red)
- `.success` — Success or completion (green)

**Features**:
- Semantic color coding (WCAG 2.1 AA compliant)
- VoiceOver-friendly accessibility labels
- Pill-shaped with DS.Radius.chip
- Consistent padding with DS.Spacing.s

**Use Cases**: Status badges, category chips, validation indicators

### CardStyle

Applies elevation and shadows for visual depth.

```swift
VStack {
    Text("Content")
}
.cardStyle(elevation: .medium, radius: DS.Radius.card)
```

**Elevation Levels**:
- `.none` — Flat appearance (no shadow)
- `.low` — Subtle shadow (radius: 2pt, opacity: 0.1)
- `.medium` — Moderate shadow (radius: 4pt, opacity: 0.15)
- `.high` — Prominent shadow (radius: 8pt, opacity: 0.2)

**Features**:
- Platform-adaptive shadows (iOS/macOS)
- Configurable corner radius
- Material-based backgrounds
- Visual hierarchy through depth

**Use Cases**: Cards, panels, elevated containers, dialogs

### InteractiveStyle

Adds hover and touch feedback for interactive elements.

```swift
Button("Action") { }
    .interactiveStyle()
```

**Features**:
- Hover effects on macOS (scale, opacity)
- Touch feedback on iOS/iPadOS
- Keyboard focus indicators
- Accessibility hints

**Platform Behavior**:
- **macOS**: Hover scale effect, cursor changes
- **iOS**: Touch highlight, haptic feedback
- **iPadOS**: Pointer interactions, hover states

**Use Cases**: Buttons, interactive cards, clickable rows

### SurfaceStyle

Applies material-based backgrounds.

```swift
VStack { }
    .surfaceStyle(material: .regular)
```

**Material Types**:
- `.thin` — Subtle translucency
- `.regular` — Balanced opacity (default)
- `.thick` — Prominent material effect
- `.ultraThin` — Maximum translucency
- `.ultraThick` — Maximum opacity

**Features**:
- Platform-adaptive materials
- Automatic Dark Mode adaptation
- System blur effects
- Depth perception

**Use Cases**: Panels, overlays, sidebars, toolbars

### CopyableModifier

Makes any view copyable with visual feedback.

```swift
Text("Value")
    .copyable(text: "Value to copy", showFeedback: true)
```

**Features**:
- Platform-specific clipboard (NSPasteboard/UIPasteboard)
- Visual "Copied!" feedback (animated)
- Keyboard shortcut (⌘C on macOS)
- VoiceOver announcements
- Configurable feedback display

**Use Cases**: UUIDs, hex values, technical strings, metadata

## Design Principles

### 1. Zero Magic Numbers

All modifiers use Design Tokens exclusively:

```swift
// ✅ BadgeChipStyle uses DS tokens internally
.badgeChipStyle(level: .error)
// → DS.Colors.errorBG, DS.Spacing.s, DS.Radius.chip, DS.Typography.label
```

### 2. Composability

Modifiers compose naturally:

```swift
Text("Badge")
    .badgeChipStyle(level: .success)
    .interactiveStyle()      // Add hover
    .copyable(text: "Badge") // Make copyable
```

### 3. Platform Adaptation

Modifiers adapt to each platform automatically:

```swift
.interactiveStyle()
// macOS: Hover effects
// iOS: Touch feedback
// iPadOS: Pointer interactions
```

## Usage Patterns

### Basic Styling

```swift
// Badge styling
Text("NEW")
    .badgeChipStyle(level: .info)

// Card elevation
Card {
    Text("Content")
}
.cardStyle(elevation: .medium)
```

### Interactive Elements

```swift
// Interactive card
Card {
    Text("Tap me")
}
.interactiveStyle()
.onTapGesture {
    // Action
}
```

### Copyable Content

```swift
// Copyable row
HStack {
    Text("UUID:")
    Text(uuid)
        .copyable(text: uuid)
}
```

## Further Reading

- <doc:BuildingComponents> — Using modifiers in custom components
- <doc:DesignTokens> — Design Tokens used by modifiers
- <doc:Components> — Components built with modifiers
- ``BadgeChipStyle`` — Badge modifier API
- ``CardStyle`` — Card modifier API
- ``InteractiveStyle`` — Interactive modifier API
- ``SurfaceStyle`` — Surface modifier API
- ``CopyableModifier`` — Copyable modifier API

## See Also

- <doc:DesignTokens>
- <doc:Components>
- <doc:Architecture>
- ``BadgeLevel``
- ``CardElevation``
- ``SurfaceMaterial``
