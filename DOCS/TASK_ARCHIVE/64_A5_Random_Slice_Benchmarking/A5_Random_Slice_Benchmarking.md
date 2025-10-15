# A5 — Random Slice Benchmarking Harness

## 🎯 Objective

Deliver a repeatable micro-benchmark suite that exercises random slice reads against both `MappedReader` and `ChunkedFileReader`, capturing latency and throughput metrics while reusing the unified `RandomAccessReaderError` taxonomy from Task A4.【F:DOCS/TASK_ARCHIVE/62_A4_RandomAccessReader_Error_Types/Summary_of_Work.md†L15-L19】

## 🧩 Context

- The execution workplan identifies Task A5 as the current focus for the IO roadmap, emphasizing benchmarking coverage
  for the random-access readers.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L14】
- The PRD TODO backlog calls for micro-benchmarks that compare mapped versus handle-based readers on large files,
  ensuring the performance envelope is understood before higher-level features expand I/O
  pressure.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L168-L169】
- Task A4 standardized error reporting so the benchmarking harness can attribute failures consistently and unblock the
  measurement scenarios tracked in recent archival
  notes.【F:DOCS/TASK_ARCHIVE/62_A4_RandomAccessReader_Error_Types/Summary_of_Work.md†L5-L13】【F:DOCS/TASK_ARCHIVE/63_Summary_of_Work_2025-10-15/Summary_of_Work.md†L19-L20】

## ✅ Success Criteria

- Benchmarks execute both reader implementations across representative slice sizes (small, medium, large) using shared
  fixtures, reporting latency and throughput deltas within XCTest’s metrics harness.
- Harness integrates into the existing performance test suite so `swift test` captures regressions automatically, leveraging `PerformanceBenchmarkConfiguration` controls delivered by Task F2.【F:DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md†L5-L16】
- Benchmark failures emit structured `RandomAccessReaderError` diagnostics, confirming the error taxonomy is preserved end-to-end during stress scenarios.【F:DOCS/TASK_ARCHIVE/62_A4_RandomAccessReader_Error_Types/Summary_of_Work.md†L5-L13】
- Documentation or README notes summarize the measurement approach and baseline numbers so future tasks can compare
  against the established
  envelope.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L14】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L168-L169】

## 🔧 Implementation Notes

- Extend the performance benchmark target introduced in Task F2, reusing the configurable payload sizing and iteration
  controls to cover random slice workloads for both reader
  implementations.【F:DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md†L5-L16】
- Start from existing fixtures used by the IO subsystem to avoid generating new large assets; parameterize slice offsets
  to model warm and cold cache behaviour.
- Capture metrics in a format suitable for future CI gating (e.g., JSON artifacts or baseline files) while keeping Linux
  compatibility for non-Combine scenarios.
- Coordinate with distribution and diagnostics follow-ups to publish any discovered bottlenecks, ensuring downstream
  tooling (CLI/UI) benefits from the measurement insights.【F:DOCS/INPROGRESS/next_tasks.md†L5-L13】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archival notes in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
