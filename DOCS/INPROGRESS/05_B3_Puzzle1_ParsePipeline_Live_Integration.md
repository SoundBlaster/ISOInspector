# Complete Puzzle #1 — Wire `ParsePipeline.live()` to Streaming Walker

## 🎯 Objective

Implement the production `ParsePipeline.live()` builder so it drives the concrete streaming walker against a `RandomAccessReader`, emitting real `ParseEvent` values for downstream consumers instead of fixture stubs.【F:todo.md†L1-L4】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L18-L132】

## 🧩 Context

- Puzzle #1 is the remaining open item from the archived B3 streaming work notes and is also called out in the active

  next-task queue, keeping the parser backlog aligned with the

workplan.【F:DOCS/TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming/next_tasks.md†L1-L4】【F:DOCS/INPROGRESS/next_tasks.md†L1-L4】

- Phase B of the execution workplan marks B1 and B2 as complete, leaving B3 (streaming parse pipeline) as the

  highest-priority dependency for UI/CLI features that consume live
  events.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L27】

- The PRD and technical specification require the pipeline to traverse MP4 boxes in document order, maintain a context stack, and surface validation hooks over an `AsyncStream`, so the integration must respect those contracts.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L33】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L50-L58】

## ✅ Success Criteria

- `ParsePipeline.live()` returns an `AsyncThrowingStream` that iterates using the streaming walker, yielding `willStartBox` and `didFinishBox` events with accurate offsets for nested containers and `mdat` skips.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L37-L132】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L28-L33】
- Integration tests cover at least one nested fixture and a large-size box to confirm ordering, depth accounting, and

  error propagation from the walker through the stream
  continuation.【F:DOCS/TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming/B3_ParsePipeline_Live_Streaming.md†L5-L22】

- Cancellation and failure states from the walker terminate the stream cleanly, matching the concurrency guarantees

  promised in the technical spec and workplan acceptance

criteria.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L37-L132】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L27】

- Existing automated tests (`swift test`) continue to pass after the integration, ensuring no regressions in prior B1/B2 functionality.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L27】

## 🔧 Implementation Notes

- Leverage the existing `RandomAccessReader` protocol and helpers for header reads; ensure walker logic uses bounded ranges when decoding sizes and UUID payloads.【F:Sources/ISOInspectorKit/IO/RandomAccessReader.swift†L3-L55】【F:Sources/ISOInspectorKit/ISO/BoxHeaderDecoder.swift†L1-L140】
- Maintain an explicit traversal stack mirroring the archived B3 solution so each container yields paired start/finish

  events without recursion depth

issues.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L56-L121】【F:DOCS/TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming/B3_ParsePipeline_Live_Streaming.md†L5-L22】

- Skip `mdat` payload bodies by advancing the cursor to the payload end while still emitting metadata events; this satisfies the streaming performance expectations from the PRD backlog.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L75-L86】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L94-L121】
- Surface walker errors (header decoding, boundary violations) by finishing the stream with a thrown error, and wire cancellation via `Task.checkCancellation()` to honor consumer backpressure.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L37-L120】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
