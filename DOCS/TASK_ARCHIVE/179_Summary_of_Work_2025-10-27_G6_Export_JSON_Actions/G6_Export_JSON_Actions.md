# G6 — Export JSON Actions

## 🎯 Objective
Deliver app-level export commands that let ISOInspector users save the entire parse tree or the currently selected node as JSON directly from SwiftUI controls.

> **Status:** Completed on 2025-10-27 — see `DOCS/INPROGRESS/Summary_of_Work.md` for verification details and regression coverage notes.

## 🧩 Context
- Backlog item **G6** calls for JSON export affordances that mirror the CLI’s export coverage and bridge the shared `JSONParseTreeExporter` APIs into the app experience.
- The product manual specifies toolbar, context menu, and menu bar entries for **Export JSON…** and **Export Selection…**, establishing the UX contract we need to fulfill.

## ✅ Success Criteria
- Toolbar buttons and command menu entries are present and active only when their flows are valid (selection-aware for subtree export).
- Invoking an export writes JSON files that match the CLI exporter output for the same scope, reusing shared encoder configuration.
- UI tests (or snapshot coverage) confirm button/menu availability and verify that export completion updates user feedback (e.g., confirmation alerts or recent documents list) without regressions.
- Accessibility affordances exist for VoiceOver and keyboard navigation, matching the shortcuts documented in the manuals.

## 🔧 Implementation Notes
- Reuse `JSONParseTreeExporter` from ISOInspectorKit to avoid format skew; wire through existing document session controllers for file save coordination.
- Hook toolbar actions in `AppShellView` and the outline context menu to the same export pipeline, ensuring command menu entries share the handler.
- Ensure exported file destinations respect sandbox constraints by delegating to the FilesystemAccessKit helpers already integrated with recents/session persistence.
- Align telemetry or logging hooks with the zero-trust logging guidelines so exports are captured without leaking absolute file paths.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived research and completed tasks in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
