# Thread Safety Guidelines for Accessibility APIs

**Document Version**: 1.0
**Created**: 2025-11-08
**Related Issue**: MainActor deadlock in AccessibilityContextTests
**Applies To**: FoundationUI framework, all components using accessibility APIs

---

## Overview

Accessibility APIs (UIAccessibility on iOS, NSAccessibility on macOS) have **strict thread safety requirements**. Improper use of actor isolation can cause deadlocks, race conditions, and test failures. This guide establishes best practices for safely accessing accessibility APIs in Swift concurrency contexts.

---

## Core Principles

### 1. Accessibility APIs Must Run on Main Thread

All accessibility API calls must execute on the **main/UI thread**:

```swift
// ❌ WRONG: Calling from background thread
DispatchQueue.global().async {
    let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled  // CRASH/HANG
}

// ✅ CORRECT: Ensure main thread
DispatchQueue.main.async {
    let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled
}
```

**Why?**: UIAccessibility APIs interact with the system UI layer, which is inherently single-threaded. Calling from other threads causes undefined behavior.

### 2. Never Use `MainActor.assumeIsolated` in `@MainActor` Context

This is a **common deadlock pattern**:

```swift
// ❌ WRONG: Already on MainActor, don't assume again
@MainActor
func getAccessibilityPreference() -> Bool {
    return MainActor.assumeIsolated {  // DEADLOCK!
        UIAccessibility.isDarkerSystemColorsEnabled
    }
}

// ✅ CORRECT: Direct call when already @MainActor
@MainActor
func getAccessibilityPreference() -> Bool {
    return UIAccessibility.isDarkerSystemColorsEnabled
}
```

**Why?**: `assumeIsolated` tells Swift "I'm guaranteeing I'm on the main actor", but if you're already there, the runtime creates a deadlock waiting to enter an actor you're already executing in.

### 3. EnvironmentValues Access Guarantees Main Thread

SwiftUI's `EnvironmentValues` always executes getters/setters on the main thread:

```swift
// ✅ SAFE: EnvironmentValues access is always main-thread
extension EnvironmentValues {
    var myAccessibilityPreference: Bool {
        get {
            // No need for MainActor - SwiftUI guarantees this runs on main thread
            return UIAccessibility.isDarkerSystemColorsEnabled
        }
        set { /* ... */ }
    }
}
```

**Why?**: SwiftUI's view system is inherently main-thread bound. Environment reads/writes never happen off the main thread.

---

## Common Deadlock Patterns to Avoid

### Pattern 1: Double-Isolation in Tests

```swift
// ❌ DEADLOCK: Test already @MainActor, property also tries @MainActor
@MainActor
final class AccessibilityTests: XCTestCase {
    func testAccessibility() {
        var env = EnvironmentValues()
        let value = env.accessibilityContext  // If getter uses assumeIsolated, DEADLOCK!
    }
}

// ✅ FIXED: Test @MainActor, property getter uses direct call
@MainActor
final class AccessibilityTests: XCTestCase {
    func testAccessibility() {
        var env = EnvironmentValues()
        let value = env.accessibilityContext  // Direct access, no deadlock
    }
}
```

### Pattern 2: Nesting MainActor Context

```swift
// ❌ DEADLOCK: Nested MainActor assumptions
@MainActor
func outer() {
    MainActor.assumeIsolated {  // Already on MainActor!
        inner()
    }
}

@MainActor
func inner() {
    let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled
}

// ✅ CORRECT: Single MainActor context
@MainActor
func outer() {
    inner()  // Direct call
}

@MainActor
func inner() {
    let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled
}
```

### Pattern 3: Unnecessary Actor Context Switches

```swift
// ❌ INEFFICIENT: Switching actors unnecessarily
func checkAccessibility() {
    MainActor.assumeIsolated {
        // This might deadlock if called from main thread
        let value = UIAccessibility.isDarkerSystemColorsEnabled
    }
}

// ✅ CORRECT: Let Swift handle actor context
@MainActor
func checkAccessibility() -> Bool {
    return UIAccessibility.isDarkerSystemColorsEnabled
}
```

---

## Implementation Checklist

### For Accessibility API Accessors

- [ ] **Mark with `@MainActor`** - Declare accessibility accessors as `@MainActor`
- [ ] **No `assumeIsolated`** - Don't use `MainActor.assumeIsolated` in `@MainActor` context
- [ ] **Direct API calls** - Call UIAccessibility/NSAccessibility APIs directly (main thread is guaranteed)
- [ ] **Document assumptions** - Add comments explaining main thread requirement if not obvious
- [ ] **Test on @MainActor** - Test with `@MainActor` annotation to catch deadlocks early

### For EnvironmentValues Extensions

```swift
public extension EnvironmentValues {
    /// Document that this is main-thread safe
    var accessibilityContext: AccessibilityContext {
        get {
            // Direct call - EnvironmentValues access is always main-thread
            // No need for MainActor isolation markers
            let isDarkerColors = UIAccessibility.isDarkerSystemColorsEnabled
            // ... rest of implementation
        }
        set { /* ... */ }
    }
}
```

### For View Modifiers

```swift
// ✅ CORRECT: Mark ViewModifier body as MainActor
private struct AccessibilityContextModifier: ViewModifier {
    let context: AccessibilityContext

    @MainActor
    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityContext, context)
    }
}
```

---

## Testing Accessibility Code

### Unit Tests for Accessibility APIs

```swift
// ✅ CORRECT: Mark test @MainActor, access APIs directly
@MainActor
final class AccessibilityContextTests: XCTestCase {
    func testEnvironmentValues_RoundTrip() {
        var environment = EnvironmentValues()

        // ✅ No MainActor.assumeIsolated needed
        let context = environment.accessibilityContext

        XCTAssertNotNil(context)
    }
}
```

