# Bug Specification: DS.Colors.tertiary Uses Wrong Color Token on macOS

**Date**: 2025-11-07
**Status**: Documented
**Severity**: High
**Layer**: Layer 0 (Design Tokens)

---

## Bug Summary

The `DS.Colors.tertiary` design token uses `.tertiaryLabelColor` (a text/label color) instead of a proper background color on macOS. This causes low contrast between window backgrounds and content in components like `SidebarPattern`, making the UI appear visually flat and hard to read.

When ComponentTestApp is launched on macOS and navigating to the Sidebar pattern screen, the background of the window/screen and main content area have very low contrast, appearing to use the same material or background color.

---

## Reproduction

### Steps to Reproduce
1. Launch ComponentTestApp on macOS
2. Navigate to "Patterns" section in the sidebar
3. Select "SidebarPattern" from the list
4. Observe the detail content area on the right

### Minimal Code Example
```swift
import SwiftUI
import FoundationUI

struct TestView: View {
    var body: some View {
        VStack {
            Text("Content")
                .padding()
        }
        .background(DS.Colors.tertiary)  // Bug: low contrast on macOS
    }
}
```

### Expected Behavior
The detail content area should have clear visual separation from the window background with adequate contrast (≥4.5:1 ratio per WCAG AA standards).

### Actual Behavior
The detail content area blends into the window background due to using a label color (`.tertiaryLabelColor`) instead of a background color. This creates extremely low contrast that makes the interface appear flat and content boundaries unclear.

### Screenshots
Observable in ComponentTestApp > Patterns > SidebarPattern on macOS

---

## Analysis Results

### Layer Classification
- **Layer**: 0 (Design Tokens)
- **Type**: Design System Violation / Platform-Specific Bug
- **Severity**: High
- **Platform Scope**: macOS only (iOS uses correct `.tertiarySystemBackground`)

### Root Cause
The `DS.Colors.tertiary` token in `Colors.swift` uses platform-specific conditional compilation that incorrectly maps to `.tertiaryLabelColor` on macOS.

**Evidence**:
```swift
// Current buggy code at Colors.swift:107-115
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .tertiaryLabelColor)  // BUG: Label color used for background!
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()
```

**Why this is wrong:**
- `.tertiaryLabelColor` is a **text/label color**, designed for foreground content
- Background colors on macOS should use system background colors like `.windowBackgroundColor`, `.controlBackgroundColor`, or `.underPageBackgroundColor`
- Using a label color for backgrounds creates semantic mismatch and poor contrast

### Affected Files
- `FoundationUI/Sources/FoundationUI/DesignTokens/Colors.swift` (line 111) — **Root cause location**
- `FoundationUI/Sources/FoundationUI/Patterns/SidebarPattern.swift` (line 176) — Uses DS.Colors.tertiary for detail content background
- `FoundationUI/Sources/FoundationUI/Modifiers/SurfaceStyle.swift` (lines 85, 122, 195) — Uses DS.Colors.tertiary as fallback
- `FoundationUI/Sources/FoundationUI/Modifiers/CardStyle.swift` (lines 159, 162) — Uses DS.Colors.tertiary for card backgrounds
- `FoundationUI/Sources/FoundationUI/Modifiers/InteractiveStyle.swift` (multiple locations) — Uses DS.Colors.tertiary for interactive states
- `FoundationUI/Sources/FoundationUI/Patterns/ToolbarPattern.swift` (lines 51, 263) — Uses DS.Colors.tertiary

**All these components exhibit low contrast on macOS due to this token bug.**

