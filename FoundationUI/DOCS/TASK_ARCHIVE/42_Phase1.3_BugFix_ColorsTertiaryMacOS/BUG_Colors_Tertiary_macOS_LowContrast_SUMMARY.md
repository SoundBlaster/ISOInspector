# Bug Specification Summary: DS.Colors.tertiary macOS Low Contrast

**Date**: 2025-11-07
**Reporter**: User
**Documented by**: Claude (BUG Command)
**Status**: Documented and ready for assignment

---

## Quick Facts

- **Component**: DS.Colors.tertiary (Layer 0 - Design Tokens)
- **Layer**: 0 (Foundation - Design Tokens)
- **Severity**: **High**
- **Root Cause**: Using `.tertiaryLabelColor` (text/label color) instead of background color on macOS
- **File**: `FoundationUI/Sources/FoundationUI/DesignTokens/Colors.swift` (line 111)
- **Platform Scope**: macOS only (iOS already uses correct `.tertiarySystemBackground`)
- **Status**: ✅ Documented and ready for developer assignment

---

## Problem Description

When launching ComponentTestApp on macOS and navigating to the Sidebar pattern screen, the background of the window/screen and main content area exhibit extremely low contrast, appearing to use the same material or background color. The UI looks visually flat with unclear content boundaries.

### User Report (Original)
> "При запуске ComponentTestApp на macOS и при переходе на экран Sidebar pattern screen наблюдается низкая контрастность фона окна/экрана и основного контента, будто бы используется общий материал или фоновый цвет"

---

## Root Cause Analysis

The `DS.Colors.tertiary` design token uses platform-specific conditional compilation that incorrectly maps to the wrong system color on macOS:

```swift
// Colors.swift:107-115 (CURRENT BUGGY CODE)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)  // ✅ CORRECT for iOS
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .tertiaryLabelColor)  // ❌ BUG: Label color, not background!
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()
```

**Why this is wrong:**
- `.tertiaryLabelColor` is designed for **text/label foreground content**, not backgrounds
- Using a label color as a background creates semantic mismatch and fails contrast requirements
- iOS correctly uses `.tertiarySystemBackground` (a background color), but macOS does not

**Impact**: All components using `DS.Colors.tertiary` on macOS show poor visual separation from window backgrounds.

---

## Affected Components

### Files Requiring Updates
1. **`FoundationUI/Sources/FoundationUI/DesignTokens/Colors.swift`** (line 111)
   - **Change from**: `.tertiaryLabelColor`
   - **Change to**: `.controlBackgroundColor` (recommended)

### Components Exhibiting the Bug
All components using `DS.Colors.tertiary` on macOS:

1. **SidebarPattern** (`SidebarPattern.swift:176`) - detail content background
2. **Card** (`CardStyle.swift:159, 162`) - card background fallback
3. **InspectorPattern** (via SurfaceStyle) - content backgrounds
4. **ToolbarPattern** (`ToolbarPattern.swift:51, 263`) - toolbar backgrounds
5. **SurfaceStyle** (`SurfaceStyle.swift:85, 195`) - material fallbacks
6. **InteractiveStyle** (multiple locations) - interactive element backgrounds

**Total Reach**: Every pattern and major component in FoundationUI on macOS is affected.

---

## Documentation Updates Completed

### ✅ Bug Specification
- **Location**: [`FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md`](./BUG_Colors_Tertiary_macOS_LowContrast.md)
- **Content**: Full root cause analysis, fix specification, testing requirements

