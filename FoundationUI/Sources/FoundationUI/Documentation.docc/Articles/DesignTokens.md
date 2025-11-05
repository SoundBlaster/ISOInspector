# Design Tokens

Complete reference for FoundationUI Design Tokens (Layer 0).

## Overview

Design Tokens are the foundation of FoundationUI's **zero magic numbers** principle. All spacing, colors, typography, radii, and animations are defined as constants in the `DS` namespace, ensuring consistency across all components and platforms.

## The DS Namespace

Access all Design Tokens through the `DS` enum:

```swift
import FoundationUI

// Spacing
let padding = DS.Spacing.l  // 16pt

// Colors
let background = DS.Colors.infoBG  // Semantic blue background

// Typography
let font = DS.Typography.body  // Standard body font

// Radius
let cornerRadius = DS.Radius.card  // 10pt rounded corners

// Animation
let duration = DS.Animation.quick  // 0.15s snappy animation
```

## Spacing Tokens

### Values

| Token | Value | Use Case |
|-------|-------|----------|
| `DS.Spacing.s` | 8pt | Compact padding, tight spacing |
| `DS.Spacing.m` | 12pt | Default padding, moderate spacing |
| `DS.Spacing.l` | 16pt | Generous padding, comfortable spacing |
| `DS.Spacing.xl` | 24pt | Section spacing, large gaps |

### Platform-Specific Defaults

```swift
// Platform-adaptive default spacing
DS.Spacing.platformDefault
// macOS: 12pt (m)
// iOS/iPadOS: 16pt (l)
```

### Usage Examples

```swift
// VStack spacing
VStack(spacing: DS.Spacing.l) {
    Text("Title")
    Text("Subtitle")
}

// Padding
Text("Hello")
    .padding(DS.Spacing.m)

// Custom spacing
HStack(spacing: DS.Spacing.xl) {
    Badge(text: "Info", level: .info)
    Badge(text: "Success", level: .success)
}
```

### When to Use Each Spacing

- **`s` (8pt)**: Tight spacing within components (badge padding, chip spacing)
- **`m` (12pt)**: Default padding for most components (card padding, button padding)
- **`l` (16pt)**: Comfortable spacing between elements (list item spacing)
- **`xl` (24pt)**: Section spacing, visual separation (header spacing, group spacing)

## Typography Tokens

### Font Styles

| Token | Style | Use Case |
|-------|-------|----------|
| `DS.Typography.label` | `.subheadline` | Small labels, captions |
| `DS.Typography.body` | `.body` | Standard text, descriptions |
| `DS.Typography.title` | `.title3` | Section titles, headers |
| `DS.Typography.caption` | `.caption` | Footnotes, helper text |
| `DS.Typography.code` | `.body.monospaced()` | Code, hex values, IDs |
| `DS.Typography.headline` | `.headline` | Prominent titles |
| `DS.Typography.subheadline` | `.subheadline` | Secondary headers |

### Dynamic Type Support

All typography tokens support Dynamic Type automatically via SwiftUI.Font:

```swift
Text("Hello")
    .font(DS.Typography.body)
// Scales from XS to XXXL based on user settings
```

### Usage Examples

```swift
// Section header
Text("Properties")
    .font(DS.Typography.title)
    .fontWeight(.semibold)

// Key-value display
HStack {
    Text("Type:")
        .font(DS.Typography.label)
        .foregroundStyle(.secondary)

    Text("ftyp")
        .font(DS.Typography.code)  // Monospaced for IDs
}

// Helper text
Text("Drag ISO file to inspect")
    .font(DS.Typography.caption)
    .foregroundStyle(.tertiary)
```

### When to Use Each Typography

- **`label`**: Small, secondary text (form labels, metadata keys)
- **`body`**: Default text (descriptions, content)
- **`title`**: Section headers, prominent titles
- **`caption`**: Footnotes, help text, timestamps
- **`code`**: Technical values (hex, UUIDs, file sizes)
- **`headline`**: Page titles, main headers
- **`subheadline`**: Subsection headers

## Color Tokens

### Semantic Colors

| Token | Purpose | WCAG Contrast |
|-------|---------|---------------|
| `DS.Colors.infoBG` | Informational badges, info states | ≥4.5:1 |
| `DS.Colors.warnBG` | Warning badges, caution states | ≥4.5:1 |
| `DS.Colors.errorBG` | Error badges, failure states | ≥4.5:1 |
| `DS.Colors.successBG` | Success badges, valid states | ≥4.5:1 |

### Additional Colors

