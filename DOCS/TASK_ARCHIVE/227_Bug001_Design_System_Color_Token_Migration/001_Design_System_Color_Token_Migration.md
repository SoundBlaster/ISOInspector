# BUG #001: Design System Color Token Migration Required

**Status:** Open  
**Priority:** Medium  
**Reported:** 2025-11-16  
**Assignee:** Claude Code  

---

## Step 1: Capture the Bug Report

### Objective

ISOInspectorApp is in active FoundationUI migration but continues to use manual SwiftUI color definitions (`.accentColor`, hardcoded opacity values) instead of FoundationUI design system tokens (`DS.*`). This violates the design system architecture and prevents Phase 5.2 completion.

### Symptoms

1. **Design Inconsistency:** 6 view files use hardcoded colors with manual opacity values (0.08, 0.12, 0.15, 0.18, 0.25)
2. **Source Duplication:** Colors defined in both Asset Catalog and `ISOInspectorBrandPalette` 
3. **FoundationUI Bypass:** Design tokens not used despite 123 integration tests and comprehensive test suite
4. **Maintenance Risk:** Color changes require updates in multiple locations

### Environment

- **Project:** ISOInspector (monorepo with FoundationUI integration)
- **Platform:** macOS 14+, iOS 16+, iPadOS 16+
- **Frameworks:** SwiftUI, FoundationUI design system
- **Test Suite:** 751 tests (all passing), 123 FoundationUI integration tests

### Reproduction Steps

1. Open `Sources/ISOInspectorApp/UI/Tree/ParseTreeOutlineView.swift`
2. Search for `.accentColor` — finds 5 direct usages with manual opacity
3. Search in `ParseTreeDetailView.swift` — finds 4 direct usages
4. Observe no use of `DS.Color.*` tokens in these views
5. Compare with Asset Catalog definitions: `AccentColor.colorset` and `SurfaceBackground.colorset`
6. Check `ISOInspectorAppTheme.swift` — uses `ISOInspectorBrandPalette` not FoundationUI

### Expected vs. Actual

| Aspect | Expected | Actual |
|--------|----------|--------|
| **Color Source** | FoundationUI `DS.Color.*` tokens | Manual `.accentColor` + opacity |
| **Design Token Usage** | 100% compliance in all views | ~20% compliance (some components only) |
| **Color Definition Locations** | Single source (FoundationUI) | Multiple (Asset Catalog, BrandPalette, views) |
| **Opacity Values** | Semantic (e.g., `DS.Color.accentSurface`) | Magic numbers (0.08, 0.12, 0.15, 0.18, 0.25) |
| **FoundationUI Phase** | Completed to Phase 6 | Blocked at Phase 5.2 |

### Open Questions

1. **Does FoundationUI provide equivalent tokens** for the opacity values currently used?
   - 0.08 (slight tint) → `DS.Color.accentOverlay` or similar?
   - 0.12 (medium tint) → `DS.Color.accentBackground`?
   - 0.15, 0.18, 0.25 → need mapping

2. **What is the FoundationUI token naming convention** for interactive states?
   - Hover states: `DS.Color.accentHover`?
   - Pressed states: `DS.Color.accentPressed`?
   - Selected/active: `DS.Color.accentActive`?

3. **Should Asset Catalog colors be removed** after FoundationUI migration?
   - Risk: App code still references `Color("AccentColor", bundle: .module)` in legacy code
   - Decision: Deprecate vs. remove completely

4. **When should Phase 5.3+ begin?**
   - Dependency: Color token audit and FoundationUI token documentation

---

## Step 2: Define Scope and Hypotheses

### Functional Area (Front of Work)

**UI Theming & Design System Integration**
- Component: ISOInspectorApp color palette
- Subsystem: FoundationUI design system migration
- Affected tier: View layer (SwiftUI)

### Code Locations to Investigate

**Primary (Manual Color Usage):**
- `Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift` — 5 usages
- `Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift` — 4 usages
- `Sources/ISOInspectorApp/Settings/ValidationSettingsView.swift` — 3 usages
- `Sources/ISOInspectorApp/Integrity/IntegritySummaryView.swift` — 1 usage
- `Sources/ISOInspectorApp/Theming/ISOInspectorAppTheme.swift` — 2 usages

**Secondary (Design System Definitions):**
- `Sources/ISOInspectorKit/Theming/ISOInspectorBrandPalette.swift` — brand colors
- `Sources/ISOInspectorApp/Resources/Assets.xcassets/` — Asset Catalog definitions
- `FoundationUI/Sources/*/DesignTokens/` — FoundationUI token definitions (to audit)

### Existing Tests

**Positive:**
- 123 FoundationUI integration tests (`Tests/ISOInspectorAppTests/FoundationUI/`)
- BadgeComponentTests, CardComponentTests, KeyValueRowComponentTests
- Full test suite passes (751 tests)

