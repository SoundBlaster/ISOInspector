# Building Components

Learn how to build custom components using FoundationUI Design Tokens and Modifiers.

## Overview

This tutorial teaches you how to create custom SwiftUI components that follow FoundationUI's design principles: zero magic numbers, accessibility-first, and platform-adaptive behavior.

## Prerequisites

- Completed <doc:GettingStarted> tutorial
- Basic SwiftUI knowledge
- Understanding of Design Tokens from <doc:DesignTokens>

## Tutorial Steps

### Step 1: Start with Design Tokens

Always use Design Tokens for all values:

```swift
import SwiftUI
import FoundationUI

struct MyCustomComponent: View {
    var body: some View {
        VStack(spacing: DS.Spacing.m) {  // ✅ Design Token
            Text("Title")
                .font(DS.Typography.title)  // ✅ Design Token
                .padding(DS.Spacing.l)      // ✅ Design Token
        }
        .background(DS.Colors.accent)       // ✅ Design Token
        .cornerRadius(DS.Radius.card)       // ✅ Design Token
    }
}
```

### Step 2: Apply View Modifiers

Use FoundationUI modifiers for consistent styling:

```swift
struct StatusIndicator: View {
    let status: BadgeLevel

    var body: some View {
        Text("Status")
            .badgeChipStyle(level: status)  // ✅ FoundationUI modifier
    }
}
```

### Step 3: Add Accessibility

Every component must be accessible:

```swift
struct AccessibleComponent: View {
    var body: some View {
        Button("Action") {
            performAction()
        }
        .accessibilityLabel("Perform action")
        .accessibilityHint("Double tap to execute the action")
        .frame(minWidth: 44, minHeight: 44)  // ✅ iOS touch target
    }
}
```

### Step 4: Make it Platform-Adaptive

Use platform checks when needed:

```swift
struct PlatformAdaptiveComponent: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .padding(DS.Spacing.platformDefault)  // ✅ Platform-adaptive
        #if os(macOS)
        .onTapGesture { }
        .keyboardShortcut("c", modifiers: .command)  // macOS only
        #endif
    }
}
```

### Step 5: Compose Existing Components

Build on FoundationUI components:

```swift
struct MetadataCard: View {
    let title: String
    let items: [(key: String, value: String)]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: title)

                ForEach(items, id: \.key) { item in
                    KeyValueRow(key: item.key, value: item.value)
                }
            }
        }
        .elevation(.medium)
    }
}
```

### Step 6: Add SwiftUI Previews

Always include previews for testing:

```swift
#Preview("Light Mode") {
    MetadataCard(
        title: "File Properties",
        items: [
            ("Type", "ftyp"),
            ("Size", "32 bytes")
        ]
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MetadataCard(
        title: "File Properties",
        items: [
            ("Type", "ftyp"),
            ("Size", "32 bytes")
        ]
    )
    .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    MetadataCard(
        title: "File Properties",
        items: [
            ("Type", "ftyp"),
            ("Size", "32 bytes")
        ]
    )
    .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}
```

## Complete Example

Here's a complete custom component following all best practices:

```swift
import SwiftUI
import FoundationUI

/// A custom component for displaying ISO box information
struct BoxInfoCard: View {
    let boxType: String
    let size: String
    let offset: String
    let isValid: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // Header with badge
                HStack {
                    Text(boxType)
                        .font(DS.Typography.title)
                        .fontWeight(.semibold)

                    Spacer()

                    Badge(
                        text: isValid ? "Valid" : "Invalid",
                        level: isValid ? .success : .error,
                        showIcon: true
                    )
                }

                Divider()

                // Metadata rows
                KeyValueRow(key: "Size", value: size)
                KeyValueRow(key: "Offset", value: offset)
                    .copyable(text: offset)
            }
        }
        .elevation(.medium)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Box information for \(boxType)")
    }
}

// MARK: - Previews

#Preview("Valid Box") {
    BoxInfoCard(
        boxType: "ftyp",
        size: "32 bytes",
        offset: "0x00000000",
        isValid: true
    )
    .padding(DS.Spacing.xl)
}

#Preview("Invalid Box") {
    BoxInfoCard(
        boxType: "mdat",
        size: "1,024 bytes",
        offset: "0x00000020",
        isValid: false
    )
    .padding(DS.Spacing.xl)
}

#Preview("Dark Mode") {
    BoxInfoCard(
        boxType: "moov",
        size: "256 bytes",
        offset: "0x00000420",
        isValid: true
    )
    .preferredColorScheme(.dark)
    .padding(DS.Spacing.xl)
}
```

## Best Practices

### ✅ Do's

- Use Design Tokens for all values
- Apply FoundationUI modifiers
- Add accessibility labels
- Include SwiftUI Previews (Light/Dark mode, Dynamic Type)
- Document with DocC comments
- Compose existing components
- Test on all platforms

### ❌ Don'ts

- Use magic numbers
- Hardcode colors or sizes
- Forget accessibility labels
- Skip preview testing
- Create components from scratch when FoundationUI has alternatives

## Next Steps

- <doc:CreatingPatterns> — Build complex layouts with patterns
- <doc:PlatformAdaptation> — Optimize for each platform
- <doc:Components> — Complete component catalog
- <doc:Modifiers> — All available modifiers

## See Also

- <doc:DesignTokens>
- <doc:Accessibility>
- ``Badge``
- ``Card``
- ``KeyValueRow``
