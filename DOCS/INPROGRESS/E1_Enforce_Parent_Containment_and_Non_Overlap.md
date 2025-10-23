# E1 — Enforce Parent Containment and Non-Overlap

## 🎯 Objective
Ensure ISOInspector emits structural validation errors whenever a child box extends beyond its parent's byte range or overlaps neighbouring payload spans, keeping CLI and UI surfaces trustworthy for nested container layouts.

## 🧩 Context
- Execution workplan highlights E1 as the active follow-up to VR-001/VR-002, extending containment guarantees beyond the initial structural rules already shipped in Phase B.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L30-L43】
- Backlog TODO keeps E1 open to deliver full parent/child boundary enforcement so overlapping payloads are caught during parsing.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L225-L230】
- The technical spec mandates container iteration that respects declared sizes (VR-001/VR-002), providing the baseline data needed for stricter containment checks.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L52-L69】
- Prior research notes catalog scenarios in which malformed encryption metadata produced overlapping fragments, offering fixtures and reproduction context for validation updates.【F:DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md†L1-L24】

## ✅ Success Criteria
- Validation layer flags any child node whose computed end offset exceeds its parent's declared range or collides with sibling spans, emitting deterministic `.error` results.
- CLI reports and SwiftUI issue lists surface the new containment failures with actionable messaging while keeping parse sessions stable after detection.
- Regression coverage exercises positive (well-formed) and negative (overflowing/overlapping) fixtures across parser, validation, CLI, and UI layers.
- Documentation sources (`next_tasks.md`, workplan, PRD backlog) reflect the task's progress and completion status once shipped.

## 🔧 Implementation Notes
- Audit existing `BoxValidator`/`ValidationRuleContext` metadata to confirm start/end offsets are available per node; extend tracking to retain sibling cursor state for overlap detection.
- Implement containment accounting that accumulates consumed payload bytes per parent and compares each child header against both the parent's declared end and the running sibling boundary.
- Introduce targeted fixtures (or synthesize ones) that reproduce child overflow and overlap scenarios, wiring them into `ISOInspectorKit` tests and CLI snapshot assertions.
- Propagate new validation IDs through CLI formatting, JSON export annotations, and SwiftUI issue presenters so surfaces explain the error and highlight the offending node.
- Coordinate with validation preset defaults to ensure the new structural rule ships enabled and can be toggled consistently across app, CLI, and export pipelines.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md`](../TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md)
