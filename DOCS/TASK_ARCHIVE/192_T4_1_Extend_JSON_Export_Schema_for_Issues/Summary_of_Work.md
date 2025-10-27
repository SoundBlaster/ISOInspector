# Summary of Work — T4.1 Extend JSON Export Schema for Issues

- Updated the JSON exporter to emit a `schema.version` descriptor (v2) whenever parse issues are present so tolerant payload consumers can detect the richer schema while strict-mode exports remain unchanged.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L17-L125】
- Added snapshot coverage for a tree containing zero, single, and multiple parse issues to guard the new schema fields and issue payload structure.【F:Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift†L17-L140】【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/tolerant-issues.json†L1-L74】
- Documented the schema bump for tolerant exports in the App manual and cleared the `T4.1` entry from the active next-tasks list.【F:Documentation/ISOInspector.docc/Manuals/App.md†L72-L79】【F:DOCS/TASK_ARCHIVE/192_T4_1_Extend_JSON_Export_Schema_for_Issues/next_tasks.md†L1-L6】

## Verification

- `swift test --filter JSONExportSnapshotTests`
