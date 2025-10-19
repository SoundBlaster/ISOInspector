# Summary of Work — Codec Metadata Extraction

## Completed Tasks

- **C6 — Extend the `stsd` sample description parser with codec-specific field extraction.** Added dedicated parsers for `avcC`, `hvcC`, and `esds` payloads plus protection metadata so CLI exports and UI detail panes surface codec profiles, NAL unit lists, AAC AudioSpecificConfig, and Common Encryption defaults.
- **C16.1–C16.3 — Codec configuration backlog.** Closed the outstanding `avcC`, `hvcC`, and `esds` milestones in `ISOInspector_PRD_TODO.md`, keeping documentation in sync with the new parser coverage.

## Implementation Notes

- Expanded `BoxParserRegistry` to enumerate codec-specific metadata, including SPS/PPS/VPS lengths, HEVC constraint flags, AAC object type and sampling frequency, and `tenc` encryption defaults threaded from `sinf/schi` boxes.
- Added targeted unit tests in `StsdSampleDescriptionParserTests` to cover AVC, HEVC, AAC, and encrypted sample entries, and refreshed the baseline JSON snapshot to validate the richer payload output.

## Verification

- `swift test` (includes JSON export snapshots and codec metadata regressions)

## Follow-Ups

- Monitor future codec payload additions (e.g., Dolby Vision-specific boxes, additional descriptor extensions) and
  extend the registry when new fixtures arrive.
