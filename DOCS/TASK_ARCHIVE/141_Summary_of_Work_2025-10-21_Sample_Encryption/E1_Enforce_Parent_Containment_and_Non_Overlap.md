# E1 — Enforce Parent Containment and Non-Overlap

## 🎯 Objective
Establish structural validation that guarantees every parsed child box stays fully within its parent's byte range and that the parser never emits overlapping container spans.

## 🧩 Context
- The technical spec outlines VR-001 and VR-002 as the foundation for size checks, and this task extends those guarantees to full parent/child containment accounting for nested containers and continuation after recovery.
- The core PRD highlights validation as a high-priority capability for ISOInspectorCore, reinforcing that structural integrity is essential before higher-level UX and export features.

## ✅ Success Criteria
- Validation pipeline detects when a child box's declared end exceeds its parent's boundary or when cumulative child spans surpass the parent's payload.
- Parser gracefully records and reports non-overlap violations without crashing, enabling CLI and UI consumers to surface errors.
- Unit and integration tests cover overlapping/overflowing child scenarios across representative fixtures.
- Documentation trackers (`next_tasks.md`, workplan, backlog) remain aligned with task status and outcomes.

## 🔧 Implementation Notes
1. Audit existing `BoxValidator` and streaming parser metrics to confirm available offset metadata for parent/child comparisons.
2. Introduce containment accounting that tracks active parent ranges and flags violations as `.error` issues when children overrun or overlap siblings.
3. Extend fixture set or synthesize targeted samples (e.g., truncated child boxes) to exercise new detection paths and assert emitted validation issues.
4. Wire validation outputs into CLI/UI surfaces, ensuring regression suites assert both messaging and continued parse stability after errors.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`ISOInspectorCore_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorCore_PRD.md)
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
