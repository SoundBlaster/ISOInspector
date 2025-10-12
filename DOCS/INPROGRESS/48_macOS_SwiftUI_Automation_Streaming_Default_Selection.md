# macOS SwiftUI Automation for Streaming Default Selection

## 🎯 Objective

Establish an automated macOS SwiftUI UI test that opens a streaming parse session and verifies the tree and detail panes
update with the default selection when live events arrive.

## 🧩 Context

- `ParseTreeExplorerView` now auto-selects the first node when snapshots update, and `ParseTreeOutlineViewModel` exposes helpers for default selection checks. This follow-up ensures the UI wiring from Task E2 has end-to-end coverage.
- XCTest-based UI hooks for SwiftUI are available, allowing macOS UI automation to drive selection assertions during
  live parses.
- Prior archive notes for the parser event pipeline highlight this automation gap as the remaining risk for ensuring
  streaming UI behavior stays stable.

## ✅ Success Criteria

- A macOS-only XCTest UI scenario exercises opening a representative media file and confirms the outline view selects
  and displays the first node without manual interaction when streaming events flow in.
- The detail pane reflects the selected node’s metadata, demonstrating tree/detail synchronization during the automated
  run.
- The test is integrated into the existing test suite and is conditionally compiled or skipped on platforms without
  SwiftUI UI automation support.
- Documentation in `next_tasks.md`, the execution workplan, and backlog PRD references are updated to show this task is in progress.

## 🔧 Implementation Notes

- Reuse existing fixture media and streaming test harnesses from `ISOInspectorAppTests`; extend them to drive SwiftUI UI actions via the new XCTest interfaces.
- Coordinate with accessibility identifier conventions (NestedA11yIDs) to reliably locate tree rows and detail views
  during automation.
- Ensure the automation gracefully handles asynchronous event delivery by waiting on published snapshots or
  notifications before asserting selection state.
- Capture any platform constraints (e.g., requiring macOS 13+ or skipping on Linux) in test annotations and
  documentation.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/45_E2_Integrate_Parser_Event_Pipeline`](../TASK_ARCHIVE/45_E2_Integrate_Parser_Event_Pipeline)
