# D3 — Fragment Run Sample Table Parsing

## 🎯 Objective
Deliver fragment run parsing that decodes `traf`, `tfhd`, `tfdt`, and `trun` boxes so ISOInspector exposes accurate sample table metadata for fragmented MP4 files across the CLI, library exports, and UI surfaces.

## 🧩 Context
- The detailed backlog lists D3 as the follow-up to D2 for fragment run scaffolding, requiring flag-aware parsing plus sample counts and offsets (`ISOInspector_PRD_TODO.md`).
- Execution workplan tracking notes D3 as the next fragment parser milestone after the completed `moof/mfhd` work (`04_TODO_Workplan.md`).
- D1 (`mvex/trex`) and D2 (`moof/mfhd`) are complete, so fragment defaults and sequence numbers are already flowing through the pipeline, letting D3 focus on per-run metadata.
- Fragment metadata unlocks validation and export expectations outlined in the master PRD’s streaming parser goals, especially for multi-fragment playback scenarios.

## ✅ Success Criteria
- `ISOInspectorKit` registers parsers for `traf`, `tfhd`, `tfdt`, and `trun`, emitting strongly typed models that honor the optional fields governed by each flag bit.
- Streaming events, JSON exports, and CLI output include fragment run details: track IDs, default/sample flags, base decode time, sample counts, sizes, durations, and optional data offsets.
- Unit and snapshot tests cover representative flag combinations (e.g., data-offset present, first-sample-flags overrides) and guard against malformed counts or offsets.
- Validation layer gains initial checks that correlate `trun` metadata with `trex` defaults and fail gracefully when runs declare zero progress or inconsistent array lengths.

## 🔧 Implementation Notes
- Reuse `FullBoxReader` to read `tfhd`/`trun` version and flag fields, applying `trex` defaults when optional values are absent.
- Extend the streaming parser to accumulate fragment state so downstream consumers can cross-reference `tfdt` base decode time and `trun` timestamps during validation.
- Update JSON export schemas and fixtures to include fragment run payloads; refresh CLI snapshot baselines to assert the new fields.
- Ensure bounds and overflow checks on cumulative sample durations/sizes mirror existing sample table protections, emitting warnings instead of crashing on malformed data.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived fragment context in [`DOCS/TASK_ARCHIVE/134_D2_moof_mfhd_Sequence_Number/`](../TASK_ARCHIVE/134_D2_moof_mfhd_Sequence_Number/)
