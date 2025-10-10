# B6 — JSON and Binary Export Modules

## 🎯 Objective

Implement reusable exporters in ISOInspectorKit that serialize parsed MP4 box trees to JSON and binary capture formats
so the CLI and UI can persist inspection results and reload them later.

## 🧩 Context

- Execution workplan task **B6** specifies adding JSON and binary export modules with regression tests, building on the

  streaming pipeline from **B3**. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】

- Functional requirement **FR-CORE-004** demands that parse results can be exported as JSON and binary captures that

  round-trip back into the tool. 【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L12-L16】

- The technical spec outlines `Core.Export` components (`JSONExporter`, `CaptureWriter`) that consume streaming events and snapshots. 【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L16-L36】

## ✅ Success Criteria

- Provide a public API in ISOInspectorKit that produces a deterministic JSON document containing each box’s fourcc,

  offsets, sizes, metadata, validation issues, and children.

- Implement a binary capture writer/reader pair that records the same event stream for lossless re-import without

  depending on JSON parsing performance.

- Add regression tests that export representative fixture parses, then reload them to verify structural parity with the

  live pipeline results.

- Ensure the CLI can invoke the exporters in smoke tests without regressions, preparing the path for D3 `export-json`/`export-report` commands.

## 🔧 Implementation Notes

- Reuse `ParseTreeStore.Builder` or a dedicated reducer to accumulate `ParseEvent` streams into a tree/snapshot model reusable by exporters.
- Define Codable models that mirror `ParseTreeNode` and `BoxDescriptor` so exported JSON preserves catalog metadata and validation issues.
- Store binary captures using a compact container (e.g., length-prefixed `ParseEvent` records encoded with `JSONEncoder` or `BinaryEncoder`) and document the format for later tooling.
- Tests should exercise multiple fixtures from `Tests/ISOInspectorKitTests/Fixtures` to cover fragmented, large `mdat`, and malformed scenarios.
- Expose convenience helpers so the CLI can request export output using an existing `ParsePipeline` without duplicating parsing logic.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
