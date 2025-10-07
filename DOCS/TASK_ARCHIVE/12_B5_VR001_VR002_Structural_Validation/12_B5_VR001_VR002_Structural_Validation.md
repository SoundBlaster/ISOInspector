# 12 — B5 Structural Validation (VR-001 & VR-002)

## 🎯 Objective

Deliver the remaining structural validation rules VR-001 and VR-002 so the streaming parser raises fatal errors when box
headers declare impossible sizes or containers fail to close at their declared boundaries.

## 🧩 Context

- Phase B task B5 in the execution workplan calls for implementing validation rules VR-001 through VR-006 once the

  streaming pipeline is in place.【../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md】

- The technical specification defines VR-001 and VR-002 as core integrity checks that must stop parsing when header

  sizes are invalid or container byte counts drift.【../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md】

- Root `todo.md` item #3 tracks VR-001, VR-002, VR-004, and VR-005 as the next critical backlog entries now that VR-003 and VR-006 are wired through `BoxValidator`.【../../todo.md】
- `ParsePipeline.live()` already enriches events with metadata and feeds them through `BoxValidator`, making it the natural integration point for new structural rules.【../../Sources/ISOInspectorKit/ISO/ParsePipeline.swift】【../../Sources/ISOInspectorKit/Validation/BoxValidator.swift】

## ✅ Success Criteria

- VR-001 emits an error-level `ValidationIssue` whenever a box header’s declared size is smaller than its header length or cannot fit within the remaining file range, and parsing skips forward safely.
- VR-002 emits an error-level `ValidationIssue` when container boxes consume fewer or more bytes than their declared payload before closing, ensuring downstream code cannot assume structural integrity.
- Unit tests cover normal, undersized, oversized, and truncated scenarios for both rules, including regression fixtures

  that exercise nested containers and large-size headers.

- Integration tests confirm the streaming pipeline yields VR-001/VR-002 issues through `ParsePipeline.live()` without crashing, and CLI/UI consumers receive the propagated errors.

## 🔧 Implementation Notes

- Extend `BoxValidator` with dedicated rule types for VR-001 and VR-002, leveraging header metadata (`payloadRange`, `endOffset`) and the existing stack context to track container entry/exit offsets.
- For VR-002, maintain per-depth accounting (e.g., a stack or dictionary keyed by box identity) so `didFinishBox` events can verify consumed byte counts against declared sizes before emitting errors.
- Ensure rules differentiate between hard errors (stop parsing container subtree) versus warnings; VR-001 and VR-002 should mark issues as `.error` and allow the walker to continue with best-effort resynchronization.
- Update diagnostics logging if additional context (offsets, expected vs. actual sizes) will aid VR-006 research logs

  and CLI reporting.

- Mirror new behavior in DocC or README snippets if developer guidance references available validation rules.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
- [`todo.md`](../../todo.md)
