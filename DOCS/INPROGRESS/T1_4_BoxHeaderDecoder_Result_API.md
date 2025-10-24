# T1.4 — BoxHeaderDecoder Result Refactor

## 🎯 Objective
Enable tolerant parsing flows to capture malformed header diagnostics without halting iteration by refactoring `BoxHeaderDecoder` to return `Result<BoxHeader, BoxHeaderDecodingError>` values instead of throwing.

## 🧩 Context
- Aligns with Phase T objectives for corrupted media resilience, specifically the T1 core parsing resiliency roadmap. See the tolerance parsing workplan for task definitions and acceptance guidance.
- Builds on previously completed ParseIssue modeling and tolerant pipeline wiring, ensuring the decoder surfaces errors that downstream callers can translate into `ParseIssue` records rather than immediate failures.
- Supports PRD commitments to continue parsing damaged files while flagging structural issues, preventing abrupt termination during sibling traversal.

## ✅ Success Criteria
- `BoxHeaderDecoder` exposes a non-throwing API that conveys malformed header conditions via a typed error and preserves successful decoding semantics.
- Call sites capture failure cases, attach `ParseIssue` metadata with appropriate severity and byte ranges, and continue iterating within the parent box boundaries.
- Regression test coverage demonstrates tolerant mode continues after malformed headers while strict mode behavior remains unchanged.
- Documentation or inline guidance clarifies how the new API participates in the broader tolerance parsing pipeline and future tasks (T1.5+).

## 🔧 Implementation Notes
- Audit decoder entry points across ISOInspectorKit (parsing pipeline, registry helpers) to ensure each path handles the new `Result` contract.
- Coordinate with upcoming tasks (T1.5–T1.7) so error propagation, boundary clamps, and progress guards share consistent error typing and issue reporting.
- Extend or introduce focused unit tests simulating truncated or oversize headers to verify tolerant parsing emits issues and advances to the next sibling box.
- Preserve ABI/API stability for strict-mode callers by offering convenience wrappers if necessary, but prefer internal adoption of the `Result`-based API to avoid double handling.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
