# C2 — Integrate Outline Explorer with Streaming Sessions

## 🎯 Objective

Connect the SwiftUI outline explorer to the existing Combine session bridge so that live parse events populate and
update the tree view without manual refresh.

## 🧩 Context

- Phase C task **C2** requires the tree view to render >10k nodes smoothly while supporting live updates and search

  filters, per the execution workplan.

- Combine-backed session stores from task **C1** already publish parse events onto the main actor; this work must

  subscribe and materialize tree nodes for the UI explorer.

- The UI PRD emphasizes an adaptive outline, details, and hex layout that reflects streaming parser progress.

## ✅ Success Criteria

- Tree view subscribes to the session publisher and displays root and nested boxes as soon as events arrive, preserving

  order.

- Selecting nodes triggers detail/hex requests using identifiers without blocking incoming updates.
- Streaming updates remain responsive (target <200 ms latency) and keep the outline in sync with parser completion

  states.

- Outline search/filter controls continue to operate against the live data set without crashing or stale content.

## 🔧 Implementation Notes

- Reuse the existing Combine stores to drive a view model that batches updates for SwiftUI diffing; consider `@MainActor` isolation for UI mutations.
- Ensure memory usage stays bounded when handling large (>10k node) trees—prefer incremental append over full array

  rebuilds.

- Verify compatibility with forthcoming detail/hex stores (task C3) to avoid conflicting data ownership.
- Add lightweight instrumentation/logging to observe event-to-UI latency during integration testing.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
