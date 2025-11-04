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
