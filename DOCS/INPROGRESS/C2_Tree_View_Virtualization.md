# C2 — Tree View Virtualization & Search

## 🎯 Objective

Deliver the SwiftUI outline explorer that renders streaming parse snapshots with virtualization, scoped search, and box
category filters so large MP4 structures remain explorable without UI lag.

## 🧩 Context

- Execution workplan task **C2** (Phase C — User Interface Package) is the next high-priority item after the Combine
  bridge, requiring a virtualized tree view with responsive search and filters over 10k
  nodes.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L29】
- Archived Combine bridge work (Task 18) explicitly hands off to C2 to render the new `ParseTreeStore` snapshots in the outline explorer.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L101-L106】
- Previous C2 spikes (Tasks 19–22) validated virtualization techniques and outlined follow-ups to connect live streaming
  sessions and expose MP4RA-driven category filters; this task consolidates those learnings into the active
  codebase.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L107-L129】

## ✅ Success Criteria

- Tree view renders streaming `ParseTreeStore` snapshots with virtualization that keeps scrolling smooth for structures exceeding 10k nodes.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L29】
- Search input narrows visible nodes with instant feedback, honoring severity/category filters described in the archived
  spikes.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L107-L129】
- Filter controls surface MP4RA category groupings and streaming metadata toggles without breaking existing severity
  filtering.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L123-L129】
- UI tests or previews verify latency stays below the 200 ms streaming target from the master PRD during live
  updates.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L4-L24】

## 🔧 Implementation Notes

- Reuse the Combine-backed `ParseTreeStore` bridge from task 18 to feed SwiftUI state while minimizing main-thread work per update.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L101-L106】
- Apply virtualization strategies proven in the archived spikes (batching, lazy stacks) but replace preview-only data
  with real parser events to meet acceptance criteria.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L107-L123】
- Wire MP4RA-derived category metadata (from task B4) into filter chips, ensuring catalog lookups stay lightweight for
  streaming workloads.【F:DOCS/INPROGRESS/B4_Integrate_MP4RA_Metadata_Catalog.md†L1-L44】
- Add instrumentation hooks (e.g., signposts or metrics) so future performance regression tests can assert <200 ms UI
  latency during large file inspection.【F:DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md†L119-L124】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
