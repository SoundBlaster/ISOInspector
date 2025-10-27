# T4.1 — Extend JSON Export Schema for Issues

## 🎯 Objective
Add tolerant parsing diagnostics to the exported JSON schema so every node serializes its collected `ParseIssue` records alongside existing metadata.

## 🧩 Context
- `CorruptedMediaTolerancePRD.md` calls for parity between on-device diagnostics and exported artifacts so QC teams can review corruption reports offline.
- `ParseIssue` metadata and `ParseTreeNode` status fields already flow through the tolerant pipeline; exports currently omit this data, leaving CLI/automation users without corruption insight.
- Prior phases (T1.x, T2.x) delivered the data structures (`ParseIssue`, `ParseIssueStore`, metrics snapshots) that this task must surface in the JSON export layer.

## ✅ Success Criteria
- JSON exports include an `issues` collection for each node with severity, reason code, byte range, and human-readable description.
- Schema/version documentation updated so downstream consumers can detect tolerant-mode payloads.
- Golden-file snapshot tests cover nodes with zero, single, and multiple issues to prevent regressions.
- Strict mode exports remain byte-for-byte compatible when no issues are present.

## 🔧 Implementation Notes
- Extend `ExportedNode`/`JSONExportEncoder` structures in `ISOInspectorKit` to encode tolerant fields conditionally.
- Ensure `ParseIssueStore` lookups remain efficient for large trees; reuse existing query helpers where possible.
- Update DocC and README snippets only if schema changes require public documentation refresh (coordinate with F6 harness if snapshots change).
- Consider forward compatibility by gating new fields behind a schema version bump and documenting fallback behavior for older consumers.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md`](../AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
