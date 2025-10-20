# D2 — moof/mfhd Sequence Number Parser

## 🎯 Objective
Implement fragment-level parsing for the `moof` container and its `mfhd` header so the CLI and UI expose correct sequence numbers for fragmented MP4 files.

## 🧩 Context
- Fragmented MP4 support in the master PRD requires decoding `moof` / `traf` structures to drive validation, exports, and UI insights.
- Section C parser work (movie box hierarchy, sample tables, metadata) is complete, eliminating dependencies on track-level metadata before adding fragment parsing.
- Execution workplan fragment tasks (D2–D3) remain outstanding despite CLI scaffolding, and this effort re-aligns the backlog with parser coverage expectations.

## ✅ Success Criteria
- `ISOInspectorKit` parses `moof` boxes and captures the `mfhd.sequence_number` field with overflow-safe math.
- Streaming pipeline emits fragment nodes with offsets, sizes, and sequence numbers reflected in JSON export snapshots.
- Validation layer gains basic checks ensuring sequence numbers increment monotonically when multiple fragments are present in a file.
- CLI `inspect` / UI tree views present the decoded sequence number and no longer show placeholder or missing values for `mfhd`.

## 🔧 Implementation Notes
- Reuse the existing container iteration utilities to traverse `moof` children while guarding against nested fragment loops.
- Extend the box registry with fragment-specific parsers (`mfhd`, `traf`, `tfhd`, etc.) while keeping leaf payloads lightweight until D3 follows up on sample tables.
- Coordinate with sample fixture catalog to ensure at least one fragmented MP4 asset exercises incrementing sequence numbers; update snapshot baselines as needed.
- Ensure error handling covers absent or zero sequence numbers by emitting validation warnings rather than crashing parsing consumers.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived fragment parser context in `DOCS/TASK_ARCHIVE` as it becomes available.
