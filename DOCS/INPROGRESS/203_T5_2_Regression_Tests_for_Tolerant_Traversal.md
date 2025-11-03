# T5.2 — Regression Tests for Tolerant Traversal

## 🎯 Objective
Deliver regression coverage that proves the tolerant parsing pipeline continues walking the box tree after corruption, records the documented `ParseIssue` entries, and surfaces the expected warnings across stores and exports.

## 🧩 Context
- Phase T5 of the Corrupted Media Tolerance roadmap moves from fixture creation (T5.1) into automated validation of tolerant behavior.
- The corrupt fixture corpus landed in Task T5.1 under `Fixtures/Corrupt/` with manifest guidance in `Documentation/FixtureCatalog/corrupt-fixtures.json`.
- Parse issue aggregation and metrics (Tasks T2.1–T2.4) already power UI ribbons and CLI summaries; we now need regression tests to ensure they stay accurate when traversal continues past bad nodes.
- No hardware or licensing blockers apply; blocked work currently only affects real-world codec assets per `DOCS/INPROGRESS/blocked.md`.

## ✅ Success Criteria
- New XCTest coverage exercises at least one truncated, overlapping, and malformed-header fixture from the corrupt corpus using tolerant pipeline options.
- Each test asserts that traversal continues beyond the corrupt node, verifies the emitted `ParseIssue` reason codes/ranges, and checks aggregate metrics (counts/depth) remain consistent with the manifest expectations.
- CLI- or exporter-facing smoke tests (snapshot or textual) confirm tolerant runs produce warnings without aborting, preventing regressions in future UI/CLI wiring.

## 🔧 Implementation Notes
- Extend `Tests/ISOInspectorKitTests/ParsePipelineLiveTests.swift` or add a dedicated `TolerantTraversalRegressionTests` suite to stream corrupt fixtures with `.tolerant` options and assert continued event emission.
- Reuse manifest expectations from `Documentation/FixtureCatalog/corrupt-fixtures.json` to drive table-based tests so fixtures and assertions stay synchronized.
- Leverage `ParseIssueStore` metrics (`makeIssueSummary()` and `metricsSnapshot()`) plus existing CLI snapshot harnesses to validate aggregated warnings without duplicating exporter logic.
- Ensure strict-mode control coverage remains unchanged by adding paired assertions that `.strict` runs still throw/abort as documented.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus`](../TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus/Summary_of_Work.md)
