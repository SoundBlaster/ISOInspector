# C14a — Finalize `edts/elst` Parser Scope

## 🎯 Objective

Document the full parsing requirements for the ISO BMFF Edit List box (`edts/elst`) so downstream implementation work can rely on an authoritative scope that aligns with ISO/IEC 14496-12 §8.6 and existing movie/track header metadata.

## 🧩 Context

- Phase C focuses on enriching parser coverage for presentation timing metadata. Edit lists reconcile movie- and track-level durations (from `mvhd`/`tkhd`) with presentation edits, so this scope review must tie into the archived header work.
- Prior tasks established access to duration, timescale, and rate information in `mvhd` and `tkhd` (`DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/`, `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/`). Their outputs provide the baseline needed to validate edit list semantics.

## ✅ Success Criteria

- Summarize `elst` box structure, including entry count derivation, field widths per version, and fixed-point rate interpretation (signed 16.16).
- Clarify how segment durations map to movie timescales and how empty edits or `media_time == -1` cases influence playback offsets.
- Outline validation touchpoints: compare aggregated edit durations against `mvhd`/`tkhd` values and note scenarios that should raise diagnostics (gaps, overlaps, rate anomalies).
- Produce implementation-ready notes covering streaming considerations (e.g., large edit list handling without excessive
  buffering) for the parser registry task.

## 🔧 Implementation Notes

- Review ISO/IEC 14496-12 §8.6 (`Edit List Box`) to confirm field ordering, flag semantics, and version-specific sizing (version 0 uses 32-bit durations/media times, version 1 uses 64-bit durations/media times).
- Capture how edit counts are derived: read `entry_count`, then iterate entries as `{ segment_duration, media_time, media_rate }` with `media_rate_fraction = 0` requirement.
- Document edge cases noted in archived header tasks, such as non-zero `mvhd` rate or differing track timescales, that influence how edit segments should be normalized for UI/export.
- Note dependency on available movie/track timescale values for validation math and ensure the scope specifies required
  cross-references for later tasks (C14b–C14d).

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context: `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/`, `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/`
