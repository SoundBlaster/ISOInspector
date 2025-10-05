# B2+ — Async Streaming Interface Evaluation

## 🎯 Objective

Assess and specify the async streaming interface that ISOInspectorCore should expose so higher parser layers can request
progressive reads and react to parse events without blocking, preparing the pipeline for UI and CLI consumers.

## 🧩 Context

- Task B2 follow-up identified the need to evaluate async streaming interfaces once higher parser layers depend on

  progressive reads, signaling that the header decoder work unblocked this
  investigation.【F:DOCS/TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder_Summary.md†L1-L14】

- The master PRD defines ISOInspectorCore as an async streaming parser that must deliver low-latency events to

  downstream experiences, framing the interface
  expectations.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L1-L18】

- The technical specification describes the parse pipeline emitting events over `AsyncStream`/Combine to consumers, indicating current architectural preferences to validate against during the evaluation.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L74】

## ✅ Success Criteria

- Document a recommended async interface shape (e.g., `AsyncSequence`, `AsyncThrowingStream`, Combine publisher) with rationale covering concurrency guarantees, backpressure, and compatibility with SwiftUI/CLI consumers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L74】
- Provide a lightweight prototype or pseudocode demonstrating the interface integration with the existing `ParsePipeline` so it can emit ordered events that uphold PRD latency goals.【F:DOCS/INPROGRESS/B3_Streaming_Parse_Pipeline.md†L1-L25】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L16-L23】
- Capture consumer requirements (UI tree updates, CLI streaming) and note any additional dependencies or research items,

  ensuring no unresolved blockers remain before implementation

proceeds.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L75-L106】

## 🔧 Implementation Notes

- Review existing parser prototypes (B3 task notes) to understand current event emission mechanics and ensure the chosen

  interface aligns with the context stack strategy.【F:DOCS/INPROGRESS/B3_Streaming_Parse_Pipeline.md†L1-L28】

- Compare `AsyncStream` and Combine-based exposure, considering ergonomics for SwiftUI `ObservableObject` stores and CLI async/await consumption paths outlined in the technical spec.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L75-L106】
- Identify any fixture or benchmarking needs (e.g., large `mdat` cases) to validate throughput once the interface lands, coordinating with F1 fixture development for representative samples.【F:DOCS/INPROGRESS/F1_Test_Fixtures.md†L1-L33】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L45-L52】

## 🔍 Evaluation Summary

- Recommend exposing parser output as `AsyncThrowingStream<ParseEvent, Error>` so consumers gain natural Swift Concurrency integration, backpressure via demand-driven iteration, and deterministic failure propagation that aligns with CLI and UI requirements.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L1-L42】【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L1-L74】
- `ParseEvent` encapsulates structured box lifecycle data (offset, depth, entry/exit moments) in a `Sendable` value type, enabling safe cross-actor transport for SwiftUI view models and CLI progress reporters without copying full payloads.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L1-L22】
- `ParsePipeline` now acts as a factory for asynchronous event streams, keeping the reader abstraction injectable so future implementations can wrap real `RandomAccessReader` instances or synthetic fixtures for testing and benchmarking.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L24-L42】

## 🧪 Prototype Outline

1. The prototype stream builder constructs an `AsyncThrowingStream` that yields deterministic test events, proving ordered delivery and error forwarding semantics expected by downstream observers.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L24-L42】【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L16-L73】
1. Unit coverage exercises sequential consumption and error propagation so acceptance tests for higher layers can rely

   on these guarantees when introducing real parsing
   logic.【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L16-L73】

1. `ParsePipeline.live()` documents the integration seam for the forthcoming streaming walker; an explicit `@todo` keeps Puzzle-Driven Development tracking the remaining implementation gap while allowing current consumers to experiment with the interface shape.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L44-L51】

## 📦 Consumer Considerations

- **SwiftUI tree updates:** The async stream plugs into `Task`-driven `ObservableObject` reducers that await events sequentially, ensuring updates remain on the main actor without bridging through Combine subject types.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L75-L106】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L24-L42】
- **CLI streaming:** Command handlers can iterate over the same stream with `for try await`, emitting progress rows or structured JSON incrementally, matching the low-latency goals called out in the technical spec.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L74】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L24-L42】
- **Error handling:** Fatal parsing issues surface as thrown errors from the stream iterator, allowing both UI and CLI

  shells to present actionable diagnostics while leaving the pipeline resumable for partial success scenarios (warnings
  continue as event metadata).【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L52-L73】

## 🚧 Follow-ups

- Implement `ParsePipeline.live()` to drive `AsyncThrowingStream` from `BoxHeaderDecoder` and the planned context stack walker, emitting both entry and exit events per box boundary.
- Coordinate with task F1 to seed large `mdat` and malformed fixtures that will stress-test stream backpressure and cancellation semantics before promoting the interface to UI and CLI packages.【F:DOCS/INPROGRESS/F1_Test_Fixtures.md†L1-L33】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
