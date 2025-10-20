# Validation Rule #15 — Sample Table Correlation

## 🎯 Objective

Implement Validation Rule #15 to cross-check `stsc` chunk run definitions, `stsz/stz2` sample sizes, and `stco/co64` chunk offsets so mismatches are surfaced alongside existing edit list duration diagnostics.

## 🧩 Context

- Builds on the completed Phase C parser baseline for `stsc`, `stsz/stz2`, and `stco/co64` documented in `DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser/`, `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/`, and `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/`.
- Must integrate with the edit list validation work from `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/` so timing warnings include chunk/sample anomalies.
- Coordinates with metadata coverage from `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/` to ensure correlated diagnostics flow through CLI and UI layers.

## ✅ Success Criteria

- Streaming validation emits a dedicated VR-015 diagnostic when correlated chunk/sample data is inconsistent (e.g.,

  counts mismatch, offsets not monotonic, or sample totals disagree).

- Existing fixtures covering chunk tables and edit lists gain positive/negative assertions for the new rule without

  regressing prior validation snapshots.

- Validation output links to affected boxes (chunk table, sample size table, edit list) for UI highlighting and CLI

  reporting.

## 🔧 Implementation Notes

- Leverage existing structured models emitted by the `BoxParserRegistry` for `stsc`, `stsz/stz2`, and `stco/co64` so validation runs without reparsing payload bytes.
- Extend the validation aggregation pipeline established in VR-014 to include cross-table summaries and computed totals.
- Add targeted fixtures or mutate existing archives (see `Tests/ISOInspectorKitTests/Validation`) to cover edge cases such as sparse chunk runs or zero-sized samples.
- Update documentation and PRD references (workplan, backlog, `todo.md`) once the rule lands to mark the task complete.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

## ✅ Outcome

- VR-015 validation now reconciles `stsc`, `stsz/stz2`, and `stco/co64` tables, emitting descriptive errors for count mismatches and non-monotonic chunk offsets.
- Added regression coverage in `ParsePipelineLiveTests` for aligned sample tables, sample count mismatches, and misordered chunk offsets.
- Refer to `DOCS/INPROGRESS/Summary_of_Work.md` for the delivery log and follow-up notes.
