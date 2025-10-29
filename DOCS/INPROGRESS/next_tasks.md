# Next Tasks

- 🚧 **T3.7.1 — Integrity Tab Sorting Refinements** _(Active — see `DOCS/INPROGRESS/197_T3_7_1_Integrity_Sorting_Refinements.md`)_:
  - Resolve TODO markers `#T36-001` (offset-based sorting) and `#T36-002` (affected node sorting) with deterministic multi-field sort implementations.
  - Implement unit tests covering edge cases (multiple issues at same offset, missing byte ranges, etc.).
  - Ensure CLI/export parity with Integrity tab ordering.
  - Once complete, proceed to #T36-003 navigation polish and then tree view filter toggle + keyboard shortcuts.

- 📋 **T3.7 — Integrity Navigation Filters** _(Planning — see `DOCS/INPROGRESS/T3_7_Integrity_Navigation_Filters.md`)_:
  - Overall roadmap for completing Phase T3 UI corruption views (final 14% of milestone).
  - Remaining after T3.7.1: #T36-003 navigation polish, tree filter toggle, keyboard shortcuts (Cmd+Shift+E).

- ✅ **#4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews** _(Completed — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md` for summary)_:
  - ResearchLog preview scenarios now invoke the audit helper and surface ready/missing/schema mismatch diagnostics from `ResearchLogPreviewProvider` fixtures.
