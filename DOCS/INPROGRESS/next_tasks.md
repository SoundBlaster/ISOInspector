# Next Tasks

## Active

### FoundationUI Integration (Priority Feature)

**See detailed plan in:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

#### Phase 1: Foundation Components (Weeks 2-3) ✅ **COMPLETED**
**Duration:** 5-7 days | **Priority:** P1 | **Dependencies:** Phase 0 ✅ complete
**Started:** 2025-11-14 | **Completed:** 2025-11-14

**All Phase 1 Tasks Completed:**
- [x] **I1.1 — Badge & Status Indicators** ✅ **COMPLETED** (2025-11-14)
- [x] **I1.2 — Card Containers & Sections** ✅ **COMPLETED** (2025-11-14)
- [x] **I1.3 — Key-Value Rows & Metadata Display** ✅ **COMPLETED** (2025-11-14)
- [x] **I1.4 — Form Controls & Input Wrappers** ✅ **IMPLEMENTATION COMPLETE** (2025-11-14)
  - Implementation complete, pending:
    - FoundationUI component integration (replace native SwiftUI with DS components)
    - Snapshot testing library integration
    - Form migration in settings/dialogs
  - **Details:** `DOCS/TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md`
- [x] **I1.5 — Advanced Layouts & Navigation** ✅ **COMPLETED** (2025-11-14)
  - Implemented layout patterns using FoundationUI grid and spacing system
  - Migrated sidebar and detail view layouts
  - Validated responsive behavior across device sizes
  - Accessibility and dark mode support
  - **Details:** `DOCS/TASK_ARCHIVE/221_I1_5_Advanced_Layouts_Navigation/Summary_of_Work.md`

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

- [ ] **C21 — Floating Settings Panel Shell** (Priority: Medium, Effort: 1 day) 🔄 **IN PROGRESS**
  - Implement `SettingsPanelScene` with FoundationUI cards separating permanent vs. session groups
  - macOS: host inside an `NSPanel` window controller with remembered frame + keyboard shortcut (`⌘,`)
  - iPad/iOS: present via `.sheet` detents; ensure VoiceOver focus starts at the selected section
  - Snapshot + accessibility tests validate both presentations
  - **Details:** `DOCS/INPROGRESS/222_C21_Floating_Settings_Panel.md`

- [ ] **C22 — Persistence + Reset Wiring** (Priority: Medium, Effort: 1 day)
  - Thread permanent changes through `UserPreferencesStore`
  - Update `DocumentSessionController` with `SessionSettingsPayload` mutations
  - Add reset actions ("Reset Global", "Reset Session")
  - Logging and DocC documentation of layered persistence behavior
  - **Dependency:** C21 must be completed first

---

## Notes

- ✅ **FoundationUI Phase 1 Complete:** All 5 tasks (I1.1–I1.5) completed 2025-11-14
  - Archived locations: `DOCS/TASK_ARCHIVE/218_*` through `DOCS/TASK_ARCHIVE/221_*`
- 🔄 **Next Phase:** User Settings Panel (C21–C22) kicks off after Phase 1
  - C21 selected as next task per prioritization rules (Phase C, Medium priority, unblocked)
  - C22 depends on C21 completion
  - Both tasks parallel to SDK Documentation (T6.3) if resources allow
- 🎯 **Next Candidate Tasks:** T6.3 (SDK Documentation), or Phase 2 FoundationUI (if prioritized higher)
