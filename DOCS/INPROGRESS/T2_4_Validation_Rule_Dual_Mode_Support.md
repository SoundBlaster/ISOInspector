# T2.4 — Validation Rule Dual-Mode Support

> ✅ **Status:** Completed — tolerant parses now record VR-001…VR-015 diagnostics via `ParseIssueStore`. See `Summary_of_Work.md` for verification notes.

## 🎯 Objective

Ensure validation rules VR-001 through VR-015 emit `ParseIssue` diagnostics whenever tolerant parsing is enabled while preserving strict-mode exception behavior for regression parity.

## 🧩 Context

- Phase T2 of the tolerance parsing plan calls for extending validation rules after `ParseIssueStore` and event streaming landed, with T1.1/T1.3 already complete and T2.3 awaiting design handoff.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L46-L67】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L246-L255】
- The integration guide recommends introducing a shared `ValidationContext.handleIssue(_:)` helper so every rule respects the tolerance options and records issues via the shared store.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L174-L198】
- Research notes highlight this refactor as a medium-risk dependency gating UI and export work, emphasizing consistent dual-mode behavior across all rules.【F:DOCS/AI/Tolerance_Parsing/ResearchSummary.md†L168-L185】

## ✅ Success Criteria

- Strict mode continues to throw the existing validation errors, while tolerant mode records equivalent `ParseIssue` entries without halting traversal.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L174-L198】
- Unit and integration tests demonstrate both behaviors across the full rule suite, ensuring downstream UI, CLI, and export flows receive issues through the shared store.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L189-L198】
- Documentation in backlog sources reflects the in-progress status so dependent UI ribbon and export tasks can sequence correctly.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L46-L67】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L246-L255】

## 🔧 Implementation Notes

- Introduce the helper on `ValidationContext` to centralize tolerance-mode branching, updating each VR-001…VR-015 implementation to call it before throwing or recording issues.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L174-L198】
- Audit rule-specific tests to cover strict and tolerant permutations, expanding fixtures if necessary to capture error vs. issue flows.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L189-L198】
- Coordinate with future metrics and UI ribbon work so the emitted issues carry severity codes aligned with `ParseIssueStore.metrics()` expectations.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L46-L58】【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L199-L214】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
