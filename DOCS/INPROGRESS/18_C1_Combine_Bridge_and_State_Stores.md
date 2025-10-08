# C1 — Combine Bridge and State Stores

## 🎯 Objective

Establish Combine-powered state stores that subscribe to the streaming parse pipeline so SwiftUI surfaces (tree, detail, hex) receive timely updates without data races.

## 🧩 Context

- Task **C1** is the next High-priority item in the execution workplan now that streaming parse events are available from Task B3. It calls for a Combine bridge that keeps UI snapshots synchronized with parser output while remaining race-free.
- The technical specification describes how ISOInspectorUI consumes core events through Combine publishers, outlines the data flow from `ParsePipeline` to UI subscribers, and emphasizes `@StateObject` stores as the bridge between async streams and SwiftUI views.
- Completed Task B3 wired `ParsePipeline.live()` to the streaming walker, so downstream consumers (such as these stores) can rely on real parse events with validation metadata attached.

## ✅ Success Criteria

- Provide a Combine publisher (or publisher-adapter) that emits `ParseEvent` updates from the core async stream and backs SwiftUI-facing state stores.
- Maintain thread-safe state transitions so snapshot updates occur deterministically and without race conditions while parsing large files.
- Supply focused unit and/or integration coverage demonstrating that representative parse fixtures update the stores and propagate validation metadata for UI consumption.

## 🔧 Implementation Notes

- Introduce dedicated store types (e.g., tree/detail/hex) that collect events, maintain derived state, and expose observable properties for SwiftUI. Ensure they are `@MainActor` or otherwise synchronized for view updates.
- Reuse existing core models (`ParseEvent`, `BoxDescriptor`, validation issues) and ensure the stores can map catalog-backed metadata and research flags into UI-friendly structures.
- Consider cancellation, replay, and completion semantics so the UI can reset or switch files without leaking tasks. Capture any future hooks required by subsequent UI tasks (tree rendering, detail pane) in TODOs.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)
- [`Summary_of_Work.md` (Task B3)](../TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration/Summary_of_Work.md)
