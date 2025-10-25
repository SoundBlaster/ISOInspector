# T2.3 — Aggregate Parse Issue Metrics for UI and CLI Ribbons

## 🎯 Objective
Deliver shared tolerant parsing analytics that expose per-severity issue counts, deepest affected hierarchy depth, and streaming-ready snapshots so SwiftUI ribbons and CLI summaries can surface corruption health at a glance.

## 🧩 Context
- Builds on the tolerant parsing roadmap in [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md), specifically Phase T2 aggregation needs ahead of Phase T3 UI surfacing.
- Supports backlog expectations in [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md) and keeps pace with the execution workplan entry in [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).
- Unblocks the outstanding `@todo` tracked in `Sources/ISOInspectorApp/State/ParseTreeStore.swift` and the CLI parity follow-up for Task T6.2 once UI design sign-off lands.

## ✅ Success Criteria
- `ParseIssueStore` (and any related façade) exposes computed properties returning counts grouped by severity and flags the deepest node depth affected during the current parse session.
- Metrics update incrementally during streaming parses so UI ribbons can reflect live progress without recomputing the entire store.
- CLI consumers can request a lightweight summary struct or DTO to print aggregated counts once parsing completes.
- Unit or integration coverage documents the aggregation math, including edge cases with zero issues, mixed severities, and deeply nested corruption.
- Documentation in `todo.md` and tolerance parsing guides points to these aggregation APIs for downstream UI/CLI wiring.

## 🔧 Implementation Notes
- Extend `ParseIssueStore` (or companion types) with cached aggregations keyed by severity enum and track maximum depth as issues register.
- Ensure aggregation APIs are concurrency-safe for the existing streaming pipeline (Combine publishers driving `ParseTreeStore`).
- Provide SwiftUI-friendly bindings (e.g., `ParseIssueMetrics` struct) so ribbons can bind without duplicating computation.
- For CLI integration, expose formatting-ready data that T6.2 will consume, keeping serialization detached from UI-specific styling.
- Coordinate with design deliverables to confirm required severity buckets and copy so computed fields align with ribbon spec terminology.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
