# Components

Building blocks for inspector UIs (Layer 2).

## Overview

FoundationUI components are the building blocks for creating accessible, platform-adaptive UIs. Each component is built on top of Design Tokens and View Modifiers, ensuring consistency and zero magic numbers throughout your application.

## Component Catalog

### Badge

Status indicators with semantic colors.

```swift
Badge(text: "Error", level: .error, showIcon: true)
Badge(text: "Success", level: .success)
Badge(text: "Warning", level: .warning, showIcon: true)
Badge(text: "Info", level: .info)
```

**Features**:
- Four semantic levels (info, warning, error, success)
- Optional SF Symbol icons
- Automatic VoiceOver labels
- WCAG 2.1 AA contrast ratios
- Pill-shaped with DS.Radius.chip

**Use Cases**:
- ISO box type indicators (ftyp, mdat, moov)
- Validation status display
- File format badges
- Error and warning indicators

### Card

Container with elevation and materials.

```swift
Card {
    VStack {
        SectionHeader(title: "Properties")
        KeyValueRow(key: "Type", value: "ftyp")
    }
}
.elevation(.medium)
.material(.regular)
```

**Features**:
- Four elevation levels (none, low, medium, high)
- Material backgrounds (.thin, .regular, .thick)
- Configurable corner radius
- Platform-adaptive shadows
- Generic content with ViewBuilder

**Use Cases**:
- Inspector panels
- Grouped content sections
- Metadata displays
- Dialog containers

### KeyValueRow

Key-value pair display with copyable text.

```swift
KeyValueRow(key: "UUID", value: "550e8400-e29b-41d4-a716-446655440000")
KeyValueRow(key: "Size", value: "1,024 bytes")
KeyValueRow(key: "Offset", value: "0x00000000", layout: .vertical)
```

**Features**:
- Horizontal and vertical layouts
- Monospaced font for values (DS.Typography.code)
- Optional copyable text integration
- Platform-specific clipboard (NSPasteboard/UIPasteboard)
- Semantic styling (label + value)

**Use Cases**:
- ISO box metadata (type, size, offset)
- File properties display
- Hex value display
- Technical metadata

### SectionHeader

Section titles with optional dividers.

```swift
SectionHeader(title: "Box Structure")
SectionHeader(title: "Validation", showDivider: true)
```

**Features**:
- Uppercase title styling
- Optional divider line
- Accessibility heading trait
- Consistent spacing (DS.Spacing)
- Semantic font (DS.Typography.title)

**Use Cases**:
- Inspector section titles
- Content group headers
- List section headers

### CopyableText

Text with copy-to-clipboard button.

```swift
CopyableText(
    text: "550e8400-e29b-41d4-a716-446655440000",
    label: "UUID"
)
```

**Features**:
- Visual "Copied!" feedback
- Platform-specific clipboard (NSPasteboard/UIPasteboard)
- Keyboard shortcut (⌘C on macOS)
- VoiceOver announcements
- Automatic success indicator

**Use Cases**:
- UUIDs and IDs
- Hex values and addresses
- File paths
- Technical strings

### Copyable

Generic wrapper for making any view copyable.

```swift
Copyable(text: "Value to copy") {
    HStack {
        Image(systemName: "doc")
        Text("Custom View")
    }
}
.showFeedback(true)
```

**Features**:
- Generic ViewBuilder support
- Works with any content type
- Uses CopyableModifier internally
- Optional visual feedback
- Full accessibility support

**Use Cases**:
- Custom copyable layouts
- Complex copyable views
- Badge + copyable text combinations
- Card + copyable metadata

## Component Composition

Components are designed to compose naturally:

### Inspector Panel

```swift
Card {
    VStack(spacing: DS.Spacing.l) {
        SectionHeader(title: "File Properties")

        KeyValueRow(key: "Name", value: "sample.mp4")
        KeyValueRow(key: "Size", value: "10.5 MB")

        SectionHeader(title: "Format")

        KeyValueRow(key: "Brand", value: "isom")
        KeyValueRow(key: "Version", value: "0x00000200")

        SectionHeader(title: "Status")

        HStack(spacing: DS.Spacing.m) {
            Badge(text: "Valid", level: .success, showIcon: true)
            Badge(text: "Playable", level: .success)
        }
    }
}
.elevation(.medium)
```

### Copyable Metadata

```swift
Card {
    VStack(spacing: DS.Spacing.m) {
        Copyable(text: uuid) {
            KeyValueRow(key: "UUID", value: uuid)
        }

        Copyable(text: checksum) {
            KeyValueRow(key: "Checksum", value: checksum)
        }
    }
}
.elevation(.low)
```

### Status Dashboard

