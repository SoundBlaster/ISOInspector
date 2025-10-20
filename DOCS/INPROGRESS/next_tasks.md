# Next Tasks

## Phase C — Specific Parsers (Baseline)

- [ ] 🔴 **P0+** C14a. Finalize the `edts/elst` parser scope by reviewing ISO/IEC 14496-12 §8.6, confirming field widths, fixed-point rate handling, and how edit list segment counts relate to `mvhd`/`tkhd` durations. Summarize parser requirements alongside the archived movie/track header work (`DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/`, `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/`). _(In Progress — see `DOCS/INPROGRESS/C14a_Finalize_Edit_List_Scope.md`.)_
- [ ] 🔴 **P0+** C14b. Implement `elst` entry parsing within `BoxParserRegistry`, capturing segment duration, media time, and rate while normalizing rate to double precision for UI/export consumers. Ensure large edit lists stream without over-allocation.
- [ ] 🔴 **P0+** C14c. Wire edit list payloads into validation so reconciled presentation durations align with

  movie/track headers and flag gaps or overlaps. Extend existing duration diagnostics to reference edit list context.

- [ ] 🔴 **P0+** C14d. Refresh fixtures, JSON exports, and snapshot baselines covering common edit list scenarios (empty

  list, single offset, multi-segment, rate adjustments) and document test execution notes in the new task summary.

- [ ] 🔴 **P0+** C15. Implement baseline metadata box coverage for `udta`, `meta` (handler), `keys`, and `ilst` atoms, surfacing simple string/integer payloads for CLI export. Follow archival context in `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` to keep handler mappings consistent.

## Validation Follow-Up

- [ ] Validation Rule #15. Correlate `stsc` chunk runs, `stsz/stz2` sample sizes, and `stco/co64` offsets to flag mismatches alongside the new sync sample metadata (see `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/Summary_of_Work.md`, `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/Summary_of_Work.md`, and `DOCS/TASK_ARCHIVE/115_C11_stss_Sync_Sample_Table/Summary_of_Work.md`).
