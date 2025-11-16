# BUG: Manual Color Usage vs FoundationUI Design System

## Issue Summary

ISOInspectorApp is actively migrating to **FoundationUI** as the primary UI Kit base (per integration strategy in `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`), but significant portions of the codebase are still using **manual SwiftUI color definitions** instead of FoundationUI's design system tokens.

This creates a **design inconsistency** and violates the principle of using a single design system as the source of truth.

## Current State

### Manual Color Usage (Found in 6 files)

The following files use hardcoded `.accentColor` and custom opacity layers instead of FoundationUI design tokens:

1. **ParseTreeOutlineView.swift** (5 usages)
   - Filter button background: `Color.accentColor.opacity(0.25)` and `.opacity(0.08)`
   - Search match text: `Color.accentColor`
   - Bookmark icon: `Color.accentColor`
   - Row highlight background: `Color.accentColor.opacity(0.18)` and `.opacity(0.12)`

2. **ParseTreeDetailView.swift** (4 usages)
   - Selected item background: `Color.accentColor.opacity(0.15)`
   - Selected item border: `Color.accentColor`
   - Highlighted item background: `Color.accentColor.opacity(0.25)`
   - Highlighted item border: `Color.accentColor`

3. **ValidationSettingsView.swift** (3 usages)
   - Rule enable/disable buttons: `.foregroundColor(.accentColor)`

4. **IntegritySummaryView.swift** (1 usage)
   - Text color: `.foregroundColor(.accentColor)`

5. **ISOInspectorAppTheme.swift** (2 usages)
   - App-wide tint: `ISOInspectorAppTheme.accentColor(for:)`
   - Background: `ISOInspectorAppTheme.surfaceBackground(for:)`

6. **Tree/ParseTreeOutlineView.swift** (5 usages combined with above)

### FoundationUI Integration Status

According to `DOCS/INPROGRESS/blocked.md`, FoundationUI integration is in:
- **Phase 5.2: Performance Profiling** (last active phase)
- **123 comprehensive tests** in `Tests/ISOInspectorAppTests/FoundationUI/`
- **6-phase gradual migration plan** defined in integration strategy
- **Design Tokens:** FoundationUI provides `DS.*` tokens for spacing, colors, typography, and animations

## Root Cause

The migration to FoundationUI is ongoing, but the following views were not updated to use FoundationUI design tokens:
- Color definitions are scattered across multiple views
- Opacity values are hardcoded (0.08, 0.12, 0.15, 0.18, 0.25) without semantic meaning
- No centralized color token system is being used
- Asset Catalog colors (`AccentColor.colorset`, `SurfaceBackground.colorset`) are defined but redundant

## Impact

1. **Design Inconsistency:** Colors and opacities are not standardized across views
2. **Maintenance Burden:** Color changes require updates in multiple locations
3. **FoundationUI Violation:** Design tokens should be the single source of truth
4. **Testing Complexity:** Manual color definitions don't benefit from FoundationUI's comprehensive test suite

## Recommended Resolution

### Phase 1: Audit FoundationUI Design Tokens
- Review FoundationUI documentation and design system to identify equivalent color tokens
- Map current opacity values (0.08, 0.12, 0.15, 0.18, 0.25) to semantic FoundationUI tokens
- Document the mapping in a design system integration guide

### Phase 2: Update Views to Use FoundationUI Tokens
Replace manual color usage with FoundationUI design system:

**Before:**
```swift
Color.accentColor.opacity(0.15)  // No semantic meaning
Color.accentColor                 // Uses system accent
```

**After:**
```swift
DS.Color.accentSurface            // Semantic, FoundationUI-managed
DS.Color.accentBorder             // Clear intent
```

### Phase 3: Remove Manual Color Definitions
- Remove `ISOInspectorAppTheme.swift` color functions (only if FoundationUI equivalents exist)
- Delete `AccentColor.colorset` and `SurfaceBackground.colorset` from Asset Catalog
- Use FoundationUI's centralized color management exclusively

### Phase 4: Validate Consistency
- Update UI integration tests to verify FoundationUI token compliance
- Add linting rules to prevent direct `.accentColor` usage in non-FoundationUI context
- Document design token usage patterns for future developers

## References

- **Integration Architecture:** `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md` (FoundationUI section)
- **Design System Guide:** `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`
- **Component Showcase:** `Examples/ComponentTestApp/`
- **Integration Tests:** `Tests/ISOInspectorAppTests/FoundationUI/` (123 tests)
- **Integration Strategy:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md` (9-week phased plan)
- **Current Status:** `DOCS/INPROGRESS/blocked.md` (Phase 5.2 - Performance Profiling)

## Related Work

- **Color Resolution Bug (Fixed):** See `Summary_Color_Theme_Resolution.md` — The recent fix to use `ISOInspectorBrandPalette` directly instead of Asset Catalog was a temporary solution that highlights the need for FoundationUI integration completion.

## Priority

**Medium** — This is a design system consistency issue. It should be addressed as part of the FoundationUI Phase 5 completion and subsequent migration phases (phases 6-9 per integration strategy).

## Blocking Factors

- FoundationUI design tokens must be fully documented and stable
- ComponentTestApp must expose all design tokens for visual verification
- Integration strategy phases 6-9 must define the migration sequence
