# B4 — Integrate MP4RA Metadata Catalog

## 🎯 Objective

Bundle the official MP4 Registration Authority (MP4RA) box metadata into the parser so box names, categories, and
fallback descriptions are available during streaming parse operations.

## 🧩 Context

- Execution workplan task **B4** (Phase B — Core Parsing Engine) requires loading an MP4RA-sourced catalog after the
  streaming parser (B3) is in place.
- Master PRD sections on "Box Parsing (Generic)" and "Metadata" call for friendly names, descriptions, and logging for
  unknown boxes to aid inspectors and downstream UIs.
- Prior task B3 established the event pipeline, so this task focuses on enriching metadata and graceful fallback
  behavior.

## ✅ Success Criteria

- MP4RA catalog JSON is bundled with the Swift package and can be loaded without network access.
- Parser emits box events annotated with human-readable names and categories when entries exist.
- Unknown or missing entries log structured fallback records compatible with the existing research log (per VR-006 note
  in workplan).
- Unit tests cover catalog loading, lookup hits, and fallback paths for unknown box types.

## 🔧 Implementation Notes

- Confirm format of MP4RA dataset (fourcc, description, grouping) and normalize into lightweight JSON for runtime
  lookup.
- Provide a registry service that the streaming pipeline consults while emitting events; avoid heavy allocations to
  maintain streaming performance.
- Reuse existing logging infrastructure so CLI/UI layers receive consistent metadata without additional coupling.
- Ensure dependency injection or configuration points allow catalog updates without code changes (e.g., versioned JSON
  asset).

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant research in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
