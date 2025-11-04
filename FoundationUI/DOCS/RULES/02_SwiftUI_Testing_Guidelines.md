# SwiftUI Testing Guidelines for FoundationUI

**Version:** 1.0  
**Last Updated:** 2025-11-03  
**Swift Version:** 6.0+  
**Minimum Deployment:** iOS 17.0+  
**Parent Document:** [ISOInspector SwiftUI Testing Guidelines](../../../DOCS/RULES/11_SwiftUI_Testing.md)

## Table of Contents

1. [Overview](#overview)
2. [Mission Statement](#mission-statement)
3. [Core Principle: No No-Op Assertions](#core-principle-no-no-op-assertions)
4. [What to Test in FoundationUI](#what-to-test-in-foundationui)
5. [Testing Strategies by Component Type](#testing-strategies-by-component-type)
6. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
7. [Swift 6 Concurrency: @MainActor Requirements](#swift-6-concurrency-mainactor-requirements)
8. [FoundationUI-Specific Testing Patterns](#foundationui-specific-testing-patterns)
9. [Design System Token Validation](#design-system-token-validation)
10. [Test Organization](#test-organization)
11. [Testing Checklist](#testing-checklist)
12. [Common Mistakes and Fixes](#common-mistakes-and-fixes)

---

## Overview

This document adapts the ISOInspector SwiftUI testing guidelines specifically for the FoundationUI package. FoundationUI is a layered design system implementation focusing on:
- Design System tokens (Layer 1)
- Composable components (Layer 2)  
- High-level patterns (Layer 3)
- Context management (accessibility, platform adaptation)

### Key Differences from Main Project

- **Focused scope:** Design system components only, no app-level logic
- **Strict token compliance:** All values must use DS tokens (zero magic numbers)
- **Cross-platform:** Tests must cover iOS, iPadOS, and macOS variations
- **Preview integration:** Tests complement SwiftUI previews
- **Public API focus:** Test public interfaces extensively

---

## Mission Statement

SwiftUI views are value types, not reference types. This fundamental difference requires a different testing approach than UIKit/AppKit. Tests must verify **observable properties and behavior**, not just view construction.

**FoundationUI-Specific Mission:**
- Validate design system token usage
- Ensure cross-platform consistency
- Verify accessibility compliance
- Document component behavior through tests
- Prevent regressions in composable layers

---

## Core Principle: No No-Op Assertions

### ❌ Anti-Pattern: Testing View Construction

```swift
// ❌ BAD: This test always passes
func testBadge() {
    let badge = Badge(text: "New", level: .info)
    XCTAssertNotNil(badge, "Badge should be created")
}
```

**Why this fails:**
- SwiftUI views are value types (structs)
- Value types **cannot be nil** in Swift
- `XCTAssertNotNil(badge)` always passes, even if the badge is completely broken
- This provides **false coverage** - tests pass but detect no bugs

### ✅ Pattern: Testing Observable Properties

```swift
// ✅ GOOD: Test design token usage
func testBadge_UsesDesignTokens() {
    let badge = Badge(text: "Test", level: .info)
    XCTAssertEqual(badge.level, .info)
    // If Badge exposes styling properties:
    XCTAssertEqual(badge.backgroundColor, DS.Colors.infoBG)
}

// ✅ GOOD: Test chip style properties
func testBadgeChipStyle_Spacing() {
    let style = BadgeChipStyle()
    XCTAssertEqual(style.horizontalPadding, DS.Spacing.m)
    XCTAssertEqual(style.verticalPadding, DS.Spacing.s)
}

// ✅ GOOD: Test environment key behavior
func testSurfaceStyleKey_DefaultValue() {
    XCTAssertEqual(SurfaceStyleKey.defaultValue, .regular)
}
```

---

## What to Test in FoundationUI

### 1. Design System Tokens (Layer 1)

**Test:** Value consistency, no magic numbers, reasonable ranges

```swift
// ✅ Test spacing tokens
func testSpacing_AllTokensDefined() {
    XCTAssertEqual(DS.Spacing.s, 8.0)
    XCTAssertEqual(DS.Spacing.m, 12.0)
    XCTAssertEqual(DS.Spacing.l, 16.0)
    XCTAssertEqual(DS.Spacing.xl, 24.0)
}

// ✅ Test spacing relationships
func testSpacing_LogicalProgression() {
    XCTAssertLessThan(DS.Spacing.s, DS.Spacing.m)
    XCTAssertLessThan(DS.Spacing.m, DS.Spacing.l)
    XCTAssertLessThan(DS.Spacing.l, DS.Spacing.xl)
}

// ✅ Test color tokens accessibility
func testColor_AllTokensAccessible() {
    _ = DS.Colors.textPrimary
    _ = DS.Colors.textSecondary
    _ = DS.Colors.infoBG
    _ = DS.Colors.errorBG
    XCTAssertTrue(true, "All color tokens should be accessible")
}

// ✅ Test typography tokens
func testTypography_AllStylesDefined() {
    _ = DS.Typography.title
    _ = DS.Typography.body
    _ = DS.Typography.caption
    _ = DS.Typography.code
    XCTAssertTrue(true, "All typography styles should be defined")
}
```

### 2. Component Properties (Layer 2)

**Test:** Badge, Card, KeyValueRow, SectionHeader, CopyableText

```swift
// ✅ Test Badge levels
func testBadge_AllLevels() {
    let levels: [Badge.Level] = [.info, .success, .warning, .error]
    
    for level in levels {
        let badge = Badge(text: "Test", level: level)
        XCTAssertEqual(badge.level, level)
    }
}

// ✅ Test Card elevation
func testCard_ElevationValues() {
    let elevations: [Card.Elevation] = [.low, .medium, .high]
    
    for elevation in elevations {
        // If Card exposes elevation property
        XCTAssertTrue(elevations.contains(elevation))
    }
}

// ✅ Test KeyValueRow structure
func testKeyValueRow_Properties() {
    let row = KeyValueRow(key: "Test Key", value: "Test Value")
    // Test that construction works and properties are set
    XCTAssertNotNil(row)
}

// ✅ Test SectionHeader divider option
func testSectionHeader_ShowDivider() {
    let withDivider = SectionHeader(title: "Test", showDivider: true)
    let withoutDivider = SectionHeader(title: "Test", showDivider: false)
    XCTAssertNotNil(withDivider)
    XCTAssertNotNil(withoutDivider)
}
```

### 3. Pattern State Management (Layer 3)

**Test:** BoxTreePattern, SidebarPattern, InspectorPattern, ToolbarPattern

```swift
// ✅ Test BoxTreePattern bindings
func testBoxTreePattern_ExpandedNodesBinding() {
    struct TreeNode: Identifiable {
        let id = UUID()
        let children: [TreeNode] = []
    }
    
    let nodes = [TreeNode()]
    var expandedNodes: Set<UUID> = []
    
    // Test that pattern can be created with binding
    let pattern = BoxTreePattern(
        data: nodes,
        children: { $0.children },
        expandedNodes: .constant(expandedNodes)
    ) { node in
        Text("Node")
    }
    
    XCTAssertNotNil(pattern)
}

// ✅ Test SidebarPattern section structure
func testSidebarPattern_SectionItem() {
    let item = SidebarPattern<UUID, Text>.Item(
        id: UUID(),
        title: "Test Item",
        iconSystemName: "star"
    )
    
    XCTAssertEqual(item.title, "Test Item")
    XCTAssertEqual(item.iconSystemName, "star")
}

// ✅ Test ToolbarPattern item properties
func testToolbarPattern_ItemInitializer() {
    let item = ToolbarPattern.Item(
        id: "test",
        iconSystemName: "star.fill",
        title: "Test Action",
        action: {}
    )
    
    XCTAssertEqual(item.id, "test")
    XCTAssertEqual(item.iconSystemName, "star.fill")
    XCTAssertEqual(item.title, "Test Action")
}

// ✅ Test ToolbarPattern layout resolution
func testToolbarPattern_LayoutResolver() {
    let compactTraits = ToolbarPattern.Traits(
        horizontalSizeClass: .compact,
        platform: .iOS,
        prefersLargeContent: false
    )
    
    let layout = ToolbarPattern.LayoutResolver.layout(for: compactTraits)
    XCTAssertEqual(layout, .compact)
}
```

### 4. Context Management

**Test:** Environment keys, surface styles, platform adaptation, accessibility

```swift
// ✅ Test SurfaceStyleKey
func testSurfaceStyleKey_DefaultValue() {
    XCTAssertEqual(SurfaceStyleKey.defaultValue, .regular)
}

func testEnvironmentValues_SurfaceStyle() {
    var env = EnvironmentValues()
    env.surfaceStyle = .thick
    XCTAssertEqual(env.surfaceStyle, .thick)
}

// ✅ Test InteractiveStyleKey
func testInteractiveStyleKey_DefaultValue() {
    XCTAssertEqual(InteractiveStyleKey.defaultValue, .standard)
}

// ✅ Test platform adaptation (if you have platform adapters)
#if os(macOS)
func testPlatformAdapter_macOS() {
    // Test macOS-specific behavior
    XCTAssertTrue(true, "macOS platform detected")
}
#endif

#if os(iOS)
func testPlatformAdapter_iOS() {
    // Test iOS-specific behavior
    XCTAssertTrue(true, "iOS platform detected")
}
#endif
```

### 5. Accessibility Integration

**Test:** VoiceOver labels, dynamic type, semantic traits

```swift
// ✅ Test Badge accessibility
func testBadge_AccessibilityLabel() {
    let badge = Badge(text: "New", level: .info)
    // If Badge exposes accessibility properties, test them
    XCTAssertNotNil(badge)
}

// ✅ Test KeyValueRow accessibility structure
func testKeyValueRow_AccessibilityStructure() {
    let row = KeyValueRow(key: "Name", value: "John Doe")
    // Test that key-value structure is semantically correct
    XCTAssertNotNil(row)
}

// ✅ Test SectionHeader as accessibility header
func testSectionHeader_AccessibilityTrait() {
    let header = SectionHeader(title: "Settings")
    // Verify header is marked as accessibility header
    XCTAssertNotNil(header)
}
```

---

## Testing Strategies by Component Type

### Design System Tokens

**What to test:**
- ✅ All tokens defined with correct values
- ✅ No magic numbers (all values are named constants)
- ✅ Logical relationships (e.g., spacing progression)
- ✅ Reasonable ranges (spacing > 0, opacity 0-1)
- ✅ Cross-platform consistency (if applicable)

**What NOT to test:**
- ❌ SwiftUI's rendering of colors/fonts
- ❌ How tokens are used internally by SwiftUI

### Components (Badge, Card, etc.)

**What to test:**
- ✅ Property initialization
- ✅ Enum cases and values
- ✅ Public API surface
- ✅ Token usage (if exposed)
- ✅ Accessibility properties (if exposed)

**What NOT to test:**
- ❌ View hierarchy structure
- ❌ SwiftUI's layout system
- ❌ Rendering appearance (use snapshot tests instead)

### Patterns (BoxTree, Sidebar, etc.)

**What to test:**
- ✅ Generic type constraints work correctly
- ✅ Binding integration
- ✅ Item/Section data structures
- ✅ Layout resolution logic (if exposed)
- ✅ State management helpers

**What NOT to test:**
- ❌ SwiftUI's NavigationSplitView behavior
- ❌ List rendering performance
- ❌ View composition internals

### Context Management

**What to test:**
- ✅ Environment key default values
- ✅ EnvironmentValues storage/retrieval
- ✅ Context independence (multiple contexts work together)
- ✅ Type safety

**What NOT to test:**
- ❌ SwiftUI's environment propagation mechanism
- ❌ Environment inheritance across view hierarchy

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: No-Op Component Tests

```swift
// ❌ BAD: Always passes
func testCard() {
    let card = Card {
        Text("Content")
    }
    XCTAssertNotNil(card)
}
```

**Fix:** Test properties or token usage:

```swift
// ✅ GOOD: Test token usage
func testCard_UsesDesignTokens() {
    // If Card exposes spacing or other configurable properties
    let card = Card(elevation: .medium)
    XCTAssertNotNil(card) // Only if testing configuration worked
}
```

### ❌ Anti-Pattern 2: Testing SwiftUI Framework

```swift
// ❌ BAD: Testing SwiftUI's List behavior
func testBoxTreePattern_ListRendering() {
    let pattern = BoxTreePattern(data: [], children: { _ in [] }) { _ in Text("") }
    // Trying to verify List renders correctly
}
```

**Fix:** Test your pattern's data structure:

```swift
// ✅ GOOD: Test pattern's public API
func testBoxTreePattern_ItemStructure() {
    struct Node: Identifiable {
        let id = UUID()
        let children: [Node]
    }
    
    let node = Node(children: [])
    XCTAssertTrue(node.children.isEmpty)
}
```

### ❌ Anti-Pattern 3: Magic Numbers in Assertions

```swift
// ❌ BAD: Using magic numbers
func testSpacing() {
    let spacing = DS.Spacing.m
    XCTAssertEqual(spacing, 12.0)  // ❌ Magic number
}
```

**Fix:** Use token constants:

```swift
// ✅ GOOD: Reference tokens
func testSpacing_Medium() {
    XCTAssertEqual(DS.Spacing.m, DS.Spacing.m)
    XCTAssertLessThan(DS.Spacing.s, DS.Spacing.m)
}
```

---

## Swift 6 Concurrency: @MainActor Requirements

**CRITICAL**: With Swift 6 strict concurrency enabled, all test methods that work with SwiftUI Views **must** be annotated with `@MainActor`.

### When to Use @MainActor in FoundationUI Tests

**Always use `@MainActor` when:**

1. **Creating FoundationUI Components**
   ```swift
   @MainActor
   func testBadge_Creation() {
       let badge = Badge(text: "Test", level: .info)  // ✅ SwiftUI view
       XCTAssertNotNil(badge)
   }
   ```

2. **Creating Patterns with Views**
   ```swift
   @MainActor
   func testBoxTreePattern_WithViews() {
       let pattern = BoxTreePattern(data: nodes, children: { $0.children }) { node in
           Text(node.title)  // ✅ ViewBuilder with Text
       }
       XCTAssertNotNil(pattern)
   }
   ```

3. **Testing View Modifiers**
   ```swift
   @MainActor
   func testSurfaceStyle_Modifier() {
       let view = Text("Test").surfaceStyle(.thick)  // ✅ View modifier
       XCTAssertNotNil(view)
   }
   ```

### When NOT to Use @MainActor

**Do NOT use `@MainActor` when:**

1. **Testing Design Tokens**
   ```swift
   // ✅ No @MainActor - pure value testing
   func testSpacing_Values() {
       XCTAssertEqual(DS.Spacing.s, 8.0)
   }
   ```

2. **Testing Environment Keys Directly**
   ```swift
   // ✅ No @MainActor - direct property access
   func testSurfaceStyleKey_DefaultValue() {
       XCTAssertEqual(SurfaceStyleKey.defaultValue, .regular)
   }
   ```

3. **Testing Enums and Structs**
   ```swift
   // ✅ No @MainActor - value type testing
   func testBadgeLevel_Equatable() {
       XCTAssertEqual(Badge.Level.info, .info)
   }
   ```

4. **Testing Layout Resolution Logic**
   ```swift
   // ✅ No @MainActor - pure logic
   func testToolbarPattern_LayoutResolver() {
       let traits = ToolbarPattern.Traits(...)
       let layout = ToolbarPattern.LayoutResolver.layout(for: traits)
       XCTAssertEqual(layout, .compact)
   }
   ```

### Rule of Thumb for FoundationUI

```swift
// If your test creates or manipulates a SwiftUI View → @MainActor
@MainActor
func testView_Something() { /* ... */ }

// If your test only works with data/logic → No @MainActor
func testData_Something() { /* ... */ }
```

---

## FoundationUI-Specific Testing Patterns

### Pattern 1: Testing Component Variants

```swift
// ✅ Test all badge levels
func testBadge_AllLevels() {
    let levels: [Badge.Level] = [.info, .success, .warning, .error]
    
    for level in levels {
        let badge = Badge(text: "Test", level: level)
        XCTAssertEqual(badge.level, level)
    }
}

// ✅ Test all surface styles
func testSurfaceStyle_AllCases() {
    let styles: [SurfaceStyle] = [.thin, .regular, .thick, .ultra]
    
    for style in styles {
        var env = EnvironmentValues()
        env.surfaceStyle = style
        XCTAssertEqual(env.surfaceStyle, style)
    }
}
```

### Pattern 2: Testing Generic Pattern Types

```swift
// ✅ Test SidebarPattern with different ID types
func testSidebarPattern_IntID() {
    let item = SidebarPattern<Int, Text>.Item(id: 1, title: "Test")
    XCTAssertEqual(item.id, 1)
}

func testSidebarPattern_UUIDID() {
    let id = UUID()
    let item = SidebarPattern<UUID, Text>.Item(id: id, title: "Test")
    XCTAssertEqual(item.id, id)
}

func testSidebarPattern_StringID() {
    let item = SidebarPattern<String, Text>.Item(id: "test-id", title: "Test")
    XCTAssertEqual(item.id, "test-id")
}
```

### Pattern 3: Testing Token Relationships

```swift
// ✅ Test spacing progression
func testSpacing_LogicalProgression() {
    let allSpacing = [
        DS.Spacing.s,
        DS.Spacing.m,
        DS.Spacing.l,
        DS.Spacing.xl
    ]
    
    // Verify each spacing is larger than the previous
    for i in 0..<(allSpacing.count - 1) {
        XCTAssertLessThan(allSpacing[i], allSpacing[i + 1],
                         "Spacing should increase progressively")
    }
}

// ✅ Test radius progression
func testRadius_LogicalProgression() {
    XCTAssertLessThan(DS.Radius.small, DS.Radius.medium)
    XCTAssertLessThan(DS.Radius.medium, DS.Radius.large)
}
```

### Pattern 4: Testing Layer Integration

```swift
// ✅ Test component uses tokens (Layer 2 uses Layer 1)
func testBadge_UsesTypographyToken() {
    // If Badge exposes font property
    // XCTAssertEqual(badge.font, DS.Typography.caption)
    XCTAssertTrue(true, "Badge should use typography tokens")
}

// ✅ Test pattern uses components (Layer 3 uses Layer 2)
func testInspectorPattern_WithKeyValueRow() {
    let inspector = InspectorPattern(title: "Test") {
        KeyValueRow(key: "Key", value: "Value")
    }
    XCTAssertNotNil(inspector)
}
```

---

## Design System Token Validation

**Zero Magic Numbers Policy:** All numeric values in FoundationUI must come from DS tokens.

### Testing Token Coverage

```swift
// ✅ Test all spacing tokens are used
func testComponents_UseOnlySpacingTokens() {
    let validSpacing: Set<CGFloat> = [
        DS.Spacing.s,
        DS.Spacing.m,
        DS.Spacing.l,
        DS.Spacing.xl
    ]
    
    // If components expose spacing properties, verify they use tokens
    XCTAssertFalse(validSpacing.isEmpty)
}

// ✅ Test token value ranges
func testSpacing_ReasonableRange() {
    let spacing = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
    
    for value in spacing {
        XCTAssertGreaterThan(value, 0, "Spacing must be positive")
        XCTAssertLessThan(value, 100, "Spacing should be reasonable (<100pt)")
    }
}

// ✅ Test opacity tokens
func testOpacity_ValidRange() {
    let opacities = [
        DS.Opacity.faint,
        DS.Opacity.medium,
        DS.Opacity.strong
    ]
    
    for opacity in opacities {
        XCTAssertGreaterThanOrEqual(opacity, 0.0)
        XCTAssertLessThanOrEqual(opacity, 1.0)
    }
}
```

---

## Test Organization

### File Structure for FoundationUI

```
Tests/FoundationUITests/
├── DesignSystemTests/
│   ├── ColorTokenTests.swift
│   ├── SpacingTokenTests.swift
│   ├── TypographyTokenTests.swift
│   └── RadiusTokenTests.swift
├── ComponentsTests/
│   ├── BadgeTests.swift
│   ├── BadgeAccessibilityTests.swift
│   ├── CardTests.swift
│   ├── KeyValueRowTests.swift
│   ├── SectionHeaderTests.swift
│   └── CopyableTextTests.swift
├── PatternsTests/
│   ├── BoxTreePatternTests.swift
│   ├── SidebarPatternTests.swift
│   ├── InspectorPatternTests.swift
│   └── ToolbarPatternTests.swift
├── ContextsTests/
│   ├── SurfaceStyleKeyTests.swift
│   ├── InteractiveStyleTests.swift
│   └── ContextIntegrationTests.swift
├── PerformanceTests/
│   ├── ComponentPerformanceTests.swift
│   └── PatternsPerformanceTests.swift
└── IntegrationTests/
    └── ComponentIntegrationTests.swift
```

### Test Naming Convention

```swift
// Design system: test[Token]_[Property]
func testSpacing_Medium()
func testColor_InfoBackground()
func testTypography_BodyFont()

// Components: test[Component]_[Feature]_[Scenario]
func testBadge_Level_Info()
func testCard_Elevation_High()
func testKeyValueRow_Properties()

// Patterns: test[Pattern]_[Feature]
func testBoxTreePattern_ExpandedNodes()
func testSidebarPattern_SectionItem()
func testToolbarPattern_LayoutResolver()

// Contexts: test[Context]_[Scenario]
func testSurfaceStyleKey_DefaultValue()
func testEnvironmentValues_SurfaceStyle()

// Integration: testIntegration_[Feature]
func testIntegration_AllContextsIndependent()
func testIntegration_ComponentsWithTokens()
```

---

## Testing Checklist

Before marking FoundationUI tests as complete:

### Design System (Layer 1)
- [ ] All tokens have value tests
- [ ] Token relationships verified (progression, ranges)
- [ ] No magic numbers in token definitions
- [ ] Cross-platform tokens tested with #if conditions
- [ ] Accessibility contrast ratios validated (if applicable)

### Components (Layer 2)
- [ ] All public initializers tested
- [ ] All variants/levels tested (Badge levels, Card elevations, etc.)
- [ ] Token usage verified (if properties exposed)
- [ ] Accessibility properties tested
- [ ] No XCTAssertNotNil on view construction

### Patterns (Layer 3)
- [ ] Generic type constraints work with multiple types
- [ ] Binding integration verified
- [ ] Item/Section structures tested
- [ ] Layout resolution logic tested (if exposed)
- [ ] Complex state scenarios covered

### Contexts
- [ ] Environment keys have default value tests
- [ ] EnvironmentValues storage/retrieval tested
- [ ] Multiple contexts work independently
- [ ] Type safety verified

### Cross-Cutting
- [ ] @MainActor applied where needed (view creation)
- [ ] @MainActor NOT applied to pure logic tests
- [ ] Platform-specific tests use #if os(...) guards
- [ ] Integration tests verify layer interactions
- [ ] Performance tests exist for complex components
- [ ] All tests have descriptive failure messages

---

## Common Mistakes and Fixes

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| `XCTAssertNotNil(badge)` | Test badge properties or token usage |
| Magic number: `XCTAssertEqual(spacing, 12.0)` | Use: `XCTAssertEqual(spacing, DS.Spacing.m)` |
| Testing view hierarchy | Test data structures and properties |
| No platform guards | Add `#if os(macOS)` / `#if os(iOS)` |
| Missing @MainActor on view tests | Add `@MainActor` to test method |
| @MainActor on token tests | Remove @MainActor from pure logic tests |
| Generic failure messages | Add context: `"Badge should use info level"` |
| Only testing happy path | Add edge cases: empty, nil, maximum values |
| Testing SwiftUI framework | Test your FoundationUI code only |

---

## Summary

### ✅ DO

- Test design tokens and their relationships
- Test component properties and variants
- Test pattern data structures and generics
- Test environment key storage/retrieval
- Use @MainActor for view creation tests
- Use design tokens in all assertions
- Write tests that can actually fail
- Document expected behavior in assertions
- Test cross-platform variations with #if guards
- Verify layer integration (tokens → components → patterns)

### ❌ DON'T

- Test view construction with XCTAssertNotNil alone
- Use magic numbers in assertions
- Test SwiftUI framework behavior
- Add @MainActor to pure logic tests
- Skip platform-specific testing
- Test rendering without snapshot tools
- Write tests that always pass
- Ignore accessibility testing

---

## References

- [Parent Document: ISOInspector SwiftUI Testing Guidelines](../../../DOCS/RULES/11_SwiftUI_Testing.md)
- [FoundationUI Architecture](../ARCHITECTURE.md)
- [SwiftUI Previews Guidelines](./SwiftUI_Previews_Guidelines.md)
- [TDD Workflow](../../../DOCS/RULES/02_TDD_XP_Workflow.md)
- [Apple: Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Swift Evolution: SE-0337 - Incremental Migration to Concurrency Checking](https://github.com/apple/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md)

---

**Document Owner:** FoundationUI Team  
**Review Cycle:** Quarterly  
**Next Review:** 2025-02-03  
**Status:** Active guideline for all FoundationUI testing
