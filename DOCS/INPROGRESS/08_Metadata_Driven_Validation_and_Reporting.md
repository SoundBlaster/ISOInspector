# Extend MP4RA Metadata into Validation and Reporting

## 🎯 Objective

Deliver validation and reporting enhancements that use the MP4RA-backed metadata already emitted by `ParsePipeline.live()` so downstream components surface human-readable context and catch metadata mismatches early.

## 🧩 Context

- Task B4 integrated the MP4RA catalog into the streaming pipeline, enabling each parse event to carry descriptive

  metadata for known boxes and logging unknown types for research
  follow-up.【F:DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/Summary_of_Work.md†L5-L16】

- The technical specification defines validation rule VR-003, which compares version and flag fields against MP4RA data,

  and outlines how the event stream feeds validation chains and CLI/UI reporting

layers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L63】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L64-L83】

- Execution workplan phase B prioritizes metadata-aware validation immediately after the streaming pipeline, ensuring

  downstream features inherit the enriched catalog context without
  delay.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L30】

## ✅ Success Criteria

- Validation layer inspects MP4RA metadata (e.g., expected version/flags) and raises rule VR-003 warnings when stream

  events diverge from catalog definitions.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L52-L67】

- CLI and future UI reporters display box names, descriptions, and validation outcomes sourced from the catalog for each

  emitted event.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L33-L63】

- Unknown or stale MP4RA entries are surfaced as research issues with enough context to update the catalog refresh

  workflow documented in task R1.【F:DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/Summary_of_Work.md†L9-L26】

## 🔧 Implementation Notes

- Extend validation pipeline to attach MP4RA-derived descriptors to `ParseEvent` results and implement rule handlers that compare event payloads against catalog expectations before raising issues.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L67】
- Update CLI reporting utilities to render descriptive names and validation summaries; capture follow-up requirements

  for SwiftUI consumers while maintaining streaming performance

guarantees.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L63】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L30】

- Coordinate with archived B4 notes for catalog structure and refresh automation guidance when designing fallback

  logging and stale entry detection

logic.【F:DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/B4_MP4RA_Metadata_Integration.md†L1-L36】【F:DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/07_R1_MP4RA_Catalog_Refresh.md†L5-L44】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
