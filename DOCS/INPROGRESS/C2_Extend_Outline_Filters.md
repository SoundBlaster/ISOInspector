# C2 — Extend Outline Filters for Box Categories & Streaming Metadata

## 🎯 Objective

Implement additional outline explorer filters that let analysts toggle the visibility of MP4 box categories and
streaming metadata indicators alongside the existing validation-severity controls.

## 🧩 Context

- Task **C2** in the execution workplan calls for a tree view with virtualization, search, and filters; the remaining gap is extending the filters per `@todo #6`.\

  See [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).

- The root repo TODO list tracks "Add box category and streaming metadata filters once corresponding models are
  available."\

  See [`todo.md`](../../todo.md).

- `ParseTreeOutlineViewModel` currently filters by validation severity and carries a `@todo #6` comment about category and streaming metadata toggles.\

  See [`ParseTreeOutlineViewModel.swift`](../../Sources/ISOInspectorApp/Tree/ParseTreeOutlineViewModel.swift).

## ✅ Success Criteria

- Outline filter UI exposes switches/chips for at least the defined box categories (e.g., metadata, media, index) and
  streaming-specific markers, allowing combinations with severity filters.
- Filtering operates on the current `ParseTreeSnapshot` without breaking virtualization performance targets (10k+ nodes) and keeps latency instrumentation within acceptable bounds.
- Filter state persists during live streaming updates from the Combine bridge and survives snapshot refreshes without
  resetting user selections.
- Unit or UI tests cover category/streaming filtering logic, ensuring boxes enter/exit the visible set as expected.

## 🔧 Implementation Notes

- Inspect `ParseTreeNode` metadata and associated catalog descriptors to determine available category or streaming flags; extend models if needed to expose structured attributes instead of summary-string parsing.
- Update `ParseTreeOutlineFilter` to model category and streaming toggles, ensuring backward compatibility with severity filters and search matching.
- Coordinate with any Combine snapshot publishers so filter recalculations remain responsive; reuse or extend existing
  latency probes for regression detection.
- Review archived C2 task summaries for prior design intent on filter controls (see `DOCS/TASK_ARCHIVE/19_C2_Tree_View_Virtualization` and follow-ups).

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
