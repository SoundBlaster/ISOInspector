# Task 244 – NavigationSplitView Parity with Demo

**Status**: RESOLVED (declined 2025-12-17 — stakeholder wants to retain current layout)

## 🎯 Objective
Refactor the app shell and parse tree experience so the three-column NavigationSplitView matches the clean NavigationSplitViewKit demo layout (no overlaid “frame” under the toolbar, single split view, stable column order, and inspector-only details/integrity).

## 🧩 Context
- Task 243 moved Selection Details and Integrity Summary to the inspector, but the original spec implied nesting a split view inside the content column. That misled implementation, producing a double split (AppShell + ParseTreeExplorer) and top padding/overlay that makes content appear inside a framed region under the toolbar.
- Current issues: columns inset under toolbar, tree can disappear when inspector toggles, integrity view sticks when selecting boxes, and inspector/content boundaries feel misaligned versus the NavigationSplitViewKit demo.
- We need a focused refactor to realign layout structure and behavior while keeping Task 243 goals (details/integrity in inspector, toggle UX) intact.

## ✅ Success Criteria
- Single top-level `NavigationSplitView` owns sidebar/content/inspector (no nested split views inside the content column).
- Columns are flush beneath the toolbar with no extra framing or vertical inset; matches NavigationSplitViewKit demo proportions.
- Box Tree (content column) cannot be hidden by inspector toggles; inspector visibility only affects the inspector column.
- Selecting a box always switches inspector to Selection Details; integrity view does not stick after selection.
- Toggle controls swap inspector content (details vs integrity) without altering column visibility or pushing other columns.
- Keyboard shortcuts (⌘⌥I, focus shortcuts) still function with the flattened layout.
- macOS/iPad/iPhone adaptive behaviors remain stable (balanced style); previews updated to reflect the final structure.

## 🔧 Implementation Notes
- Keep the single `NavigationSplitView` at the AppShell level; ensure content is a plain `VStack` (or equivalent) without outer padding that creates a “frame” under the toolbar.
- Remove or minimize per-column padding that causes visual insets; prefer internal spacing within views rather than outer padding on the split columns.
- Ensure inspector content is exclusive to `InspectorDetailView`; content column should not host details/integrity.
- Reaffirm column visibility handling: only `.all`/`.doubleColumn`, never nested or secondary split visibility.
- Update previews and (if feasible) add a snapshot/UI preview reflecting the parity layout for regression.

## 🧠 Source References
- [`DOCS/COMMANDS/SELECT_NEXT.md`](../COMMANDS/SELECT_NEXT.md)
- [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md)
- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md)
- [`DOCS/RULES/04_PDD.md`](../RULES/04_PDD.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/AI/ISOViewer/ISOInspector_Master_PRD_Full/ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
