# Summary of Work — 2025-10-22

## Completed Tasks
- **E5 — Basic `stbl` Coherence Checks**
  - Extended VR-015 sample-table correlation to reconcile decoding-time (`stts`) and composition-offset (`ctts`) counts with sample sizes and chunk layouts.
  - Regenerated JSON exporter snapshots to capture the new table representations and validation signals.
  - Updated ParsePipeline live tests to assert VR-015 diagnostics on the `stsz` and `ctts` events that now emit them.

## Implementation Notes
- Added decoding-time and composition-offset table details to the JSON exporter and sample-table parser registry so downstream tooling can surface the correlated metadata.
- Refined `SampleTableCorrelationRule` to aggregate sample counts from time-to-sample and composition-offset boxes and compare them against sample sizes and chunk coverage.

## Tests
- `swift test`

## Follow-ups
- None; E5 validation coverage is complete and snapshots are up to date.
