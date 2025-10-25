# T3.1 — Tolerant Parsing Warning Ribbon

## 🎯 Objective
Implement the non-modal corruption warning ribbon in the SwiftUI app shell so tolerant parsing issue metrics surface immediately after a parse completes.

## 🧩 Context
- Aligns with the tolerance parsing rollout defined in [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../../AI/Tolerance_Parsing/IntegrationSummary.md#user-interface).
- Delivers the UI counterpart to the metrics aggregation from [`DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/`](../184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/Summary_of_Work.md).
- Replaces the blocking load-failure banner behavior described in the master PRD (`AppShellView` load flow) within [`DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`](../../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md).

## ✅ Success Criteria
- Ribbon displays whenever `ParseIssueStore.metricsSnapshot().totalCount > 0`, summarizing error and warning counts plus deepest affected depth.
- Tapping the ribbon focuses the forthcoming "Integrity" tab or equivalent diagnostics destination.
- VoiceOver announces the ribbon with severity and action affordances, matching accessibility notes in the tolerance parsing PRD.
- Existing document loading and layout flows remain regression-free (no overlap with navigation bars, supports light/dark mode).

## 🔧 Implementation Notes
- Introduce a dedicated SwiftUI component (e.g., `CorruptionWarningRibbon`) that accepts `IssueMetrics` snapshots supplied by `ParseTreeStore`.
- Ensure `ParseTreeStore` publishes ribbon-ready metrics (likely via `@Published var issueMetrics: IssueMetrics`) so the view updates live during streaming parses.
- Provide dismissal persistence (`UserDefaults`/`AppStorage`) hook as outlined in the integration summary to respect user preference to hide the ribbon after acknowledgement.
- Coordinate text, color tokens, and iconography with the UI guidelines in [`DOCS/AI/Tolerance_Parsing/FeatureAnalysis.md`](../../AI/Tolerance_Parsing/FeatureAnalysis.md#ui-implications) and maintain consistency with existing warning styles.
- Update previews and add at least one SwiftUI preview exercising mocked metrics for design review; extend UI tests or snapshot baselines if available.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../../RULES)
- [`DOCS/TASK_ARCHIVE`](..)
