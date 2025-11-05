# Actor Isolation Fix - Correct Approach

## Issue

Swift 6 strict concurrency error in CI:
```
error: main actor-isolated property 'content' can not be mutated
from a nonisolated context
```

## ❌ Wrong Approach (Reverted)

**Commit**: `8003f6b` (reverted in `0f400f9`)

Added `nonisolated` to component initializers:
```swift
public nonisolated init(text: String, ...) { // ❌ WRONG
    self.content = content() // Error: can't mutate @MainActor property
}
```

**Problem**:
- Component initializers with `@ViewBuilder` closures create SwiftUI Views
- Views are `@MainActor` isolated
- `nonisolated` init can't mutate `@MainActor` properties
- Broke compilation for Card, Copyable components

## ✅ Correct Approach

**Commit**: `0f400f9`

Mark test classes as `@MainActor` instead:
```swift
@MainActor
final class BadgeTests: XCTestCase {
    func testBadgeInitialization() {
        let badge = Badge(text: "Test", level: .info) // ✅ Now in @MainActor context
        // ...
    }
}
```

### Why This Works

1. **Component initializers** remain `@MainActor` (implicitly via `View`)
2. **Test methods** run in `@MainActor` context
3. **No actor hopping** required
4. **Type safety** maintained

### Files Changed

**Components** (reverted to original):
- Badge.swift
- Card.swift
- KeyValueRow.swift
- SectionHeader.swift
- Copyable.swift

**Tests** (added `@MainActor`):
- 19 test classes updated with `@MainActor` annotation
- All component tests, context tests, performance tests

## Test Execution

### Before Fix
```
❌ error: calls to initializer from outside of its actor context
   are implicitly asynchronous
```

### After Fix
```
✅ All 53 unit tests pass
✅ Swift 6 strict concurrency compliant
✅ No actor isolation errors
```

## Technical Details

### @MainActor on Test Classes

```swift
@MainActor
final class BadgeTests: XCTestCase {
    // All test methods automatically run on MainActor
    func testBadge() {
        // Can safely create Views here
        let badge = Badge(text: "Test", level: .info)
    }
}
```

### Why Not nonisolated?

**Components with @ViewBuilder**:
```swift
public struct Card<Content: View>: View {
    private let content: Content // @MainActor isolated

    public init(@ViewBuilder content: () -> Content) { // Must be @MainActor
        self.content = content() // Mutating @MainActor property
    }
}
```

**Problem with nonisolated**:
```swift
public nonisolated init(...) { // ❌
    self.content = content() // Error: can't mutate @MainActor property
}
```

## Lessons Learned

1. **Don't fight the type system** - SwiftUI Views are `@MainActor` for good reasons
2. **Annotate tests, not components** - Tests should adapt to component requirements
3. **@ViewBuilder requires @MainActor** - Closures that create Views need proper isolation
4. **Test from correct context** - Mark test classes with appropriate isolation

## References

- **Swift Evolution**: [SE-0313 Improved control over actor isolation](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md)
- **Swift Concurrency**: [Actor Isolation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Actor-Isolation)
- **SwiftUI @MainActor**: [View protocol requires MainActor](https://developer.apple.com/documentation/swiftui/view)

---

**Date**: 2025-11-05
**Branch**: `claude/foundation-ui-setup-011CUqUD1Ut28p3kMM2DGemX`
**Status**: ✅ Fixed correctly with @MainActor on test classes
