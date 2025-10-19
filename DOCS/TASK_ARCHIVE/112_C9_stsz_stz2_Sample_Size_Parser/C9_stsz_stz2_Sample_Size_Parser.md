# C9 — `stsz`/`stz2` Sample Size Parser

## 🎯 Objective

Implement dedicated parsers for the `stsz` and `stz2` sample size tables so ISOInspector surfaces per-sample byte lengths alongside summary statistics in both CLI and SwiftUI clients.

## 🧩 Context

- Phase C requires decoding each sample table component so tooling can reconcile counts, sizes, and offsets when

  presenting track media details. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L191-L208】

- Recent coordination notes highlight the need to align upcoming sample size and chunk offset parsers with the delivered `stsc` detail model to enable cross-table validation. 【F:DOCS/INPROGRESS/next_tasks.md†L5-L8】【F:DOCS/TASK_ARCHIVE/110_Summary_of_Work_2025-10-19_C9_C10_Planning/Summary_of_Work.md†L12-L15】

## ✅ Success Criteria

- Parsing handles both `stsz` (constant sample size plus per-sample overrides) and `stz2` (field size encoded entries) according to ISO/IEC 14496-12, populating model structs consumed by CLI/UI layers.
- Sample counts emitted by `stsz`/`stz2` align with `stsc` entries and drive validation that flags mismatches during export, CLI summaries, and UI detail panes.
- Unit tests cover large constant-size tables, variable-size overrides, and 4/8/16-bit packed `stz2` entries, including malformed fixture cases that trigger validation warnings.
- Snapshot/JSON export baselines reflect decoded sample size arrays and continue to pass.

## 🔧 Implementation Notes

- Reuse the shared `FullBoxReader` and buffer abstractions established in prior parser work to read headers and iteratively decode entry payloads.
- Extend the `stsc`-backed detail model so it can correlate sample size arrays with chunk maps; add guardrails that surface inconsistencies to validation routines.
- Ensure parsers register within `BoxParserRegistry`, wiring outputs to SwiftUI detail sections and CLI summaries that currently stub sample size data.
- Coordinate with the forthcoming C10 (`stco`/`co64`) parser to guarantee combined validation over sample counts, sizes, and chunk offsets for each track.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