**Negative:**
- No tests specifically validating design token compliance
- No linting rules preventing `.accentColor` usage
- No integration test for color consistency across views

### Initial Diagnostic Hypotheses

**H1: FoundationUI provides all necessary tokens**
- Likelihood: High (design system should be comprehensive)
- Test: Review FoundationUI design token documentation
- Impact if true: Straightforward migration, update views to use `DS.*`

**H2: Some opacity values lack FoundationUI equivalents**
- Likelihood: Medium (custom opacity values may be app-specific)
- Test: Audit FoundationUI token coverage; check integration strategy docs
- Impact if true: Define app-specific semantic tokens in wrapper layer (e.g., `ISOInspectorAppTheme` extended)

**H3: Asset Catalog colors are shadowing FoundationUI**
- Likelihood: High (Asset Catalog takes precedence in bundle resolution)
- Test: Remove Asset Catalog colors and verify no breakage
- Impact if true: Delete unused Asset Catalog definitions after migration

**H4: Manual color usage indicates incomplete FoundationUI spec**
- Likelihood: Low (unlikely given 123 tests and integration strategy)
- Test: Review phase 5 completion checklist
- Impact if true: FoundationUI spec may need extension before full adoption

---

## Step 3: Plan Diagnostics and Testing

### Diagnostics Plan

**Task D1: FoundationUI Token Audit**
- [ ] Review FoundationUI design token documentation (`FoundationUI/DOCS/DESIGN_TOKENS.md` or equivalent)
- [ ] List all color tokens available (e.g., `DS.Color.*`)
- [ ] Extract opacity/semantic layer tokens (primary, secondary, subtle, overlay)
- [ ] Document coverage: 100% match, 80% match, gaps identified
- [ ] Output: Token mapping table (opacity values → semantic tokens)

**Task D2: Current Usage Analysis**
- [ ] Extract all `.accentColor` usages with context
- [ ] Extract all hardcoded opacity values and their intent
- [ ] Categorize by pattern: hover, selected, background, border, text
- [ ] Output: Usage matrix (file, line, opacity, context)

**Task D3: Asset Catalog Impact Analysis**
- [ ] Verify `AccentColor.colorset` and `SurfaceBackground.colorset` are unused in updated code
- [ ] Check if any legacy code still references `Color("AccentColor", bundle: .module)`
- [ ] Output: Safe-to-delete confirmation or identified dependencies

### TDD Testing Plan

**Test Group T1: Design Token Compliance**
- [ ] Create test: `testAllViewsUseDesignTokensNotManualColors()`
  - Scan view source code for `.accentColor` (fail if found)
  - Scan for opacity values (fail if magic numbers found)
  - Pass only if `DS.Color.*` used
- [ ] Create test: `testDesignTokensResolveCorrectly()`
  - Verify each `DS.Color.*` token resolves to expected RGB value
  - Compare against FoundationUI specification
- [ ] Create test: `testColorContrastMeetsWCAG()`
  - Validate color combinations meet WCAG AA contrast ratio (4.5:1 for text)
  - Apply to all `.accentColor` usage contexts

**Test Group T2: Migration Validation**
- [ ] Create test: `testParseTreeOutlineViewUsesDesignTokens()`
  - Verify no `.accentColor` or opacity usage
  - Confirm `DS.Color.*` tokens used for all color needs
- [ ] Create test: `testParseTreeDetailViewUsesDesignTokens()`
- [ ] Create test: `testValidationSettingsViewUsesDesignTokens()`
- [ ] Create test: `testIntegritySummaryViewUsesDesignTokens()`
- [ ] Create test: `testISOInspectorAppThemeUsesBrandPalette()` (already passes)

**Test Group T3: Asset Catalog Removal**
- [ ] Create test: `testAssetCatalogColorNotReferenced()`
  - Scan codebase for `Color("AccentColor"` patterns
  - Fail if found (ensure complete migration before removal)

---

## Step 4: Produce a Focused PRD Update

### PRD Section: Design System Token Migration

#### Customer Impact
- **User-Facing:** None (internal refactoring)
- **Developer-Facing:** Improved maintenance, consistency, design system compliance

#### Acceptance Criteria

1. ✅ All manual `.accentColor` usages replaced with FoundationUI `DS.Color.*` tokens
2. ✅ All hardcoded opacity values replaced with semantic token values
3. ✅ Asset Catalog colors (`AccentColor.colorset`, `SurfaceBackground.colorset`) removed
4. ✅ FoundationUI integration tests pass (123 tests)
5. ✅ Full test suite passes (751 tests)
6. ✅ New design token compliance tests added and passing
7. ✅ Zero references to `.accentColor` in app code (excluding tests)
8. ✅ Design token documentation updated in `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`

#### Technical Approach

**Phase A: Audit & Planning**
1. Complete FoundationUI token audit (Task D1)
2. Create token mapping table (opacity → semantic)
3. Document any gaps requiring custom tokens

