# T3.5 Contextual Status Labels

## 🎯 Objective
Surface contextual status labels (Invalid, Empty, Corrupted, Partial, Trimmed) in both the outline tree and detail inspector so tolerant parsing metadata is actionable at a glance.

## 🧩 Context
- Builds directly on tolerant parsing metadata published via `ParseTreeNode.status` (Task T1.2) and the placeholder node affordances from T3.4, ensuring corrupted or missing structures communicate severity consistently.
- Aligns with the tolerant parsing UI roadmap documented in [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md) and the Phase T3 objectives in the master PRD to keep outline, Integrity pane, and exports synchronized.
- Feeds the upcoming Integrity summary pass (T3.6) and existing issue ribbons by reusing shared copy, colors, and accessibility semantics.

## ✅ Success Criteria
- Outline rows display localized, color-coded status chips for nodes flagged as invalid, empty, corrupted, partial, or trimmed, meeting contrast and VoiceOver labeling guidance.
- Detail inspector presents the same status chip near the corruption guidance block, keeping copy and announcements in sync across panes.
- Status chips respond to `ParseIssueStore` updates without manual refresh, preserving tolerant parsing live-update behavior and snapshot baselines.

## 🔧 Implementation Notes
- Reuse badge styling foundations from the T3.2/T3.4 outline work (spacing, typography, accessibility modifiers) to avoid regressions.
- Confirm status-to-severity mapping matches tolerant parsing definitions in the execution workplan and archived T3.4 notes before hard-coding colors or labels.
- Coordinate with the Integrity tab (T3.6) and export ribbons so any shared components or strings live in `ISOInspectorUI` modules rather than ad-hoc view code.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE/190_T3_4_Placeholder_Nodes_for_Missing_Children`](../TASK_ARCHIVE/190_T3_4_Placeholder_Nodes_for_Missing_Children)
