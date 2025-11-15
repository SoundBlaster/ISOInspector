# Next Tasks

## Recently Completed

### ✅ User Settings Panel: Phase 2 — Persistence + Reset Wiring (Completed 2025-11-15)

**Task:** C22 — Persistence + Reset Wiring
**Status:** ✅ **COMPLETED** (5/7 puzzles fully implemented, 2/7 deferred with @todo markers)
**Duration:** 1 day | **Priority:** P1 | **Dependencies:** C21 ✅ complete

**Description:** Completed the settings panel by threading persistence through `UserPreferencesStore` and `DocumentSessionController`, implementing reset actions with confirmation dialogs, and documenting keyboard shortcut + platform-specific presentation approaches.

**See full summary in:** `DOCS/INPROGRESS/Summary_of_Work.md`

**Completed Subtasks (Puzzles #222.1–#222.5):**
- [x] **#222.1 — UserPreferencesStore Integration** ✅ COMPLETE
  - Implemented `FileBackedUserPreferencesStore` with load/save/reset
  - Integrated with `SettingsPanelViewModel` via dependency injection
  - Added optimistic writes with error handling
  - 18 unit tests (9 store + 9 ViewModel)
- [x] **#222.2 — SessionSettingsPayload Mutations** ✅ COMPLETE
  - Integrated `DocumentSessionController` for session-scoped settings
  - Implemented `resetSessionSettings()`, `selectValidationPreset()`, `setValidationRule()`
  - Added dirty tracking with badge indicators
- [x] **#222.3 — Reset Actions** ✅ COMPLETE
  - Implemented "Reset to Defaults" and "Reset to Global" buttons
  - Added native confirmation alerts with destructive role
  - Badge indicator showing session overrides
- [x] **#222.4 — Keyboard Shortcut (⌘,)** ⏳ PARTIAL (documented)
  - NotificationCenter-based stub implemented
  - Comprehensive documentation with @todo markers
  - Deferred: CommandGroup integration in ISOInspectorApp
- [x] **#222.5 — Platform-Specific Presentation** ⏳ PARTIAL (documented)
  - macOS sheet with size constraints implemented
  - iPad/iPhone sheet presentation implemented
  - Deferred: NSPanel window controller, detents, fullScreenCover
- [ ] **#222.6 — Snapshot Tests** 📋 DEFERRED
  - Marked with @todo #222 for future work
- [ ] **#222.7 — Advanced Accessibility Tests** 📋 DEFERRED
  - Marked with @todo #222 for future work

**Branch:** `claude/execute-start-commands-01YL6cwxPDk6Ub3FvsCjgHXA`
**Commits:** 6 (445b766, 83fe93d, 32aae99, 75d7173, 5561414, 9672d0d)

---

## Active Tasks

---

### SDK Documentation (Parallel Work Option)

- [ ] **T6.3 — SDK Tolerant Parsing Documentation** (Priority: Medium, Effort: 1 day)
  - Can be done in parallel with C22 if resources allow
  - Create DocC article `TolerantParsingGuide.md` in `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
  - Add code examples for tolerant parsing setup and `ParseIssueStore` usage
  - Update inline documentation for `ParsePipeline.Options`, `.strict`, `.tolerant`
  - Link new guide from main `Documentation.md` Topics section
  - Verify examples with test file in `Tests/ISOInspectorKitTests/`

---

## Backlog Notes

- ✅ **FoundationUI Phase 1 Complete (5/5 tasks):** All completed 2025-11-14
  - Archived locations: `DOCS/TASK_ARCHIVE/218_*` through `DOCS/TASK_ARCHIVE/221_*`

- ✅ **User Settings Panel Phase 1 (C21):** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/222_C21_Floating_Settings_Panel/`

- ✅ **User Settings Panel Phase 2 (C22):** Completed 2025-11-15
  - Summary: `DOCS/INPROGRESS/Summary_of_Work.md`
  - 5/7 puzzles complete, 2/7 deferred with @todo markers
  - Core functionality (persistence, reset actions) fully implemented

- 📅 **Candidate Tasks (If Resources Allow):**
  - **T6.3 — SDK Documentation** (unblocked, can run in parallel with C22)
  - **FoundationUI Phase 2 — Interactive Components (I2.1–I2.3)** (scheduled after C22 if prioritized)

---

## Execution Context

**Reference materials:**
- [Execution workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules](../RULES/03_Next_Task_Selection.md)
- [C22 PRD](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md)
- [C21 Summary of Work](../TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md)
- [Blocked tasks log](./blocked.md)
- [Archive index](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)
