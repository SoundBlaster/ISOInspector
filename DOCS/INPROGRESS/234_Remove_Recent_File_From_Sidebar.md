# Bug #234 — Remove Recent File from Sidebar

## 🎯 Objective
Deliver an in-app affordance to remove individual entries from the Recent Files sidebar list so users can declutter or protect sensitive filenames without clearing all history.

## 🧩 Context
- Bug report describes missing removal action and clutter/privacy concerns (`DOCS/BUGS/234_Remove_Recent_File_From_Sidebar.md`).
- No blockers noted in current planning artifacts; task marked implementation-ready in `next_tasks.md` and `Current_State.md`.
- Expected touchpoints: sidebar SwiftUI list rendering recent files, persistence layer that maintains MRU history, and any analytics/logging hooks for sidebar interactions.

## ✅ Success Criteria
- Sidebar exposes an accessible “Remove from Recent” action (e.g., context menu or inline button) for the selected entry.
- Removing an entry updates the UI immediately and persists across app relaunches without affecting other recents.
- Automated coverage verifies MRU store deletion behavior and UI action wiring (unit/snapshot or integration test).

## 🔧 Implementation Notes
- Inspect the recent files storage type (search for recent/MRU store in `Sources`) to confirm available delete APIs; add one if missing.
- Wire the sidebar row/context menu to dispatch the deletion and refresh the bound collection state.
- Ensure keyboard/accessibility pathways (Delete key, VoiceOver labels) are considered and logged in tests or notes.
- If telemetry exists for sidebar actions, emit a deletion event consistent with existing analytics patterns.

## 🧠 Source References
- [`DOCS/BUGS/234_Remove_Recent_File_From_Sidebar.md`](../BUGS/234_Remove_Recent_File_From_Sidebar.md)
- [`DOCS/INPROGRESS/next_tasks.md`](./next_tasks.md)
- [`DOCS/INPROGRESS/Current_State.md`](./Current_State.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- Archives under [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
