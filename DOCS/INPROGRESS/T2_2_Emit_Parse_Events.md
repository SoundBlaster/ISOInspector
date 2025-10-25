# T2.2 — Emit Parse Events with Severity Metadata

## 🎯 Objective
Deliver enriched tolerant parsing stream events that include severity, offset, and reason code metadata so UI and CLI consumers can react to corruption diagnostics without waiting for the full parse to complete.

## 🧩 Context
- The Tolerance Parsing workplan identifies Task T2.2 as the next high-priority item to propagate detailed `ParseIssue` metadata through the streaming event system after the aggregation store landed in T2.1. 【F:DOCS/AI/Tolerance_Parsing/TODO.md†L51-L67】
- The master PRD requires streaming parsing with live event emission that surfaces diagnostics across the SwiftUI app and CLI, ensuring users can monitor integrity issues during long-running inspections. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L25-L55】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L16-L73】

## ✅ Success Criteria
- Streaming parse events carry structured severity, offsets, and reason code fields aligned with `ParseIssue` records.
- `ParseTreeStore` observes the enriched events and updates UI state without regressing strict-mode behavior.
- CLI streaming consumers receive the new metadata without breaking existing log formats; regression tests updated as needed.
- Feature is guarded by existing tolerant parsing configuration options with documentation updates queued for downstream tasks.

## 🔧 Implementation Notes
- Extend the existing `ParsePipeline` event payload to embed issue metadata, leveraging the aggregation capabilities introduced in T2.1. 【F:DOCS/TASK_ARCHIVE/175_Summary_of_Work_2025-10-26_ParseIssueStore_Aggregation/Summary_of_Work.md†L5-L32】
- Audit `ParseTreeStore` Combine bindings to ensure issue metrics remain synchronized with live events; coordinate with the pending SwiftUI metrics surfacing task noted in backlog. 【F:todo.md†L13-L18】
- Validate CLI streaming output paths and JSON export hooks to keep schema compatibility, using fixture-driven tests where available. 【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L120】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
