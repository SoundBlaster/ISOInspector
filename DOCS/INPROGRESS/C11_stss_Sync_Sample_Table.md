# C11 — `stss` Sync Sample Table Parser

## 🎯 Objective

Implement a parser that reads `stss` (Sync Sample Table) boxes so ISOInspector surfaces random-access sample numbers alongside existing sample table metadata.

## 🧩 Context

- Phase C parser backlog classifies Task C11 as a critical P0+ deliverable needed to finish the baseline MP4 sample

  table coverage. See the execution workplan and detailed TODO tracker.

- Accurate `stss` decoding unlocks UI and CLI displays that distinguish keyframes, enabling validation rule VR-015 to correlate sync samples with chunk/sample tables.

## ✅ Success Criteria

- Parser reads the `entry_count` followed by each sync sample number using big-endian 32-bit integers and gracefully handles truncated payloads.
- `BoxParserRegistry` registers the parser so streaming pipelines, CLI output, and UI tree nodes expose sync sample metadata.
- Snapshot/fixture updates cover representative media (with and without `stss` boxes) and assert correct sample numbering and empty-table handling.
- Documentation or code comments record how `stss` integrates with downstream validation (e.g., VR-015) and related sample table views.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` helpers introduced in Task B5 for consistent `(version, flags)` handling.
- Parser depends on existing sample table data from C8 (`stsc`), C9 (`stsz/stz2`), and C10 (`stco/co64`); coordinate acceptance tests that combine these boxes to ensure coherent indices.
- Anticipate future VR-015 validation by emitting structured sync sample arrays accessible to validation and UI

  components.

- Confirm MP4RA catalog metadata for `stss` is surfaced (name, specification link) to keep tree labels consistent.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived sample table parser work in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
