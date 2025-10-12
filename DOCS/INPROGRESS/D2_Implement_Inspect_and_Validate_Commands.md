# D2 — Implement `inspect` and `validate` commands

## 🎯 Objective

Deliver streaming-powered `inspect` and `validate` subcommands for the `isoinspector` CLI so users can parse media files, surface incremental parse events, and receive validation summaries with correct exit codes.

## 🧩 Context

- Builds on the CLI scaffold from Task D1, which established the executable target and root command interface.
- Aligns with the Execution Workplan mandate for Task D2 to provide streaming output that processes sample fixtures
  end-to-end.
- Supports the CLI PRD focus on the Inspect and Validate feature slices that were waiting on the streaming pipeline.

## ✅ Success Criteria

- `isoinspector inspect <file>` streams parse events for reference fixtures without regressions, printing structured output that mirrors the JSON contract defined in the CLI PRD.
- `isoinspector validate <file>` aggregates validation results and exits with status `0` on success and non-zero on failure, matching the acceptance criteria in the workplan.
- Commands share the established streaming infrastructure (`ParsePipeline`, validation rules VR-001 through VR-006) and remain responsive on large files.
- Integration tests cover success and failure flows for both commands using representative fixtures and enforce exit
  code expectations.

## 🔧 Implementation Notes

- Reuse the `swift-argument-parser` scaffolding from Task D1 to define subcommands, options (e.g., output format toggles), and shared configuration flags.
- Hook into `ParsePipeline` to stream `inspect` output, leveraging the follow-up TODOs to consume events and surface telemetry while avoiding blocking the UI/app roadmap.
- For `validate`, bridge the existing validation engine so streaming events can update aggregate status while emitting user-facing diagnostics.
- Ensure logging/telemetry toggles and export hooks called out in the follow-up TODOs remain compatible with future CLI features (`export`, batch processing).
- Maintain parity with CLI PRD formatting expectations (structured JSON, human-readable summaries) to keep downstream
  documentation accurate.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`ISOInspectorCLI_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorCLI_PRD.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