| Token | Purpose |
|-------|---------|
| `DS.Colors.accent` | Primary accent color (links, buttons) |
| `DS.Colors.secondary` | Secondary UI elements |
| `DS.Colors.tertiary` | Tertiary UI elements |
| `DS.Colors.textPrimary` | Primary text color |
| `DS.Colors.textSecondary` | Secondary text color |
| `DS.Colors.textPlaceholder` | Placeholder text |

### Dark Mode Support

All colors automatically adapt to Dark Mode using SwiftUI system colors:

```swift
// Automatically adapts to Light/Dark mode
Badge(text: "Error", level: .error)
// Light mode: Red background with dark text
// Dark mode: Red background with light text
```

### Usage Examples

```swift
// Semantic badge backgrounds
Badge(text: "Info", level: .info)        // Uses DS.Colors.infoBG
Badge(text: "Warning", level: .warning)  // Uses DS.Colors.warnBG

// Custom backgrounds
Card {
    Text("Content")
}
.background(DS.Colors.accent)

// Text colors
Text("Primary text")
    .foregroundColor(DS.Colors.textPrimary)

Text("Secondary text")
    .foregroundColor(DS.Colors.textSecondary)
```

### WCAG 2.1 Compliance

All semantic colors meet WCAG 2.1 AA standards (≥4.5:1 contrast ratio):

- **infoBG**: Blue with sufficient contrast
- **warnBG**: Yellow/Orange with dark text
- **errorBG**: Red with sufficient contrast
- **successBG**: Green with sufficient contrast

Test contrast with AccessibilityHelpers:

```swift
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: DS.Colors.textPrimary,
    background: DS.Colors.infoBG
)
// Returns: ≥4.5:1 (WCAG AA compliant)
```

## Radius Tokens

### Corner Radii

| Token | Value | Use Case |
|-------|-------|----------|
| `DS.Radius.small` | 6pt | Tight corners, compact elements |
| `DS.Radius.medium` | 8pt | Standard corners, moderate rounding |
| `DS.Radius.card` | 10pt | Card containers, panels |
| `DS.Radius.chip` | 999pt | Pill-shaped badges, chips |

### Usage Examples

```swift
// Card with rounded corners
RoundedRectangle(cornerRadius: DS.Radius.card)
    .fill(DS.Colors.accent)

// Badge with pill shape
Text("Badge")
    .padding(DS.Spacing.s)
    .background(
        Capsule()  // Or use DS.Radius.chip with RoundedRectangle
            .fill(DS.Colors.infoBG)
    )

// Compact button
Button("Action") { }
    .buttonStyle(.bordered)
    .cornerRadius(DS.Radius.small)
```

### When to Use Each Radius

- **`small` (6pt)**: Buttons, small elements, tight corners
- **`medium` (8pt)**: Default for most rectangular elements
- **`card` (10pt)**: Cards, panels, containers (matches iOS design)
- **`chip` (999pt)**: Badges, chips, pills (fully rounded ends)

## Animation Tokens

### Animation Presets

| Token | Duration | Curve | Use Case |
|-------|----------|-------|----------|
| `DS.Animation.quick` | 0.15s | Snappy (easeOut) | Hover states, interactions |
| `DS.Animation.medium` | 0.25s | EaseInOut | Transitions, reveals |
| `DS.Animation.slow` | 0.35s | EaseInOut | Major transitions |
| `DS.Animation.spring` | Spring | Spring (response: 0.3) | Bouncy interactions |

### Usage Examples

```swift
// Fade in with medium animation
Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animation(DS.Animation.medium, value: isVisible)

// Hover effect with quick animation
Rectangle()
    .fill(isHovered ? Color.blue : Color.gray)
    .animation(DS.Animation.quick, value: isHovered)

// Spring animation for playful interactions
Circle()
    .scaleEffect(isPressed ? 0.9 : 1.0)
    .animation(DS.Animation.spring, value: isPressed)
```

### Reduce Motion Support

Use `ifMotionEnabled` helper to respect Reduce Motion accessibility settings:

```swift
// Animation only if motion is enabled
Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animation(DS.Animation.medium.ifMotionEnabled(), value: isVisible)
// If Reduce Motion is ON: No animation (instant change)
// If Reduce Motion is OFF: Smooth 0.25s animation
```

### When to Use Each Animation

- **`quick` (0.15s)**: Fast feedback (hover, focus, button press)
- **`medium` (0.25s)**: Standard transitions (expand/collapse, fade in/out)
- **`slow` (0.35s)**: Major state changes (modal present, navigation)
- **`spring`**: Playful, physical interactions (drag, bounce, rubber-band)

