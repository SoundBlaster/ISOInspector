# B3 — Streaming Parse Pipeline

## 🎯 Objective

Implement the streaming parse pipeline that reads MP4 boxes sequentially, emits typed parse events, and maintains a
context stack so downstream consumers (UI, CLI, validation) can react incrementally.

## 🧩 Context

- Builds upon the core parser scope in the ISOInspector Technical Spec (`Core.Parser`, event model, context stack).
- Aligns with master PRD goals for ISOInspectorCore to provide low-latency, low-memory streaming of large files.
- Follows Execution Workplan Phase B progression after completing the box header decoder (B2).

## ✅ Success Criteria

- Parsing sample fixtures yields ordered parse events containing headers, offsets, and context metadata per

  specification.

- Event stream maintains parent/child context via explicit stack without recursion depth issues.
- Pipeline handles container traversal, `size==0/1`, and malformed structures by emitting validation hooks rather than crashing.

- XCTest coverage proves deterministic event ordering and error handling across nominal and malformed inputs.

## 🔧 Implementation Notes

- Use `RandomAccessReader` and `BoxHeaderDecoder` from B1/B2 as the foundation for reading headers and payload ranges.
- Define `ParsePipeline` (or similar) that produces `AsyncStream<ParseEvent>` or Combine publisher for consumers; ensure thread safety with Swift concurrency primitives.

- Maintain an explicit context stack/iterator to traverse container boxes without recursion, enforcing declared payload

  boundaries.

- Integrate validation hooks for VR-001/VR-002, capturing issues in emitted events but allowing parsing to continue when

  possible.

- Provide smoke fixtures (small MP4 samples, malformed headers) to validate pipeline behavior; reuse or extend existing

  test utilities.

## 🧠 Source References

- DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md
- DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md
- DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md
