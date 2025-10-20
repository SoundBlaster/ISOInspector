# C12 — `dinf/dref` Data Reference Parser

## 🎯 Objective

Enable ISOInspector to parse the movie data information container (`dinf`) and its data reference table (`dref`), exposing entry metadata (type, version, flags, and location payload) through the `BoxParserRegistry` so downstream components can resolve external or self-contained media references.

## 🧩 Context

- Phase C parser backlog prioritizes `dinf/dref` as a P0+ blocker for the baseline parser milestone, unlocking follow-up validation on random access metadata.
- The existing random-access pipeline from Task C10 (`stco/co64`) and Validation Rule #15 relies on accurate data reference indexing to correlate chunk offsets with referenced media sources.
- Prior work in `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/C10_stco_co64_Chunk_Offset_Parser.md` outlines how chunk metadata is consumed; `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` captures handler semantics that must align with data references.

## ✅ Success Criteria

- `BoxParserRegistry` registers dedicated decoders for `dinf` (container) and `dref` (full box) that iterate all child entries without breaking streaming guarantees.
- Each `dref` entry captures its reference type (e.g., `url `, `urn `), flags, and payload bytes, surfacing URL/URN strings for CLI JSON export and UI detail panes.
- The parser updates JSON export snapshots to include data reference collections under the owning track/media context, with regression coverage in `ISOInspectorKitTests`.
- Validation scaffolding consumes parsed references to associate chunk offsets with the correct reference index,

  enabling follow-up rule authoring without additional structural changes.

## 🔧 Implementation Notes

- Extend existing full-box parsing helpers (`FullBoxReader`) to decode `dref` version/flags, then branch on entry type identifiers to extract URL and optional name fields.
- Ensure reference indices align with one-based numbering described in ISO/IEC 14496-12; unit tests should assert index

  ordering and flag-driven semantics (self-contained bit vs. external resource).

- Update CLI export mappers and SwiftUI detail views to include parsed data references, mirroring the formatting used

  for other sample table arrays.

- Coordinate with pending Validation Rule #15 work so parsed reference indices are available to correlation logic

  without duplicating traversal state.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/C10_stco_co64_Chunk_Offset_Parser.md`](../TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/C10_stco_co64_Chunk_Offset_Parser.md)
- [`DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md`](../TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md)
