# T6.2 — CLI Corruption Summary Output

## 🎯 Objective
Expose tolerant parsing metrics in the `iso-inspector-cli` output so operators can immediately understand corruption severity without opening the UI.

## 🧩 Context
- Task T6.2 in the tolerance parsing roadmap calls for surfacing counts by severity plus deepest affected depth in CLI output, building on the aggregation work from T2.3. Recent integration guidance sketches the desired format and messaging for the corruption summary block.
- `ParseIssueStore.metricsSnapshot()` and `makeIssueSummary()` were delivered in Task T2.3 to provide formatter-ready data for both UI ribbons and CLI parity.
- The CLI currently emits basic counts (boxes, duration) but omits lenient-mode diagnostics even after the `--tolerant` flag from Task T6.1.

## ✅ Success Criteria
- CLI analysis output prints corruption summary lines (errors, warnings, info, deepest affected depth) whenever lenient mode encounters recorded issues.
- Strict-mode runs exit unchanged while tolerant-mode runs without issues continue to omit the summary block.
- Unit or snapshot tests cover representative outputs: strict success, lenient with no issues, lenient with mixed-severity issues.
- Documentation (help text or usage examples) references the new summary block.

## 🔧 Implementation Notes
- Extend the CLI formatter to query `ParseIssueStore` metrics after analysis completes; ensure formatting stays deterministic for snapshot tests.
- Reuse the existing `ParseIssueSummary` types introduced by T2.3 instead of duplicating aggregation logic.
- Gate summary emission on tolerant mode or presence of issues to avoid altering strict-mode ergonomics.
- Update CLI tests (likely under `Tests/ISOInspectorCLITests`) or introduce new ones mirroring the format outlined in the integration summary.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)
- [`DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons.md`](../TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons.md)
