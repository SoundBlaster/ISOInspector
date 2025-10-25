# Next Tasks

- 🚀 **T2.4 — Validation Rules Emit Parse Issues in Lenient Mode** _(In Progress — enabling dual-mode diagnostics)_:
  - Refactor validation rules VR-001…VR-015 to emit `ParseIssue` records when tolerant parsing is enabled while preserving strict-mode exceptions.
  - Coordinate with the shared validation helper proposed in the tolerance parsing integration notes so downstream consumers receive consistent issue payloads.
- 🎯 **T2.3 — Aggregate Parse Issue Metrics for UI and CLI Ribbons** _(Pending design handoff)_:
  - Extend `ParseIssueStore` aggregation to expose per-severity counts for tolerant parsing dashboards and streaming summaries.
  - Coordinate with design deliverables noted in `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` to confirm ribbon layout requirements.
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(Blocked — pending hardware)_:
  - Schedule macOS and iPadOS hardware verification to confirm focus command menus announce controls and restore focus targets. Reference `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.
- ⏳ **Real-World Assets** _(Blocked — awaiting licensing approvals)_:
  - Secure Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so regression baselines can shift from synthetic payloads once approvals land.
- 🎨 **Tolerant Parsing — Surface Issue Metrics in SwiftUI** _(Pending design sign-off)_:
  - Surface `ParseIssueStore` metrics in SwiftUI ribbons once tolerant parsing UI specs are finalized. Track via `@todo PDD:45m` in `Sources/ISOInspector/Stores/ParseTreeStore.swift` and the open item in `todo.md`.
