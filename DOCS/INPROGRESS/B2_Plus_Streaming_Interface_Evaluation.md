# B2+ — Async Streaming Interface Evaluation

## 🎯 Objective
Assess and specify the async streaming interface that ISOInspectorCore should expose so higher parser layers can request progressive reads and react to parse events without blocking, preparing the pipeline for UI and CLI consumers.

## 🧩 Context
- Task B2 follow-up identified the need to evaluate async streaming interfaces once higher parser layers depend on progressive reads, signaling that the header decoder work unblocked this investigation.【F:DOCS/TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder_Summary.md†L1-L14】
- The master PRD defines ISOInspectorCore as an async streaming parser that must deliver low-latency events to downstream experiences, framing the interface expectations.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L1-L18】
- The technical specification describes the parse pipeline emitting events over `AsyncStream`/Combine to consumers, indicating current architectural preferences to validate against during the evaluation.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L74】

## ✅ Success Criteria
- Document a recommended async interface shape (e.g., `AsyncSequence`, `AsyncThrowingStream`, Combine publisher) with rationale covering concurrency guarantees, backpressure, and compatibility with SwiftUI/CLI consumers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L41-L74】
- Provide a lightweight prototype or pseudocode demonstrating the interface integration with the existing `ParsePipeline` so it can emit ordered events that uphold PRD latency goals.【F:DOCS/INPROGRESS/B3_Streaming_Parse_Pipeline.md†L1-L25】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L16-L23】
- Capture consumer requirements (UI tree updates, CLI streaming) and note any additional dependencies or research items, ensuring no unresolved blockers remain before implementation proceeds.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L75-L106】

## 🔧 Implementation Notes
- Review existing parser prototypes (B3 task notes) to understand current event emission mechanics and ensure the chosen interface aligns with the context stack strategy.【F:DOCS/INPROGRESS/B3_Streaming_Parse_Pipeline.md†L1-L28】
- Compare `AsyncStream` and Combine-based exposure, considering ergonomics for SwiftUI `ObservableObject` stores and CLI async/await consumption paths outlined in the technical spec.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L1-L40】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L75-L106】
- Identify any fixture or benchmarking needs (e.g., large `mdat` cases) to validate throughput once the interface lands, coordinating with F1 fixture development for representative samples.【F:DOCS/INPROGRESS/F1_Test_Fixtures.md†L1-L33】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L45-L52】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
