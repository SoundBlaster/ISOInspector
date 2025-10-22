# Sample Encryption Parser Alignment — micro PRD

## Intent
Align the new `senc`/`saio`/`saiz` parser scaffolding with targeted unit tests so placeholder metadata is emitted consistently.

## Scope
- Kit: `BoxParserRegistry+MovieFragments`, `ParsedBoxPayload`, `BoxParserRegistry+DefaultParsers`, `JSONParseTreeExporter`
- CLI: None
- App: None

## Integration contract
- Public Kit API added/changed: `ParsedBoxPayload.Detail` now exposes `sampleEncryption`, `sampleAuxInfoOffsets`, and `sampleAuxInfoSizes` detail structs with range helpers.
- Call sites updated: Parser registry registration for `senc`/`saio`/`saiz` boxes uses the new detail accessors.
- Backward compat: Existing consumers continue to parse previous detail cases; JSON exporter keeps placeholders until D6B lands.
- Tests: `SencSampleEncryptionParserTests`, `SaioSampleAuxInfoOffsetsParserTests`, `SaizSampleAuxInfoSizesParserTests`

## Next puzzles
- [x] #D6B Surface sample encryption helper metadata in JSON/CLI/App outputs once formatting contracts are finalized.

## Notes
Build: `swift build && swift test`
