# Summary of Work — C8 `stsc` Sample-To-Chunk Parser

## ✅ Completed Outcomes

- Registered a dedicated `stsc` parser in `BoxParserRegistry`, decoding full box headers, entry counts, and each sample-to-chunk tuple while capturing byte ranges for UI highlighting.
- Added the typed `ParsedBoxPayload.SampleToChunkBox` detail model so downstream surfaces (CLI export, UI) can consume structured `stsc` data and expose per-entry ranges.
- Hardened parsing against truncated payloads with status fields instead of throwing, ensuring validation can surface actionable errors.
- Updated JSON export snapshots to include the newly structured `stsc` output and introduced focused unit coverage in `StscSampleToChunkParserTests`.

## 🧪 Tests

- `swift test --filter StscSampleToChunkParserTests`
- `swift test --filter JSONExportSnapshotTests`
- `swift test`

## 🔜 Follow-Ups

- [ ] Cross-check `stsc` entries with `stco/co64` chunk offsets and `stsz/stz2` sample counts once those parsers are implemented so validation rules can flag inconsistencies.
