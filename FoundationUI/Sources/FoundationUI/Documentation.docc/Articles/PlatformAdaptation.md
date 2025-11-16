# Platform Adaptation

Build UIs that feel native on macOS, iOS, and iPadOS.

## Overview

FoundationUI components automatically adapt to each platform, providing native experiences on macOS, iOS, and iPadOS. This tutorial shows you how to leverage platform adaptation and add platform-specific features.

## Automatic Adaptation

### Spacing

FoundationUI uses platform-appropriate spacing:

```swift
VStack(spacing: DS.Spacing.platformDefault) {
    Text("Title")
    Text("Subtitle")
}
// macOS: 12pt spacing (m)
// iOS/iPadOS: 16pt spacing (l)
```

### Touch Targets

iOS components automatically meet 44×44 pt minimum:

```swift
Button("Action") { }
    .platformAdaptive()
// iOS: 44×44 pt minimum
// macOS: 24×24 pt minimum
```

### Clipboard

CopyableText uses the correct clipboard API:

```swift
CopyableText(text: "Value")
// macOS: NSPasteboard
// iOS/iPadOS: UIPasteboard
```

## Platform-Specific Features

### macOS

**Keyboard Shortcuts**:

```swift
Button("Copy") {
    performCopy()
}
.keyboardShortcut("c", modifiers: .command)  // ⌘C
```

**Hover Effects**:

```swift
Card {
    Text("Content")
}
.interactiveStyle()  // Hover feedback on macOS
```

**Focus Rings**:

```swift
TextField("Name", text: $name)
    .textFieldStyle(.roundedBorder)
// Automatically shows blue focus ring on macOS
```

### iOS

**Touch Gestures**:

```swift
Text("Tap me")
    .onTapGesture {
        // Tap action
    }
    .onLongPressGesture {
        // Long press action
    }
```

**Minimum Touch Targets**:

```swift
Button("Small Button") { }
    .frame(minWidth: 44, minHeight: 44)  // iOS requirement
```

**VoiceOver**:

```swift
Badge(text: "Error", level: .error)
    .accessibilityLabel("Error badge")
    .accessibilityHint("Indicates an error occurred")
```

### iPadOS

**Size Classes**:

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .regular {
        // iPad landscape: Multi-column layout
        threePaneLayout
    } else {
        // iPad portrait: Single column
        singlePaneLayout
    }
}
```

**Pointer Interactions**:

```swift
Button("Action") { }
    .hoverEffect(.lift)  // Lifts on pointer hover (iPad + mouse/trackpad)
```

## Platform Detection

```swift
#if os(macOS)
// macOS-specific code
#elseif os(iOS)
// iOS/iPadOS-specific code
#endif
```

Or use PlatformAdapter:

```swift
let isMacOS = PlatformAdapter.isMacOS
let isIOS = PlatformAdapter.isIOS
```

## Complete Example

Here's a complete component with platform adaptation:

```swift
struct PlatformAdaptiveView: View {
    @State private var value: String = ""
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack(spacing: DS.Spacing.platformDefault) {
            Text("Platform Adaptive")
                .font(DS.Typography.title)

            // Text field with platform-specific styling
            TextField("Enter value", text: $value)
                #if os(macOS)
                .textFieldStyle(.roundedBorder)
                #else
                .textFieldStyle(.plain)
                .padding(DS.Spacing.m)
                .background(DS.Colors.tertiary)
                .cornerRadius(DS.Radius.small)
                #endif

            // Buttons with platform-specific layout
            platformButtons
        }
        .padding(DS.Spacing.platformDefault)
        .platformAdaptive()
    }

    @ViewBuilder
    private var platformButtons: some View {
        #if os(macOS)
        // macOS: Horizontal button layout
        HStack(spacing: DS.Spacing.m) {
            Button("Cancel") { }
                .keyboardShortcut(.cancelAction)

            Button("OK") { }
                .keyboardShortcut(.defaultAction)
        }
        #else
        // iOS: Vertical button layout
        VStack(spacing: DS.Spacing.m) {
            Button("OK") { }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.borderedProminent)

            Button("Cancel") { }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.bordered)
        }
        #endif
    }
}

#Preview("macOS") {
    PlatformAdaptiveView()
        .frame(width: 400, height: 300)
}

#Preview("iOS") {
    PlatformAdaptiveView()
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPad") {
    PlatformAdaptiveView()
        .environment(\.horizontalSizeClass, .regular)
}
```

## Best Practices

### ✅ Do's

```swift
// ✅ Use platformDefault for spacing
.padding(DS.Spacing.platformDefault)

// ✅ Use #if for platform-specific code
#if os(macOS)
    macOSView
#else
    iOSView
#endif

// ✅ Test on all platforms
#Preview("macOS") { }
#Preview("iOS") { }
#Preview("iPad") { }

// ✅ Use size classes for iPad
@Environment(\.horizontalSizeClass) var sizeClass
```

### ❌ Don'ts

```swift
// ❌ Hardcode platform-specific values
.padding(12)  // Use DS.Spacing.platformDefault

// ❌ Use opacity to hide views
#if os(macOS)
    macOSView.opacity(0)  // Still rendered!
#endif

// ❌ Forget touch target sizes on iOS
Button { }.frame(width: 20, height: 20)  // Too small!
```

## Testing Checklist

### macOS
- [ ] Keyboard shortcuts work (⌘C, ⌘V, ⌘A)
- [ ] Hover effects appear
- [ ] Focus rings are visible
- [ ] 12pt default spacing looks correct

### iOS
- [ ] Touch targets ≥44×44 pt
- [ ] Touch gestures work (tap, long press, swipe)
- [ ] 16pt default spacing looks correct
- [ ] VoiceOver labels are descriptive

### iPadOS
- [ ] Size classes adapt correctly (compact/regular)
- [ ] Pointer interactions work (hover effects)
- [ ] Keyboard shortcuts work (with hardware keyboard)
- [ ] Split view layouts work correctly

## See Also

- <doc:Performance>
- <doc:Accessibility>
- ``PlatformAdaptation``
- ``PlatformAdapter``
