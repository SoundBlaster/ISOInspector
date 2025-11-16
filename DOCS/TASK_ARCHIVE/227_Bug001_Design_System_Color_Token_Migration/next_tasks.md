# Next Tasks

## Recently Completed

### ✅ A9 — Automate Strict Concurrency Checks (Completed 2025-11-15)

**Task:** A9 — Automate Strict Concurrency Checks
**Status:** ✅ **COMPLETED** (including post-A9 Swift 6 migration cleanup)
**Duration:** 1 day | **Priority:** P0 | **Dependencies:** A2 ✅ complete

**Description:** Established automated strict concurrency checking via Swift's `.enableUpcomingFeature("StrictConcurrency")` across all build and test phases, enforcing thread-safe concurrent design patterns through both pre-push hooks and GitHub Actions CI. Followed up with Swift 6 migration cleanup to remove redundant flags and align CI environments.

**See full summary in:** `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/Summary_of_Work.md`

**Archived location:** `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/`

---

## Backlog Status

- ✅ **FoundationUI Phase 1 Complete (5/5 tasks):** All completed 2025-11-14
  - Archived locations: `DOCS/TASK_ARCHIVE/218_*` through `DOCS/TASK_ARCHIVE/221_*`

- ✅ **User Settings Panel Phase 1 (C21):** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/222_C21_Floating_Settings_Panel/`

- ✅ **User Settings Panel Phase 2 (C22):** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/`

- ✅ **A9 — Automate Strict Concurrency Checks:** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/`

- ✅ **T6.3 — SDK Tolerant Parsing Documentation:** Completed 2025-11-12
  - Archived location: `DOCS/TASK_ARCHIVE/211_T6_3_SDK_Tolerant_Parsing_Documentation/`

---

## Currently Selected Task (In Progress)

### ✋ A6 — Enforce SwiftFormat Formatting (Selected 2025-11-15)
- **Priority:** Medium
- **Effort:** 0.5 days
- **Dependencies:** A2 ✅ complete
- **Description:** Add SwiftFormat enforcement to pre-push hook and CI workflow to maintain consistent code style across the project.
- **INPROGRESS Document:** `DOCS/INPROGRESS/226_A6_Enforce_SwiftFormat_Formatting.md`

---

## Candidate Tasks (For Next Selection)

### Automation Track (High Priority)

#### **A7 — Reinstate SwiftLint Complexity Thresholds**
- **Priority:** Medium
- **Effort:** 0.75 days
- **Dependencies:** A2 ✅ complete
- **Description:** Restore and enforce SwiftLint complexity thresholds (cyclomatic, function length, type length) to prevent code quality regressions.

#### **A8 — Gate Test Coverage Using `coverage_analysis.py`**
- **Priority:** Medium
- **Effort:** 1 day
- **Dependencies:** A2 ✅ complete
- **Description:** Integrate test coverage analysis into CI using existing `coverage_analysis.py` script to enforce minimum coverage thresholds.

#### **A10 — Add Swift Duplication Detection to CI**
- **Priority:** Medium
- **Effort:** 1 day
- **Dependencies:** A2 ✅ complete
- **Description:** Implement `.github/workflows/swift-duplication.yml` using `jscpd` to block copy/paste regressions.
- **Reference:** `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md`

---

### Feature Development Track

#### **FoundationUI Phase 2 — Interactive Components (I2.1–I2.3)**
- **Priority:** Medium
- **Effort:** 4-7 days
- **Dependencies:** FoundationUI Phase 1 ✅ complete
- **Description:** Implement interactive SwiftUI components including buttons, sliders, toggles, and other user input controls.

---

### Store Migration Track (Long-term)

#### **Phase 2 — Migrate ParseIssueStore to Swift Concurrency**
- **Priority:** Low (infrastructure complete via A9)
- **Effort:** 2-3 days
- **Dependencies:** A9 ✅ complete
- **Description:** Migrate `ParseIssueStore` from GCD queues to `@MainActor` or custom `actor` isolation.
- **Reference:** `DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`

#### **Phase 3 — Remove @unchecked Sendable**
- **Priority:** Low
- **Dependencies:** Phase 2
- **Description:** Remove `@unchecked Sendable` conformance once actor isolation is complete.

#### **Phase 4 — Migrate Other Stores**
- **Priority:** Low
- **Dependencies:** Phase 3
- **Description:** Migrate other stores following the ParseIssueStore pattern.

---

## Execution Context

**Reference materials:**
- [Execution workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules](../RULES/03_Next_Task_Selection.md)
- [Root TODO list](../../todo.md)
- [Backlog detail](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [Blocked tasks log](./blocked.md)
- [Archive index](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)
