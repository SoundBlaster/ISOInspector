# C10 — `stco/co64` Chunk Offset Parser

## 🎯 Objective

Implement dedicated parsers for the 32-bit `stco` and 64-bit `co64` chunk offset tables so ISOInspector exposes precise byte offsets for each media chunk and enables validation against the recently delivered `stsc` and `stsz/stz2` sample table models.

## 🧩 Context

- Phase C "Specific Parsers (Baseline)" backlog escalated items `C10`–`C15` to **P0+** priority, with `C10` identified as the next critical parser required to unlock validation rule @todo #15. (See [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md).)
- Previous tasks `C8` (`stsc` sample-to-chunk`) and `C9` (`stsz/stz2` sample sizes) are complete and archived, and they highlight coordination requirements for `stco/co64` to reconcile chunk ranges, sample counts, and validation reporting.
- Execution guidance and archived planning notes (`DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser/`, `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/`) outline how chunk offsets must integrate with the shared detail models consumed by the CLI and SwiftUI tree views.

## ✅ Success Criteria

- Parsers decode `entry_count` and capture each chunk offset as either `UInt32` (`stco`) or `UInt64` (`co64`), normalizing to a shared model downstream.
- `BoxParserRegistry` registers both boxes, and streaming parse events emit structured metadata consumed by the CLI and SwiftUI experiences without regression.
- Validation pipeline gains access to chunk offsets, enabling cross-checks that correlate `stsc` chunk ranges and `stsz/stz2` sample sizes (unblocking repo `todo.md` item #15).
- Snapshot and fixture coverage updated so regression tests confirm offsets, counts, and 32/64-bit handling across
  representative MP4 fixtures.

## 🔧 Implementation Notes

- Extend the shared sample table detail model to carry chunk offsets; ensure formatting aligns with existing `stsc`/`stsz` entries for UI presentation and JSON export.
- Implement unit tests covering mixed `stco`/`co64` fixtures, including boundary cases (maximum chunk count, large offsets) and ensure offsets fit within the parent file range.
- Wire validation hooks that reconcile chunk offset arrays with `stsc` chunk runs and sample counts, flagging discrepancies once all sample table data is parsed.
- Coordinate documentation updates (DocC, README matrices if required) to list `stco/co64` as supported boxes once parser ships.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
