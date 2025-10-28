# Next Tasks

- 🚧 **T3.7.1 — Integrity Tab Sorting Refinements** _(Active — see `DOCS/INPROGRESS/197_T3_7_1_Integrity_Sorting_Refinements.md`)_:
  - Resolve TODO markers `#T36-001` (offset-based sorting) and `#T36-002` (affected node sorting) with deterministic multi-field sort implementations.
  - Implement unit tests covering edge cases (multiple issues at same offset, missing byte ranges, etc.).
  - Ensure CLI/export parity with Integrity tab ordering.
  - Once complete, proceed to #T36-003 navigation polish and then tree view filter toggle + keyboard shortcuts.

- 📋 **T3.7 — Integrity Navigation Filters** _(Planning — see `DOCS/INPROGRESS/T3_7_Integrity_Navigation_Filters.md`)_:
  - Overall roadmap for completing Phase T3 UI corruption views (final 14% of milestone).
  - Remaining after T3.7.1: #T36-003 navigation polish, tree filter toggle, keyboard shortcuts (Cmd+Shift+E).

- 🚧 **#4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews** _(Active — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md`)_:
  - Ensure preview scenarios invoke `ResearchLogMonitor.audit` for VR-006 fixtures and surface schema/missing-data diagnostics during design-time validation.
  - Thread `ResearchLogPreviewProvider` snapshots through preview compositions so diagnostics appear alongside sample payloads.
  - Back previews with canonical VR-006 fixtures plus mismatch/missing variants for regression visibility, and document the refresh workflow when schemas change.
