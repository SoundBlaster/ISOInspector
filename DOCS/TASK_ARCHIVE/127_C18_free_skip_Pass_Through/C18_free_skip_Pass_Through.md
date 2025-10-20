# C18 — `free/skip` Opaque Pass-Through

## 🎯 Objective

Ensure the parsing pipeline recognizes `free` and `skip` boxes, treating them as opaque padding segments while preserving offsets and lengths for downstream consumers (UI tree, CLI exports, validation hooks).

## 🧩 Context

- Phase C baseline backlog identifies `free/skip` handling as the remaining gap for core box coverage.
- Master PRD requires baseline parsers to recognize padding boxes so streaming views and exports remain faithful to

  source structure.

- Existing streaming pipeline (`BoxParserRegistry`, `ISOInspectorKit`) already supports pass-through nodes for other opaque boxes such as `mdat`.

## ✅ Success Criteria

- Register a parser (or stub) that emits `ParseEvent` entries for `free` and `skip` types without attempting to decode payloads.
- Preserve byte range metadata (start offset, size) so UI/CLI presentations list padding regions accurately.
- Add fixture coverage ensuring mixed content (`free` interleaved with metadata/data boxes) surfaces correctly in JSON exports and tree snapshots.
- Document handling expectations for future validation rules (e.g., skipping structural checks for padding boxes).

## 🔧 Implementation Notes

- Extend `BoxParserRegistry` with entries for `free` and `skip`, reusing existing opaque-box utilities where possible (compare with `mdat`).
- If no fixtures currently exercise padding boxes, author lightweight synthetic samples via existing fixture tooling for

  regression coverage.

- Verify CLI JSON output includes nodes with type `free`/`skip`, size, and offsets while omitting payload fields.
- Update UI preview/sample data only if necessary; ensure Combine-backed stores accept the new node types without

  additional work.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
