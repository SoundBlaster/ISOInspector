# C1 — `ftyp` Box Parser

## 🎯 Objective

Implement a streaming parser for the `ftyp` (File Type) box that extracts `major_brand`, `minor_version`, and the ordered `compatible_brands` array so downstream validation and UI layers can display compatibility metadata.

## 🧩 Context

- Phase C "Specific Parsers" backlog prioritizes `ftyp` decoding as a P0 requirement for the parser milestone, ensuring brand metadata is surfaced early in the tree view and exports.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L181-L205】
- VR-004 ordering validation depends on correctly identifying the first `ftyp` occurrence, so the parser must integrate with the existing registry and streaming pipeline from Tasks B1–B5.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L20-L49】【F:DOCS/TASK_ARCHIVE/13_B5_VR004_VR005_Ordering_Validation/13_B5_VR004_VR005_Ordering_Validation.md†L5-L35】

## ✅ Success Criteria

- `BoxParserRegistry` registers a concrete `ftyp` parser that emits typed field values for `major_brand`, `minor_version`, and every `compatible_brand` detected in payload order.
- Parsing logic handles payload lengths that are not multiples of four gracefully, rejecting malformed brand lists via

  existing validation pathways.

- Snapshot/fixture coverage exercises representative MP4 samples to verify decoded values and confirm JSON exports

  surface the new metadata fields.

- CLI and UI layers surface decoded `ftyp` metadata without regressions in streaming order validation.

## 🔧 Implementation Notes

- Reuse shared `RandomAccessReader` utilities for big-endian four-character codes and integers introduced in Tasks B1–B3.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L20-L34】
- Extend the streaming parser event model to attach a structured payload (e.g., `FtypBox`) while preserving existing node construction behavior.
- Update JSON export schemas and any UI detail presenters to include the new fields; coordinate with existing snapshot

  tests to capture schema evolution.

- Consider future codec inference hooks that combine `ftyp` brand data with `stsd` codecs, documenting extension points for follow-up tasks noted in the backlog.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L52-L62】【F:todo.md†L40-L44】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
