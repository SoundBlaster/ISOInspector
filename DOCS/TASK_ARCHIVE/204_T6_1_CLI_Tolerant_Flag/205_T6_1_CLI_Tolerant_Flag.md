# T6.1 — CLI Tolerant Parsing Flag

## 🎯 Objective
Allow `isoinspect` CLI users to opt into tolerant parsing so corruption diagnostics can be gathered without aborting the run, while keeping strict mode as the default for CI scripts.

## 🧩 Context
- The Corrupted Media Tolerance workplan calls for a `--tolerant` flag that toggles lenient parsing in the CLI to match the UI feature set, contingent on the existing `ParsePipeline.Options` infrastructure.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L121-L130】
- Parse pipeline options, validation rule dual-mode support, issue aggregation, and exports are already delivered, so the CLI can safely expose the toggle without waiting on additional backend work.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L24-L52】【F:DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/Summary_of_Work.md†L1-L28】
- No blockers are recorded in the active `blocked.md` log or the permanent blocker archive for CLI tolerance parity, so the task is ready to proceed.【F:DOCS/INPROGRESS/blocked.md†L1-L11】【F:DOCS/TASK_ARCHIVE/BLOCKED/README.md†L1-L16】

## ✅ Success Criteria
- `isoinspect` accepts a `--tolerant` (and inverse `--strict`) flag, defaulting to strict behavior when unspecified.
- CLI help text and documentation explain the tolerant mode, its defaults, and how it interacts with existing logging/export options.
- Tolerant runs surface corruption summaries (leveraging existing metrics) without regressing strict-mode exits or error codes.
- Regression tests cover tolerant flag parsing and ensure strict mode remains default for CI-friendly invocations.

## 🔧 Implementation Notes
- Extend the ArgumentParser command configuration to add mutually exclusive tolerant/strict flags, mapping into `ParsePipeline.Options` presets already shipped for the app/SDK.
- Wire the chosen mode into CLI execution so tolerant runs reuse `ParseIssueStore` summaries in final output.
- Refresh CLI documentation (DocC manual and `--help`) to describe the new switches and defaults.
- Add unit or integration tests in `ISOInspectorCLITests` exercising tolerant vs. strict invocations against corrupt fixtures.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
