# Next Tasks

## Phase C — Specific Parsers (Baseline)

- [ ] 🔴 **P0+** C14d. Refresh fixtures, JSON exports, and snapshot baselines covering common edit list scenarios (empty

  list, single offset, multi-segment, rate adjustments) so the VR-014 diagnostics introduced in Task C14c have full
  regression coverage.

- [ ] 🔴 **P0+** C15. Implement baseline metadata box coverage for `udta`, `meta` (handler), `keys`, and `ilst` atoms to surface simple string/integer payloads for CLI export while preserving handler mappings documented in `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/`.

## Validation Follow-Up

- [ ] Validation Rule #15. Correlate `stsc` chunk runs, `stsz/stz2` sample sizes, and `stco/co64` offsets to flag mismatches alongside the new edit list duration diagnostics archived in `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`.
