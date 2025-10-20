# Next Tasks

## Phase C — Specific Parsers (Baseline)

- [x] 🟢 **Done — P0+** C13. Surface `smhd`/`vmhd` media header fields (balance, graphics mode, opcolor) via `BoxParserRegistry` and refresh JSON exports. See `DOCS/INPROGRESS/Summary_of_Work.md` for implementation notes.
- [ ] 🔴 **P0+** C14. Decode `edts/elst` edit lists, including segment duration, media time, and rate, and extend validation hooks so timeline adjustments reconcile with `mvhd`/`tkhd` durations (see `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/Summary_of_Work.md`).
- [ ] 🔴 **P0+** C15. Implement baseline metadata box coverage for `udta`, `meta` (handler), `keys`, and `ilst` atoms, surfacing simple string/integer payloads for CLI export. Follow archival context in `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` to keep handler mappings consistent.

## Validation Follow-Up

- [ ] Validation Rule #15. Correlate `stsc` chunk runs, `stsz/stz2` sample sizes, and `stco/co64` offsets to flag mismatches alongside the new sync sample metadata (see `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/Summary_of_Work.md`, `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/Summary_of_Work.md`, and `DOCS/TASK_ARCHIVE/115_C11_stss_Sync_Sample_Table/Summary_of_Work.md`).
