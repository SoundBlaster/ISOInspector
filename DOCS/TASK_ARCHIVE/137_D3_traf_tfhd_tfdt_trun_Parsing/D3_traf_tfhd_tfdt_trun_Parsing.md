# D3 — Fragment Run Sample Table Parsing

## 🎯 Objective
Deliver fragment run parsing that decodes `traf`, `tfhd`, `tfdt`, and `trun` boxes so ISOInspector exposes accurate fragment sample timing, offsets, and flag-driven defaults across streaming events, JSON exports, and CLI output.

## 🧩 Context
- Execution workplan designates D3 as the follow-up to the completed D2 `moof/mfhd` sequencing, requiring fragment run scaffolding to unlock downstream validation and export goals. See `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` for priority and dependency notes.
- The PRD TODO backlog reiterates that D3 must honor flag-governed optional fields (`sample_count`, `data_offset`, per-sample entries) to keep the streaming parser aligned with product requirements. Consult `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` for acceptance pointers.
- The repository TODO highlights the need to surface `tfdt` base decode time and aggregated `traf` metadata so fragment runs expose reliable sample timing data (`todo.md`).

## ✅ Success Criteria
- Register parsers for `traf`, `tfhd`, `tfdt`, and `trun`, emitting typed models that respect flag-controlled optional fields and `trex` defaults.
- Ensure streaming events, JSON exports, and CLI rendering include fragment run details: track IDs, base decode times, sample counts, sizes, durations, data offsets, and optional per-sample overrides.
- Extend validation to cross-check `trun` payloads against `trex` defaults, rejecting inconsistent counts or zero-progress runs while keeping error handling graceful.
- Add unit and snapshot coverage for representative flag combinations (e.g., data-offset present, first-sample-flags overrides) plus malformed boundary cases.

## 🔧 Implementation Notes
- Reuse `FullBoxReader` helpers for `(version, flags)` decoding and pipe defaults from existing `trex` models when optional fields are omitted.
- Maintain fragment state within the streaming pipeline so `tfdt` base decode times and `trun` sample timing feed aggregation logic shared by validation, export, and UI layers.
- Update JSON schemas, snapshots, and CLI fixtures to include fragment run payloads; refresh any impacted UI previews once streaming structs change.
- Coordinate with forthcoming multi-fragment integration coverage and real-world codec fixtures (tracked in `DOCS/INPROGRESS/next_tasks.md`) to validate the implementation end-to-end when assets arrive.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
