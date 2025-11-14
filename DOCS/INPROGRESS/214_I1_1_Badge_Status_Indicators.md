# I1.1 — Badge & Status Indicators

## 🎯 Objective

Consolidate scattered manual badge implementations in ISOInspectorApp into consistent, reusable FoundationUI components (`DS.Badge` and `DS.Indicator`) for displaying parse status, error levels, and processing indicators.

## 🧩 Context

**Current State:**
- ISOInspectorApp uses manual text styling for status indicators throughout the codebase
- Parse error/warning badges are inconsistently styled
- Processing status indicators lack unified design language

**Target State:**
- All status indicators use `DS.Badge` component
- Parse status uses `DS.Indicator` for tree view nodes
- Consistent visual language across light/dark modes
- Full accessibility compliance (VoiceOver, contrast, focus)

**Phase Context:**
- Part of **FoundationUI Integration Phase 1: Foundation Components**
- First task in Phase 1 (low-risk atomic components)
- Phase 0 (Setup & Verification) completed 2025-11-14 ✅
- Enables consistent status visualization before proceeding to I1.2 (Cards) and I1.3 (Key-Value Rows)

## ✅ Success Criteria

1. **Component Migration:**
   - ✅ All manual badges replaced with `DS.Badge`
   - ✅ All status indicators use `DS.Indicator`
   - ✅ `BoxStatusBadgeView` wrapper created for box status levels
   - ✅ `ParseStatusIndicator` wrapper created for tree view nodes

2. **Testing Coverage:**
   - ✅ Unit test coverage ≥90% for badge/indicator variants
   - ✅ Snapshot tests pass for all variants (light/dark modes, all 4 status levels)
   - ✅ Accessibility tests verify VoiceOver labels, contrast ratios, and focus management
   - ✅ All tests passing on macOS, iOS, iPadOS platforms

3. **Quality Gates:**
   - ✅ Zero SwiftLint violations
   - ✅ Accessibility score ≥98% (WCAG 2.1 AA compliance)
   - ✅ Build time impact <5%
   - ✅ No performance regressions in tree rendering

4. **Documentation:**
   - ✅ Component showcase updated with badge/indicator examples
   - ✅ Migration path documented in MIGRATION.md
   - ✅ Integration patterns documented in 03_Technical_Spec.md

## 🔧 Implementation Notes

### Subtasks (from FoundationUI_Integration_Strategy.md)

1. **I1.1.1** — Audit current badge usage in codebase
   - Grep for status indicators, manual text styling
   - Document all locations requiring migration
   - Identify badge variants (info/warning/error/success)

2. **I1.1.2** — Create `BoxStatusBadgeView` wrapper around `DS.Badge`
   - Support level: `.info`, `.warning`, `.error`, `.success`
   - Platform-adaptive sizing
   - Dark mode support

3. **I1.1.3** — Create `ParseStatusIndicator` for tree view nodes
   - Support sizes: mini, small, medium
   - Integration with tree node status
   - Performance optimization for large trees

4. **I1.1.4** — Add unit tests for badge/indicator variants
   - Test all status levels
   - Test all size variants
   - Test platform-specific behavior

5. **I1.1.5** — Add snapshot tests for light/dark modes
   - Capture all 4 status levels
   - Light and dark mode variants
   - Platform-specific rendering

6. **I1.1.6** — Add accessibility tests
   - VoiceOver label verification
   - Contrast ratio compliance
   - Focus management
   - Keyboard navigation

7. **I1.1.7** — Update component showcase
   - Add badge examples
   - Add indicator examples
   - Interactive demo of all variants

8. **I1.1.8** — Document migration path
   - Old code → new code examples
   - Best practices
   - Common pitfalls

### Files to Create/Modify

**New Files:**
```
Sources/ISOInspectorApp/UI/Components/BoxStatusBadgeView.swift
Sources/ISOInspectorApp/UI/Components/ParseStatusIndicator.swift
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorTests.swift
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorSnapshotTests.swift
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorAccessibilityTests.swift
DOCS/MIGRATION.md
```

**Updated Files:**
```
DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md
DOCS/INPROGRESS/next_tasks.md
```

### Important Considerations

- **Performance**: Ensure badge rendering doesn't impact tree view performance (virtualization)
- **Platform Adaptation**: Use `DS.PlatformAdaptation` for size/spacing differences
- **Accessibility**: All badges must have meaningful VoiceOver labels, not just visual indicators
- **Dark Mode**: Test thoroughly in both light and dark modes
- **Status Levels**: Map existing status concepts to FoundationUI levels:
  - Info → `.info` (blue)
  - Warning → `.warning` (yellow/orange)
  - Error → `.error` (red)
  - Success → `.success` (green)

## 🧠 Source References

- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — Phase 1.1 detailed plan
- [`next_tasks.md`](next_tasks.md) — Active task queue (Phase 1 status)
- [`03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) — Task selection rules
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Overall project workplan
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md) — Integration patterns documentation
- [`10_DESIGN_SYSTEM_GUIDE.md`](../AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md) — Design system integration checklist

## 📊 Estimated Effort

**Priority:** P1 (High)
**Effort:** 1-2 days
**Risk:** Low
**Dependencies:** Phase 0 complete ✅

## 🚀 Next Steps

1. Begin with subtask I1.1.1: Audit current badge usage
2. Create wrapper components (I1.1.2, I1.1.3)
3. Implement comprehensive test suite (I1.1.4-I1.1.6)
4. Update documentation and showcase (I1.1.7-I1.1.8)
5. Mark task complete and proceed to I1.2 (Card Containers)
