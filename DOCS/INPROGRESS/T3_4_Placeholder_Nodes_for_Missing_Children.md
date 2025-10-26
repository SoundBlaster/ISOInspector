# T3.4 Placeholder Nodes for Missing Children

## 🎯 Objective
Surface expected-but-absent structures in the parse tree by creating synthetic placeholder nodes that carry tolerant parsing issues, so operators can understand missing context and navigate directly to relevant hex ranges.

## 🧩 Context
- Extends the tolerant parsing roadmap captured in [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md), which calls for placeholder nodes once status metadata (T1.2) and integrity surfaces (T3.1–T3.3) are in place.
- UI behavior and parser touchpoints are outlined in section 9 of [`IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md), highlighting italicized labels, badges, and jump-to-hex affordances for placeholders.
- Placeholder heuristics are tracked in the PRD backlog ([`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)) and the feature analysis ([`FeatureAnalysis.md`](../AI/Tolerance_Parsing/FeatureAnalysis.md)), ensuring alignment with the overall corruption tolerance PRD.
- Coordinate with the contextual status labeling workstream (T3.5) so placeholder styling, severity badges, and copy blocks stay consistent across both tasks.

## ✅ Success Criteria
- Missing required children (e.g., `stbl` under `minf`, `tfhd` under `traf`) produce placeholder `ParseTreeNode` entries with `status == .corrupt`, attached `ParseIssue` metadata, and contextual copy in the detail pane.
- Tree outline renders placeholders with distinct styling (italic fourcc, muted row) and corruption badges that mirror the behavior established in T3.2.
- Selecting a placeholder surfaces guidance in the Integrity detail section plus a jump action into the hex viewer anchored to the parent range.
- Regression coverage includes a fixture with a removed `stbl` (or similar) and UI/unit tests asserting placeholder creation, issue propagation, and navigation hooks.

## 🔧 Implementation Notes
- Leverage the existing missing-child detection from validation (VR-001…VR-015) and tolerant parsing guardrails to synthesize `ParseTreeNode` instances without disrupting stream traversal.
- Extend `ParseIssueStore` or related aggregation to register placeholder issues so ribbon counts and Integrity panes remain accurate.
- Coordinate with the Integrity detail pane (T3.3) and contextual status labels (T3.5) to ensure placeholder guidance links back into the issue list, the upcoming Integrity tab (T3.6), and outline badges without duplicating copy.
- Keep accessibility affordances in mind: VoiceOver should announce the placeholder status and the suggested remediation, matching the keyboard shortcut regression expectations tracked in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing`](../AI/Tolerance_Parsing)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
