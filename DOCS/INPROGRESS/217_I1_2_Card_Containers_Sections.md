# I1.2 — Card Containers & Sections

## 🎯 Objective

Migrate the ISOInspectorApp details panel from manual container styling (padding, corners, shadows) to the FoundationUI Design System `DS.Card` and `DS.SectionHeader` components. This task delivers consistent, platform-adaptive card layouts with automatic dark mode support and accessibility compliance.

## 🧩 Context

**Current State:**
- Details panel sections use manual background colors, borders, corner radius, and shadows
- Section headers are implemented with custom dividers and typography
- Metadata cards have hardcoded spacing values (magic numbers)
- Dark mode adaptation is partially manual

**Target State:**
- All container sections migrated to `DS.Card` with elevation levels (`.thin`, `.regular`, `.thick`)
- Section headers use `DS.SectionHeader` for consistent typography and spacing
- All spacing uses Design System tokens (no magic numbers)
- Dark mode fully automatic via FoundationUI's `ColorSchemeAdapter`
- Platform-adaptive layouts using `PlatformAdaptation` context

**Dependencies:**
- ✅ Phase 0 complete (FoundationUI integrated, test infrastructure established)
- ✅ I1.1 complete (Badge & Status Indicators migrated)

**Related Work:**
- Follows immediately after I1.1 (Badge & Status Indicators)
- Prepares ground for I1.3 (Key-Value Rows & Metadata Display)
- Part of Phase 1 (Foundation Components) in the 9-week FoundationUI integration roadmap

## ✅ Success Criteria

### Functional Requirements
- ✅ All details panel container sections use `DS.Card` component
- ✅ All section headers replaced with `DS.SectionHeader`
- ✅ Zero hardcoded padding/corner/shadow values (use DS.Spacing tokens)
- ✅ Dark mode rendering correct and consistent across all cards
- ✅ Card elevation hierarchy visually clear (thin < regular < thick)

### Testing Requirements
- ✅ Unit test coverage ≥90% for new wrapper components
- ✅ Snapshot tests pass for all card variants (light/dark modes, elevation levels)
- ✅ Integration tests verify card nesting behavior
- ✅ Accessibility tests confirm semantic structure and landmarks
- ✅ No SwiftLint violations introduced

### Quality Requirements
- ✅ Accessibility score ≥98% (WCAG 2.1 AA compliance)
- ✅ Build time impact <5%
- ✅ No performance regressions in details panel rendering
- ✅ Snapshot regression tests pass on all platforms (macOS, iOS, iPadOS)

## 🔧 Implementation Notes

### Phase 1: Audit & Planning (0.5 day)

**I1.2.1 — Audit current container styles**
- Search codebase for manual container implementations
- Document current elevation patterns (which sections use which styles)
- Identify all hardcoded spacing/padding/corner values
- Map current styles to DS.Card elevation levels

**Audit Locations:**
```swift
Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift
Sources/ISOInspectorApp/Views/Details/*.swift
// Search patterns:
// - .background(Color.*)
// - .cornerRadius(*)
// - .shadow(*)
// - .padding(*)
```

### Phase 2: Component Wrappers (1 day)

**I1.2.2 — Create `BoxDetailsCard` wrapper**
- Build SwiftUI wrapper around `DS.Card`
- Support all DS.Card elevation levels (thin/regular/thick)
- Add ISO-specific card configuration (if needed)
- Integrate with platform adaptation context

**I1.2.3 — Create `BoxSectionHeader` wrapper**
- Build SwiftUI wrapper around `DS.SectionHeader`
- Support typography variants from Design System
- Add divider support (if section requires visual separation)
- Ensure VoiceOver correctly announces section landmarks

**Files to Create:**
```
Sources/ISOInspectorApp/UI/Components/BoxDetailsCard.swift (NEW)
Sources/ISOInspectorApp/UI/Components/BoxSectionHeader.swift (NEW)
```

### Phase 3: Migration (1 day)

**I1.2.4 — Refactor details panel layout**
- Replace manual container backgrounds with `BoxDetailsCard`
- Replace custom section headers with `BoxSectionHeader`
- Remove all hardcoded spacing/padding values
- Use `DS.Spacing` tokens throughout
- Verify visual hierarchy maintained

**Files to Modify:**
```
Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift (MAJOR UPDATE)
```

**Example Migration Pattern:**
```swift
// BEFORE:
VStack(spacing: 12) {
    Text("Metadata")
        .font(.headline)
    Divider()
    HStack {
        // content
    }
}
.padding(16)
.background(Color(.systemBackground))
.cornerRadius(8)
.shadow(radius: 2)

// AFTER:
BoxDetailsCard(elevation: .regular) {
    VStack(spacing: DS.Spacing.medium) {
        BoxSectionHeader(title: "Metadata")
        HStack {
            // content
        }
    }
}
```

