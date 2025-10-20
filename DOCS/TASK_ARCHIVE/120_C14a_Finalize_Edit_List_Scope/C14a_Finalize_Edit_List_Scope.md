# C14a — Finalize `edts/elst` Parser Scope

## 🎯 Objective

Define the complete parsing and validation scope for the ISO Base Media File Format `edts/elst` edit list so subsequent parser
work can rely on an authoritative contract aligned with ISO/IEC 14496-12 §8.6 and previously archived movie (`mvhd`) and track
(`tkhd`) header metadata.

## 📦 Box Placement and Versioning

- `elst` is the sole defined child of the optional `edts` container. Multiple `edts` boxes are not expected; treat the first
  `elst` encountered under a track as authoritative and surface a warning if duplicates appear.
- The full box header supplies `version` and `flags` (flags are unused in the current standard and should be preserved but
  ignored by consumers).
- `entry_count` (32-bit unsigned) follows the header and determines how many edit records to parse. Large edit lists are valid
  and must stream without pre-allocation of all entries.
- Entry field widths depend on `version`:
  - **Version 0** uses 32-bit unsigned `segment_duration` and 32-bit signed `media_time`.
  - **Version 1** promotes both fields to 64-bit.
  - `media_rate` fields are always stored as a signed 16.16 fixed-point pair
    `{ media_rate_integer (S16), media_rate_fraction (U16) }`.

## 🧮 Field Semantics

- `segment_duration` is expressed in the **movie timescale** obtained from `mvhd`. It represents presentation time on the movie
  timeline that this edit occupies.
- `media_time` is expressed in the owning track’s **media timescale** from `mdhd` and identifies the first media sample to play
  within the edit. A value of `-1` indicates an empty edit: playback outputs silence/black for the specified duration and does
  not consume media samples.
- `media_rate` controls playback rate adjustments. The spec requires `media_rate_fraction == 0`; non-zero fractions should raise
  a diagnostics warning. `media_rate_integer` defaults to `0x0001` for normal playback. Values of `0` pause playback while
  advancing media time; negative values play in reverse and should flag unsupported-rate diagnostics in current builds.
- Empty edits that lead the list define presentation offsets; later segments advance the composed timeline. Trailing empty edits
  prolong presentation without consuming media and should be surfaced to consumers for trimming/diagnostics.

## 🔄 Parsing Workflow

1. Read `entry_count` and stream entries one at a time to avoid allocating unbounded arrays. Surface progress to downstream
   consumers immediately so UI and CLI exports can render partial results.
2. For each entry, normalize:
   - `segment_duration_seconds = segment_duration / mvhd.timescale`.
   - `media_time_seconds = media_time / mdhd.timescale` (skip normalization for empty edits where `media_time == -1`).
   - `media_rate` should be emitted as a signed double by dividing the fixed-point pair (`integer + fraction / 65536`).
3. Maintain cumulative movie timeline offsets to expose `presentation_start` and `presentation_end` for each edit entry. These
   values enable validation and UI timeline visualizations.
4. Preserve the raw fixed-point integers alongside normalized values so round-tripping to JSON exports retains fidelity.

## ✅ Validation & Diagnostics

- **Duration reconciliation:** Sum of all `segment_duration` values must match the movie duration (`mvhd.duration`) when both are
  expressed in the movie timescale. Report discrepancies greater than one movie timescale tick.
- **Track duration cross-check:** For non-empty edits, map each edit’s media span into track timescale units and verify the total
  aligns with the track duration from `tkhd`. Allow tolerance for disabled tracks (`tkhd.flags & 0x0001 == 0`).
- **Ordering:** Edits should be evaluated sequentially; overlapping media ranges imply reverse playback or incorrect authoring.
  Flag overlapping positive-rate edits as anomalies.
- **Empty edit handling:** Ensure leading empty edits do not push presentation start before zero. Trailing empty edits that extend
  past track duration should raise “padding beyond media” diagnostics.
- **Rate sanity:** Flag entries whose `media_rate_integer` is neither `0` nor `1`, or that supply non-zero fractions, as
  unsupported. Surface negative rates separately to guide future reverse playback support.
- **Duplicate `edts` boxes:** Emit a validation warning if multiple edit lists are present for a track.

## 🚦 Streaming & Memory Considerations

- Support incremental delivery by emitting each parsed entry immediately. Avoid buffering the entire list; large professional
  encodes can include thousands of edits for caption or trick-play streams.
- Clamp resource usage by recycling decode buffers and reusing fixed-point conversion helpers from existing header parsers.
- Ensure parser state tracks movie and media timescale references without repeatedly fetching them from shared registries.
- Provide hooks for cancellation: long edit lists parsed from network streams must respond promptly to upstream cancellation.

## 🔗 Dependencies & Follow-Up Work

- Requires movie timescale (`mvhd.timescale`) and duration (`mvhd.duration`) plus track duration and enabled flag from `tkhd`,
  and media timescale from `mdhd` to compute normalized spans.
- Downstream tasks:
  - **C14b** implements the concrete parser and data models.
  - **C14c** wires validations listed above into the diagnostics pipeline.
  - **C14d** refreshes fixtures, CLI exports, and snapshot baselines to cover edge cases enumerated here.

## 📚 Reference Materials

- ISO/IEC 14496-12 §8.6 — Edit List Box
- Archived context: `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/`,
  `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/`, and
  `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/` for timebase utilities.
