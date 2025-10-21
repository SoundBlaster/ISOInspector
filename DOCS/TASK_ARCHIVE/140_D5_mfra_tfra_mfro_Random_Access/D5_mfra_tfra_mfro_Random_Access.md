# D5 — mfra/tfra/mfro Random Access Tables

## 🎯 Objective
Deliver parsing and data-model support for the `mfra`, `tfra`, and `mfro` random access boxes so ISOInspector surfaces fragment index metadata across the core library, CLI, and UI.

## 🧩 Context
- The detailed backlog calls for implementing the `mfra/tfra/mfro` random access table to round out the fragmented MP4 workflow, with D1–D4 already complete in the same list (`ISOInspector_PRD_TODO.md`).
- Phase D tasks execute sequentially per the execution workplan, so D5 should immediately follow the archived fragment header and `sidx` work.
- Random access indexing underpins the master PRD objective to expose navigation aids for fragmented, large assets.

## ✅ Success Criteria
- `mfra`, `tfra`, and `mfro` parsers emit structured nodes via `BoxParserRegistry`, preserving offsets, sizes, and per-track random access entries.
- Sample fixtures (fragmented MP4/DASH) produce deterministic random access metadata that flows through CLI output, JSON export, and the SwiftUI detail views.
- Automated tests cover representative entry combinations (single-track, multi-track, and empty tables) and guard against malformed lengths or inconsistent offsets.

## 🔧 Implementation Notes
- Extend the parser registry and decoding layer with dedicated types for `MovieFragmentRandomAccessBox`, `TrackFragmentRandomAccessBox`, and `MovieFragmentRandomAccessOffsetBox`, mirroring the earlier fragment parser style.
- Reuse stream context established in D3 (`traf/tfhd/tfdt/trun`) to correlate random access entries with fragment sequence numbers where data is available.
- Update CLI formatting, JSON export, and UI presentation helpers so random access entries display track IDs, times, and offsets without regressing existing snapshot tests.
- Validate payload ranges against the Phase E containment rules once those checks land, ensuring random access metadata does not flag false positives.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
