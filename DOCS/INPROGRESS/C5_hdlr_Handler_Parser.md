# C5 — Implement `hdlr` Handler Parser

## 🎯 Objective

Introduce a concrete parser for the ISO BMFF `hdlr` (handler reference) box so media, metadata, and streaming contexts expose handler type and name details across the CLI, SwiftUI detail panes, and JSON exports.

## 🧩 Context

- Aligns with the Phase C parser backlog and MVP checklist that still flags the `hdlr` parser as outstanding.
- Builds on the `FullBoxReader` helper introduced in Task B5 and the recently completed `mdhd` parser wiring to populate media header data.
- Enables downstream UI and export layers to surface handler metadata alongside timing information, as called for in the

  master PRD’s movie tree requirements.

## ✅ Success Criteria

- `BoxParserRegistry` registers a `hdlr` parser that extracts handler type, subtype, and name strings using the shared `FullBoxReader` for `(version, flags)`.
- Parsing representative fixtures populates structured data for movie (`mdia/hdlr`) and metadata (`meta/hdlr`) boxes, with unit tests covering text vs. null-terminated names.
- Streaming pipeline, CLI exports, and SwiftUI detail panes render handler metadata without regressions (update

  snapshots or fixtures if required).

- Documentation and backlog entries referencing the missing `hdlr` parser are updated to reflect active work and eventual completion.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` to consume the header, then parse `pre_defined`, `handler_type`, `reserved` fields, and the UTF-8/Pascal name as described in ISO/IEC 14496-12.
- Extend the `HandlerType` model (if present) or introduce a lightweight wrapper to expose common handlers (`vide`, `soun`, `hint`, `mdir`, etc.) referenced by the master PRD.
- Ensure the parser gracefully handles null-terminated names and empty strings, matching expectations in Bento4 sample files located under `DOCS/SAMPLES`.
- Update the `BoxParserRegistry` default parser map and any JSON/export schema translations so handler information is preserved end-to-end.
- Add or refresh tests in `Tests/ISOInspectorKitTests` that read known fixtures and assert handler metadata is emitted, keeping CI coverage green.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
