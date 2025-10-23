# G7 — State Management View Models

## 🎯 Objective
Establish dedicated document, node, and hex view models that coordinate parse tree state, ensuring the SwiftUI outline, detail, and export flows stay synchronized while the streaming parser mutates data in real time.

## 🧩 Context
- `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` calls for a `DocumentVM`, `NodeVM`, and `HexVM` to manage selection and slice state for UI consumers.
- The `ISOInspectorUI` PRD prioritizes a DocumentViewModel layer that adapts parser output into tree, detail, and hex components.
- Execution workplan milestones for the parser pipeline and SwiftUI outline/detail flows are complete, so this task focuses on the cohesive state glue across those subsystems.

## ✅ Success Criteria
- A `DocumentVM` (or equivalent controller) exposes the parsed tree, validation badges, and export affordances with observable updates.
- A `NodeVM` tracks selection, filters, and bookmarks, keeping the outline and detail panes consistent.
- A `HexVM` provides on-demand slice loading with highlight ranges aligned to selected nodes.
- Unit and integration tests cover multi-pane synchronization (selection changes, filter toggles, and exports).

## 🔧 Implementation Notes
- Reuse the established parse pipeline bridges and SwiftUI outline/detail components; this task formalizes the state orchestration above them.
- Ensure view models coordinate with persistence layers (recents, annotations, bookmarks) without introducing race conditions.
- Surface export hooks for full document and node-level JSON flows, mirroring CLI expectations.
- Consider accessibility affordances (focus order, keyboard navigation) when exposing selection APIs.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`ISOInspectorUI_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorUI_PRD.md)
- [`DOCS/RULES`](../RULES)
- Relevant entries in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
