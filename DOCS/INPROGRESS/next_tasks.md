# Next Tasks

## Active (Following C21 Completion)

### User Settings Panel: Phase 2 — Persistence + Reset Wiring (Priority Feature)

**Task:** C22 — Persistence + Reset Wiring
**Status:** 🎬 **IN PROGRESS** (Selected 2025-11-15, Task document: `223_C22_User_Settings_Persistence_and_Reset.md`)
**Duration:** 1 day | **Priority:** P1 | **Dependencies:** C21 ✅ complete

**Description:** Complete the settings panel by threading persistence through `UserPreferencesStore` and `DocumentSessionController`, implementing reset actions, keyboard shortcut support, and finalizing platform-specific presentation (NSPanel on macOS, sheet on iPad/iOS).

**See detailed plan in:** `DOCS/TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md` (Section "Next Steps (C22)")

**Subtasks (Puzzles #222.1–#222.7):**
- [ ] **#222.1 — UserPreferencesStore Integration** (Puzzle)
  - Thread permanent settings changes through `UserPreferencesStore`
  - Update ViewModel to load/save global preferences on app startup
- [ ] **#222.2 — SessionSettingsPayload Mutations** (Puzzle)
  - Update `DocumentSessionController` to bind session settings changes
  - Implement dirty tracking for session scope
- [ ] **#222.3 — Reset Actions** (Puzzle)
  - Implement "Reset Global" button → restore defaults in UserPreferencesStore
  - Implement "Reset Session" button → restore current document's session defaults
  - Add confirmation dialogs
- [ ] **#222.4 — Keyboard Shortcut (⌘,)** (Puzzle)
  - Bind keyboard shortcut to toggle settings panel visibility
  - Ensure shortcut works across app lifecycle
- [ ] **#222.5 — Platform-Specific Presentation** (Puzzle)
  - macOS: Host in NSPanel window controller with remembered frame
  - iPad: Present via `.sheet` with detents
  - iPhone: Full screen cover or modal presentation
- [ ] **#222.6 — Snapshot Tests** (Puzzle)
  - Test all platforms (iOS, macOS, iPadOS)
  - Test all color schemes (light, dark, auto)
  - Validate responsive behavior
- [ ] **#222.7 — Advanced Accessibility Tests** (Puzzle)
  - Dynamic Type scaling across all sizes (XS–XXXL)
  - Reduce Motion compliance
  - Advanced VoiceOver focus order tests

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

- 🔄 **Current:** User Settings Panel Phase 1 (C21) — archived 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/222_C21_Floating_Settings_Panel/`

- 🎯 **Next Priority:** C22 (Persistence + Reset Wiring) now unblocked after C21
  - Estimated start: 2025-11-15 (same day as C21 archive)
  - Estimated completion: 2025-11-16

- 📅 **Candidate Tasks (If Resources Allow):**
  - **T6.3 — SDK Documentation** (unblocked, can run in parallel with C22)
  - **FoundationUI Phase 2 — Interactive Components (I2.1–I2.3)** (scheduled after C22 if prioritized)
  - **A10 — Swift Duplication Workflow Gate** (new CI quality gate)
    - Implements `.github/workflows/swift-duplication.yml` using `jscpd` to block copy/paste regressions.
    - Scope + acceptance criteria captured in `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md`; puzzles tracked in that folder's `TODO.md`.

---

## Execution Context

**Reference materials:**
- [Execution workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules](../RULES/03_Next_Task_Selection.md)
- [C22 PRD](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md)
- [C21 Summary of Work](../TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md)
- [Blocked tasks log](./blocked.md)
- [Archive index](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)
