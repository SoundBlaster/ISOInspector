# Next Tasks

- ✅ **T3.7.1 — Integrity Tab Sorting Refinements** _(Complete)_:
  - Multi-field offset and affected-node sort implementations are live in `IntegritySummaryViewModel`, giving deterministic order for CLI/UI parity and closing puzzles #T36-001/#T36-002.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L56-L115】

- 🚧 **T3.7 — Integrity Navigation Filters** _(Active — see `DOCS/INPROGRESS/200_T3_7_Integrity_Navigation_Filters.md`)_:
  - Finish #T36-003 so selecting an Integrity issue expands and focuses the matching node in the Explorer outline before switching tabs.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L99-L121】
  - Add an "issues only" outline filter and keyboard shortcuts to jump between issue-bearing nodes per the tolerant parsing backlog.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L5-L52】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L109-L194】

- ✅ **#4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews** _(Complete — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md` for current notes)_:
  - ResearchLog preview scenarios invoke the audit helper and surface ready/missing/schema mismatch diagnostics from `ResearchLogPreviewProvider` fixtures.
