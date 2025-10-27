# T4.2 — Plaintext Integrity Issue Export

## 🎯 Objective
Create a human-readable text export that summarizes tolerant parsing issues alongside key file metadata so operators can share integrity results without JSON tooling.

## 🧩 Context
- Builds on the tolerant parsing exports delivered in [`DOCS/TASK_ARCHIVE/192_T4_1_Extend_JSON_Export_Schema_for_Issues/`](../TASK_ARCHIVE/192_T4_1_Extend_JSON_Export_Schema_for_Issues/).
- Requirements captured in [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md) under Phase T4 — Diagnostics Export.
- Align output structure with Integrity tab design notes in [`DOCS/INPROGRESS/T3_6_Integrity_Summary_Tab.md`](T3_6_Integrity_Summary_Tab.md) so export rows match UI sorting/filtering capabilities.

## ✅ Success Criteria
- Export command (UI and CLI) offers a plaintext option that writes a UTF-8 report summarizing file metadata (path, size, analysis timestamp) followed by each `ParseIssue` grouped by severity.
- Report includes issue code, severity, affected node path, and byte range offsets using the tolerant parsing metadata already aggregated by `ParseIssueStore`.
- Automated tests verify the plaintext export for representative fixtures matches stored baselines and handles files with zero issues.

## 🔧 Implementation Notes
- Reuse the shared export pipeline introduced for JSON exports (`ParseIssueStore.makeIssueSummary()`); extend it with a formatter that produces deterministic plain text.
- Ensure metadata fields match forthcoming T4.3 requirements (size, hash, timestamp) to avoid duplicate work—placeholder fields may remain TODOs if the hash work is deferred.
- Wire the new export option into the Integrity tab’s Share menu and the CLI `isoinspector export` command, mirroring the JSON option naming.
- Add DocC and README snippets explaining when to prefer plaintext reports and how they differ from JSON payloads.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
