# R2 Fixture Acquisition

## 🎯 Objective

Identify and document a curated catalog of MP4/QuickTime fixtures that exercise standard, fragmented, and
vendor-specific atoms so the parsing, validation, and benchmarking suites can rely on representative media samples.

## 🧩 Context

- Research backlog R2 prioritizes gathering legally distributable media covering a wide atom surface, including DASH
  fragments and vendor boxes, to unblock QA and benchmarking
  coverage.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Performance and validation workflows in the execution plan depend on diverse fixtures to exercise streaming readers,
  benchmarks, and follow-up hardware validation work once macOS infrastructure is
  available.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】【F:DOCS/INPROGRESS/next_tasks.md†L5-L12】

## ✅ Success Criteria

- Produce a ranked list of sample sources (public datasets, vendor bundles) with licensing notes and download
  metadata.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Ensure the catalog covers core MP4 families (progressive `moov`/`mdat`), fragmented streaming (`moof`/`traf`), metadata-heavy assets, and edge cases referenced in benchmarking runbooks.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】
- Document storage and size requirements so CI or hardware runners can stage the media without exhausting
  quotas.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】

## 🔧 Implementation Notes

- Audit existing archives and public collections (Apple sample media, DASH-IF, vendor-provided files) for coverage,
  recording checksum, codecs, and notable boxes before
  inclusion.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Capture follow-up actions for fixtures that require macOS hardware to validate streaming automation once runners exist, keeping `next_tasks.md` aligned with any hardware-dependent execution steps.【F:DOCS/INPROGRESS/next_tasks.md†L5-L21】
- Coordinate with benchmarking documentation to align selected samples with the random-slice and Combine UI benchmark
  plans so the datasets serve both CLI and UI
  workflows.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
