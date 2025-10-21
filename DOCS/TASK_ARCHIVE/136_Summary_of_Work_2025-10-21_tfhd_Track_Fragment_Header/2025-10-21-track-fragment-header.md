# Track fragment header parsing — micro PRD

## Intent
Expose structured parsing for `tfhd` so fragment run metadata includes track defaults across Kit, CLI, and JSON export surfaces.

## Scope
- Kit: `BoxParserRegistry+MovieFragments`, `ParsedBoxPayload`, `JSONParseTreeExporter`
- CLI: `EventConsoleFormatter`
- App: n/a (CLI coverage and parse tree exporter touched shared Kit APIs)

## Integration contract
- Public Kit API added/changed: `ParsedBoxPayload.Detail.trackFragmentHeader`, `ParsedBoxPayload.TrackFragmentHeaderBox`
- Call sites updated: CLI `EventConsoleFormatter`, JSON exporter snapshot fixture
- Backward compat: additive parsing and formatting; existing fields remain intact
- Tests: `TfhdTrackFragmentHeaderParserTests`, updated CLI formatter tests, regenerated JSON snapshot (`Tests/ISOInspectorKitTests/Fixtures/Snapshots/dash-segment-1.json`)

## Next puzzles
- [ ] #D3 Parse `tfdt` and `trun` boxes plus aggregate `traf` container metadata (see @todo in `BoxParserRegistry+MovieFragments.swift`).

## Notes
Build: `swift test`
