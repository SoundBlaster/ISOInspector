# I1.3 — Key-Value Rows & Metadata Display

## 🎯 Objective

Migrate metadata display patterns across the ISOInspector UI to use the FoundationUI `DS.KeyValueRow` component, creating a consistent, accessible, and testable wrapper (`BoxMetadataRow`) that integrates copyable actions for field values.

## 🧩 Context

This task is part of **Phase 1: Foundation Components** of the FoundationUI integration roadmap:
- **Phase 0** (Setup & Verification): ✅ Complete (2025-11-14)
  - FoundationUI dependency integrated
  - 123 comprehensive integration tests established
  - Integration patterns documented
  - Design System Guide updated

- **Phase 1 Completed Tasks:**
  - ✅ **I1.1** — Badge & Status Indicators (Archived: `DOCS/TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/`)
  - ✅ **I1.2** — Card Containers & Sections (Archived: `DOCS/TASK_ARCHIVE/217_I1_2_Card_Containers_Sections/`)

**Key Dependencies:**
- All Phase 0 tasks complete ✅
- I1.1 and I1.2 complete ✅
- Existing metadata display patterns in `ComponentTestApp` and ISOInspectorUI
- Design System integration patterns documented in `03_Technical_Spec.md`

**Reference Materials:**
- FoundationUI Integration Strategy: `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`
- Integration test patterns: `Tests/ISOInspectorUITests/FoundationUI/` (123 tests)
- Component showcase: `ComponentTestApp/Screens/`
- Technical specifications: `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/03_Technical_Spec.md`

## ✅ Success Criteria

### Core Implementation
- [ ] Audit all current metadata display patterns (row heights, spacing, font sizes, colors)
- [ ] Create `BoxMetadataRow` wrapper component around `DS.KeyValueRow`
  - Support label, value, and optional copyable action
  - Inherit dark mode adaptation from FoundationUI
  - Match accessibility pattern from I1.1 and I1.2
- [ ] Refactor all metadata field displays to use `BoxMetadataRow`
  - ISO box metadata (offsets, sizes, types)
  - Parse results and issue summaries
  - Codec and track information
  - File header details

### Testing & Quality
- [ ] Unit tests for `BoxMetadataRow` component (≥90% coverage)
- [ ] Snapshot tests validating layout, colors, dark mode adaptation
- [ ] Accessibility tests confirming WCAG 2.1 AA compliance (≥98% score)
- [ ] Integration tests with copyable action behavior
- [ ] Regression tests ensuring existing metadata displays still function correctly

### Integration & Documentation
- [ ] Add `BoxMetadataRow` to ComponentTestApp showcase screen
- [ ] Update Design System Guide with migration patterns
- [ ] Verify zero SwiftLint violations
- [ ] Test coverage remains ≥80% across affected targets

## 🔧 Implementation Notes

### Sub-Steps
1. **Audit Current Patterns** — Inventory all metadata display sites:
   - Search for `Text`, `Label`, and manual row layouts in metadata-related views
   - Document current spacing (padding, margins), fonts, colors, and accessibility attributes
   - Identify copyable candidates and current copy-to-clipboard implementations

2. **Component Design** — Build `BoxMetadataRow`:
   - Wrap `DS.KeyValueRow` for consistent styling
   - Expose label, value, and optional `CopyableAction` configuration
   - Support conditional display of copy button
   - Inherit dark mode and accessibility from FoundationUI components

3. **Migration** — Refactor metadata displays:
   - Start with high-value screens (Box Details, Parse Results)
   - Batch similar display patterns (offsets, sizes, type labels)
   - Test each screen for visual regressions and functional correctness

4. **Copyable Integration** — Wire copy-to-clipboard actions:
   - Reuse or adapt existing `CopyableAction` pattern from prior UI work
   - Provide visual/haptic feedback on successful copy
   - Test on iOS, iPadOS, and macOS

5. **Testing** — Comprehensive validation:
   - Unit tests for component behavior and state
   - Snapshot tests comparing layouts to approved baselines
   - Accessibility tests using `AccessibilityTestingScreen` patterns
   - Integration tests simulating user interactions (copy, expand, etc.)

### Key Technical Considerations
- **Dark Mode Adaptation:** FoundationUI components automatically handle dark mode; verify `BoxMetadataRow` inherits this behavior via environment modifiers.
- **Copyable Action Pattern:** Review prior implementations in `ComponentTestApp` or archived `C19` (Validation Preset UI Settings) for copy-to-clipboard best practices.
- **Spacing & Alignment:** Maintain visual hierarchy between label and value; respect FoundationUI padding rules.
- **Accessibility Labels:** Ensure VoiceOver users can identify both label and value; test with Dynamic Type size variations (XS–XXXL).

## 🧠 Source References
- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — Phase 1-6 roadmap
- [`03_Technical_Spec.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/03_Technical_Spec.md) — Integration patterns, test structure, and accessibility guidelines
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md) — Strategic context and user needs
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Execution workplan and phase dependencies
- Previous Phase 1 archives:
  - [`DOCS/TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/`](../TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/) — Badge migration patterns
  - [`DOCS/TASK_ARCHIVE/217_I1_2_Card_Containers_Sections/`](../TASK_ARCHIVE/217_I1_2_Card_Containers_Sections/) — Card container patterns
- [`DOCS/RULES`](../RULES) — Project rules and development practices

---

## 📋 Task Metadata

| Field | Value |
|-------|-------|
| **Task ID** | 218 |
| **Phase** | 1 (Foundation Components) |
| **Priority** | P1 (High) |
| **Estimated Effort** | 2–3 days |
| **Status** | Not Started |
| **Started** | 2025-11-14 |
| **Dependencies** | I1.1 ✅, I1.2 ✅ |
| **Blockers** | None |

