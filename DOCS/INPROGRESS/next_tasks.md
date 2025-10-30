# Next Tasks

- ✅ **T3.7.1 — Integrity Tab Sorting Refinements** _(Complete)_:
  - Multi-field offset and affected-node sort implementations now ship in `IntegritySummaryViewModel`, giving deterministic order for CLI/UI parity and closing puzzles #T36-001/#T36-002.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L56-L115】

- ✅ **T3.7 — Integrity Navigation Filters** _(Complete)_:
  - Explorer outline now expands ancestors, selects affected nodes, and returns focus when Integrity issues are chosen.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L99-L196】
  - Added an "Issues only" toggle plus Cmd+Shift+E / Cmd+Shift+Option+E shortcuts backed by new issue navigation helpers.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L10-L246】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L217-L366】
