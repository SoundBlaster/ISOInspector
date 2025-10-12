# F2 — Configure Performance Benchmarks for Large Files

## 🎯 Objective

Establish automated performance benchmarks that capture CLI and app throughput for large MP4 analyses, creating
guardrails for regressions while documenting baseline metrics.

## 🧩 Context

- Phase F of the execution workplan prioritizes dedicated benchmarking once the streaming pipeline is stable, calling
  for XCTest Metric harnesses that fail CI on
  regressions.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L55】
- Non-functional requirements mandate sub-45-second CLI validation for 4 GB reference files and <200 ms UI update
  latency, anchoring the performance targets these benchmarks must
  validate.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L21-L30】
- Research task R4 outlines outstanding questions around tooling, fixture generation, and instrumentation for large-file
  benchmarking that should inform implementation
  choices.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L13】

## ✅ Success Criteria

- Benchmarks execute representative large-file scenarios for CLI streaming validation and UI event propagation,
  recording latency, throughput, and memory use.
- Baseline thresholds derived from initial runs are encoded so CI fails when regressions exceed agreed tolerances.
- Documentation updates summarize benchmark scenarios, metrics captured, and instructions for reproducing measurements
  locally.

## 🔧 Implementation Notes

- Leverage existing streaming fixtures and, if necessary, generate synthetic large files guided by Research Task R4
  recommendations for sustainable test assets.
- Integrate XCTest Metrics and signpost instrumentation to capture CPU time, wall-clock latency, and memory for both CLI
  commands and UI pipelines.
- Provide configuration hooks (e.g., environment variables) to toggle benchmark intensity to keep default CI runtime
  manageable while enabling deeper local profiling when needed.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md`](../AI/ISOInspector_Execution_Guide/05_Research_Gaps.md)
