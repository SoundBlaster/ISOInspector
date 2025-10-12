# D1 — Scaffold CLI Base Command

## 🎯 Objective

Create the initial `isoinspector` executable with a root command that prints help and wires shared configuration so future subcommands can reuse the streaming parser pipeline.

## 🧩 Context

- Follows the Phase D roadmap for ISOInspectorCLI, where the argument parser setup is the first required capability before implementing `inspect` and `validate` streaming commands.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L32-L36】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorCLI_PRD.md†L8-L13】
- Depends on the completed streaming engine from Phase B to expose reusable services when the CLI invokes
  inspections.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L15-L24】

## ✅ Success Criteria

- SwiftPM workspace defines an `ISOInspectorCLI` target that builds a runnable tool.
- Running `isoinspector --help` lists the base command description and planned subcommands placeholder(s).
- Command-line entry point shares logging/telemetry hooks with existing packages without regressing existing tests.

## 🔧 Implementation Notes

- Add a `swift-argument-parser` dependency if not already declared and register the root `ParsableCommand` for `isoinspector`.
- Structure the command hierarchy to accept global options (e.g., verbosity, output format) that downstream subcommands
  can extend.
- Introduce smoke tests or fixtures that execute the command with `--help` to guard the interface contract.
- Update documentation and planning artifacts once scaffolding is merged so Task D2 can focus solely on streaming
  behavior.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspectorCLI_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorCLI_PRD.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
