# B5 — VR-003 Metadata Comparison Rule

## 🎯 Objective

Implement validation rule VR-003 so the parser flags mismatches between parsed box version/flags and the MP4RA-driven
catalog, emitting warnings that propagate through CLI and UI pipelines.

## 🧩 Context

- Phase B task B5 requires delivering validation rules VR-001 through VR-006 after the streaming pipeline and catalog
  work completed in earlier milestones.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】
- VR-003 is specified to compare MP4RA metadata expectations against actual payload values and report any divergence as
  warnings.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L60-L67】
- The MP4RA-backed `BoxCatalog` is already wired into the parse pipeline, so metadata describing expected version/flags is available to the validation layer.【F:DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/Summary_of_Work.md†L3-L8】

## ✅ Success Criteria

- Parsing standard fixtures surfaces VR-003 warnings whenever the catalog provides version or flag expectations that
  differ from the file contents, and benign files remain
  warning-free.【F:Tests/ISOInspectorKitTests/ParsePipelineLiveTests.swift†L86-L109】
- Validation issues tagged with VR-003 appear in CLI output formatting and downstream consumers without regressions to
  existing VR-006 handling.【F:Tests/ISOInspectorKitTests/ParsePipelineLiveTests.swift†L83-L128】
- New or updated unit tests cover both matching and mismatching metadata scenarios to guard the rule’s behavior in
  future changes.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L80-L88】

## 🔧 Implementation Notes

- Extend `BoxValidator` to derive expected values from the catalog descriptor attached to `ParseEvent` metadata and compare against bytes read from the payload header; ensure truncated payloads emit warnings rather than crashing.【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L7-L80】
- Reuse or augment existing fixtures to exercise multiple boxes with catalog expectations (e.g., `tkhd`, `mdhd`) and confirm CLI/UI formatting includes the rule ID and descriptive messages.【F:Tests/ISOInspectorKitTests/ParsePipelineLiveTests.swift†L86-L109】【F:Tests/ISOInspectorCLITests/EventConsoleFormatterTests.swift†L1-L44】
- Keep the rule opt-in for boxes lacking metadata to avoid unnecessary I/O and align with the catalog integration
  guarantees from Task B4.【F:DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/Summary_of_Work.md†L3-L8】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
