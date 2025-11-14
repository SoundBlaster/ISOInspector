# I1.5 — Advanced Layouts & Navigation

**Date:** 2025-11-14
**Task ID:** I1.5
**Phase:** FoundationUI Integration Phase 1 (Foundation Components)
**Priority:** P1 (High)
**Effort Estimate:** 2 days
**Status:** 🚀 In Progress

---

## 🎯 Objective

Implement layout patterns and navigation structures using FoundationUI's grid system, spacing tokens, and responsive design capabilities. Migrate the app's sidebar and detail view layouts to use FoundationUI patterns while ensuring accessibility, dark mode support, and responsive behavior across all platform sizes (iPhone SE, iPhone 15 Pro Max, iPad, macOS).

This is the **final Phase 1 task**, completing the foundation component integration before moving to interactive components (Phase 2) and advanced layout patterns (Phase 3).

---

## 🧩 Context

### Phase 1 Progress

FoundationUI Phase 1 (Foundation Components) is **80% complete** with 4 of 5 tasks delivered:

✅ **I1.1** — Badge & Status Indicators (COMPLETED 2025-11-14)
✅ **I1.2** — Card Containers & Sections (COMPLETED 2025-11-14)
✅ **I1.3** — Key-Value Rows & Metadata Display (COMPLETED 2025-11-14)
✅ **I1.4** — Form Controls & Input Wrappers (COMPLETED 2025-11-14)
🚀 **I1.5** — Advanced Layouts & Navigation (THIS TASK)

See `DOCS/TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md` for I1.4 completion details.

### FoundationUI Integration Strategy

