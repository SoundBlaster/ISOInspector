# C2 — mvhd Movie Header Parser

## 🎯 Objective
Implement a dedicated parser for the `mvhd` movie header box so ISOInspector can surface its timeline metadata (timescale, duration, playback rate, volume, and transformation matrix) across streaming, UI, and export surfaces.

## 🧩 Context
- Phase C parser items are escalated to **Critical P0+** priority, so completing `mvhd` is required for the current milestone.
- The `mvhd` task explicitly calls for decoding timescale, 32/64-bit durations, rate, volume, and matrix fields to unlock downstream presentation.

## ✅ Success Criteria
- Parsing supports both version 0 (32-bit) and version 1 (64-bit) `mvhd` duration layouts while always exposing the declared timescale.
- The parser outputs normalized playback rate and volume values needed by clients that visualize movie timing characteristics.
- The transformation matrix entries are decoded and propagated so UI and export consumers can represent orientation metadata alongside other header fields.

## 🔧 Implementation Notes
- Treat `mvhd` as a `FullBox`, reusing the shared version/flags reader so downstream code can gate duration width on the version bit.
- Wire the parser into the core registry once the `BoxParserRegistry` scaffolding stabilizes so the broader movie tree gains `mvhd` coverage alongside existing `mdhd`/`hdlr` support.
- Add focused fixtures or sample slices covering both version 0 and version 1 headers to maintain regression coverage for the decoded fields.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
