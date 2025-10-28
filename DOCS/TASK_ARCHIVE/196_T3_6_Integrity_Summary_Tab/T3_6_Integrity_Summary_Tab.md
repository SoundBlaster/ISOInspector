# T3.6 — Integrity Summary Tab — Next Iteration

> Earlier notes and status updates were archived in `DOCS/TASK_ARCHIVE/195_T4_4_Sanitize_Issue_Exports/T3_6_Integrity_Summary_Tab.md`.

## 🎯 Objective
Deliver a dedicated Integrity tab that consolidates all recorded `ParseIssue` entries into a sortable, filterable table and exposes exports so operators can triage corruption without scanning the outline manually.

## 🧩 Context
- `ParseIssueStore` now aggregates tolerant parsing diagnostics with severity counts following T2.1 and T2.3, enabling ribbon updates and Share sheet summaries without recomputation.
- Integrity detail work from T3.3–T3.5 introduced navigation helpers in `DocumentSessionController` so views can focus nodes and badge counts consistently.
- Export hardening from T4.2/T4.4 refreshed plaintext and JSON issue summary pipelines, so the new tab must reuse those exporters rather than duplicating logic.

## ✅ Success Criteria
- Integrity tab appears alongside the tree/detail panes and lists aggregated `ParseIssue` rows with default severity sorting plus controls to sort by offset and affected node.
- Severity filters adjust the table contents while keeping ribbon counts (`ParseIssueStore.IssueMetrics`) and the detail pane badges in sync.
- Selecting a table row focuses the associated node in the outline and detail panes using the existing navigation APIs.
- Share/Export actions invoked from the tab reuse the document-level plaintext and JSON exporters, and exported counts match the tab and ribbon totals.
- UI automation or snapshot coverage verifies that a corrupt fixture displays the expected issue count in the tab and that exports succeed for both full-document and selection scopes.

## 🔧 Implementation Notes
- Introduce `IntegritySummaryView` (SwiftUI) under `Sources/ISOInspectorApp` backed by a lightweight view model that observes `ParseIssueStore.issues` and metrics snapshots.
- Extend `ParseTreeExplorerView`/`AppShellView` to include the new tab alongside existing tree/detail/hex content, ensuring tab state updates `DocumentSessionController.focusIntegrityDiagnostics()`.
- Reuse selection wiring from `DocumentSessionController` and `ParseTreeOutlineView` so row activation drives `DocumentViewModel.nodeViewModel` focus.
- Connect Share menu buttons to `DocumentSessionController.exportIssueSummary(scope:)` and `exportJSON(scope:)`, validating counts against `ParseIssueStore.makeIssueSummary()`.
- Update UI and exporter tests (e.g., `Tests/ISOInspectorAppTests` and `Tests/ISOInspectorKitTests/ParseExportTests.swift`) to cover tab rendering, filter interactions, and export parity.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
