# E2 — Detect Zero/Negative Progress Loops

## 🎯 Objective
Ensure the streaming parser always makes forward progress by detecting zero- or negative-advance iterations and enforcing a safe maximum nesting depth so malformed media cannot hang parsing or exhaust resources. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L61-L65】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L229-L234】

## 🧩 Context
- Structural validation requirements already demand overflow checks, containment guarantees, and explicit progress safeguards for every parsed box. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L61-L65】
- The detailed backlog highlights Task E2 as the remaining guard-rail to finish the validation phase, keeping parity with the random-access pipeline and UI consumers that rely on deterministic event streaming. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L102-L119】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L229-L234】
- Reliability and security non-functional requirements emphasize deterministic behavior and bounded resource usage, both of which hinge on preventing infinite loops and runaway recursion. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L90-L94】

## ✅ Success Criteria
- Parsing any fixture or fuzzed input must either complete or emit a structured validation error without entering an infinite loop or exceeding the configured depth budget.
- New unit and regression tests cover zero/negative-size boxes, malicious `largesize` combinations, and degenerate container nesting, failing if progress guards or depth caps are bypassed.
- CLI, UI, and JSON export smoke tests continue to succeed, demonstrating that the added guards do not regress legitimate deep hierarchies.
- Logging or diagnostics clearly communicate when progress limits are triggered so follow-up fixture triage can occur quickly.

## 🔧 Implementation Notes
- Extend the streaming parser loop (within `BoxParser` and any iterator helpers) to track the previous offset and assert monotonic advancement before reading the next header.
- Introduce a centralized maximum-depth constant shared by kit, CLI, and UI targets so guard rails remain consistent across entry points.
- Surface guard failures through existing validation error plumbing, aligning with VR-001/VR-002 behavior while avoiding noisy duplication for already-covered bounds checks.
- Augment regression coverage with targeted fixtures or synthetic payloads that intentionally stall progress, ensuring the guard rails trip during automated testing.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Any relevant archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
