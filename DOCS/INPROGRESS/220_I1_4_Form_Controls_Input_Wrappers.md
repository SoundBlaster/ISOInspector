# I1.4 — Form Controls & Input Wrappers

**Status:** In Progress
**Priority:** P1 (High)
**Effort:** 2 days
**Started:** 2025-11-14
**Phase:** FoundationUI Integration — Phase 1 (Foundation Components)

---

## 🎯 Objective

Wrap FoundationUI form components (`DS.TextInput`, `DS.Toggle`, `DS.Picker`) and migrate existing input patterns in settings and configuration dialogs to use these standardized controls. This task completes Phase 1 foundation components, bringing the FoundationUI integration to 80% of Phase 1 (4/5 tasks).

---

## 🧩 Context

### Prior Completion
- ✅ **I1.1** — Badge & Status Indicators (2025-11-14)
- ✅ **I1.2** — Card Containers & Sections (2025-11-14)
- ✅ **I1.3** — Key-Value Rows & Metadata Display (2025-11-14)
  _Archived in: `DOCS/TASK_ARCHIVE/219_I1_3_Key_Value_Rows_Metadata_Display/`_

### Current Phase Progress
- Phase 1 completion: **4/5 tasks** (80%)
- Remaining: I1.5 (Advanced Layouts & Navigation) — will follow after I1.4

### Dependencies
- Phase 0 (Setup & Verification) — ✅ **COMPLETE**
- FoundationUI Swift Package — ✅ Available in ISOInspectorApp
- Integration test infrastructure — ✅ In place
- Component Showcase — ✅ Available for development/testing

### Strategic Context
This task is part of the 9-week FoundationUI integration roadmap outlined in:
- `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

---

## ✅ Success Criteria

### Code Implementation
- [ ] **BoxTextInputView** wrapper component created
  - Wraps `DS.TextInput` with ISO-specific styling
  - Supports placeholder, validation, and keyboard types
  - File: `Sources/ISOInspectorApp/UI/Components/BoxTextInputView.swift` (NEW)

- [ ] **BoxToggleView** wrapper component created
  - Wraps `DS.Toggle` component
  - Supports labels, disabled state, and accessibility labels
  - File: `Sources/ISOInspectorApp/UI/Components/BoxToggleView.swift` (NEW)

- [ ] **BoxPickerView** wrapper component created
  - Wraps `DS.Picker` with custom selection logic
  - Supports binding to Codable enums
  - File: `Sources/ISOInspectorApp/UI/Components/BoxPickerView.swift` (NEW)

### Migration & Integration
- [ ] Audit existing form inputs across codebase
  - Settings panel: User preferences (parsing mode, display options, etc.)
  - Configuration dialogs: Filter settings, export options
  - Search/filter controls
  - File: Document findings in implementation notes

- [ ] Migrate at least 3 critical form locations to use new wrappers
  - Priority: Settings panel inputs (highest user visibility)
  - Secondary: Configuration dialogs
  - Document migration path in `DOCS/MIGRATION.md`

### Testing (≥90% coverage)
- [ ] Unit tests for all 3 wrapper components
  - File: `Tests/ISOInspectorAppTests/FoundationUI/FormControlsTests.swift` (NEW)
  - Tests: Input validation, state binding, accessibility attributes

- [ ] Snapshot tests (light/dark modes)
  - File: `Tests/ISOInspectorAppTests/FoundationUI/FormControlsSnapshotTests.swift` (NEW)
  - Variants: Empty, filled, error state, disabled state (all 3 components)
  - Platforms: macOS, iOS, iPadOS

- [ ] Accessibility tests
  - File: `Tests/ISOInspectorAppTests/FoundationUI/FormControlsAccessibilityTests.swift` (NEW)
  - Verify: VoiceOver labels, focus management, keyboard interaction
  - Target: ≥98% accessibility audit score

### Documentation
- [ ] Update Component Showcase with form control examples
- [ ] Add DocC documentation for wrapper components
- [ ] Update `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`
  - Add Form Controls subsection to FoundationUI Integration Patterns
  - Document wrapper API surface
  - Provide usage examples

- [ ] Update `DOCS/MIGRATION.md` with old→new form control mapping

### Code Quality
- [ ] SwiftLint: 0 violations (strict mode)
- [ ] Type safety: No force unwraps or implicitly unwrapped optionals
- [ ] Concurrency: All components marked `@MainActor` where appropriate
- [ ] Code review approved

---

## 🔧 Implementation Notes

### Component Design Decisions

#### BoxTextInputView
```swift
// Desired public API
struct BoxTextInputView: View {
    @Binding var text: String
    let placeholder: String
    let validationError: String?
    let keyboardType: UIKeyboardType
    let onEditingChanged: (Bool) -> Void
}
```
- Expose `DS.TextInput` public API (padding, corners, shadows)
- Support custom error messages (red border + error text)
- Accessibility: Ensure label linkage to input field

#### BoxToggleView
```swift
// Desired public API
struct BoxToggleView: View {
    @Binding var isOn: Bool
    let label: String
    let disabled: Bool
}
```
- Wrap `DS.Toggle` with label positioning options
- Support accessibility label (separate from visual label if needed)

#### BoxPickerView
```swift
// Desired public API
struct BoxPickerView<T: Hashable>: View {
    @Binding var selection: T
    let label: String
    let options: [(label: String, value: T)]
}
```
- Generic over selection type (enums, strings, integers)
- Provide platform-specific picker (Picker on iOS, Segmented on macOS for simple cases)
- Accessibility: Ensure all options are screen-reader accessible

### Form Control Audit

**Settings Panel Inputs to Migrate:**
- Parsing mode toggle: `ParsePipeline.Options` → P1 use ToggleView
- Display density toggle: Compact/Standard → P2 use ToggleView
- Export format picker: JSON/YAML/CSV → P1 use PickerView
- Search text input: Current search box → P2 use TextInputView

**Configuration Dialogs:**
- File filter text field
- Export destination selector
- Parse issue display threshold

### Testing Strategy

1. **Unit Tests** — Interaction with underlying FoundationUI components
   - TextInput: validate input text, placeholder display, error state
   - Toggle: state binding, disabled state
   - Picker: selection binding, option enumeration

2. **Snapshot Tests** — Visual consistency across modes
   - Base case: Empty/default state
   - Filled: Text/selection populated
   - Error: Validation failure (TextInput only)
   - Disabled: All 3 components in disabled state
   - Light/Dark modes for each variant

3. **Accessibility Tests** — VoiceOver, Focus Management, Keyboard
   - Verify VoiceOver labels read correctly
   - Confirm focus order logical
   - Keyboard Tab navigation works
   - Error messages announced to screen readers

### Migration Path

**Phase A (Immediate):**
- Implement wrapper components (1 day)
- Add unit + snapshot tests (0.5 day)
- Add accessibility tests (0.5 day)

**Phase B (Same task):**
- Audit existing form locations in codebase
- Migrate critical inputs (Settings, Export dialogs)
- Update documentation

### Potential Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Form state binding issues | Medium | Comprehensive unit tests for binding behavior |
| Accessibility violations | Medium | 50+ a11y tests + external audit before Phase 1 completion |
| Performance (picker rendering) | Low | Lazy rendering for large option lists if needed |
| Keyboard navigation conflicts | Low | Test Tab/Return/Escape in all contexts |

---

## 🧠 Source References

- **FoundationUI Integration Strategy:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`
  - Phase 1 section (lines 52–169)
  - Form Controls subtask (implied in Phase 1.4)