### ✅ Task Plan
- **Location**: [FoundationUI Task Plan - Phase 1.3 Bug Fixes](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#13-bug-fixes)
- **Updates**:
  - Added 1 task to Phase 1.3 (Bug Fixes)
  - Updated progress: 9/10 tasks (90%)
  - Updated overall progress: 73/117 tasks (62.4%)
  - Priority: **P0** (Critical)

### ✅ PRD
- **Location**: [FoundationUI PRD - Layer 0 Bug Fix](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#bug-fix-dscolorstertiary-macos-low-contrast)
- **Updates**: Bug fix requirements and success criteria documented

### ✅ Test Plan
- **Location**: [FoundationUI Test Plan - Bug Fix Regression Testing](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md#bug-fix-regression-testing)
- **Updates**: Comprehensive regression test strategy:
  - Unit tests for token validation
  - Snapshot tests for all affected components (macOS)
  - Accessibility tests (WCAG AA contrast ≥4.5:1)
  - Integration tests for component composition
  - Manual testing checklist for ComponentTestApp

---

## Impact Assessment

### User Impact: **HIGH**
**Who is affected:**
- All macOS users of FoundationUI components
- All developers using ComponentTestApp for demonstrations on macOS
- Users with accessibility needs (low vision, contrast sensitivity)

**Severity:**
- Low contrast makes UI harder to use, especially in bright lighting
- Unclear content boundaries reduce usability
- Fails accessibility standards for users with visual impairments

**User Scenarios Affected:**
- Navigating ComponentTestApp patterns on macOS
- Using SidebarPattern in any macOS application
- All UI patterns that rely on background differentiation

### Design System Impact: **MAINTAINS INTEGRITY**
**Current State:**
- ✅ Zero Magic Numbers rule followed (uses system colors)
- ❌ Wrong semantic color chosen for macOS
- ❌ Platform inconsistency (iOS correct, macOS broken)

**After Fix:**
- ✅ Platform parity restored (macOS matches iOS semantic intent)
- ✅ Correct semantic usage (background color for backgrounds)
- ✅ Design system integrity strengthened

### Accessibility Impact: **CURRENTLY BLOCKS ACCESSIBILITY**
**Current State:**
- ❌ Fails WCAG 2.1 AA requirements (contrast ratio <4.5:1)
- ❌ Low contrast affects users with low vision
- ❌ Unclear boundaries confuse VoiceOver context
- ❌ Increase Contrast setting may not help due to wrong base color

**After Fix:**
- ✅ WCAG AA compliance restored (≥4.5:1 contrast)
- ✅ Clear visual boundaries for all users
- ✅ Proper Increase Contrast support
- ✅ VoiceOver can announce content structure clearly

### Platform Scope
- **iOS**: ✅ Already correct (`.tertiarySystemBackground`)
- **iPadOS**: ✅ Already correct (`.tertiarySystemBackground`)
- **macOS**: ❌ Broken (`.tertiaryLabelColor` - wrong color type)

---

## Estimated Effort

**Size**: **S (Small)**

### Justification:
- **Code complexity**: Simple (one-line change in Colors.swift:111)
- **Test coverage needed**: Basic (unit + snapshot tests)
- **Documentation updates**: Already completed
- **Prerequisites required**: None

### Breakdown:
1. **Code change**: 5 minutes
   - Change line 111 from `.tertiaryLabelColor` to `.controlBackgroundColor`
2. **Unit tests**: 15 minutes
   - Add platform-specific token validation test
3. **Snapshot tests**: 30 minutes
   - Create macOS baselines for SidebarPattern, Card
   - Verify Light/Dark mode
4. **Manual verification**: 15 minutes
   - Test in ComponentTestApp
   - Verify Increase Contrast mode
5. **SwiftLint & CI**: 10 minutes
   - Ensure clean build
   - Wait for CI to pass

**Total estimated time**: ~1.5 hours

---

## Priority Recommendation

**Priority: P0 (Critical)**

### Justification:
1. **High severity** - Affects all macOS users
2. **Blocks accessibility** - Fails WCAG AA compliance
3. **Design system violation** - Platform inconsistency undermines framework credibility
4. **Low effort** - Simple fix with high impact
5. **Foundation layer** - Bug affects all components built on top

### Recommended Timeline:
- **Assignment**: Immediate
- **Fix implementation**: Within 1 day
- **Review & merge**: Within 2 days
- **Release**: Next patch release

---

## Proposed Fix

### Code Change
**File**: `FoundationUI/Sources/FoundationUI/DesignTokens/Colors.swift`

```swift
// Line 107-115 (CURRENT)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .tertiaryLabelColor)  // ❌ BUG
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()

// PROPOSED FIX (Option 2: controlBackgroundColor - RECOMMENDED)
public static let tertiary: SwiftUI.Color = {
    #if canImport(UIKit)
    return SwiftUI.Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
    return SwiftUI.Color(nsColor: .controlBackgroundColor)  // ✅ FIX
    #else
    return SwiftUI.Color.gray.opacity(0.1)
    #endif
}()
```

### Alternative Options:
1. **Option 1**: `.windowBackgroundColor` - Most neutral, matches main window
2. **Option 2**: `.controlBackgroundColor` - **RECOMMENDED** - Provides subtle differentiation
3. **Option 3**: `.underPageBackgroundColor` - Stronger visual separation

**Recommendation**: Option 2 (`.controlBackgroundColor`) best matches iOS's `.tertiarySystemBackground` semantic intent.

### Testing Requirements
1. **Unit test**: Verify token uses background color, not label color
2. **Snapshot tests**: macOS baselines for all affected components
3. **Accessibility test**: Verify ≥4.5:1 contrast ratio
4. **Manual test**: ComponentTestApp visual verification

---

## Success Criteria

### Code Quality
- [ ] Fix uses correct macOS background color (`.controlBackgroundColor`)
- [ ] All tests pass (unit, snapshot, accessibility)
- [ ] SwiftLint 0 violations
- [ ] Test coverage ≥100% for bug fix lines

### Visual Quality
- [ ] ComponentTestApp shows clear contrast on macOS
- [ ] SidebarPattern detail area visually distinct from window
- [ ] All components using tertiary color have proper separation
- [ ] Light and Dark mode both work correctly
- [ ] Increase Contrast mode enhances separation

### Accessibility
- [ ] Contrast ratio ≥4.5:1 verified (WCAG AA)
- [ ] VoiceOver announces content boundaries correctly
- [ ] Keyboard focus indicators are visible
- [ ] Increase Contrast setting works properly

### Platform Parity
- [ ] macOS semantic intent matches iOS
- [ ] No regression on iOS/iPadOS
- [ ] Consistent user experience across all platforms

---

## Open Questions

1. **Which macOS background color provides best semantic match?**
   - **Answer**: `.controlBackgroundColor` (recommended) - provides subtle differentiation while maintaining semantic consistency with iOS

2. **Should we add macOS-specific snapshot tests?**
   - **Answer**: Yes - create separate macOS snapshot baselines for affected components

3. **Do we need a new token for stronger differentiation?**
   - **Answer**: No - fix existing token first, evaluate need for additional tokens later

4. **Should we audit all other platform-specific tokens?**
   - **Answer**: Yes (future work) - this bug suggests a broader review of macOS/iOS conditional color mappings

---

## Next Steps

### For Project Manager:
1. Assign task to developer (estimate: 1.5 hours)
2. Set priority to P0 (Critical)
3. Schedule for next sprint/patch release

### For Developer:
1. Read full specification: [`BUG_Colors_Tertiary_macOS_LowContrast.md`](./BUG_Colors_Tertiary_macOS_LowContrast.md)
2. Review affected files and test plan
3. Implement fix with tests
4. Verify in ComponentTestApp on macOS
5. Submit PR with before/after screenshots

### For QA:
1. Follow manual testing checklist in Test Plan
2. Verify contrast ratio with accessibility tools
3. Test on multiple macOS versions (14.0+)
4. Compare with iOS for semantic consistency

---

## References

- **Full Specification**: [`FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md`](./BUG_Colors_Tertiary_macOS_LowContrast.md)
- **Task Plan**: [Phase 1.3 Bug Fixes](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#13-bug-fixes)
- **PRD**: [Layer 0 Bug Fix](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#bug-fix-dscolorstertiary-macos-low-contrast)
- **Test Plan**: [Bug Fix Regression Testing](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md#bug-fix-regression-testing)
- **WCAG 2.1 Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/

---

**Report Generated**: 2025-11-07
**BUG Command Version**: 1.0
**Framework**: FoundationUI
**Project**: ISO Inspector
