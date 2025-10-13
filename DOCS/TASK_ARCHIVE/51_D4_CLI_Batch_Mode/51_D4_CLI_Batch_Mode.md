# D4 — CLI Batch Mode Summary Export

## 🎯 Objective

Deliver batch processing for `isoinspector` so a single invocation can analyze multiple media files, print an aggregated summary, and write the results to CSV, extending the streaming CLI built in Task D2.

## 🧩 Context

- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) prioritizes Task D4 to "create batch mode processing with aggregated summary + CSV export" once D2 is complete.
- [`02_Product_Requirements.md`](../AI/ISOInspector_Execution_Guide/02_Product_Requirements.md) requirement **FR-CLI-002** mandates batch mode support with a tabular summary saved to CSV for automation flows.
- The master PRD describes `ISOInspectorCLI` as a core deliverable alongside the parser and app experiences, reinforcing the need for parity with GUI validation flows.

## ✅ Success Criteria

- CLI accepts multiple input files (paths, directory globs, or explicit lists) and processes them sequentially using the

  existing streaming pipeline, producing a consolidated summary table.

- Summary output includes per-file path, size, parse/validation status, box counts, and aggregates that match the table

  expectations noted in the product requirements.

- CSV export flag writes the aggregated table to disk with headers so CI systems can consume the batch results, while

  the textual summary mirrors the CSV content.

- Exit code selection reflects aggregate success/failure: any failed parse or validation yields a non-zero batch exit

  status suitable for CI gating.

## 🔧 Implementation Notes

- Reuse Task D2 command plumbing for `inspect`/`validate` to minimise duplication; introduce a dedicated batch subcommand or flag (e.g., `validate --batch --report summary.csv`).
- Implement a result accumulator type that collects per-file metrics and produces both console table and CSV rows.

  Ensure data model aligns with FR-CLI-002 expectations and is extensible for future metrics (timings, warnings).

- Add integration tests covering mixed-success batches, CSV emission, and glob expansion where supported. Tests should

  validate deterministic ordering and exit codes.

- Coordinate with documentation updates (CLI manual, help text) so usage instructions reflect new batch capabilities.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`02_Product_Requirements.md`](../AI/ISOInspector_Execution_Guide/02_Product_Requirements.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
