# T3.6 — Integrity Summary Tab

## 🎯 Objective
Deliver a dedicated Integrity tab that consolidates all recorded `ParseIssue` entries into a sortable, filterable table and exposes exports so operators can triage corruption without scanning the outline manually.

## 🧩 Context
- Extends the tolerant parsing UI pass for corruption surfacing in Phase T3, building directly on the warning ribbon, badges, placeholders, and contextual status labels already completed.
- `ParseIssueStore` now exposes aggregated issue data (T2.1–T2.3), and the Integration Summary calls for a tabbed view that lists severity, code, message, offset, and owning node with Share menu actions for JSON/text exports.
- The Master PRD positions tolerant parsing as a forensic workflow aid; this tab is the hub linking metrics ribbons to detail inspectors and export pipelines.

## ✅ Success Criteria
- Integrity tab is accessible from the main inspector alongside Tree, Detail, and Hex tabs.
- Table lists every issue with sortable columns (severity default) and severity filters.
- Selecting an issue focuses the associated node in the outline/detail views.
- Share/Export menu offers JSON (existing schema v2) and plaintext summaries that include file metadata.
- UI automation or SwiftUI preview coverage demonstrates populated corrupt fixture renders.

## 🔧 Implementation Notes
- Surface data via shared `ParseIssueStore` observers so counts stay in sync with ribbons.
- Reuse contextual status copy/colors from `ISOInspectorUI` to avoid divergence with badges and detail pane.
- Provide keyboard shortcuts/hooks that future T3.7 navigation work can extend.
- Coordinate export actions with ongoing T4 diagnostics deliverables to prevent duplicative menu wiring.
- Validate VoiceOver labels and table focus order per accessibility guidance.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
