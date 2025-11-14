# Next Tasks

## Active

### FoundationUI Integration (Priority Feature)

**See detailed plan in:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

#### Phase 1: Foundation Components (Weeks 2-3) 🔄 **IN PROGRESS**
**Duration:** 5-7 days | **Priority:** P1 | **Dependencies:** Phase 0 ✅ complete
**Started:** 2025-11-14

**Completed Tasks:**
- [x] **I1.1 — Badge & Status Indicators** ✅ **COMPLETED** (2025-11-14)
- [x] **I1.2 — Card Containers & Sections** ✅ **COMPLETED** (2025-11-14)
- [x] **I1.3 — Key-Value Rows & Metadata Display** ✅ **COMPLETED** (2025-11-14)

**Remaining Phase 1 Tasks:**

- [ ] **I1.4 — Form Controls & Input Wrappers** (Priority: P1, Effort: 2 days)
  - Wrap FoundationUI form components (`DS.TextInput`, `DS.Toggle`, `DS.Picker`)
  - Migrate existing input patterns in settings and configuration dialogs
  - Comprehensive test suite (≥90% coverage)
  - Accessibility validation (WCAG 2.1 AA)

- [ ] **I1.5 — Advanced Layouts & Navigation** (Priority: P1, Effort: 2 days)
  - Implement layout patterns using FoundationUI grid and spacing system
  - Migrate sidebar and detail view layouts
  - Validate responsive behavior across device sizes
  - Accessibility and dark mode support

---

### SDK Documentation (High Priority)

- [ ] **T6.3 — SDK Tolerant Parsing Documentation** (Priority: Medium, Effort: 1 day)
  - Create DocC article `TolerantParsingGuide.md` in `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
  - Add code examples for tolerant parsing setup and `ParseIssueStore` usage
  - Update inline documentation for `ParsePipeline.Options`, `.strict`, `.tolerant`
  - Link new guide from main `Documentation.md` Topics section
  - Verify examples with test file in `Tests/ISOInspectorKitTests/`

---

### User Settings Panel (Floating Preferences)

**Reference:** `DOCS/AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md`

- [ ] **C21 — Floating Settings Panel Shell** (Priority: Medium, Effort: 1 day)
  - Implement `SettingsPanelScene` with FoundationUI cards separating permanent vs. session groups
  - macOS: host inside an `NSPanel` window controller with remembered frame + keyboard shortcut (`⌘,`)
  - iPad/iOS: present via `.sheet` detents; ensure VoiceOver focus starts at the selected section
  - Snapshot + accessibility tests validate both presentations

- [ ] **C22 — Persistence + Reset Wiring** (Priority: Medium, Effort: 1 day)
  - Thread permanent changes through `UserPreferencesStore`
  - Update `DocumentSessionController` with `SessionSettingsPayload` mutations
  - Add reset actions ("Reset Global", "Reset Session")
  - Logging and DocC documentation of layered persistence behavior

---

## Notes

- Phase 1 Task I1.3 archived: `DOCS/TASK_ARCHIVE/219_I1_3_Key_Value_Rows_Metadata_Display/`
- Phase 1 Progress: 3/5 tasks completed (60% complete)
- Next: I1.4, I1.5 remaining in Phase 1
- Can parallelize C21/C22 (User Settings) with Phase 1-3 FoundationUI work if needed
- Roadmap: 9 weeks total (45 working days) if executing serially
