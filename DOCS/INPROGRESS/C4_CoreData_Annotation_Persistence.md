# C4 — CoreData Annotation & Bookmark Persistence

## 🎯 Objective

Implement a CoreData-backed store for annotations and bookmarks so ISOInspectorUI and ISOInspectorApp can persist user
notes across sessions and sync with existing SwiftUI view models.

## 🧩 Context

- Execution workplan item **C4** calls for annotation and bookmark management with persistence hooks after the detail
  pane and hex viewer work. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L29】
- Product requirement **FR-UI-003** mandates session bookmarking and annotations stored per file that survive app
  relaunches. 【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L7-L18】
- Research task **R6** captured the decision-making around CoreData vs. JSON; incorporate its outcomes so downstream
  tasks (e.g., app session persistence) have a stable storage layer.
  【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L13】

## ✅ Success Criteria

- Define a CoreData model (entities for annotations, bookmarks, file metadata) with schema migration guidance replacing
  the prior JSON spike.
- Integrate the new store with existing SwiftUI view models so create/update/delete flows and bookmark toggles update UI
  state immediately.
- Provide unit tests covering persistence round-trips, conflict handling, and integration with the random-access payload
  annotation provider.
- Ensure persisted data survives app relaunch and remains compatible with planned session persistence work (E3) without
  regressions in existing tests.

## 🔧 Implementation Notes

- Design fetch/update APIs that align with the current in-memory store protocol so UI consumers require minimal changes.
- Capture migration strategy from the archived JSON store spike, noting any data transformation steps or compatibility
  shims.
- Verify CoreData stack initialization works in both macOS/iOS app contexts and SwiftUI previews/tests; document any
  required container configuration.
- Update DocC/user docs after implementation to describe annotation workflows once the storage path is stable.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant notes in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
