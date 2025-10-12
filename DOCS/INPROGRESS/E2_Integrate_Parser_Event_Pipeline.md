# E2 — Integrate Parser Event Pipeline with UI Components

## 🎯 Objective
Connect the streaming parser output from `ISOInspectorCore` to the SwiftUI document shell so that opening a media file immediately updates the outline, detail, and validation panels in the app experience.

## 🧩 Context
- Execution workplan milestone **E2** targets this integration after the shell (E1) and UI components (C2/C3) were completed. These prerequisites provide the document browser, outline, and detail panes now ready to consume live data.
- The master PRD calls for a cohesive app experience that combines the streaming parser, SwiftUI UI, and app targets while keeping latency under 200 ms for responsive inspection workflows.

## ✅ Success Criteria
- Selecting or opening a supported file within the app triggers the parser pipeline and populates the UI tree/detail panes without manual refresh.
- Validation and event state remain synchronized between the streaming pipeline and UI view models while respecting main-actor updates.
- Integration work keeps end-to-end latency within the <200 ms responsiveness requirement defined for streaming updates.

## 🔧 Implementation Notes
- Reuse the Combine bridge and session stores established during task C1 to fan out parser events to SwiftUI-managed state.
- Ensure the document shell from E1 invokes the parser through a clear coordinator (e.g., an app-level controller) and cleans up subscriptions when sessions close.
- Verify compatibility with existing export and benchmarking hooks so downstream telemetry tasks can observe the same streamed data.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