```swift
VStack(spacing: DS.Spacing.xl) {
    SectionHeader(title: "Validation Results")

    Card {
        HStack(spacing: DS.Spacing.m) {
            Badge(text: "Structure", level: .success, showIcon: true)
            Badge(text: "Checksum", level: .success, showIcon: true)
            Badge(text: "Format", level: .warning)
        }
    }
    .elevation(.low)

    Text("2 checks passed, 1 warning")
        .font(DS.Typography.caption)
        .foregroundStyle(.secondary)
}
```

## Design Principles

### 1. Zero Magic Numbers

All components use Design Tokens exclusively:

```swift
// ✅ Badge uses DS tokens
Badge(text: "Error", level: .error)
// Internally: DS.Spacing.s, DS.Radius.chip, DS.Colors.errorBG

// ✅ KeyValueRow uses DS tokens
KeyValueRow(key: "Type", value: "ftyp")
// Internally: DS.Spacing.m, DS.Typography.label, DS.Typography.code
```

### 2. Accessibility-First

All components include:
- VoiceOver labels and hints
- Keyboard navigation support
- Touch target sizes ≥44×44 pt (iOS)
- WCAG 2.1 AA contrast ratios
- Dynamic Type support

```swift
Badge(text: "Error", level: .error)
// VoiceOver: "Error badge, error"

KeyValueRow(key: "Type", value: "ftyp")
// VoiceOver: "Type: ftyp"

CopyableText(text: "UUID")
// VoiceOver: "UUID, copyable, button. Double tap to copy."
```

### 3. Platform Adaptation

Components automatically adapt to each platform:

**macOS**:
- 12pt default spacing
- Keyboard shortcuts (⌘C for copyable text)
- Hover effects on interactive elements

**iOS/iPadOS**:
- 16pt default spacing
- 44pt minimum touch targets
- Touch gestures (tap, long press)

```swift
// Same code, platform-adaptive behavior
CopyableText(text: "Value")
// macOS: ⌘C shortcut, NSPasteboard
// iOS: Touch to copy, UIPasteboard
```

### 4. Composability

Components work together seamlessly:

```swift
// Compose Badge + Copyable
Copyable(text: "ftyp") {
    Badge(text: "ftyp", level: .info)
}

// Compose Card + SectionHeader + KeyValueRow
Card {
    SectionHeader(title: "Metadata")
    KeyValueRow(key: "Type", value: "ftyp")
}

// Compose multiple components
InspectorPattern(title: "Details") {
    SectionHeader(title: "Properties")
    KeyValueRow(key: "Size", value: "32 bytes")
    Badge(text: "Valid", level: .success)
}
```

## Component APIs

### Badge API

```swift
public struct Badge: View {
    public init(
        text: String,
        level: BadgeLevel,
        showIcon: Bool = false
    )
}

public enum BadgeLevel {
    case info, warning, error, success
}
```

### Card API

```swift
public struct Card<Content: View>: View {
    public init(@ViewBuilder content: () -> Content)

    public func elevation(_ level: CardElevation) -> some View
    public func material(_ material: SurfaceMaterial) -> some View
}

public enum CardElevation {
    case none, low, medium, high
}
```

### KeyValueRow API

```swift
public struct KeyValueRow: View {
    public init(
        key: String,
        value: String,
        layout: KeyValueLayout = .horizontal
    )
}

public enum KeyValueLayout {
    case horizontal, vertical
}
```

### SectionHeader API

```swift
public struct SectionHeader: View {
    public init(
        title: String,
        showDivider: Bool = false
    )
}
```

### CopyableText API

```swift
public struct CopyableText: View {
    public init(
        text: String,
        label: String? = nil
    )
}
```

### Copyable API

```swift
public struct Copyable<Content: View>: View {
    public init(
        text: String,
        @ViewBuilder content: () -> Content
    )

    public func showFeedback(_ show: Bool) -> Self
}
```

## Testing Components

All components include comprehensive unit tests:

```swift
// Badge tests
testBadgeCreation()
testBadgeAccessibility()
testBadgeLevels()
testBadgeIcons()

// Card tests
testCardElevation()
testCardMaterials()
testCardContent()

// KeyValueRow tests
testKeyValueLayouts()
testKeyValueCopyable()
testKeyValueFonts()
```

Run tests:

```bash
swift test --filter FoundationUITests
```

## Performance

Components are highly optimized:

- **Badge**: <1ms creation, ~500 bytes memory
- **Card**: <10ms render (with content), ~2KB memory
- **KeyValueRow**: <1ms creation, ~1KB memory
- **SectionHeader**: <1ms creation, ~500 bytes memory

See <doc:Performance> for detailed benchmarks.

## Further Reading

- <doc:DesignTokens> — Token reference
- <doc:Modifiers> — View Modifiers guide
- <doc:Patterns> — Composite patterns
- <doc:BuildingComponents> — Tutorial

## See Also

- ``Badge``
- ``Card``
- ``KeyValueRow``
- ``SectionHeader``
- ``CopyableText``
- ``Copyable``
- ``BadgeLevel``
- ``CardElevation``
- ``KeyValueLayout``