## Creating Custom Tokens

If you need custom tokens for your project, extend the `DS` namespace:

```swift
extension DS {
    enum CustomSpacing {
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    enum CustomColors {
        static let brandPrimary = Color(hex: "#FF6B6B")
        static let brandSecondary = Color(hex: "#4ECDC4")
    }
}

// Usage
Text("Title")
    .padding(DS.CustomSpacing.xxl)
    .foregroundColor(DS.CustomColors.brandPrimary)
```

**Best Practice**: Only add custom tokens if existing tokens don't cover your use case. Prefer reusing existing tokens for consistency.

## Token Usage Guidelines

### ✅ Do's

```swift
// ✅ Use tokens for all spacing
VStack(spacing: DS.Spacing.l) { }

// ✅ Use tokens for all padding
.padding(DS.Spacing.m)

// ✅ Use tokens for all colors
.foregroundColor(DS.Colors.textPrimary)

// ✅ Use tokens for all typography
.font(DS.Typography.body)

// ✅ Use tokens for all radii
.cornerRadius(DS.Radius.card)

// ✅ Use tokens for all animations
.animation(DS.Animation.quick, value: state)
```

### ❌ Don'ts

```swift
// ❌ Never use magic numbers
VStack(spacing: 16) { }  // Use DS.Spacing.l instead

// ❌ Never use hardcoded colors
.foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.8))  // Use DS.Colors

// ❌ Never use system font sizes directly
.font(.system(size: 14))  // Use DS.Typography.body

// ❌ Never use hardcoded radii
.cornerRadius(8)  // Use DS.Radius.medium

// ❌ Never use hardcoded durations
.animation(.easeInOut(duration: 0.25), value: state)  // Use DS.Animation.medium
```

## Token Validation

FoundationUI includes comprehensive tests to validate Design Tokens:

```swift
// From TokenValidationTests.swift

// Spacing is in ascending order
assert(DS.Spacing.s < DS.Spacing.m)
assert(DS.Spacing.m < DS.Spacing.l)
assert(DS.Spacing.l < DS.Spacing.xl)

// All semantic colors exist
assert(DS.Colors.infoBG != nil)
assert(DS.Colors.warnBG != nil)

// Animation durations are reasonable
assert(DS.Animation.quick < DS.Animation.medium)
assert(DS.Animation.medium < DS.Animation.slow)
```

Run tests to verify token integrity:

```bash
swift test --filter TokenValidationTests
```

## Platform-Specific Considerations

### macOS

- Default spacing: `DS.Spacing.m` (12pt) — more compact
- Focus indicators: Visible with keyboard navigation
- Hover states: Use `InteractiveStyle` modifier

### iOS/iPadOS

- Default spacing: `DS.Spacing.l` (16pt) — more generous
- Touch targets: Minimum 44×44 pt (use `PlatformAdaptation`)
- Gestures: Tap, swipe, long press support

### Cross-Platform

Use `platformDefault` for automatic adaptation:

```swift
VStack(spacing: DS.Spacing.platformDefault) {
    // 12pt on macOS, 16pt on iOS/iPadOS
}
```

## Token Evolution

Design Tokens can evolve over time. When updating tokens:

1. **Update the token value** in the DS namespace
2. **All components update automatically** (no code changes needed)
3. **Run tests** to verify no regressions
4. **Update documentation** if token usage changes

Example: Increasing default spacing:

```swift
// Before
enum Spacing {
    static let l: CGFloat = 16
}

// After (more generous spacing)
enum Spacing {
    static let l: CGFloat = 20
}

// All components using DS.Spacing.l automatically get new spacing
// No need to update every component individually
```

## Debugging Token Usage

Use SwiftLint to detect magic numbers:

```yaml
# .swiftlint.yml
custom_rules:
  no_magic_numbers:
    name: "No Magic Numbers"
    regex: '\.padding\(\d+\)|\.frame\(.*:\s*\d+\)|\.font\(\.system\(size:\s*\d+\)\)'
    message: "Use Design Tokens instead of magic numbers"
    severity: error
```

Run SwiftLint:

```bash
swiftlint lint --strict
# Reports any magic number usage as error
```

## Further Reading

- <doc:Architecture> — Understanding the layered architecture
- <doc:Components> — How components use Design Tokens
- <doc:Accessibility> — WCAG compliance and accessibility considerations
- ``DS`` — Complete DS namespace API reference

## See Also

- ``DS/Spacing``
- ``DS/Typography``
- ``DS/Colors``
- ``DS/Radius``
- ``DS/Animation``
