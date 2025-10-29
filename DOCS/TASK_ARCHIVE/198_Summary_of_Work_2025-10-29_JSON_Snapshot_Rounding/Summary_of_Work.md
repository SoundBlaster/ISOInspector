# Summary of Work — 2025-10-29

## Completed Tasks
- **JSON Snapshot Determinism (Export/Tests)**: Added a shared `quantizedSeconds` utility and applied it throughout the edit-list exporter so all second-based values round to a fixed six-decimal precision before JSON encoding (`Sources/ISOInspectorKit/ISO/BoxParserRegistry+Utilities.swift`, `Sources/ISOInspectorKit/ISO/BoxParserRegistry+EditList.swift`). Updated the exporter’s JSON encoding to emit those rounded values via `Decimal`, eliminating macOS/Linux formatting drift and refreshed the affected fixture (`Tests/ISOInspectorKitTests/Fixtures/Snapshots/edit-list-multi-segment.json`).

## Verification
- `swift test --filter JSONExportSnapshotTests`

## Follow-ups
- Audit other exporter surfaces (e.g., time-to-sample, composition offsets) to confirm they benefit from the shared quantization helper and do not reintroduce cross-platform float drift.
