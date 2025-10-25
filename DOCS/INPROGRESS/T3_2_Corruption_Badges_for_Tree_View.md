# T3.2 Corruption Badges for Tree View Nodes

## 🎯 Objective

Highlight corrupt or degraded structures directly inside the outline tree so operators can triage tolerant parsing results without leaving their navigation workflow.

## 🧩 Context

- Tolerance Parsing PRD emphasizes surfacing corruption signals in primary navigation surfaces before the Integrity tab is built out.
- Master PRD calls for SwiftUI tree affordances that reveal validation warnings and corruption cues alongside node metadata.
- T3.1 warning ribbon already summarizes tolerant parsing metrics; this task extends the signal into each node so the ribbon links to actionable entry points.

## ✅ Success Criteria

- Every `TreeNodeView` entry with one or more `ParseIssue` records renders a corruption badge with severity color consistent with the warning ribbon palette.
- VoiceOver announces the badge state (e.g., "Corrupted, 2 issues") and the badge is keyboard focusable.
- Hover tooltips (macOS) and secondary detail affordances (iPadOS) show a short issue summary sourced from `ParseIssueStore`.
- Unit/UI preview coverage demonstrates badges for at least error, warning, and info severities without regressing healthy nodes.

## 🔧 Implementation Notes

- Reuse `ParseIssueStore.metricsSnapshot()` and tolerant parsing ribbon color tokens to keep severity styling consistent.
- Extend the outline item view model to expose aggregated issue counts so SwiftUI views stay declarative.
- Coordinate badge layout with existing selection, disclosure, and icon affordances to avoid clipping on compact width (iPad split view).
- Consider adding lightweight snapshot previews for corrupt fixtures under `Documentation/Previews` to aid accessibility reviews.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