**Phase B: Migration**
1. Update `ISOInspectorAppTheme.swift` to use FoundationUI tokens (or remove if FoundationUI provides direct equivalent)
2. Update `ParseTreeOutlineView.swift` — replace 5 usages
3. Update `ParseTreeDetailView.swift` — replace 4 usages
4. Update `ValidationSettingsView.swift` — replace 3 usages
5. Update `IntegritySummaryView.swift` — replace 1 usage

**Phase C: Cleanup**
1. Remove Asset Catalog color definitions
2. Remove `ISOInspectorAppTheme.swift` if FoundationUI provides equivalents
3. Update imports across all views

**Phase D: Validation**
1. Add design token compliance tests
2. Run full test suite
3. Manual verification in ComponentTestApp

---

## Step 5: Execute the Fix via TDD/XP/PDD

*(To be completed during fix execution)*

### TDD Cycle Tracking

- [ ] Red: Write failing design token compliance tests
- [ ] Green: Implement minimal migrations to pass tests
- [ ] Refactor: Consolidate color definitions, remove duplication
- [ ] Iterate: Address each view file systematically

### XP Principles Applied

- **Small iterations:** Migrate one view at a time
- **Continuous refactoring:** Remove `ISOInspectorAppTheme.swift` if unneeded
- **Pair programming mindset:** Document decisions for team review
- **Continuous testing:** Run suite after each file update

### PDD (Problem-Driven Development)

Treat each question in Step 2 as a puzzle:
- **P1:** FoundationUI token coverage — research + audit
- **P2:** Custom opacity values — design review
- **P3:** Asset Catalog deprecation — safe removal strategy
- **P4:** FoundationUI spec completion — escalate if needed

---

## Step 6: Validate and Document

*(To be completed during validation phase)*

- [ ] Full test suite passes (751 tests)
- [ ] New compliance tests added and passing
- [ ] Manual verification in app and ComponentTestApp
- [ ] Design guide updated
- [ ] No `.accentColor` references in app code

---

## Step 7: Handle Blockers or Large Scope

### Current Blockers

1. **FoundationUI Token Documentation**
   - Need: Complete token reference (all `DS.Color.*` definitions)
   - Owner: FoundationUI team or product documentation
   - Impact: Blocks Token Audit task (D1)

2. **Integration Strategy Phase 5 Closure Criteria**
   - Need: Formal definition of Phase 5.2 completion requirements
   - Owner: Project architecture/PM
   - Reference: `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

### Escalation Path

If Phase 5.2 cannot complete without design token migration:
1. Escalate to FoundationUI integration lead
2. Request Phase 5.2 → Phase 5.3 blocking factor update
3. Update `DOCS/INPROGRESS/blocked.md` with dependencies
4. Reschedule migration to explicit task in workplan

---

## Step 8: Finalize

*(To be completed upon resolution)*

- [ ] Archive this file to `DOCS/TASK_ARCHIVE/[TASK_ID]_Design_System_Token_Migration/`
- [ ] Update `DOCS/INPROGRESS/blocked.md` to mark as resolved
- [ ] Update `DOCS/INPROGRESS/next_tasks.md` with follow-ups
- [ ] Create summary document in new archive location
- [ ] Link PR/commit references to this task

---

## 📊 Tracking & Status

| Milestone | Status | Notes |
|-----------|--------|-------|
| Bug Report Formalized | ✅ Complete | This document |
| Scope & Hypotheses Defined | ✅ Complete | Step 2 above |
| Diagnostics Plan Created | ✅ Complete | Step 3 above |
| PRD Section Draft | ✅ Complete | Step 4 above |
| Diagnostics Executed | ⏳ Pending | Task D1-D3 |
| Tests Written (Red Phase) | ⏳ Pending | Task T1-T3 |
| Code Migration (Green Phase) | ⏳ Pending | Phase B |
| Refactoring | ⏳ Pending | Phase C |
| Validation | ⏳ Pending | Phase D |
| Finalization | ⏳ Pending | Step 8 |

---

## 📎 References

- **FoundationUI Docs:** `FoundationUI/DOCS/`, `FoundationUI/README.md`
- **Integration Strategy:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`
- **Design System Guide:** `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`
- **Color Usage Analysis:** `DOCS/INPROGRESS/BUG_Manual_Color_Usage_vs_FoundationUI.md`
- **Related Fix:** `DOCS/INPROGRESS/Summary_Color_Theme_Resolution.md`
- **Test Results:** All 751 tests passing; 123 FoundationUI integration tests
- **BUG Workflow:** `DOCS/COMMANDS/BUG.md`

---

## 📝 Notes

- This document serves as the single source of truth for bug #001
- Update this file as diagnostics progress and blockers are discovered
- Link all commits related to this bug with `Fixes #001` references
