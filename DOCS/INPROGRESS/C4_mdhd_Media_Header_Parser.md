# C4 — Parse `mdhd` (Media Header) Boxes

## 🎯 Objective

Implement a concrete parser for `mdhd` (Media Header) boxes so the streaming pipeline, CLI exports, and SwiftUI detail panes surface creation/modification timestamps, media timescale, duration, and ISO-639-2/T language codes.

## 🧩 Context

- Master PRD highlights `mdhd` metadata as core movie tree coverage for Phase C parser work.
- The execution backlog treats remaining parser stubs (`mdhd`, `hdlr`, etc.) as urgent follow-ups after `FullBoxReader` adoption.
- `FullBoxReader` already provides the scaffolding to decode versioned fields for full boxes (see `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/`).

## ✅ Success Criteria

- `BoxParserRegistry` registers an `mdhd` parser that consumes the full box header via `FullBoxReader` and extracts:
  - creation and modification timestamps (32- or 64-bit based on version),
  - timescale and duration fields,
  - language code (converted from the packed 5-bit characters),
  - optional pre-roll or reserved fields documented in the PRD.
- Parser returns a `ParsedBoxPayload` that powers CLI JSON export and SwiftUI detail views with descriptive labels and byte ranges.
- Unit tests cover both version 0 and version 1 payload layouts, including malformed/short payload handling.
- Hex/detail UI reflects parsed values for representative fixtures without regressions in existing tests.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` to handle version/flags and derive the payload cursor.
- Use helper utilities (extend if necessary) to decode the 15-bit language code into a three-letter identifier.
- Add fixtures or targeted payload slices under `Tests/ISOInspectorKitTests` to validate both big and small sample values.
- Ensure `mdhd` parser gracefully returns `nil` when payload length is insufficient, matching registry conventions.
- After parser lands, update documentation/backlog entries to mark C4 complete and consider follow-up for `hdlr` parsing.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/`
