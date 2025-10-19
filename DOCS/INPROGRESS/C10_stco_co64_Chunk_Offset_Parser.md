# C10 — `stco/co64` Chunk Offset Parser

## 🎯 Objective

Implement structured parsing for the `stco` (32-bit) and `co64` (64-bit) chunk offset tables so the inspector exposes accurate byte offsets for each media chunk across legacy and large-file assets.

## 🧩 Context

- Phase C baseline parsing work in [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md) elevates `stco/co64` to **P0+** priority because downstream sample table validation depends on correct chunk offsets.
- Existing parsers for `stsc` and `stsz/stz2` (archived under `DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser` and `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser`) already emit structured data; this task completes the trio needed for cross-table correlation planned in Validation Rule #15.
- The execution workplan (Phase C — Specific Parsers) currently lists C10 as the next urgent deliverable and lacks an
  active in-progress record.

## ✅ Success Criteria

- `ISOInspectorKit` gains decoders that handle both `stco` and `co64` payload layouts, respecting entry counts and integer width differences.
- Parsed offsets populate the box detail view and JSON export with correctly typed numeric values (UInt32 vs UInt64)
  while presenting a normalized Swift model for consumers.
- Fixtures covering small (<4 GiB) and large (≥4 GiB) files parse without overflow, and malformed tables (e.g., counts
  exceeding payload length) raise validation warnings consistent with Phase B guardrails.
- Automated tests assert the parser behavior for representative assets and snapshot exports update accordingly.

## 🔧 Implementation Notes

- Reuse the shared FullBox reading utilities introduced in `B5` to parse version/flags, ensuring 64-bit alignment for `co64` entries.
- Mirror the data model approach from `stsc`/`stsz` so sample table aggregation layers can iterate offsets alongside chunk run definitions.
- Coordinate with Validation Rule #15 planning notes in `DOCS/INPROGRESS/next_tasks.md` to document any additional metrics the rule will require (e.g., verifying chunk offsets are monotonically increasing).
- Update parser registry wiring and UI/CLI formatting helpers to surface human-readable offsets (decimal + hex) without
  double-counting memory-mapped base addresses.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- `DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser/`
- `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/`