### Mocking Accessibility Preferences

For tests that need to control accessibility settings:

```swift
// ✅ Use overrides in EnvironmentValues
struct AccessibilityContextOverrides {
    var prefersReducedMotion: Bool?
    var prefersIncreasedContrast: Bool?
    // ...
}

@MainActor
func testWithMockedPreferences() {
    var env = EnvironmentValues()
    env.accessibilityContextOverrides = AccessibilityContextOverrides(
        prefersIncreasedContrast: true
    )

    let context = env.accessibilityContext
    XCTAssertTrue(context.prefersIncreasedContrast)
}
```

---

## Platform-Specific Considerations

### iOS/tvOS (UIAccessibility)

```swift
#if canImport(UIKit)
import UIKit

@available(iOS 13.0, tvOS 13.0, *)
@MainActor
func isHighContrastEnabled() -> Bool {
    // Direct call - already @MainActor
    return UIAccessibility.isDarkerSystemColorsEnabled
}
#endif
```

### macOS (NSAccessibility)

```swift
#if canImport(AppKit)
import AppKit

@MainActor
func isHighContrastEnabled() -> Bool {
    // Direct call - already @MainActor
    return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
}
#endif
```

---

## Debugging Deadlocks

### Identifying Accessibility-Related Deadlocks

1. **Symptom**: Test hangs indefinitely (typically 1 hour timeout)
2. **Test characterization**: Usually involves `@MainActor` tests accessing environment values
3. **Root cause**: `MainActor.assumeIsolated` called when already on main thread
4. **Stack trace clue**: Multiple MainActor context switches in backtrace

### Debugging Steps

```bash
# 1. Check if test uses @MainActor annotation
grep -n "@MainActor" Tests/AccessibilityContextTests.swift

# 2. Check if implementation uses MainActor.assumeIsolated
grep -n "MainActor.assumeIsolated" Sources/AccessibilityContext.swift

# 3. If both present, remove MainActor.assumeIsolated from implementation
# 4. Re-run tests - deadlock should resolve

# 5. Run with timeout to confirm it was hanging:
# swift test --filter AccessibilityContextTests -v
```

### Testing Timeout Behavior

```bash
# Run with explicit timeout to catch hangs early
timeout 60 swift test  # Fails after 60 seconds instead of hanging
```

---

## Code Review Checklist

When reviewing accessibility API code:

- [ ] Does it access UIAccessibility/NSAccessibility APIs?
- [ ] Is it marked `@MainActor`?
- [ ] Does it use `MainActor.assumeIsolated`? ⚠️ Flag if it does
- [ ] Are tests also `@MainActor`?
- [ ] Are there comments explaining thread safety?
- [ ] Does it handle Swift 5.8 vs 5.9+ differences appropriately?

### Review Template

```swift
// ✅ GOOD
@MainActor
extension EnvironmentValues {
    /// Accessibility preferences for FoundationUI.
    var accessibilityContext: AccessibilityContext {
        get {
            // Direct API call - main thread guaranteed by SwiftUI
            let isDarkerColors = UIAccessibility.isDarkerSystemColorsEnabled
            // ...
        }
        set { /* ... */ }
    }
}

// ❌ BAD - Flag for revision
@MainActor
extension EnvironmentValues {
    var accessibilityContext: AccessibilityContext {
        get {
            return MainActor.assumeIsolated {  // ⚠️ WRONG! Already on MainActor
                UIAccessibility.isDarkerSystemColorsEnabled
            }
        }
        set { /* ... */ }
    }
}
```

---

## Real-World Example: AccessibilityContext Fix

**Issue**: Test froze for 1 hour on iOS

**Root Cause**:
```swift
// ❌ BEFORE: Unnecessary assumeIsolated in @MainActor context
@MainActor
var baselinePrefersIncreasedContrast: Bool {
    #if canImport(UIKit)
    if #available(iOS 13.0, tvOS 13.0, *) {
        return MainActor.assumeIsolated {  // DEADLOCK when called from @MainActor test
            UIAccessibility.isDarkerSystemColorsEnabled
        }
    }
    #endif
    return false
}
```

**Solution**:
```swift
// ✅ AFTER: Direct call - main thread already guaranteed
@MainActor
var baselinePrefersIncreasedContrast: Bool {
    #if canImport(UIKit)
    if #available(iOS 13.0, tvOS 13.0, *) {
        // Direct call - EnvironmentValues always on main thread
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    #endif
    return false
}
```

**Result**: Test completes in <100ms instead of hanging

---

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
- [MainActor Documentation](https://developer.apple.com/documentation/swift/mainactor)
- [UIAccessibility Documentation](https://developer.apple.com/documentation/uikit/uiaccessibility)
- [NSAccessibility Documentation](https://developer.apple.com/documentation/appkit/nsaccessibility)
- [FoundationUI AccessibilityContext Implementation](../../../Sources/FoundationUI/Contexts/AccessibilityContext.swift)

---

## Summary

| Pattern | Status | Action |
|---------|--------|--------|
| `@MainActor` on accessibility code | ✅ Recommended | Use for clarity |
| Direct API calls in `@MainActor` context | ✅ Recommended | Simplest, safest approach |
| `MainActor.assumeIsolated` in `@MainActor` | ❌ Avoid | Causes deadlocks |
| Nesting `assumeIsolated` | ❌ Avoid | Unnecessary and error-prone |
| Tests marked `@MainActor` | ✅ Required | Catches isolation issues early |
| EnvironmentValues access | ✅ Safe | Always main-thread by design |

---

**Last Updated**: 2025-11-08
**Status**: Active
**Applies To**: FoundationUI 1.0+
