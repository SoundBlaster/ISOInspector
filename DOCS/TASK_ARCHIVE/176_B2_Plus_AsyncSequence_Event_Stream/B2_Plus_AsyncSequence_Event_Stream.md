# B2+ — AsyncSequence Event Stream Integration

## 🎯 Objective
Implement the production AsyncSequence interface for `ParsePipeline` so streaming parse events feed CLI and SwiftUI consumers without blocking while preserving tolerant parsing metadata.

## 🧩 Context
- The master PRD positions **ISOInspectorCore** as an async streaming parser and commits to sub-200 ms event latency for UI consumers, making the live event stream a release-critical capability.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L4-L23】
- The technical specification directs `ParsePipeline` to distribute events via `AsyncStream`/Combine and outlines the concurrency model consumers expect, anchoring how CLI and SwiftUI layers subscribe to the stream.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L4-L35】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L82-L86】
- The earlier B2+ evaluation documented the AsyncThrowingStream design and seeded scaffolding/tests, leaving the live integration puzzle for follow-up execution.【F:DOCS/TASK_ARCHIVE/03_B2_Plus_Streaming_Interface_Evaluation/Summary_of_Work.md†L1-L22】

## ✅ Success Criteria
- `ParsePipeline.live()` constructs an `AsyncThrowingStream` powered by `StreamingBoxWalker`, yielding ordered box lifecycle events with validation, research logging, and issue tracking wired for downstream consumers.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L695-L760】
- CLI and SwiftUI entry points consume the stream directly with async/await, matching the architecture’s distribution guidance without additional bridging layers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L29-L35】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L82-L86】
- Regression coverage exercises ordered delivery and error propagation through the finalized stream so downstream integrations inherit the guarantees captured during evaluation.【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L4-L66】

## 🔧 Implementation Notes
- Reuse the existing AsyncThrowingStream builder to host the real `StreamingBoxWalker`, ensuring metadata/environment coordinators remain connected to validators, research logging, and random-access tracking when yielding events.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L727-L760】
- Audit CLI and SwiftUI consumers against the finalized stream contract, adjusting adapters or documentation only if required to keep within the PRD’s latency expectations.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L4-L35】
- Extend the existing interface tests (and add integration coverage if necessary) so ordered emission and failure propagation remain enforced once the live walker powers the stream.【F:Tests/ISOInspectorKitTests/ParsePipelineInterfaceTests.swift†L4-L66】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
