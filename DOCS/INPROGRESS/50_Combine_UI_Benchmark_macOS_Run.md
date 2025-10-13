# Execute the Combine-Backed UI Benchmark on macOS

## 🎯 Objective

Capture end-to-end latency, CPU, and memory metrics from the SwiftUI streaming bridge on real macOS hardware so we can
confirm the UI continues to meet the PRD latency budget and aligns with the CLI benchmark baselines.

## 🧩 Context

- The master PRD mandates that streaming UI updates stay under the 200 ms latency ceiling while handling large MP4

  inputs, so we need measurements from a platform that actually ships Combine.

- Task F2 in the execution workplan delivered the benchmark harnesses; this follow-up run remains the highest-priority

  open QA item for that task and is now tracked here instead of the archived attempt log.

- The previous Linux container attempt skipped the Combine scenario entirely, reinforcing the requirement to execute the test suite (`LargeFileBenchmarkTests.testAppEventBridgeDeliversUpdatesWithinLatencyBudget`) on macOS hardware.

## ✅ Success Criteria

- Run the Combine-gated benchmark on macOS (Xcode or `xcodebuild test`) and capture latency, CPU, and memory metrics for the streaming UI bridge.
- Compare the collected numbers against the configured performance budgets and record the findings in the performance

  tracking log or raise follow-up issues if limits are exceeded.

- Update the backlog/workplan entries with the captured results so the QA task can transition out of “In Progress.”

## 🔧 Implementation Notes

- Use a macOS runner with the Combine SDK; ensure `#if canImport(Combine)` paths compile and execute.
- Allocate sufficient disk space for temporary large-file fixtures created by `LargeFileBenchmarkFixture`, and clean them up after the run.
- Keep CLI benchmark results available for parity comparison and document any configuration adjustments required by the

  macOS environment.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`47_Combine_UI_Benchmark_macOS.md`](../TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/47_Combine_UI_Benchmark_macOS.md)
- [`DOCS/RULES`](../RULES)

## 🚧 Status Update — 2025-02-16

- Unable to execute the benchmark here because the container lacks macOS tooling and the Combine frameworks required by

  the test harness.

- Capturing metrics still requires a macOS runner with Xcode. Keep the scenario in “In Progress” until that hardware

  pass is scheduled.
