# H3 — JSON Export Snapshot Tests

## 🎯 Objective

Establish deterministic snapshot coverage for ISOInspectorKit's JSON export pipeline using representative fixture files
so schema or formatting regressions are detected automatically.

## 🧩 Context

- Execution Workplan Phase H identifies Task H3 as capturing snapshot tests after B6's exporters were
  delivered.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L93-L96】
- The detailed backlog keeps H3 open and now references this document for active
  planning.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L249-L250】
- Prior work from Task B6 introduced the JSON exporters and ParseTreeBuilder utilities required to serialize parse
  results.【F:DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/Summary_of_Work.md†L5-L20】

## ✅ Success Criteria

- Snapshot fixtures exist for at least one small MP4 sample per major track type (video, audio, metadata) covering
  nested containers and parsed fields.
- Running `swift test` exercises new snapshot cases that fail when JSON output changes unexpectedly.
- Snapshot baselines live alongside existing exporter tests with documentation on how to update them after intentional
  schema revisions.
- Tests run in CI without macOS-only requirements and complete within current suite timing targets.

## 🔧 Implementation Notes

- Reuse `ParseTreeBuilder` to generate deterministic tree structures from fixture parse events before exporting via `JSONParseTreeExporter`.
- Store JSON baselines in the Tests target using stable formatting (e.g., sorted keys, pretty-printed) to minimize
  churn.
- Cover both CLI-facing and Swift API entry points if they produce distinct export code paths; otherwise document why a
  single path suffices.
- Document snapshot update workflow in test comments to keep future contributors aligned with release readiness
  guidance.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules`](../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules)
