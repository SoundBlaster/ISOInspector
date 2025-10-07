# B4 Follow-Up Planning — Catalog Integration Coverage

## 🎯 Objective

Outline the concrete follow-up tasks unlocked by the MP4RA catalog integration so the parser, validators, and downstream
consumers gain full metadata-aware coverage and fallbacks.

## 🧩 Context

- Task B4 in the execution workplan prioritizes integrating the MP4RA metadata catalog once streaming parse events are
  in place, and highlights the need for graceful handling of unknown
  boxes.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L30】
- The technical specification describes how `ParsePipeline` should consult `BoxCatalog` to enrich events and enable validation/reporting layers to surface descriptive metadata.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L40】
- The PRD backlog calls for metadata-driven validation and reporting so CLI/UI surfaces human-readable context and
  captures mismatches against MP4RA
  definitions.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L73】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L70-L108】

## ✅ Success Criteria

- Produce a prioritized checklist of downstream B4 follow-up tasks (tests, fallbacks, consumer updates) with
  dependencies and expected artifacts.
- Identify required fixtures and catalog scenarios (standard, UUID, unknown types) and document how they will be
  exercised in automation.
- Specify how validation and reporting layers (CLI/UI/export) should consume catalog metadata, including acceptance
  signals for graceful degradation when descriptors are missing.
- Capture any open risks or external research needed before implementation begins.

## 🔧 Implementation Notes

- Leverage existing `ParsePipeline.live()` event coverage to define integration test hooks for metadata assertions and fallback logging.
- Coordinate with validation rule backlog (VR-003, VR-006) so catalog mismatches and unknown box tracking align with
  success criteria.
- Call out tooling or data needs (e.g., fixture MP4 files with custom UUID boxes) and whether new scripts must be added to `scripts/`.
- Ensure proposed follow-ups map cleanly to workplan phases (e.g., B4 extensions before B5 validation or D2 CLI wiring)
  to maintain dependency order.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
