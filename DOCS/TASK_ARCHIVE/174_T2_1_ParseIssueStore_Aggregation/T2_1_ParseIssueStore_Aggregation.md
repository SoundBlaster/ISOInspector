# T2.1 ParseIssueStore Aggregation

## 🎯 Objective
Create the shared `ParseIssueStore` aggregate so tolerant parsing issues produced during streaming runs are captured once and exposed to CLI and SwiftUI consumers with real-time metrics.

## 🧩 Context
- Tolerance parsing roadmap promotes Task **T2.1** as the first corruption aggregation milestone, requiring a reusable store that records issues by node and byte range before downstream presentation work. [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- The PRD backlog highlights **T2 — Corruption aggregation** as the next focus to unlock tolerant summaries once ParsePipeline resiliency landed. [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- Integration notes specify a new `ParseIssueStore` observable object injected into `ValidationContext`, bridged through Combine, and queried by exports. [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)
- Feature analysis frames the store as a new core component that depends on the existing `ParseIssue` model and must publish issue metrics for UI ribbons and filtering. [`DOCS/AI/Tolerance_Parsing/FeatureAnalysis.md`](../AI/Tolerance_Parsing/FeatureAnalysis.md)

## ✅ Success Criteria
- `ParseIssueStore` records issues emitted by tolerant parsing pipelines, supports queries by node identifier and byte range, and publishes metrics summarizing severity counts and deepest affected depth.
- Streaming parse workflows pass a store instance through `ValidationContext`, ensuring CLI summaries and SwiftUI observers receive issue updates without additional bookkeeping.
- Unit and integration tests cover recording, querying, and metric computation paths, including concurrent issue emissions that drive UI refreshes.
- Documentation in backlog/workplan remains aligned, noting the In-Progress status and linking to this PRD for collaborators.

## 🔧 Implementation Notes
- Add `ParseIssueStore` under `Sources/ISOInspectorKit` as an `ObservableObject` with `@Published` issue collections, range- and node-based query helpers, and a lightweight `IssueMetrics` struct for summary ribbons. [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)
- Thread the store through `ParsePipeline` and `ValidationContext` so validators and traversal hooks register issues centrally instead of mutating `ParseTreeNode` arrays directly.
- Update the Combine bridge (`ParseTreeStore`, CLI capture utilities) to observe the new store and react to `@Published` metrics, preparing downstream tasks (CLI summary wiring, UI ribbons) without implementing them yet.
- Extend test targets with focused specs that validate recording order, query accuracy, and metrics math using corrupt fixture stubs introduced in tolerant parsing archives.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
