# T1.7 — Finalize Traversal Guard Requirements

## 🎯 Objective
Codify the forward-progress, depth, and issue-budget rules that tolerant parsing
must obey so traversal never hangs or explodes resource usage while still
emitting actionable `ParseIssue` diagnostics.

## 🧩 Context
- The Corrupted Media Tolerance initiative requires lenient traversal to make
  progress even when child sizes are malformed, but guardrails are needed to
  prevent infinite loops and stack exhaustion.【F:DOCS/AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md†L1-L108】
- Earlier tasks (T1.1–T1.6) delivered issue recording, tolerant options, and
  binary range clamps; T1.7 supplies the remaining progress heuristics before UI
  and CLI consumers can rely on guard metadata.【F:DOCS/TASK_ARCHIVE/170_T1_6_Implement_Binary_Reader_Guards/Summary_of_Work.md†L1-L10】【F:DOCS/AI/Tolerance_Parsing/TODO.md†L25-L104】
- Execution planning lists T1.7 as the final blocker for tolerant parsing before
  aggregation and presentation work picks up.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L44】

## ✅ Success Criteria
- Guard catalogue defines minimum progress budgets, zero-length retry limits,
  recursion caps, and per-frame issue ceilings with rationale linked to fixture
  behaviour and fuzzing goals.【F:DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md†L9-L64】
- Acceptance plan enumerates fixtures, fuzz harnesses, and regression tests that
  must pass once guards are implemented, preventing hangs while preserving valid
  traversal output.【F:DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md†L82-L111】
- API notes specify new `ParseIssue` codes and `ParsePipeline.Options` knobs so
  downstream consumers can present guard violations consistently.【F:DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md†L66-L80】
- Follow-up tasks capture implementation, fixture generation, UI/CLI wiring, and
  telemetry hooks so engineering can execute without additional clarification.【F:DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md†L113-L122】

## 🧠 Source References
- [`Traversal_Guard_Requirements.md`](../AI/Tolerance_Parsing/Traversal_Guard_Requirements.md)
- [`CorruptedMediaTolerancePRD.md`](../AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md)
- [`Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
