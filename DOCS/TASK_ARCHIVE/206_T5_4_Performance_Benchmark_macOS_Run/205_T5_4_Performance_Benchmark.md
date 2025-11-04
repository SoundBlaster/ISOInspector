# T5.4 Performance Benchmark: Lenient vs. Strict Parsing

## 🎯 Objective
Ensure the tolerant parsing pipeline remains within the performance budget by benchmarking lenient mode against strict mode on the 1 GB reference fixture.

## 🧩 Context
- Task T5.4 in the corrupted media tolerance workplan requires validating that lenient parsing incurs no more than a 1.2× runtime overhead versus strict mode on a healthy 1 GB sample.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L108-L118】
- Performance harnesses from Task F2 already provide large-file benchmark scaffolding in `LargeFileBenchmarkTests`, and prior notes call out pending execution on macOS hardware capable of exercising Combine-backed paths.【F:DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md†L1-L16】
- The tolerance integration summary reiterates that the performance gate must be enforced before the beta exit criteria can be met, pairing strict-mode baselines with lenient-mode runs on `large_file_1GB.mp4`.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L594-L633】

## ✅ Success Criteria
- Strict-mode benchmark establishes baseline metrics for the 1 GB reference fixture using the existing XCTest performance suite.
- Lenient-mode benchmark completes on the same fixture with ≤1.2× runtime overhead and ≤50 MB additional peak memory compared to the baseline.
- Results (metrics, configuration, fixture hash) are recorded and linked for archival in the forthcoming task summary.
- CI or local automation notes indicate how to repeat the benchmark (e.g., command invocation, environment requirements).

## 🔧 Implementation Notes
- Confirm the large fixture is available or regenerate via the documented scripts before running the performance suite.
- Reuse `LargeFileBenchmarkTests` by parameterizing the parsing mode (strict vs. lenient) and capturing metrics for both runs.
- Capture raw output (timings, memory) for inclusion in the eventual archive and to support regression thresholds.
- If Combine-dependent benchmarks still require macOS hardware, document any environment constraints and mitigation steps for future automation.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md`](../TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md)
- [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)

---

## 📈 Progress Log — 2025-11-04

- Added lenient-versus-strict harness to `LargeFileBenchmarkTests` with a new XCTest case that captures runtime ratios and peak RSS deltas across repeated CLI validation runs. Metrics are emitted during the run for archival in `Documentation/Performance`.【F:Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift†L49-L105】【3dc8f9†L6-L13】
- Extended `PerformanceBenchmarkConfiguration` with tolerant-mode overhead budgets (1.2× runtime, +50 MiB RSS) so the suite enforces the gate directly.【F:Sources/ISOInspectorKit/Benchmarking/PerformanceBenchmarkConfiguration.swift†L24-L47】
- Local Linux run (default 32 MiB fixture) produced a worst-case ratio of 1.049× and <1 MiB extra RSS, well below the 1.2× / 50 MiB threshold.【cdd012†L12-L17】

### ⚠️ Outstanding Work

- The 1 GiB fixture execution remains pending on macOS hardware with Combine support. Use `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824` and rerun `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget` once the runner has sufficient disk space. Archive the emitted metrics into `Documentation/Performance/` when complete.
