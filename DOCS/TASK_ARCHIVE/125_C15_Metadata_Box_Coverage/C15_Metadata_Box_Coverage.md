# C15 Metadata Box Coverage

## 🎯 Objective

Implement baseline parsing and export coverage for QuickTime metadata boxes (`udta`, `meta` with handler metadata, `keys`, and `ilst`) so the CLI can surface simple string and integer tags while preserving handler mappings captured in prior handler parser work.

## 🧩 Context

- Phase C parser backlog escalated as P0+ blockers; metadata coverage is the last outstanding C-series baseline item.
- Prior tasks (`C5` handler parser, metadata planning archives) already define handler codes and expected relationships between `meta` and downstream `ilst` entries.
- CLI export pathways and fixture catalogs exist from earlier metadata integration and validation tasks.

## ✅ Success Criteria

- `BoxParserRegistry` registers parsers for `udta`, `meta`, `keys`, and `ilst` boxes with baseline decoding for UTF-8 strings and integer payloads documented in MP4RA.
- Handler mapping from the `meta` box correctly ties parsed `ilst` entries to the owning namespace (e.g., `mdta`, `mdir` Apple tags).
- CLI export output includes the decoded metadata pairs in JSON/terminal formats with regression fixtures refreshed.
- Unit and fixture tests cover representative tags (`©nam`, `©day`, integer values) and confirm graceful fallback for unsupported value types.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` utilities for version/flags handling in `meta`, `keys`, and `ilst` payloads; consult `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/` for handler constants.
- Leverage metadata planning artifacts (`DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/`, `08_Metadata_Driven_Validation_and_Reporting/`) to align exported field names and CLI formatting expectations.
- Ensure parsers emit structured warnings for unknown key types but do not block traversal.
- Update fixture generation scripts to include sample `udta/meta/ilst` structures and extend validation suites accordingly.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/`](../TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/)
- [`DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/`](../TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/)
- [`DOCS/TASK_ARCHIVE/08_Metadata_Driven_Validation_and_Reporting/`](../TASK_ARCHIVE/08_Metadata_Driven_Validation_and_Reporting/)