- **ISOInspector Master PRD:** `DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`
  - Settings & User Preferences subsection
  - Export functionality subsection

- **Execution Workplan:** `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`
  - FoundationUI Integration Phase 1

- **Current Next Tasks:** `DOCS/INPROGRESS/next_tasks.md`
  - Phase 1 progress tracking

- **Technical Specification:** `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`
  - FoundationUI Integration Patterns section

- **Design System Guide:** `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`

- **Prior Completion Archive:** `DOCS/TASK_ARCHIVE/219_I1_3_Key_Value_Rows_Metadata_Display/`
  - Context on Phase 1 progress to date

---

## 📋 Immediate Next Steps

1. **Code Audit** — Locate all existing form inputs in ISOInspectorApp
   - Search for `TextField`, `Toggle`, `Picker` patterns
   - Catalog in implementation notes

2. **Implement Wrappers** — Build 3 wrapper components with stubs
   - Start with BoxTextInputView (most common)
   - Follow with BoxToggleView
   - Finish with BoxPickerView

3. **Write Tests** — Add comprehensive test coverage
   - Unit tests first (interaction behavior)
   - Snapshot tests (visual consistency)
   - Accessibility tests (a11y compliance)

4. **Migrate Critical Forms** — Replace instances in Settings panel
   - Begin with export format picker (PickerView)
   - Continue with parsing mode toggle (ToggleView)
   - Document migration path for future work

5. **Documentation** — Update spec and migration guide
   - Publish wrapper APIs in Technical Spec
   - Record migration mapping in MIGRATION.md
   - Add examples to Component Showcase

---

**Document Created:** 2025-11-14
**Phase:** FoundationUI Integration Phase 1 (Foundation Components)
**Progress Tracking:** See `DOCS/INPROGRESS/next_tasks.md`
