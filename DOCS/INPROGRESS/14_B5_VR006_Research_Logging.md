# B5 VR-006 Research Logging

## 🎯 Objective

Implement research logging for validation rule VR-006 so unknown or catalog-missing boxes encountered during streaming
parses are persisted for follow-up analysis across CLI and UI workflows.

## 🧩 Context

- Execution workplan task **B5** calls for finishing validation rules VR-001 through VR-006 once the streaming pipeline

  is available, and VR-006 is the remaining research-focused follow-up.

- Recent archive notes highlight the need to pair VR-006 logging with CLI/UI metadata consumers so ordering and catalog

  insights propagate downstream.

- The technical specification defines VR-006 as recording unknown box types in a research log and treating the findings

  as info-level issues.

## ✅ Success Criteria

- Unknown or catalog-missing boxes encountered by the parser append deduplicated entries (fourcc, path, offsets) to a

  persistent research log file accessible to subsequent CLI/UI runs.

- CLI surface: `validate`/`inspect` commands expose flags or default behavior to enable VR-006 logging and confirm log file location, with tests proving log entries are emitted.
- UI surface: metadata consumers receive VR-006 research entries alongside validation issues so warnings and info events

  remain visible in tree/detail panes.

- Documentation in TODO/PRD trackers updated to reflect VR-006 logging availability and guidance for analysts.

## 🔧 Implementation Notes

- Reuse or extend existing diagnostics logging infrastructure to capture VR-006 events without blocking streaming

  throughput; ensure async-safe writes.

- Coordinate storage location and format (e.g., JSONL or CSV) so CLI and UI share the same research log schema and

  dedupe strategy.

- Validate behavior with fixtures that include unknown fourcc entries and catalog mismatches to guarantee VR-006 issues

  propagate through CLI/UI pipelines.

- Review prior VR-004/VR-005 ordering work to ensure logging preserves ordering context for downstream analysis.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
