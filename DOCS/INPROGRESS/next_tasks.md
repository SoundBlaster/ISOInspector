# Next Tasks

## Recently Completed

### ✅ User Settings Panel: Phase 2 — Persistence + Reset Wiring (Completed 2025-11-15)

**Task:** C22 — Persistence + Reset Wiring
**Status:** ✅ **COMPLETED** (5/7 puzzles fully implemented, 2/7 deferred with @todo markers)
**Duration:** 1 day | **Priority:** P1 | **Dependencies:** C21 ✅ complete

**Description:** Completed the settings panel by threading persistence through `UserPreferencesStore` and `DocumentSessionController`, implementing reset actions with confirmation dialogs, and documenting keyboard shortcut + platform-specific presentation approaches.

**See full summary in:** `DOCS/TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/Summary_of_Work.md`

**Archived location:** `DOCS/TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/`

---

## Active Tasks

### 🔄 A9 — Automate Strict Concurrency Checks (In Progress 2025-11-15)

**Task:** A9 — Automate Strict Concurrency Checks
**Status:** 🔄 **IN PROGRESS** (Phase A Infrastructure)
**Priority:** P0 (High) | **Dependencies:** A2 ✅ complete
**Duration:** 1 day | **PRD Reference:** [`DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`](../AI/PRD_SwiftStrictConcurrency_Store.md)

**Description:** Establish automated strict concurrency checking via `--strict-concurrency=complete` flag across build and test phases, enforcing thread-safe concurrent design patterns through pre-push hooks and GitHub Actions CI.

**See task plan in:** `DOCS/INPROGRESS/224_A9_Automate_Strict_Concurrency_Checks.md`

**Sub-tasks:**
- Phase 1: Update `.githooks/pre-push` with strict concurrency checks (0.5 days)
- Phase 2: Extend `.github/workflows/ci.yml` with strict concurrency jobs (0.3 days)
- Phase 3: Documentation & rollout, update PRD with passing logs (0.2 days)

---

## Backlog Status

- ✅ **FoundationUI Phase 1 Complete (5/5 tasks):** All completed 2025-11-14
  - Archived locations: `DOCS/TASK_ARCHIVE/218_*` through `DOCS/TASK_ARCHIVE/221_*`

- ✅ **User Settings Panel Phase 1 (C21):** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/222_C21_Floating_Settings_Panel/`

- ✅ **User Settings Panel Phase 2 (C22):** Completed 2025-11-15
  - Summary: `DOCS/TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/Summary_of_Work.md`
  - 5/7 puzzles complete, 2/7 deferred with @todo markers
  - Core functionality (persistence, reset actions) fully implemented

- ✅ **T6.3 — SDK Tolerant Parsing Documentation:** Completed 2025-11-12
  - Archived location: `DOCS/TASK_ARCHIVE/211_T6_3_SDK_Tolerant_Parsing_Documentation/`

- 📅 **Candidate Tasks (For Next Selection):**
  - **A6 — Enforce SwiftFormat Formatting** (Priority: Medium, Effort: 0.5 days)
  - **A7 — Reinstate SwiftLint Complexity Thresholds** (Priority: Medium, Effort: 0.75 days)
  - **A8 — Gate Test Coverage Using `coverage_analysis.py`** (Priority: Medium, Effort: 1 day)
  - **A10 — Add Swift Duplication Detection to CI** (Priority: Medium, Effort: 1 day)
    - Implements `.github/workflows/swift-duplication.yml` using `jscpd` to block copy/paste regressions.
    - Scope + acceptance criteria captured in `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md`
  - **FoundationUI Phase 2 — Interactive Components (I2.1–I2.3)** (Priority: Medium, Effort: 4-7 days)

---

## Execution Context

**Current Active Task:**
- [A9 — Automate Strict Concurrency Checks](./224_A9_Automate_Strict_Concurrency_Checks.md)

**Reference materials:**
- [Execution workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules](../RULES/03_Next_Task_Selection.md)
- [A9 PRD — Swift Strict Concurrency](../AI/PRD_SwiftStrictConcurrency_Store.md)
- [C22 PRD](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md)
- [C22 Summary of Work](../TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/Summary_of_Work.md)
- [C21 Summary of Work](../TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md)
- [Blocked tasks log](./blocked.md)
- [Archive index](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)
