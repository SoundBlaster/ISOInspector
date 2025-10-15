# A4 — RandomAccessReader Error Types

## 🎯 Objective

Introduce explicit `RandomAccessReader` error types (`IOError`, `BoundsError`, `OverflowError`) and align existing reader implementations so downstream components receive consistent diagnostics while preparing for the A5 benchmarking follow-up.

## 🧩 Context

- The master PRD defines ISOInspector as a cross-platform MP4 inspector with shared core, UI, CLI, and app components,

  requiring predictable IO behavior across the
  stack.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L1-L16】

- The execution workplan’s Phase A tracks the IO foundation, and the current focus calls out Task A4 following the `MappedReader` milestone.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L6-L10】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L12】
- The PRD TODO backlog calls for adding the new error cases in A4 and running random-slice benchmarks in A5, both building upon the current `RandomAccessReader` interface and reader conformers.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L165-L168】
- Existing `RandomAccessReader` utilities and the `MappedReader` conformer currently surface ad-hoc errors, providing the baseline to extend with the standardized error taxonomy.【F:Sources/ISOInspectorKit/IO/RandomAccessReader.swift†L1-L42】【F:Sources/ISOInspectorKit/IO/MappedReader.swift†L1-L52】

## ✅ Success Criteria

- Define repository-wide error enumerations that cover IO failures, invalid request bounds, and arithmetic overflow scenarios exposed via `RandomAccessReader` APIs.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L165-L168】
- Update `MappedReader` and other conformers to translate their internal error conditions into the shared error surface, maintaining existing read semantics.【F:Sources/ISOInspectorKit/IO/MappedReader.swift†L1-L52】
- Extend unit tests to validate each error path, including offset/count guards and simulated IO failures, ensuring the

  typed errors propagate to decoding helpers.【F:Sources/ISOInspectorKit/IO/RandomAccessReader.swift†L1-L42】

- Document the new error contracts to unblock A5 benchmarking scenarios that compare reader implementations under

  failure and stress conditions.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L165-L168】

## 🔧 Implementation Notes

- Introduce a top-level `RandomAccessReaderError` (or similar) that encapsulates IO, bounds, and overflow cases while mapping existing conformer-specific errors to the shared cases.
- Audit each `RandomAccessReader` implementation (`MappedReader`, `ChunkedFileReader`, future variants) to ensure they conform to the shared error interface and return deterministic `Swift.Error` values.
- Update decoding helpers and associated tests to assert on the new error cases where appropriate, including overflow

  checks in integer-sized reads.

- Outline the performance metrics and harness hooks required for Task A5 so benchmarking can consume the standardized

  error metadata without additional refactors.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/61_A2_Implement_MappedReader`](../TASK_ARCHIVE/61_A2_Implement_MappedReader)
