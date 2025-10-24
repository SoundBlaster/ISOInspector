# T1.5 — Propagate Decoder Failures Through Tolerant Parsing

## 🎯 Objective
Enable the streaming container walker to treat `BoxHeaderDecoder` failures as recoverable events by emitting `ParseIssue` records on the active node and resuming iteration without aborting tolerant parses.

## 🧩 Context
- Builds directly on Tasks T1.2–T1.4 from the Corrupted Media Tolerance plan (`DOCS/AI/Tolerance_Parsing/TODO.md`), which introduced issue-capable tree nodes and a `Result`-based header decoder.
- Aligns with tolerant parsing goals outlined in the master PRD (`DOCS/AI/ISOViewer/ISOInspector_Master_PRD_Full/ISOInspector_Master_PRD.md`) and the execution workplan (`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`).
- Must preserve strict-mode behavior described in the PRD backlog (`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`) and existing validation pipelines.

## ✅ Success Criteria
- Decoder failures encountered during container iteration attach a `ParseIssue` to the current node with reason code, byte range, and severity, matching the acceptance test bullets in `DOCS/AI/Tolerance_Parsing/TODO.md` (T1.5).
- After logging the issue, iteration advances to the next sibling using the parent boundary without infinite loops or duplicate traversal.
- Existing strict parsing flows remain unchanged; unit and integration tests for strict mode continue to pass.
- New regression coverage demonstrates tolerant continuation for at least one malformed header fixture (e.g., truncated size, `exceedsParent`).

## 🔧 Implementation Notes
- Update the streaming walker (`StreamingBoxWalker.walk` and related helpers) to switch on the `Result` returned by `BoxHeaderDecoder` and translate failures into `ParseIssue` instances via the tolerant parsing options.
- Ensure parent-range arithmetic leverages the existing forward-progress guard from Task B3 so tolerant mode cannot re-read the same offsets when a header is rejected.
- Extend tolerant parsing tests to cover skipped headers and placeholder nodes, referencing corrupt fixture notes in `DOCS/TASK_ARCHIVE/167_T1_4_BoxHeaderDecoder_Result_API/` and follow-ups captured in `DOCS/AI/Tolerance_Parsing/ResearchSummary.md`.
- Confirm CLI/app integrations that depend on header iteration continue to surface nodes in order, updating snapshots only when intentional.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- Relevant historical context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
