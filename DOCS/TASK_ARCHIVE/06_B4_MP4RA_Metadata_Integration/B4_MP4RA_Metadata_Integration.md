# B4 — MP4RA Metadata Integration

## 🎯 Objective

Bundle and expose MP4RA box metadata so the streaming parse pipeline can label known boxes and flag unknown types for
follow-up.

## 🧩 Context

- Phase B task B4 in the execution workplan requires loading the MP4RA catalog after the streaming pipeline foundation

  from B3 is complete.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L19】

- The technical specification assigns `Core.Metadata` ownership for the catalog and describes `ParsePipeline` consulting the catalog when emitting events.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L33】
- VR-003 and VR-006 depend on authoritative metadata to verify version/flags and log unknown boxes for research

  continuity.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L60-L67】

## ✅ Success Criteria

- MP4RA registry JSON (or generated data) is bundled or fetched and loaded by the core catalog during pipeline

  startup.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L19】

- Known box events attach human-readable metadata (name, description, version flags) sourced from MP4RA.
- Unknown boxes trigger structured logging or research hooks without crashing parsing, satisfying VR-006

  expectations.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L60-L67】

- Unit and integration tests cover catalog loading, lookup by FourCC/extended types, and fallback behavior.

## 🔧 Implementation Notes

- Start from `ISOInspectorCore` by creating a `BoxCatalog` backed by MP4RA data; consider generating Swift structures from registry JSON for compile-time safety.
- Ensure catalog access is concurrency-safe since `ParsePipeline` operates asynchronously; an actor or immutable structure can meet this requirement.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L69-L73】
- Provide diagnostics for missing or stale catalog entries and document the process for updating MP4RA data (aligning

  with research gap R1).

- Extend existing fixtures or add new MP4 samples to validate metadata coverage and unknown box handling.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