### Design System Violations
- **Violation 1**: Semantic mismatch (label color used where background color expected)
- **Violation 2**: Platform inconsistency (iOS works correctly, macOS doesn't)
- **Violation 3**: Accessibility failure (contrast ratio likely below WCAG AA 4.5:1 requirement)
- **Violation 4**: Zero Magic Numbers rule maintained (uses system color, not hardcoded value), but wrong system color chosen

---

## Fix Specification

### Proposed Changes

**File**: `FoundationUI/Sources/FoundationUI/DesignTokens/Colors.swift`

```swift
// Before (line 107-115)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .tertiaryLabelColor)  // BUG
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()

// After (OPTION 1: Use windowBackgroundColor)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .windowBackgroundColor)
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()

// After (OPTION 2: Use controlBackgroundColor for more subtle differentiation)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .controlBackgroundColor)
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()

// After (OPTION 3: Use underPageBackgroundColor for pattern backgrounds)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .underPageBackgroundColor)
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()
```

**Recommendation**: Option 2 (`.controlBackgroundColor`) provides the best semantic match to iOS's `.tertiarySystemBackground` while maintaining proper contrast on macOS.

### Design Tokens Required
No new tokens needed — fix requires changing existing token to use correct system color.

### Testing Requirements

#### Unit Tests
```swift
@available(macOS 10.15, *)
func testTertiaryColorUsesBackgroundColorOnMacOS() {
    #if os(macOS)
    // Verify DS.Colors.tertiary is suitable for backgrounds, not labels
    // Should use windowBackgroundColor, controlBackgroundColor, or similar
    // Should NOT use tertiaryLabelColor
    XCTAssertNotNil(DS.Colors.tertiary)

    // Visual contrast test (requires snapshot testing)
    // Verify contrast ratio ≥4.5:1 against window background
    #endif
}
```

#### Snapshot Tests
- **SidebarPattern** on macOS in Light/Dark mode
  - Verify clear visual separation between sidebar and detail content
  - Verify detail content background is distinct from window background
- **All components using DS.Colors.tertiary** (Card, InspectorPattern, ToolbarPattern)
  - Light mode snapshot
  - Dark mode snapshot
  - Compare before/after fix

#### Visual Regression Tests
- Launch ComponentTestApp on macOS
- Navigate to each pattern screen (Sidebar, Inspector, Toolbar)
- Verify adequate contrast between content areas
- Test in Light and Dark mode
- Test with Increase Contrast accessibility setting enabled

#### Accessibility Tests
- Contrast ratio validation (must be ≥4.5:1)
- Test with macOS Accessibility Inspector
- Verify VoiceOver correctly identifies content boundaries
- Test with Increase Contrast enabled

---

## Documentation Updates

### Task Plan
- Added 1 task to Phase 1 (Design Tokens)
- Location: [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#phase-1-design-tokens-layer-0)

### PRD
- Added bug fix specification to Design System Tokens section
- Location: [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#design-system-tokens-ds)

### Test Plan
- Added regression prevention strategy for DS.Colors.tertiary
- Location: [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)

---

## Implementation Requirements

### Prerequisites
None — this is a straightforward token fix with no dependencies.

### Proposed Implementation Approach
1. Update `Colors.swift` line 111 to use appropriate macOS background color
2. Run all existing unit tests to ensure no regressions
3. Create snapshot tests for SidebarPattern on macOS (Light/Dark mode)
4. Manually test ComponentTestApp on macOS to verify fix
5. Test with Increase Contrast accessibility setting
6. Run SwiftLint (must show 0 violations)
7. Update documentation comments if needed

### Success Criteria
- [ ] Bug is not reproducible in ComponentTestApp
- [ ] DS.Colors.tertiary uses appropriate background color on macOS
- [ ] All affected components (SidebarPattern, Card, etc.) show proper contrast
- [ ] Contrast ratio ≥4.5:1 verified via accessibility testing
- [ ] Light and Dark mode both work correctly
- [ ] Increase Contrast mode works correctly
- [ ] All tests pass
- [ ] Design system integrity maintained (zero magic numbers)
- [ ] SwiftLint 0 violations
- [ ] Platform parity: macOS behavior matches iOS semantic intent

---

## Impact Assessment

### User Impact
**High** — Affects all macOS users of FoundationUI components. Low contrast makes UI harder to use, especially for users with visual impairments or in bright lighting conditions.

Affected user scenarios:
- ComponentTestApp demonstrations on macOS
- Any pattern using SidebarPattern on macOS
- All components using DS.Colors.tertiary for backgrounds on macOS
- Users with accessibility needs (low vision, contrast sensitivity)

### Design System Impact
**Maintains design system integrity** — Fix corrects a violation of semantic color usage. The Zero Magic Numbers rule is already followed (uses system colors), but the wrong semantic color was chosen for macOS.

After fix:
- Platform parity restored (macOS matches iOS semantic intent)
- Correct semantic usage (background color for backgrounds)
- Improved accessibility compliance (WCAG AA contrast requirements)

### Accessibility Impact
**Currently blocks accessibility** — Low contrast fails WCAG 2.1 AA requirements (≥4.5:1 contrast ratio).

Impact on users:
- Users with low vision cannot distinguish content boundaries
- Increase Contrast setting may not help if base color choice is wrong
- VoiceOver users may have unclear context about content structure

After fix:
- WCAG AA compliance restored
- Clear visual boundaries for all users
- Proper support for Increase Contrast setting

### Platform Scope
**macOS only** — iOS and iPadOS already use correct `.tertiarySystemBackground` token. This bug only affects macOS builds.

---

## Open Questions

1. **Which macOS background color provides best semantic match?**
   - Option A: `.windowBackgroundColor` (most neutral, matches window)
   - Option B: `.controlBackgroundColor` (subtle differentiation, recommended)
   - Option C: `.underPageBackgroundColor` (stronger differentiation)
   - **Recommendation**: `.controlBackgroundColor` best matches iOS's `.tertiarySystemBackground` intent

2. **Should we add snapshot tests for macOS platform?**
   - Current snapshot tests focus on iOS
   - macOS platform needs separate snapshot baseline
   - **Recommendation**: Yes, add macOS-specific snapshots for affected components

3. **Do we need a new token for stronger differentiation?**
   - Current fix reuses existing `DS.Colors.tertiary`
   - Alternatively, could create `DS.Colors.contentBackground` for explicit intent
   - **Recommendation**: Fix existing token first, evaluate need for additional tokens later

4. **Should we audit all other platform-specific tokens?**
   - This bug suggests other macOS tokens might have similar issues
   - **Recommendation**: Yes, conduct full audit of all conditional macOS/iOS color tokens

---

**Specification Date**: 2025-11-07
**Estimated Effort**: S (Small)
**Priority**: P0 (Critical) — High severity UX issue affecting all macOS users
**Assignment**: To be determined by project manager
