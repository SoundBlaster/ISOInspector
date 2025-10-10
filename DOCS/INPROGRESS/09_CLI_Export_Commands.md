# #9 — CLI Export Commands for JSON and Binary Captures

## 🎯 Objective

Implement dedicated `export-json` and binary capture commands in ISOInspectorCLI that wrap the ISOInspectorKit exporters so users can persist inspection results directly from the CLI.

## 🧩 Context

- Workplan task **D3** schedules the CLI export commands after the inspect/validate pipeline and kit exporters, with
  acceptance criteria around schema validation of generated
  files.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L32-L37】
- Functional requirement **FR-CLI-001** mandates that the CLI provide `export-json` and `export-report` commands alongside inspect/validate with documented help output.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L6-L18】
- ISOInspectorKit already exposes JSON and binary exporters from completed task **B6**, which smoke tests exercised in
  preparation for this CLI wiring.【F:DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/Summary_of_Work.md†L3-L21】
- The CLI runner still carries `@todo #9` where the export subcommands should be routed, confirming no overlapping work is in progress.【F:Sources/ISOInspectorCLI/CLI.swift†L51-L76】

## ✅ Success Criteria

- `isoinspector export-json <input> --output <file>` streams a parse tree into the JSON exporter and writes a deterministic document matching the schema used in kit round-trip tests.
- `isoinspector export-capture <input> --output <file>` persists a binary capture compatible with the kit reader, and the command reports the output path.
- Both export commands respect existing logging conventions (research log notices, validation summaries) and return
  non-zero exit codes on I/O or encoding failures.
- CLI help (`--help`) lists the new subcommands with brief usage examples, keeping inspect behavior unchanged.
- Add focused tests that invoke each command against fixture media, asserting file creation and re-import using
  ISOInspectorKit APIs.

## 🔧 Implementation Notes

- Reuse `ParseTreeBuilder` to collect streaming events before handing them to `JSONParseTreeExporter` and the capture encoder; share pipeline/environment wiring with existing inspect command paths.
- Provide symmetric option parsing for `--output` (defaulting to `<input>.isoinspector.json` / `.capture`) and validate that the destination path is writable before starting export work.
- Surface validation issues or exporter errors through `printError` and distinct exit codes so CI consumers can react programmatically.
- Consider future batch mode alignment by encapsulating export logic in reusable helpers that accept an array of files.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
- [`todo.md`](../../todo.md)
- [`Sources/ISOInspectorCLI/CLI.swift`](../../Sources/ISOInspectorCLI/CLI.swift)
