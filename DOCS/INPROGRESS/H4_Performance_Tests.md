# H4 — Performance Benchmark Validation

## 🎯 Objective

Execute the automated large-file benchmarks to confirm the CLI and reader implementations meet the parse-time and memory
budgets specified in the master PRD, and publish the resulting metrics for release readiness reviews.

## 🧩 Context

- `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` lists Task **H4** as the remaining performance gate after configuring the benchmark harness in Task F2.
- `Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift` already exercises CLI validation, UI event latency, and random slice scenarios using `PerformanceBenchmarkConfiguration`.
- The release runbook (`Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`) requires archived metrics for the go/no-go review and references these benchmarks explicitly.
- Hardware-dependent macOS UI benchmarks remain tracked separately in `DOCS/INPROGRESS/next_tasks.md`; this task focuses on executing the existing automation on available infrastructure and reporting outcomes.

## ✅ Success Criteria

- Benchmark runs cover `testCLIValidationCompletesWithinPerformanceBudget` plus both random slice benchmarks, using payload sizes representative of large production files.
- Captured metrics (duration, CPU, memory) stay within the budgets calculated by `PerformanceBenchmarkConfiguration` or the configuration is adjusted with documented rationale if thresholds need refinement.
- Results and any tuning instructions are documented alongside command invocations so release managers can reproduce them (e.g., via a short note appended to the Release Readiness runbook or archived under `DOCS/TASK_ARCHIVE`).
- Test automation is wired into `swift test` (no manual skip) and passes in CI once fixtures and configuration are aligned.

## 🔧 Implementation Notes

- Prefer running benchmarks with `ISOINSPECTOR_BENCHMARK_INTENSITY=local` on developer hardware to stress payload size/iterations, but fall back to CI defaults when resources are constrained.
- Leverage the `LargeFileBenchmarkFixture` utilities to generate or reuse synthetic large payloads rather than checking bulky assets into the repo.
- If Combine is unavailable (e.g., Linux), capture the XCTSkip output for the UI latency test and note any follow-up
  macOS validation remains covered by the blocked hardware task.
- Store raw benchmark logs in a dedicated folder (`Documentation/Performance/` or similar) to simplify future regressions analysis.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`](../Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md)
- [`DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md`](../TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md)
