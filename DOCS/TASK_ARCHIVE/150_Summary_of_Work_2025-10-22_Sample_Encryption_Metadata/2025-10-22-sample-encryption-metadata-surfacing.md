# Sample Encryption Metadata Surfacing — micro PRD

## Intent
Expose placeholder metadata from `senc`/`saio`/`saiz` boxes across JSON exports, CLI streaming output, and SwiftUI detail panes so users can locate encrypted payload scaffolding without decoding bytes.

## Scope
- Kit: `JSONParseTreeExporter`, `ParsedBoxPayload.Detail` structured encoders.
- CLI: `EventConsoleFormatter` summary output.
- App: `ParseTreeDetailView` encryption section, `ParseTreeNodeDetail.accessibilitySummary` updates.

## Integration contract
- Public Kit API added/changed: JSON structured payload now includes `sample_encryption`, `sample_aux_info_offsets`, `sample_aux_info_sizes` dictionaries with counts, sizes, and byte ranges.
- Call sites updated: CLI formatter emits short encryption summaries; SwiftUI detail view renders encryption rows with accessibility identifiers and labels.
- Backward compat: Existing payload consumers continue to parse; new keys are additive.
- Tests: `ParseExportTests.testJSONExporterIncludesSampleEncryptionMetadata`, `EventConsoleFormatterTests` coverage for encryption/aux info, `ParseTreeAccessibilityFormatterTests` sample encryption assertions.

## Next puzzles
- [x] Finalize D6.C regression fixtures and documentation to validate encryption metadata across end-to-end parses.

## Notes
Build: `swift test`
- Regression fixture: `sample-encryption-placeholder` (`Tests/ISOInspectorKitTests/Fixtures/Media/sample_encryption_metadata.txt`).
- Snapshot baseline: `Tests/ISOInspectorKitTests/Fixtures/Snapshots/sample-encryption-placeholder.json`.
