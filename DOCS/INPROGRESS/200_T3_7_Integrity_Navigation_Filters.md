# T3.7 — Integrity Navigation Filters

## 🎯 Objective
Deliver the navigation aids and outline filtering required by Phase T3 so investigators can jump from Integrity tab issues to the affected nodes, hide healthy branches, and finish the remaining T3.7 backlog scope for tolerant parsing UI workflows.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L246-L266】

## 🧩 Context
- Phase T3 of the tolerant parsing roadmap calls for a tree filter toggle and Cmd+Shift+E navigation shortcut once the Integrity summary tab shipped, and those items remain open in the backlog.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】
- The master PRD confirms UI corruption views are ~86% complete with issue navigation filters (T3.7) outstanding, keeping this work at the top of the remaining roadmap.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L248-L266】
- `ParseTreeOutlineView` still contains the `#T36-003` TODO for navigating to the affected node when an Integrity issue is selected, showing the integration gap between the Integrity tab and the Explorer outline.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L99-L121】
- The outline view model already exposes filter state and navigation helpers (`filter`, `rowID(after:direction:)`, etc.), providing the scaffolding for issue-focused toggles and shortcuts without re-architecting the tree representation.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L14-L145】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L5-L52】
- IntegritySummaryView passes `onIssueSelected` callbacks for each issue row, so completing the navigation work will immediately connect the summary list to the outline interactions.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryView.swift†L11-L95】

## ✅ Success Criteria
- Selecting an Integrity issue expands ancestors as needed, focuses the Explorer outline on the affected node, and keeps the Integrity ↔ Explorer handoff stable so #T36-003 is resolved for macOS and iPadOS builds.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L99-L121】【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】
- Outline toolbar offers an "Issues only" toggle (with clear state indicator) that hides healthy branches using the existing filter pipeline, while preserving sibling context for affected nodes.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L5-L52】
- Keyboard shortcuts (e.g., Cmd+Shift+E / Cmd+Shift+Option+E) cycle through issue-bearing nodes in document order without conflicting with existing focus shortcuts, leveraging the navigation helpers exposed on the view model.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L160-L170】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L109-L145】
- Unit tests and preview-driven QA cover the new filter mode and navigation helpers so deterministic behavior is enforced across fixtures, extending the current `ParseTreeOutlineViewModelTests` coverage.【F:Tests/ISOInspectorAppTests/ParseTreeOutlineViewModelTests.swift†L8-L151】

## 🔧 Implementation Notes
- Extend `handleIssueSelected` to request outline expansion and scrolling before switching tabs by calling new helpers on `ParseTreeOutlineViewModel` (e.g., ensuring `rows` contains the affected node and updating `expandedIdentifiers`).【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L99-L121】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L28-L164】
- Introduce an issue-focused flag inside `ParseTreeOutlineFilter` (e.g., `showsOnlyIssues`) and thread it through the filter bar / toolbar so `collectRows` keeps ancestors visible while pruning healthy branches.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L5-L52】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L149-L194】
- Add keyboard shortcut registrations beside existing focus commands that call a new navigation coordinator (e.g., next/previous issue) implemented with the view model’s `rowID(after:direction:)` utility and ParseIssue metadata.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L160-L170】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L109-L145】
- Expand `ParseTreeOutlineViewModelTests` with fixtures that include tolerant parsing issues to verify the filter hides healthy branches, ancestors stay expanded, and navigation helpers return expected node IDs.【F:Tests/ISOInspectorAppTests/ParseTreeOutlineViewModelTests.swift†L74-L151】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/199_T3_7_Integrity_Sorting_and_Navigation`](../TASK_ARCHIVE/199_T3_7_Integrity_Sorting_and_Navigation)
