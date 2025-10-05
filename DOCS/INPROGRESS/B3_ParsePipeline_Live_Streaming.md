# B3 — Wire `ParsePipeline.live()` to Streaming Walker

## 🎯 Objective

Implement the real streaming pipeline so `ParsePipeline.live()` iterates through MP4 boxes using the async reader stack and emits ordered parse events for downstream consumers.【F:todo.md†L1-L4】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L1-L40】

## 🧩 Context

- The master PRD positions ISOInspectorCore as an async streaming parser whose events must arrive with low latency for UI and CLI integrations, making the live pipeline critical.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L1-L18】
- The technical specification details the data flow from `ChunkReader` through `ParsePipeline` to event distribution via `AsyncStream`, framing how the live implementation should behave.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L74】
- B2 delivered robust header decoding, so the remaining dependency is wiring the streaming walker to consume those headers and drive the async event stream.【F:DOCS/TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder_Summary.md†L1-L14】

## ✅ Success Criteria

- `ParsePipeline.live()` produces an `AsyncThrowingStream` that walks the file via the configured `RandomAccessReader`, yielding `willStartBox`/`didFinishBox` events in document order with accurate offsets.【F:todo.md†L1-L4】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L1-L40】
- Container traversal respects size boundaries and context stack semantics outlined in the technical spec to avoid infinite loops or mis-nested events.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L47-L106】
- Streaming integration is validated with unit tests that feed synthetic readers and assert event ordering and error propagation, ensuring readiness for UI/CLI consumers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L74】

## 🔧 Implementation Notes

- Reuse the existing `RandomAccessReader` implementations and `BoxHeaderDecoder` from B1/B2 to decode headers before emitting events; ensure error handling forwards through the stream continuation.【F:DOCS/TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder_Summary.md†L1-L14】
- Model traversal with an explicit stack so containers emit paired start/finish events without recursion depth issues, matching the technical spec guidance.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L47-L106】
- Use the existing `ParsePipeline` builder abstraction to keep the reader injectable for tests; replace the current placeholder continuation that immediately finishes.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L24-L51】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