The complete integration roadmap is documented in:
- `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

Phase 1 focuses on **atomic, reusable UI elements** with minimal state dependencies. Phase 3 (Layout Patterns & Navigation) provides the detailed specifications for sidebar, inspector, and responsive patterns that will be refined in I1.5.

### Key Design Principles

1. **Gradual Integration** — FoundationUI components coexist with native SwiftUI during transition
2. **No Breaking Changes** — All existing app functionality remains operational
3. **Comprehensive Testing** — Unit tests, snapshot tests, and accessibility tests for all variants
4. **Platform-Aware Design** — Leverage platform adaptation contexts (macOS, iOS, iPadOS)
5. **Accessibility First** — WCAG 2.1 AA compliance across all interactive elements

---

## ✅ Success Criteria

### Layout Implementation

- ✅ Sidebar layout refactored to use FoundationUI grid and spacing tokens
  - File browser integrated into sidebar pattern
  - Section headers follow DS.SectionHeader style
  - Search/filter placement uses DS spacing

- ✅ Detail view layout migrated to FoundationUI patterns
  - All padding/margins use DS.Spacing tokens (no magic numbers)
  - Cards use DS.Card with appropriate elevation levels
  - Key-value metadata uses DS.KeyValueRow consistency
  - Form controls use wrapper components from I1.4

- ✅ Responsive behavior validated across all device sizes
  - iPhone SE (375pt width)
  - iPhone 15 Pro Max (440pt width)
  - iPad (variable portrait/landscape)
  - macOS (variable window sizes)

### Testing & Quality

- ✅ Unit tests cover all layout variants (≥85% coverage)
- ✅ Snapshot tests validate visual consistency across platforms
  - Light mode snapshots
  - Dark mode snapshots
  - All device sizes
- ✅ Accessibility tests verify
  - VoiceOver navigation flow
  - Keyboard-only interaction
  - Dynamic Type support (all sizes XS-XXXL)
  - Contrast compliance (WCAG AA)
- ✅ SwiftLint compliance (zero violations)
- ✅ Code coverage ≥80% for new/modified components

### Platform-Specific Features

- ✅ **macOS**
  - Sidebar collapsible (Cmd+Option+S shortcut)
  - Multi-column layout with proper spacing
  - Window resizing behavior validated

- ✅ **iOS**
  - Adaptive sidebar (full width on iPhone landscape, hidden on portrait)
  - Bottom navigation/tabs as alternative to sidebar
  - Touch-friendly spacing and hit targets

- ✅ **iPadOS**
  - Split view with appropriate sidebar width
  - Adaptive columns for larger screens
  - Landscape/portrait orientation handling

### Documentation

- ✅ Update `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md` with I1.5 implementation notes
- ✅ Update `10_DESIGN_SYSTEM_GUIDE.md` with FoundationUI layout patterns
- ✅ Add migration notes to `DOCS/MIGRATION.md` for layout refactoring
- ✅ DocC documentation for new/modified components

---

## 🔧 Implementation Notes

### Layout Component Hierarchy

```
ContentView
├── AppSidebar (refactored with DS patterns)
│   ├── FileBrowser (using DS.SidebarPattern)
│   │   └── FileItems with DS.Spacing
│   └── Navigation (using DS spacing tokens)
├── MainContent
│   ├── TreeView (with DS.Indicator badges)
│   ├── DetailsPanel (refactored)
│   │   ├── HeaderSection (DS.SectionHeader)
│   │   ├── MetadataSection (DS.KeyValueRow)
│   │   ├── ControlsSection (DS form controls)
│   │   └── FooterSection (DS.Card)
│   └── Toolbar (DS spacing tokens)
```

### Key Files to Modify

**Components (New/Modified):**
- `Sources/ISOInspectorApp/UI/Layouts/LayoutPatterns.swift` — NEW
  - `SidebarLayoutContainer` — DS pattern wrapper
  - `DetailPanelLayout` — DS card-based layout
  - `ResponsiveGrid` — DS grid system wrapper

**Views (Refactoring):**
- `Sources/ISOInspectorApp/Views/ContentView.swift` — MAJOR REFACTOR
  - Migrate to DS spacing tokens
  - Adopt DS.SidebarPattern
  - Add platform adaptation context

- `Sources/ISOInspectorApp/Views/Sidebar/BoxesSidebar.swift` — REFACTOR
  - Use FoundationUI grid
  - Apply DS.Spacing throughout
  - Add responsive breakpoints

- `Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift` — REFACTOR
  - Replace manual padding with DS.Spacing tokens
  - Use DS.Card for sections
  - Ensure dark mode adaptation

**Tests (New):**
- `Tests/ISOInspectorAppTests/FoundationUI/LayoutPatternTests.swift`
  - Unit tests for layout components
  - Container behavior tests
  - Spacing token verification

- `Tests/ISOInspectorAppTests/FoundationUI/LayoutSnapshotTests.swift`
  - Snapshot tests for all device sizes
  - Light/dark mode variants
  - Orientation variants (iPad)

- `Tests/ISOInspectorAppTests/FoundationUI/ResponsiveLayoutTests.swift`
  - Size class adaptation tests
  - Breakpoint behavior validation
  - Platform-specific layout tests

- `Tests/ISOInspectorAppTests/FoundationUI/LayoutAccessibilityTests.swift`
  - VoiceOver flow tests
  - Keyboard navigation tests
  - Dynamic Type compatibility
  - Contrast verification

**Documentation (Update):**
- `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`
- `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`
- `DOCS/MIGRATION.md`

### Implementation Approach

1. **Phase 1a: Sidebar Refactoring** (0.5 days)
   - Apply DS spacing tokens to all sidebar sections
   - Integrate with DS.SidebarPattern placeholder
   - Add responsive breakpoints for iPhone/iPad

2. **Phase 1b: Detail Panel Refactoring** (0.5 days)
   - Replace manual padding with DS.Spacing
   - Convert sections to DS.Card
   - Ensure all content uses DS tokens

3. **Phase 2: Testing Suite** (0.75 days)
   - Create unit tests for layout components
   - Add snapshot tests for all device sizes
   - Implement accessibility tests

4. **Phase 3: Accessibility & Refinement** (0.25 days)
   - Verify VoiceOver navigation
   - Test keyboard-only usage
   - Dynamic Type and contrast validation

### Dependencies & Blockers

**Satisfied Dependencies:**
- ✅ Phase 0 (Setup & Verification) — Complete
- ✅ Phase 1 Tasks 1-4 (Badge, Cards, KV Rows, Form Controls) — Complete
- ✅ FoundationUI package integration — In place
- ✅ Integration test infrastructure — Established

**No Known Blockers:** All required tools, dependencies, and infrastructure are in place.

### Acceptance Criteria Checklist

- [ ] All manual padding/margins replaced with `DS.Spacing` tokens
- [ ] Sidebar layout uses `DS.SidebarPattern` or compatible patterns
- [ ] Detail panels use `DS.Card` for visual hierarchy
- [ ] Responsive layout tested on iPhone SE, iPhone 15 Pro Max, iPad, macOS
- [ ] Dark mode adaptation validated across all layouts
- [ ] Unit test coverage ≥80%
- [ ] Snapshot tests pass for all device/platform variants
- [ ] Accessibility tests pass (VoiceOver, keyboard, Dynamic Type)
- [ ] Zero SwiftLint violations
- [ ] Documentation updated in technical spec and design guide
- [ ] `DOCS/MIGRATION.md` includes layout refactoring notes
- [ ] All tests green on CI

---

## 🧠 Source References

### Core Documentation
- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — Complete integration roadmap
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md) — Product vision and requirements
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Task execution plan
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md) — Detailed backlog

### Phase 1 Completed Tasks
- [`DOCS/TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/Summary_of_Work.md`](../TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/Summary_of_Work.md)
- [`DOCS/TASK_ARCHIVE/218_I1_2_Card_Containers_Sections/Summary_of_Work.md`](../TASK_ARCHIVE/218_I1_2_Card_Containers_Sections/Summary_of_Work.md)
- [`DOCS/TASK_ARCHIVE/219_I1_3_Key_Value_Rows/Summary_of_Work.md`](../TASK_ARCHIVE/219_I1_3_Key_Value_Rows/Summary_of_Work.md)
- [`DOCS/TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md`](../TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md)

### Design System & Technical Guidance
- [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) — Task selection framework
- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md) — Development workflow
- FoundationUI Design System documentation (DS.Spacing, DS.Card, DS.SidebarPattern, etc.)

### Related Blocked Work
- See [`DOCS/INPROGRESS/blocked.md`](blocked.md) for recoverable blockers (manual testing, hardware availability)
- See [`DOCS/TASK_ARCHIVE/BLOCKED/`](../TASK_ARCHIVE/BLOCKED) for permanently blocked efforts

---

## 📋 Next Steps (When Task Starts)

1. **Environment Setup**
   - Verify FoundationUI package is properly imported
   - Confirm design system tokens are accessible (DS.Spacing, DS.Card, etc.)
   - Review existing layout component patterns from I1.1-I1.4

2. **Code Audit**
   - Grep for hardcoded padding values to identify migration targets
   - Document current sidebar/detail panel structure
   - Identify responsive breakpoints needed for different devices

3. **Implementation Kickoff**
   - Create layout pattern components (SidebarLayoutContainer, DetailPanelLayout)
   - Begin sidebar refactoring
   - Set up test structure for layouts

4. **Validation & Review**
   - Run snapshot tests on all platforms
   - Verify accessibility compliance
   - Ensure zero SwiftLint violations
   - Conduct code review with team

---

**End of Task Document for I1.5**
