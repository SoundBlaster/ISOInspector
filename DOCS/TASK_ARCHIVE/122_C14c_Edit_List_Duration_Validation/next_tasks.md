# Next Tasks

## Phase C — Specific Parsers (Baseline)

- [x] 🔴 **P0+** C14c. Wire edit list payloads into validation so reconciled presentation durations align with

  movie/track headers and flag gaps or overlaps. Extend duration diagnostics to reference edit list context. _(Completed
— see
  `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/Summary_of_Work.md`.)_

- [x] 🔴 **P0+** C14d. Refresh fixtures, JSON exports, and snapshot baselines covering common edit list scenarios (empty

  list, single offset, multi-segment, rate adjustments) so VR-014 diagnostics have full regression coverage. _(Completed
  — see `DOCS/TASK_ARCHIVE/123_C14d_Refresh_Edit_List_Fixtures/Summary_of_Work.md` and the in-progress summary at
  `DOCS/INPROGRESS/Summary_of_Work.md`.)_

- [ ] 🔴 **P0+** C15. Implement baseline metadata box coverage for `udta`, `meta` (handler), `keys`, and `ilst` atoms, surfacing simple string/integer payloads for CLI export. Follow archival context in `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` to keep handler mappings consistent.

## Validation Follow-Up

- [ ] Validation Rule #15. Correlate `stsc` chunk runs, `stsz/stz2` sample sizes, and `stco/co64` offsets to flag mismatches alongside the new sync sample metadata (see `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/Summary_of_Work.md`, `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/Summary_of_Work.md`, and `DOCS/TASK_ARCHIVE/115_C11_stss_Sync_Sample_Table/Summary_of_Work.md`).
