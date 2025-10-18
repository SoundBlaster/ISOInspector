# G6 — Export JSON Actions

## 🎯 Objective

Enable ISOInspector to export the parsed box tree as JSON—either the entire document or a selected subtree—directly from
the app UI while reusing the existing streaming exporters.

## 🧩 Context

- The execution workplan calls for Task G6 to bring JSON export controls into the SwiftUI surface now that the tree,

  detail, and hex panes are stable.

- `ISOInspector_PRD_TODO.md` lists export actions as the remaining UI deliverable alongside existing search, filter, and detail functionality.
- CLI commands already emit JSON via `ISOInspectorKit` exporters; the app lacks equivalent actions for parity with the PRD.

## ✅ Success Criteria

- Provide explicit export affordances (menu command + toolbar or context menu) for full document and selected subtree

  JSON captures.

- Wire the UI actions to the existing exporter pipeline so generated files match the CLI schema, including offsets,

  sizes, and metadata fields.

- Persist exported files to a user-chosen location via FilesystemAccessKit with proper sandbox-scoped bookmarks and

  error handling.

- Cover the feature with unit or UI tests that validate command availability and the structure of produced JSON for

  representative fixtures.

- Update user-facing documentation or release notes if new UI elements are introduced.

## 🔧 Implementation Notes

- Extend `ISOInspectorApp` scene commands and document toolbar with export options that invoke the JSON exporter APIs from `ISOInspectorKit`.
- Reuse existing document/session view models to scope exports (root vs. current selection) and ensure operations remain

  responsive by leveraging async tasks.

- Integrate with FilesystemAccessKit save flows to present destination pickers on macOS/iPadOS/iOS and record bookmarks

  where required.

- Coordinate with telemetry/logging to record export attempts and failures, following the zero-trust logging conventions

  already in place.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- `DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/` (exporter implementation background)
