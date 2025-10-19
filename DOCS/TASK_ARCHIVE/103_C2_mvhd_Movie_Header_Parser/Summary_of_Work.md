# Summary of Work

## 2025-10-19 — C2 mvhd Movie Header Parser

### Completed Items

- Added a dedicated `mvhd` parser (`Sources/ISOInspectorKit/ISO/BoxParserRegistry.swift`) that decodes versioned timeline fields, normalized playback rate/volume, and the full 3×3 transformation matrix while guarding against truncated payloads.
- Introduced `ParsedBoxPayload.MovieHeaderBox` with a `TransformationMatrix` helper so downstream exporters and UI consumers can access normalized doubles for timescale, duration, rate, volume, and orientation metadata.
- Extended the JSON exporter (`Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift`) to emit structured `movie_header` payloads and refreshed the `baseline-sample.json` and `fragmented-stream-init.json` snapshots to cover the new schema.
- Strengthened unit coverage in `Tests/ISOInspectorKitTests/BoxParserRegistryTests.swift` (version 0/1 decoding and truncation handling) and regenerated exporter snapshots via `JSONExportSnapshotTests`.

### Tests & Validation

- `swift test` (all packages) — verifies parser behavior, exporter updates, and regenerated snapshots.

### Follow-Up Notes

- Downstream UI/export surfaces now receive normalized movie header metadata; future work can layer richer presentation
  or analytics using the new structured detail without additional parser changes.

## 2025-10-18 — C6 Codec Payload Planning

### Completed Items

- Documented the codec payload expansion roadmap covering Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H configuration boxes in `DOCS/INPROGRESS/C6_Codec_Payload_Additions.md`, including parser models, fixtures, and validation strategies.
- Updated `DOCS/INPROGRESS/next_tasks.md` to close the "Monitor upcoming codec payload additions" follow-up and point future implementation to dedicated puzzles.

### Tests & Validation

- No code changes were required for this planning task; validation will occur alongside future parser implementations.

### Follow-Up Notes

- Implementation work for each codec payload will spin up individual puzzles once fixtures are staged and failing tests
  are authored.
