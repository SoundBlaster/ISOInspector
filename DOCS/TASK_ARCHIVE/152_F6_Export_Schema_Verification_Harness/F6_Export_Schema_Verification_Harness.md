# F6 — Export Schema Verification Harness

## 🎯 Objective
Establish automated coverage that locks down the proposed JSON export compatibility aliases and format summary fields before any production schema updates land.

## 🧩 Context
- The master PRD requires reliable JSON export capabilities that capture tree structure, offsets, sizes, and parsed fields for downstream tooling.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L5-L23】
- The execution workplan identifies the R5 Export Schema Standardization research as complete and directs the team to extend tests ensuring compatibility with Bento4 and FFmpeg outputs.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L16-L29】【F:DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/Summary_of_Work.md†L1-L13】
- Existing snapshot tests in `JSONExportSnapshotTests` protect current exporter structure and document the refresh workflow for intentional schema changes.【F:Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift†L5-L132】【F:DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/Summary_of_Work.md†L6-L12】

## ✅ Success Criteria
- New or updated `JSONExportSnapshotTests` cover fixtures that include the compatibility alias fields and format summary metadata proposed by R5, failing if output diverges from the agreed schema.【F:DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/R5_Export_Schema_Standardization.md†L51-L59】
- CLI-level regression coverage compares exported JSON against stored Bento4 and ffprobe baselines, confirming adapters remain byte-for-byte compatible on representative assets.【F:DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/R5_Export_Schema_Standardization.md†L57-L59】
- Snapshot regeneration workflow documentation stays accurate so future schema migrations follow the reviewed process.【F:DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/Summary_of_Work.md†L6-L12】

## 🔧 Implementation Notes
- Reuse the archived Bento4 and ffprobe fixture outputs captured during R5 analysis to seed comparison expectations for both unit and CLI integration tests.【F:DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/Summary_of_Work.md†L7-L13】
- Consider environment variables (e.g., `ISOINSPECTOR_REGENERATE_SNAPSHOTS`) and targeted test filters when refreshing baselines to limit the surface area of schema diffs.【F:Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift†L98-L112】
- Ensure CLI checks run in CI-friendly time by scoping fixtures to small canonical assets already tracked in the repository.【F:DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/Summary_of_Work.md†L7-L13】【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L1-L95】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
