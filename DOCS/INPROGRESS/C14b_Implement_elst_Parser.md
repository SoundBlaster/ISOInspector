# C14b — Implement `elst` Edit List Parser

## 🎯 Objective

Implement streaming support for the `edts/elst` edit list within `BoxParserRegistry`, exposing normalized duration, media time, and playback rate metadata for UI and CLI consumers while respecting the finalized scope from C14a.

## 🧩 Context

- Build on the scoped requirements for edit lists captured during Task C14a, including field widths, normalization
  rules, and validation follow-ups.
  【F:DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/C14a_Finalize_Edit_List_Scope.md†L1-L64】
- Ensure compatibility with existing movie and track header metadata parsed in tasks C2 (`mvhd`) and C3 (`tkhd`), along with media timescale data from `mdhd`. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L173-L209】
- Align parser outputs with the master PRD expectations for streaming parsers and diagnostics so edit lists inform
  downstream validation work (C14c) and fixture updates (C14d).
  【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L1-L20】

## ✅ Success Criteria

- `BoxParserRegistry` registers an `elst` parser that reads entries incrementally, honoring version-specific field sizes (32-bit vs 64-bit durations/media times).
- Each entry emits normalized seconds for segment duration and media time, plus the raw fixed-point rate pair and a
  computed double value without accumulating entire lists in memory.
- Parser records presentation offsets per entry and surfaces rate anomalies (non-zero fractions, unsupported integers)
  for validation consumers.
- Large edit lists stream without excessive allocation and integrate with existing export pathways (JSON, CLI) without
  breaking regression tests.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` helpers for `(version, flags)` decoding and derive timescale context from already parsed `mvhd`, `tkhd`, and `mdhd` nodes available in parse state.
- Represent each edit entry with a lightweight struct that carries raw integers and normalized doubles so subsequent
  tasks can plug into validation and fixture refresh flows.
- Emit diagnostics hooks for duplicate `edts` boxes or anomalous media rates, but defer the full reconciliation logic to Task C14c.
- Validate streaming behavior with representative fixtures covering empty edits, offsets, multi-segment lists, and rate
  adjustments to guide C14d test updates.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope`](../TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope)
