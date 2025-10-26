# T3.5 Contextual Status Labels

## 🎯 Objective
Deliver contextual status chips in the outline and detail inspector so operators immediately understand whether a node is invalid, empty, corrupted, partial, or trimmed when tolerant parsing surfaces issues.

## 🧩 Context
- Builds on the tolerant parsing UI roadmap tracked in [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md), which calls for status-aware UI affordances after issues and badges are in place.
- Satisfies the "contextual issue states" requirement from the corrupted media tolerance PRD so users can distinguish missing boxes from malformed payloads at a glance.
- Complements the `ParseTreeNode.status` metadata introduced with tolerant parsing, ensuring UI surfaces align with the forthcoming Integrity summary flows.

## ✅ Success Criteria
- Outline rows render status labels with severity-aware colors and accessible text for nodes flagged as invalid, empty, corrupted, partial, or trimmed.
- Detail inspector mirrors the status label near existing corruption sections, keeping copy targets and VoiceOver announcements consistent.
- Status presentation updates automatically as `ParseIssueStore` emits changes, with snapshot/UI tests planned under T5 verifying the bindings.

## 🔧 Implementation Notes
- Reuse the badge styling conventions established in T3.2 for consistent typography, spacing, and accessibility hooks.
- Confirm `ParseTreeNode.status` transitions align with issue severities defined in tolerant parsing integration notes to avoid mismatched labels.
- Coordinate with the upcoming Integrity summary tab (T3.6) so the same status language propagates into aggregated issue listings and exports.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing`](../AI/Tolerance_Parsing)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
