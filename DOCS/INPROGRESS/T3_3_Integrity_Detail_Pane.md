# T3.3 Integrity Detail Pane

## 🎯 Objective
Deliver a dedicated "Corruption" section in the inspector detail pane so investigators can review tolerant parsing diagnostics for the selected node without leaving the primary workflow.

## 🧩 Context
- Builds on tolerant parsing UI roadmap item T3.3 captured in `DOCS/AI/Tolerance_Parsing/TODO.md` and the integration notes for the detail inspector in `DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`.
- Extends the SwiftUI inspector pane introduced in `Sources/ISOInspector/Views/DetailView.swift`, alongside the existing `CorruptionBadge` work from Task T3.2.
- Aligns with the corruption reporting expectations in the master PRD integrity experience sections (`DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`).

## ✅ Success Criteria
- Selecting a node with `ParseIssue` entries reveals a "Corruption" section summarizing each issue (severity icon, error code, message, byte range).
- Byte offsets, lengths, and reason codes are copyable via standard text selection or explicit copy actions.
- Issue rows expose affordances to jump to the associated hex range or open follow-up actions when available.
- VoiceOver announces the section heading and each issue row with severity context and actionable hints, matching accessibility guidance from prior tolerant parsing tasks.

## 🔧 Implementation Notes
- Introduce a dedicated `CorruptionIssueSection` (or similar helper) used by `DetailView` when `!node.issues.isEmpty` to render a structured list.
- Reuse `CorruptionIssueRow` presentation patterns established in the badge work, ensuring severity color tokens and iconography remain consistent across tree and detail pane.
- Wire callbacks so tapping "View in Hex" (or analogous action) forwards to the existing hex jump mechanism in `DocumentVM`/`NodeVM` without breaking strict mode behavior.
- Audit copy/paste affordances: confirm `Text` views use selectable/copyable styles on macOS and provide context menu actions on iPadOS.
- Capture preview coverage with representative corrupt fixtures and note any additional test harness updates needed for tolerant parsing snapshots.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