### Phase 4: Testing (0.5-1 day)

**I1.2.5 — Unit + snapshot tests for card variants**
- Test all elevation levels (thin, regular, thick)
- Test light/dark mode rendering
- Test with different content sizes
- Verify DS.Spacing token application

**I1.2.6 — Integration tests for card nesting**
- Test nested card layouts
- Test cards within scrollable containers
- Test interaction with other FoundationUI components

**I1.2.7 — Accessibility tests**
- Verify semantic structure (landmarks, headings)
- Test VoiceOver announcements for sections
- Verify keyboard focus order
- Test with VoiceOver running (manual pass if possible)

**I1.2.8 — Dark mode verification**
- Visual inspection of dark mode rendering
- Snapshot tests for dark appearance
- High contrast mode compatibility check

**Files to Create:**
```
Tests/ISOInspectorAppTests/FoundationUI/CardSectionTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/CardSectionSnapshotTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/CardSectionAccessibilityTests.swift (NEW)
```

### Risk Mitigation

**Risk:** Breaking existing detail panel layout
- **Mitigation:** Incremental migration, one section at a time
- **Rollback:** Keep old views in git history, revert if regression found

**Risk:** Performance impact from extra view layers
- **Mitigation:** Measure render time before/after, ensure <16ms frame time
- **Benchmark:** Profile with Instruments (Time Profiler)

**Risk:** Dark mode rendering inconsistencies
- **Mitigation:** Comprehensive snapshot tests for light/dark/high-contrast
- **Validation:** Manual testing on actual macOS/iOS devices

### Platform-Specific Considerations

**macOS:**
- Card elevation may render differently (native materials vs. SwiftUI)
- Test with both light/dark appearance
- Verify NSPanel integration (if cards used in settings panel)

**iOS/iPadOS:**
- Test on multiple screen sizes (iPhone SE, iPhone 15, iPad Pro)
- Verify card layouts in both portrait/landscape orientations
- Test size class adaptation (compact vs. regular)

## 🧠 Source References

### Primary References
- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — Phase 1.2 detailed breakdown
- [`03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) — Task selection rules applied
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md) — Overall product requirements
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Phase C UI package tasks

### Related Archives
- [`DOCS/TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/`](../TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/) — Previous Phase 1 task
- [`DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/) — Phase 0 setup and test patterns

### Design System Documentation
- FoundationUI `DS.Card` API documentation
- FoundationUI `DS.SectionHeader` API documentation
- FoundationUI `DS.Spacing` token reference
- FoundationUI Platform Adaptation guide

### Testing Patterns
- Phase 0 integration test suite patterns
- I1.1 Badge test coverage examples
- Snapshot testing workflow from Phase 0

---

## 📋 Subtask Checklist

- [ ] **I1.2.1** — Audit current container styles (CardStyle, elevation levels)
- [ ] **I1.2.2** — Create `BoxDetailsCard` wrapper around `DS.Card`
- [ ] **I1.2.3** — Create `BoxSectionHeader` wrapper around `DS.SectionHeader`
- [ ] **I1.2.4** — Refactor details panel layout to use Cards
- [ ] **I1.2.5** — Add unit + snapshot tests for card variants (elevation, material)
- [ ] **I1.2.6** — Add integration tests for card nesting
- [ ] **I1.2.7** — Add accessibility tests (semantic structure, landmarks)
- [ ] **I1.2.8** — Verify dark mode adaptation

---

## 📊 Estimated Effort

**Total Duration:** 2-3 days (16-24 hours)

**Breakdown:**
- Audit & Planning: 0.5 day (4 hours)
- Component Wrappers: 1 day (8 hours)
- Migration: 1 day (8 hours)
- Testing & Verification: 0.5-1 day (4-8 hours)

**Priority:** P1 (High)
**Risk Level:** Low-Medium
**Dependencies:** Phase 0 ✅, I1.1 ✅

---

## 🏁 Definition of Done

- ✅ All 8 subtasks completed
- ✅ Code review approved
- ✅ All tests passing (unit + snapshot + integration + accessibility)
- ✅ SwiftLint clean (zero violations)
- ✅ Test coverage ≥90%
- ✅ Accessibility audit ≥98%
- ✅ Dark mode verified on all platforms
- ✅ No performance regressions measured
- ✅ Documentation updated in Technical Spec
- ✅ Changes merged to main branch
- ✅ Task archived with Summary_of_Work.md

---

**Created:** 2025-11-14
**Status:** Ready to Start
**Phase:** FoundationUI Integration Phase 1
**Session:** claude/implement-select-next-01WtVqaN3Ho3pXi8q49d4YKn
