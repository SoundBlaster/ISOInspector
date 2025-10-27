# Phase 3.2: Create platform-specific extensions

## 🎯 Objective
Create platform-specific extensions for macOS keyboard shortcuts, iOS gestures, and iPadOS pointer interactions to enable full platform-native behavior across all FoundationUI components.

## 🧩 Context
- **Phase**: Phase 3.2 - Layer 4: Contexts & Platform Adaptation
- **Layer**: Layer 4 (Contexts)
- **Priority**: P1
- **Dependencies**:
  - ✅ PlatformAdaptation modifiers (completed)
  - ✅ ColorSchemeAdapter (completed)
  - ✅ SurfaceStyleKey environment key (completed)

## ✅ Success Criteria
- [ ] Platform-specific extensions implemented for macOS, iOS, and iPadOS
- [ ] macOS keyboard shortcuts (⌘C, ⌘V, ⌘X, ⌘A, etc.)
- [ ] iOS-specific gestures (tap, long press, swipe)
- [ ] iPadOS pointer interactions (hover effects)
- [ ] Conditional compilation for platform-specific code
- [ ] Unit tests written and passing (≥15 test cases)
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Previews included (3-4 examples)
- [ ] DocC documentation complete (100% API coverage)
- [ ] Accessibility labels and hints added
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes

### Files to Create/Modify
- **Source**: `Sources/FoundationUI/Contexts/PlatformExtensions.swift`
- **Tests**: `Tests/FoundationUITests/ContextsTests/PlatformExtensionsTests.swift`

### Design Requirements

#### macOS-Specific Features
- Keyboard shortcuts using `.keyboardShortcut()` modifier
- Standard shortcuts: ⌘C (copy), ⌘V (paste), ⌘X (cut), ⌘A (select all)
- Custom shortcuts for app-specific actions
- Conditional compilation with `#if os(macOS)`

#### iOS-Specific Features
- Gesture recognizers using SwiftUI gesture modifiers
- `.onTapGesture()` for single tap
- `.onLongPressGesture()` for long press
- `.gesture(DragGesture())` for swipe detection
- Conditional compilation with `#if os(iOS)`

#### iPadOS-Specific Features
- Pointer interaction support using `.hoverEffect()` modifier
- Runtime detection using `UIDevice.current.userInterfaceIdiom == .pad`
- Note: `.hoverEffect()` only works on iPad, not iPhone
- Conditional compilation with `#if os(iOS)` + runtime idiom check
- Size class adaptation for pointer hover
- Support for both compact and regular size classes

### Design Token Usage
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: System colors for hover effects
- Animation: `DS.Animation.{quick|medium}` for transitions
- No magic numbers allowed

## 🧠 Source References
- [FoundationUI Task Plan § Phase 3.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#32-layer-4-contexts--platform-adaptation)
- [FoundationUI PRD § Platform Adaptation](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Keyboard Shortcuts](https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:modifiers:))
- [Apple SwiftUI Gestures](https://developer.apple.com/documentation/swiftui/gestures)
- [Apple iPadOS Pointer Interactions](https://developer.apple.com/design/human-interface-guidelines/pointing-devices)

## 📋 Checklist
- [ ] Read task requirements from Task Plan and next_tasks.md
- [ ] Review existing PlatformAdaptation.swift for consistency
- [ ] Create test file `PlatformExtensionsTests.swift` and write failing tests
- [ ] Run tests to confirm failure (if Swift available)
- [ ] Implement PlatformExtensions.swift with platform-specific view extensions
- [ ] Implement macOS keyboard shortcut helpers
- [ ] Implement iOS gesture helpers
- [ ] Implement iPadOS pointer interaction helpers
- [ ] Use DS tokens exclusively (zero magic numbers)
- [ ] Run tests to confirm pass
- [ ] Add 3-4 SwiftUI Previews showing platform-specific behavior
- [ ] Add comprehensive DocC comments (100% coverage)
- [ ] Run `swiftlint` (target: 0 violations)
- [ ] Test on iOS simulator (if available)
- [ ] Test on macOS (if available)
- [ ] Test on iPadOS (if available)
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message
- [ ] Archive task document to TASK_ARCHIVE/

## 📝 Implementation Strategy

### Step 1: Test-First Approach
Create comprehensive unit tests covering:
- macOS keyboard shortcut registration
- iOS gesture recognition
- iPadOS pointer interaction effects
- Platform detection logic
- Conditional compilation verification

### Step 2: Platform Extensions Implementation
```swift
// Example structure (pseudo-code)

#if os(macOS)
extension View {
    func platformKeyboardShortcut(_ key: KeyEquivalent,
                                   modifiers: EventModifiers) -> some View {
        self.keyboardShortcut(key, modifiers: modifiers)
    }
}
#endif

#if os(iOS)
extension View {
    func platformTapGesture(count: Int = 1,
                           perform action: @escaping () -> Void) -> some View {
        self.onTapGesture(count: count, perform: action)
    }

    /// iPadOS-specific pointer interaction (hover effect)
    /// Note: Only applies on iPad devices, ignored on iPhone
    @ViewBuilder
    func platformHoverEffect() -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.hoverEffect(.lift)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
#endif
```

### Step 3: Integration Examples
Create SwiftUI Previews demonstrating:
1. macOS keyboard shortcut in action
2. iOS gesture handling
3. iPadOS hover effects
4. Cross-platform component using extensions

### Step 4: Documentation
- Document each extension with usage examples
- Explain platform-specific behavior
- Provide best practices for cross-platform code
- Include accessibility considerations

## 🎬 Next Steps
After completing this task:
1. Use the ARCHIVE command to move this task to TASK_ARCHIVE/
2. Update the Task Plan marking this task as [x] complete
3. Update next_tasks.md with the next priority task
4. Proceed to next Phase 3.2 task: "Create platform comparison previews"

---

**Status**: 🚧 IN PROGRESS
**Started**: 2025-10-27
**Estimated Effort**: M (6-8 hours)
