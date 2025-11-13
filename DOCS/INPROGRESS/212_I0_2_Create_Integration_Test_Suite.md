# I0.2 — Create Integration Test Suite

## 🎯 Objective

Expand the `Tests/ISOInspectorAppTests/FoundationUI/` test suite with comprehensive FoundationUI component test coverage, enabling reliable snapshot testing for visual regression detection and ensuring component behavior meets FoundationUI integration standards across iOS and macOS platforms.

## 🧩 Context

FoundationUI Integration Phase 0 is a critical P0 blocker that gates all subsequent integration phases. Task I0.1 (Add FoundationUI Dependency) was completed on 2025-11-13, adding FoundationUI as a SwiftPM dependency and verifying basic builds. Task I0.2 follows immediately to establish comprehensive test coverage for core FoundationUI components before showcasing them in I0.3.

**Related artifacts:**
- Prior task archive: `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/212_I0_1_Add_FoundationUI_Dependency.md`
- Integration strategy: `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/FoundationUI_Integration_Strategy.md`
- Design system guide: `DOCS/AI/Design_System_and_Technical_Spec/10_DESIGN_SYSTEM_GUIDE.md`
- Master PRD: `DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`

## ✅ Success Criteria

- [ ] Comprehensive test coverage ≥80% for core FoundationUI components (Badge, Card, KeyValueRow, Button, TextField)
- [ ] Snapshot tests implemented for visual regression detection across iOS and macOS
- [ ] Platform-specific test variants (iOS 17+, macOS 14+) covering all target OS versions
- [ ] All tests passing locally with `swift test`
- [ ] Test output shows zero failures and snapshot diffs match expectations
- [ ] CI integration ready (tests integrated into GitHub Actions workflow if applicable)
- [ ] Updated `DOCS/INPROGRESS/next_tasks.md` marking I0.2 as completed and I0.3 as next priority

## 🔧 Implementation Notes

### Test Suite Expansion Strategy

**Location:** `Tests/ISOInspectorAppTests/FoundationUI/`

**Core components to test (minimum coverage):**
1. **Badge** — test rendering with various states, sizes, colors
2. **Card** — test container layout, padding, shadow handling
3. **KeyValueRow** — test label/value alignment, wrapping behavior
4. **Button** — test action trigger, state changes, accessibility labels
5. **TextField** — test input binding, placeholder text, validation states

**Snapshot testing approach:**
- Use SwiftUI `.snapshot()` testing framework (or equivalent test harness)
- Capture snapshots for:
  - Light mode baseline
  - Dark mode variant
  - Accessibility sizes (regular, larger, extra-large)
  - Different platform traits (compact vs. regular environment)

**Platform-specific tests:**
- iOS 17.x simulator tests
- macOS 14.x simulator tests (if available)
- iPad Pro variant (12.9", 11") for responsive layout validation

### Quality Gates

- Minimum test coverage: **≥80%** of FoundationUI component code paths
- Snapshot baseline lock to prevent regressions
- All snapshot diffs reviewed and approved before merge
- Accessibility validation: verify components announce properly with VoiceOver enabled
- Performance assertion: component render time <100ms per SwiftUI preview render cycle

### Dependencies & Prerequisites

- ✅ FoundationUI added to SwiftPM dependencies (I0.1 complete)
- ✅ Build succeeds with FoundationUI target
- ⚠️ Xcode 15+ required for snapshot testing features
- ⚠️ iOS 17 SDK and macOS 14 SDK installed locally

### Risk & Mitigation

**Risk:** Snapshot tests may differ between Xcode versions or CI runner vs. local development
**Mitigation:** Lock snapshot baseline to specific Xcode version in CI config; document expected variance in `Documentation/Testing.md`

**Risk:** Large number of snapshots may slow down test suite execution
**Mitigation:** Parallelize snapshot generation across test targets; consider async snapshot collection if execution exceeds 30s

## 🧠 Source References

- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/FoundationUI_Integration_Strategy.md)
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`10_DESIGN_SYSTEM_GUIDE.md`](../AI/Design_System_and_Technical_Spec/10_DESIGN_SYSTEM_GUIDE.md)
- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md) — Testing best practices
- [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) — Task selection framework

---

**Status:** 🟡 In Progress
**Created:** 2025-11-13
**Last Updated:** 2025-11-13
