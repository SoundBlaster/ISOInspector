# Route Export Operations to Streaming Capture Utilities

## 🎯 Objective

Enable the `isoinspector export` subcommand to stream parse events through the shared `ISOInspectorCLIEnvironment` and produce JSON or binary capture artifacts without relying on the legacy `ISOInspectorCLIRunner` implementation. This keeps the new ArgumentParser entry point aligned with the CLI export requirements from the product backlog.

## 🧩 Context

- The CLI PRD calls for export functionality that saves parse results in structured formats alongside inspect/validate

  behaviors.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorCLI_PRD.md†L4-L15】

- Legacy exports already stream parse events, build parse trees, and write JSON or capture files inside `CLI.handleExportCommand`, demonstrating the expected flow for the new command surface.【F:Sources/ISOInspectorCLI/CLI.swift†L342-L414】
- The modern Swift ArgumentParser command set implements `inspect` and `validate`, but the `export` command still throws a placeholder exit pending migration to the shared streaming capture utilities.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L49-L183】
- Prior streaming command work (Task D2) identified routing export operations through the shared utilities as the

  remaining follow-up for completing the CLI
  migration.【F:DOCS/TASK_ARCHIVE/42_D2_Streaming_CLI_Commands/Summary_of_Work.md†L5-L16】

## ✅ Success Criteria

- `isoinspector export` accepts the target media path (and optional output overrides) and streams events using `ISOInspectorCLIEnvironment.parsePipeline`, writing JSON trees or capture files via the existing exporters.【F:Sources/ISOInspectorCLI/CLI.swift†L342-L405】【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L171-L183】
- Output paths mirror the legacy defaults (e.g., `.isoinspector.json` and `.capture`) while validating writability and emitting success/error messaging consistent with other subcommands.【F:Sources/ISOInspectorCLI/CLI.swift†L347-L409】
- Tests cover the new `export` subcommand end-to-end, including success cases and error propagation, ensuring `swift test` exercises both JSON and capture flows.【F:DOCS/TASK_ARCHIVE/42_D2_Streaming_CLI_Commands/Summary_of_Work.md†L5-L11】

## 🔧 Implementation Notes

- Lift option parsing and default-path logic from the legacy runner into reusable helpers or directly into `Commands.Export`, adapting them to async execution while avoiding duplicated semaphore patterns.【F:Sources/ISOInspectorCLI/CLI.swift†L342-L414】
- Reuse `ParseTreeBuilder`, `JSONParseTreeExporter`, and `ParseEventCaptureEncoder` to build outputs, wiring them through `ISOInspectorCommandContext` so the environment remains swappable for tests.【F:Sources/ISOInspectorCLI/CLI.swift†L383-L405】【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L20-L183】
- Update CLI help text and DocC command reference once the export subcommand is functional, aligning documentation with

  the PRD requirements.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L216-L227】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
