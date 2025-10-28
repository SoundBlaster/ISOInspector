# T3.7 — Integrity Navigation Filters

## 🎯 Objective
Establish the follow-up plan that completes the Integrity diagnostics UX by adding navigation aids and sorting polish so investigators can jump between corrupt nodes directly from the Integrity tab while keeping the outline tree in sync.

## 🧩 Context
- The tolerance parsing roadmap shows Phase T3 is almost complete with only task **T3.7** outstanding; it calls for a tree view filter toggle and keyboard shortcuts that hop between corruption issues once badge rendering and the Integrity tab are in place.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】
- The master PRD reiterates that the UI corruption views milestone is 86% done and that issue navigation filters (T3.7) are the remaining deliverable following the Integrity Summary tab release.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L251-L267】
- Current source code still contains `@todo` markers from the T3.6 rollout that document the required sorting refinements and explorer navigation hand-off when an issue row is selected, confirming the scope that must roll into this milestone.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L52-L79】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L100-L121】

## ✅ Success Criteria
- Integrity summary table supports deterministic offset and affected-node sorting that matches CLI/export ordering across large fixture sets.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L60-L79】
- Selecting an issue row re-centers the Explorer outline on the affected node and preserves tab focus so investigators can immediately inspect details.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L100-L121】
- Outline toolbar exposes a filter toggle (and matching keyboard shortcut) that hides resolved/healthy nodes and cycles through corrupt entries in document order per the T3.7 acceptance notes.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】
- Navigation controls respect existing accessibility shortcuts and do not regress warning ribbon metrics or export parity validated in prior Integrity tasks.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L253-L270】

## 🔧 Implementation Notes
- Audit existing keyboard shortcut catalogs (`ParseTreeOutlineView.focusCommands`) to layer in issue navigation without conflicting with current Command+Option bindings.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L142-L170】
- Coordinate with `ParseIssueStore` metrics to reuse severity filters and ensure the toggle aligns with ribbon counts before introducing new UI state.
- Extend integration tests alongside the Integrity tab suite once filters and navigation land to protect CLI/UI parity called out in the PRD backlog.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L253-L267】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab`](../TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab)
