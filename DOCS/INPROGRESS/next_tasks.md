# Next Tasks

## Recently Completed

### ✅ A6 — Enforce SwiftFormat Formatting (Completed 2025-11-15)

**Task:** A6 — Enforce SwiftFormat Formatting
**Status:** ✅ **COMPLETED**
**Duration:** 0.5 days | **Priority:** Medium | **Dependencies:** A2 ✅ complete

**Description:** Added SwiftFormat enforcement to pre-push hook and CI workflow to maintain consistent code style across the project.

**See full summary in:** `DOCS/TASK_ARCHIVE/226_A6_Enforce_SwiftFormat_Formatting/Summary_of_Work.md`

**Archived location:** `DOCS/TASK_ARCHIVE/226_A6_Enforce_SwiftFormat_Formatting/`

---

### 📋 BUG #001 — Design System Color Token Migration (Archived 2025-11-16)

**Issue:** ISOInspectorApp continues to use hardcoded `.accentColor` and manual opacity values instead of FoundationUI design tokens.

**Status:** Archived as in-progress work; documented in `DOCS/TASK_ARCHIVE/227_Bug001_Design_System_Color_Token_Migration/`

**Key documents:**
- `001_Design_System_Color_Token_Migration.md` — Detailed bug report with 8 steps
- `BUG_Manual_Color_Usage_vs_FoundationUI.md` — Summary with recommended resolution phases
- `Summary_Color_Theme_Resolution.md` — Recent fix to color resolution tests

**Blocked by:** FoundationUI token documentation and Phase 5.2 completion criteria

**Next step:** Audit FoundationUI design tokens, map opacity values to semantic tokens, and update views to use `DS.*` tokens exclusively.

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

- ✅ **A6 — Enforce SwiftFormat Formatting:** Completed 2025-11-15
  - Archived location: `DOCS/TASK_ARCHIVE/226_A6_Enforce_SwiftFormat_Formatting/`

---

## Currently In Progress

### 🔄 A7 — Reinstate SwiftLint Complexity Thresholds
- **Status:** 🔄 IN PROGRESS (2025-11-16)
- **Priority:** Medium
- **Effort:** 0.75 days
- **Dependencies:** A2 ✅ complete
- **Document:** `DOCS/INPROGRESS/228_A7_Reinstate_SwiftLint_Complexity_Thresholds.md`

---

## Candidate Tasks (For Next Selection)

### Automation Track (High Priority)

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

#### **BUG #001 — Design System Color Token Migration**
- **Priority:** Medium
- **Effort:** 2-3 days
- **Dependencies:** FoundationUI Phase 5.2 completion, token documentation availability
- **Description:** Migrate manual `.accentColor` usages to FoundationUI design tokens (`DS.Color.*`)
- **Reference:** `DOCS/TASK_ARCHIVE/227_Bug001_Design_System_Color_Token_Migration/`

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
