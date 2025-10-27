# Phase 3.2: PlatformExtensions Context

## 🎯 Objective
Deliver a suite of lightweight platform-specific extensions that expose ergonomic APIs for keyboard shortcuts, gesture affordances, and pointer interactions across macOS, iOS, and iPadOS. These helpers must stay aligned with the existing `PlatformAdaptation` context and reuse the shared design token system so that adopters can add idiomatic behavior without duplicating platform checks.

## 🧩 Context
- **Phase**: Phase 3.2 – Patterns & Platform Adaptation
- **Layer**: Layer 4 – Contexts
- **Priority**: P1 (High)
- **Dependencies**:
  - ✅ `SurfaceStyleKey` context (complete)
  - ✅ `PlatformAdaptation` context (complete)
  - ✅ `ColorSchemeAdapter` context (complete)
  - ⚠️ Pending pointer interaction polish from PlatformAdaptation integration tests (reference only)

## ✅ Success Criteria
- [ ] View extensions for macOS keyboard shortcuts expose a declarative API backed by DS tokens
- [ ] Gesture extensions reuse DS timing tokens and provide iOS-specific ergonomics
- [ ] Pointer interaction helpers map to iPadOS hover/indirect input affordances without affecting iPhone builds
- [ ] No magic numbers – all spacing, animation, and opacity values come from `DS`
- [ ] Conditional compilation keeps unused code paths out of unsupported platforms
- [ ] Unit tests cover the extensions with ≥90% branch coverage
- [ ] DocC documentation exists for every public API symbol
- [ ] SwiftLint reports 0 violations

## 🔧 Implementation Notes

### Files to Create/Modify
- **Primary source**: `Sources/FoundationUI/Contexts/PlatformExtensions.swift`
- **Unit tests**: `Tests/FoundationUITests/ContextsTests/PlatformExtensionsTests.swift`
- **DocC articles**: Extend the FoundationUI catalog with an "Platform Extensions" article

### macOS Keyboard Shortcuts
- Provide `View.platformKeyboardShortcut(_ action:)` that internally uses `KeyboardShortcut`
- Default shortcut styling should leverage `DS.Animation.quick` for feedback
- Ensure commands are excluded from iOS builds by wrapping macOS code paths with `#if os(macOS)`

### iOS Gesture Helpers
- Expose convenience wrappers for long-press and drag gestures that automatically use `DS.Animation.standard`
- Preserve compatibility with UIKit’s gesture recognizers when the host view hierarchy is bridged
- Avoid `.hoverEffect` usage on iPhone; guard pointer-specific modifiers so they compile only where available

### Pointer & Hover Interactions (iPadOS + Catalyst)
Use layered conditional compilation and idiom checks so `.hoverEffect` never reaches unsupported devices:

```swift
#if os(macOS)
extension View {
    public func platformHoverEffect(_ style: HoverEffect = .lift) -> some View {
        hoverEffect(style)
    }
}
#elseif os(iOS) && targetEnvironment(macCatalyst)
extension View {
    public func platformHoverEffect(_ style: HoverEffect = .lift) -> some View {
        hoverEffect(style)
    }
}
#elseif os(iOS)
extension View {
    public func platformHoverEffect(_ style: HoverEffect = .lift) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.hoverEffect(style)
            } else {
                self
            }
        }
    }
}
#endif
```

- Prefer compile-time gates (`#if os(macOS)`) for macOS-specific logic
- When targeting iOS, use `UIDevice.current.userInterfaceIdiom == .pad` (or size class environment values in SwiftUI) so that iPhone builds skip pointer-only APIs
- Maintain parity with the integration tests planned in `PlatformAdaptationIntegrationTests`

### Testing Strategy
- Mirror the structure from `PlatformAdaptationTests`, focusing on DS token usage and conditional compilation behavior
- Inject platform flags via `#if os(macOS)` / `#if os(iOS)` compile-time checks inside test targets to validate availability
- Use `XCTSkipUnless` to guard tests that only run on specific platforms when compiling on CI

### Documentation
- Update the DocC catalog with a new article under "Contexts" explaining the keyboard, gesture, and pointer helpers
- Provide code examples that illustrate macOS shortcuts, iPad pointer hover, and iOS gesture conveniences
- Link back to this task plan from the DocC article via "Related Tasks"

## 🧠 Source References
- [FoundationUI Task Plan § Phase 3.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#32-layer-4-contexts--platform-adaptation)
- [Apple Human Interface Guidelines – Pointer Interactions](https://developer.apple.com/design/human-interface-guidelines/pointer-interactions)
- [SwiftUI Documentation – Hover Effect](https://developer.apple.com/documentation/swiftui/view/hovereffect(_:))
- [SwiftUI Documentation – KeyboardShortcut](https://developer.apple.com/documentation/swiftui/keyboardshortcut)

## 📋 Checklist
- [ ] Review existing context architecture to ensure API consistency
- [ ] Define keyboard shortcut extension API surface
- [ ] Define gesture helper API surface
- [ ] Define pointer/hover helper API surface with proper availability checks
- [ ] Implement macOS-specific extensions
- [ ] Implement iOS gesture extensions
- [ ] Implement iPadOS/Catalyst pointer extensions with idiom guards
- [ ] Add comprehensive unit tests for every extension
- [ ] Document APIs via DocC articles and in-source comments
- [ ] Update `next_tasks.md` to reflect progress

## 📝 Implementation Log
- 2025-10-26 – Task specification drafted based on feedback from PlatformAdaptation integration tests
- 2025-10-26 – Verified dependency graph and design token requirements
- 2025-10-26 – Logged follow-up requirements for pointer interaction coverage

## 🎬 Next Steps After Completion
- Notify integration test owners so they can extend coverage for the new APIs
- Sync with documentation team to schedule DocC publish updates
- Prepare migration guide for early adopters integrating keyboard shortcuts and pointer interactions
