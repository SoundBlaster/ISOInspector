# E3 — Warn on Unusual Top-Level Ordering

## 🎯 Objective
Establish an advisory validation rule that surfaces when top-level boxes arrive in an unexpected order so CLI, JSON exports, and UI surfaces can point reviewers to potentially malformed packaging without blocking legitimate streaming layouts.

## 🧩 Context
- The execution backlog calls for an E3 task that warns on unusual top-level ordering as part of the validation phase, following the structural rules delivered in earlier iterations.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L221-L228】
- Existing validation rules VR-004 and VR-005 already enforce fatal/warning conditions around missing `ftyp` headers and `moov` placement; this advisory should build on the same event sequencing model rather than duplicating logic.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L64-L69】
- Task archive notes from the VR-004/VR-005 delivery describe how the validator tracks media boxes and streaming exceptions, providing implementation hooks and fixture coverage patterns to extend.【F:DOCS/TASK_ARCHIVE/13_B5_VR004_VR005_Ordering_Validation/13_B5_VR004_VR005_Ordering_Validation.md†L1-L36】

## ✅ Success Criteria
- Advisory diagnostics trigger when `moov`/`ftyp` ordering differs from common multiplexing layouts yet still passes existing VR-004/VR-005 checks, with tests confirming CLI and JSON export visibility.
- Configuration supports severity toggles so UI consumers can present non-blocking guidance distinct from structural errors.
- Regression fixtures cover baseline MP4, fragmented, and streaming-friendly orderings to avoid false positives, and documentation cross-links the new advisory to VR-004/VR-005 behavior.

## 🔧 Implementation Notes
- Reuse the validator state machine hooks that register top-level encounters and streaming signals, emitting a soft advisory when heuristics flag uncommon patterns.
- Plumb advisory messages through the existing validation payload so CLI/UI front-ends inherit the new signal without schema churn, augmenting JSON exports with a dedicated advisory code.
- Coordinate messaging with the VR-004/VR-005 archive to align terminology and recommended operator actions, ensuring the warning suggests reviewing packaging workflows rather than implying fatal corruption.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
