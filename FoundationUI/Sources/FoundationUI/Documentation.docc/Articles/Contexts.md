# Contexts

Environment values and platform adaptation (Layer 4).

## Overview

FoundationUI Contexts provide environment values and platform adaptation that enhance all other layers. Contexts are orthogonal to components, providing cross-cutting concerns like color scheme adaptation, platform-specific behavior, and accessibility preferences.

## Available Contexts

### SurfaceStyleKey

Environment key for surface materials.

```swift
@Environment(\.surfaceStyle) var surfaceStyle

VStack {
    Text("Content")
}
.environment(\.surfaceStyle, .thick)
```

**Material Types**:
- `.thin` — Subtle translucency
- `.regular` — Balanced opacity (default)
- `.thick` — Prominent material effect
- `.ultraThin` — Maximum translucency
- `.ultraThick` — Maximum opacity

**Features**:
- Environment propagation to child views
- Platform-adaptive rendering
- Automatic Dark Mode adaptation
- Material blur effects

**Use Cases**: Panels, overlays, sidebars, inspector backgrounds

### PlatformAdaptation

Platform-specific spacing and layout modifiers.

```swift
VStack {
    Text("Content")
}
.platformAdaptive()  // Applies platform-appropriate spacing
```

**Platform Detection**:

```swift
#if os(macOS)
    // macOS-specific code
#elseif os(iOS)
    // iOS/iPadOS-specific code
#endif

// Or use PlatformAdapter
let isMacOS = PlatformAdapter.isMacOS
let isIOS = PlatformAdapter.isIOS
```

**Features**:
- Automatic spacing adaptation (12pt macOS, 16pt iOS)
- Touch target sizing (≥44×44 pt iOS, ≥24×24 pt macOS)
- Platform-specific behaviors
- Conditional compilation support

**Platform Differences**:
- **macOS**: Keyboard shortcuts, hover effects, focus rings, 12pt default spacing
- **iOS**: Touch gestures, 44pt touch targets, 16pt default spacing
- **iPadOS**: Size classes, pointer interactions, adaptive layouts

### ColorSchemeAdapter

Automatic Dark Mode adaptation.

```swift
@Environment(\.colorScheme) var colorScheme

var body: some View {
    Text("Hello")
        .foregroundColor(colorScheme == .dark ? .white : .black)
}

// Or use ColorSchemeAdapter
let isDarkMode = ColorSchemeAdapter.isDarkMode
```

**Features**:
- Automatic light/dark mode detection
- Adaptive color properties (background, text, border, divider)
- System color integration
- Platform-specific color handling

**Adaptive Colors**:

```swift
ColorSchemeAdapter.background   // Adaptive background
ColorSchemeAdapter.text         // Adaptive text color
ColorSchemeAdapter.border       // Adaptive border color
ColorSchemeAdapter.divider      // Adaptive divider color
```

**Use Cases**: Theme switching, color adaptation, dark mode support

### AccessibilityContext

User accessibility preferences and scaling.

```swift
@Environment(\.accessibilityContext) var a11yContext

Text("Hello")
    .font(a11yContext.scaledFont(for: DS.Typography.body))
    .padding(a11yContext.scaledSpacing(DS.Spacing.m))
```

**Accessibility Preferences**:
- `reduceMotion` — Disable animations when requested
- `increaseContrast` — Use high-contrast colors
- `boldText` — Use bold font weights (iOS)
- `sizeCategory` — Current Dynamic Type size
- `isAccessibilitySize` — True for extra-large text sizes

**Features**:
- Reduce Motion support (animations → instant)
- Increase Contrast mode (higher contrast colors)
- Bold Text handling (iOS legibilityWeight)
- Dynamic Type scaling (XS to XXXL)
- Automatic font and spacing scaling

**Adaptive Methods**:

```swift
// Scale font
a11yContext.scaledFont(for: DS.Typography.body)

// Scale spacing
a11yContext.scaledSpacing(DS.Spacing.m)

// Animation with motion preference
a11yContext.animation(DS.Animation.quick)
// Returns nil if Reduce Motion is enabled
```

**Use Cases**: Accessibility compliance, WCAG 2.1 Level AA, user preference adaptation

## Using Contexts

### Environment Propagation

```swift
// Set at top level
ContentView()
    .environment(\.surfaceStyle, .regular)

// Access in child views
struct ChildView: View {
    @Environment(\.surfaceStyle) var surfaceStyle

    var body: some View {
        Text("Material: \(surfaceStyle)")
    }
}
```

### Platform Adaptation

```swift
VStack(spacing: DS.Spacing.platformDefault) {
    // macOS: 12pt spacing
    // iOS: 16pt spacing
}
.platformAdaptive()  // Applies platform-specific behavior
```

### Accessibility Adaptation

```swift
@Environment(\.accessibilityContext) var a11yContext

Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animation(a11yContext.animation(DS.Animation.medium), value: isVisible)
// Animation disabled if Reduce Motion is on
```

## Context Composition

Contexts work together seamlessly:

```swift
VStack(spacing: DS.Spacing.platformDefault) {
    Text("Title")
        .font(a11yContext.scaledFont(for: DS.Typography.title))
}
.environment(\.surfaceStyle, .regular)
.adaptiveColorScheme()           // Dark Mode
.platformAdaptive()              // Platform spacing
.adaptiveAccessibility()         // Accessibility preferences
```

## Design Principles

### 1. Orthogonal to Components

Contexts don't depend on components; they enhance them:

```swift
// Badge works without contexts
Badge(text: "Error", level: .error)

// Badge enhanced with contexts
Badge(text: "Error", level: .error)
    .environment(\.surfaceStyle, .thick)
    .platformAdaptive()
```

### 2. Environment-Based

Contexts use SwiftUI environment for propagation:

```swift
// Set once at top level
WindowGroup {
    ContentView()
        .environment(\.surfaceStyle, .regular)
}

// All child views inherit the value
```

### 3. Platform-Adaptive

Contexts automatically adapt to each platform:

```swift
.platformAdaptive()
// macOS: 12pt spacing, keyboard shortcuts
// iOS: 16pt spacing, touch gestures
// iPadOS: Size classes, pointer interactions
```

## Complete Example

Using all contexts together:

```swift
@main
struct MyApp: App {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.surfaceStyle, .regular)
                .adaptiveColorScheme()
                .adaptiveAccessibility()
                .platformAdaptive()
        }
    }
}

struct ContentView: View {
    @Environment(\.surfaceStyle) var surfaceStyle
    @Environment(\.accessibilityContext) var a11yContext

    var body: some View {
        VStack(spacing: DS.Spacing.platformDefault) {
            Text("Hello")
                .font(a11yContext.scaledFont(for: DS.Typography.body))
        }
        .surfaceStyle(material: surfaceStyle)
    }
}
```

## Further Reading

- <doc:PlatformAdaptation> — Platform adaptation tutorial
- <doc:Accessibility> — Accessibility best practices
- <doc:Architecture> — Understanding Layer 4 (Contexts)
- ``SurfaceStyleKey`` — Surface material environment key
- ``PlatformAdaptation`` — Platform adaptation API
- ``ColorSchemeAdapter`` — Color scheme API
- ``AccessibilityContext`` — Accessibility API

## See Also

- <doc:Architecture>
- <doc:Accessibility>
- <doc:PlatformAdaptation>
- ``SurfaceStyleKey``
- ``PlatformAdaptation``
- ``ColorSchemeAdapter``
- ``AccessibilityContext``
