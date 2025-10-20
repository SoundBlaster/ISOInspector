# D1 — mvex/trex Defaults Parser

## 🎯 Objective
Implement parsing support for the fragmented movie extension (`mvex`) and its track extends entries (`trex`) so the parser surfaces default sample parameters required by movie fragments.

## 🧩 Context
- The detailed backlog flags D1 as a remaining Phase D parser deliverable covering `mvex/trex` defaults.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L205-L219】
- Fragmented MP4 support is part of the core product scope; decoded defaults feed `moof`/`traf` fragment interpretation and validation workflows described across the execution guide and master PRD.
- All Phase C structural parsers are complete, so fragment metadata can now be layered on without blocking dependencies.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L37-L121】

## ✅ Success Criteria
- `mvex` boxes are registered as containers whose children are parsed and attached to the tree.
- Each `trex` child exposes track ID, default sample description index, duration, size, and flags fields with correct numeric widths.
- Streaming parser preserves byte ranges and flag semantics for export/validation consumers.
- Unit and snapshot tests cover fixtures with fragmented files to guard regressions.

## 🔧 Implementation Notes
- Extend `BoxParserRegistry` with dedicated handlers for `mvex` (container) and `trex` (full box with fixed payload layout). Coordinate with `FourCharContainerCode` where necessary.
- Reuse the existing `FullBoxReader` utilities for version/flags and for big-endian integer decoding across 32-bit fields.
- Ensure defaults integrate with forthcoming D2/D3 fragment parsers by storing parsed values on the node payload model consumed by fragment validation.
- Update fixtures or add new fragmented samples (DASH/init segments) as needed for regression coverage.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
