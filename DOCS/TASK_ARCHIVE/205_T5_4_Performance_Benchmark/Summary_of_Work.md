# Summary of Work — Task T5.4 Performance Benchmark

## Overview
- Added lenient-vs-strict CLI benchmarking to `LargeFileBenchmarkTests`, capturing average duration and RSS deltas for each mode. 【F:Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift†L49-L105】
- Introduced tolerant-mode overhead budgets (1.2× runtime, +50 MiB RSS) in `PerformanceBenchmarkConfiguration` and enforced them through new XCTest assertions. 【F:Sources/ISOInspectorKit/Benchmarking/PerformanceBenchmarkConfiguration.swift†L24-L47】
- Archived local Linux metrics (32 MiB payload) in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log`, showing ≤1.049× runtime overhead and ≤0.01 MiB additional RSS. 【F:Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log†L1-L24】【cdd012†L12-L17】

## How to Reproduce
1. Ensure the large fixture is generated automatically by `LargeFileBenchmarkFixture` (temporary directory under `isoinspector-benchmarks`).
2. Run the CLI benchmark test:
   ```bash
   swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget
   ```
3. To exercise the 1 GiB reference payload, export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824` and rerun on macOS hardware with Combine available. Capture the printed metrics for archival alongside this log.

## Follow-Up
- Schedule a macOS run to validate Combine-backed paths and record metrics for the 1 GiB fixture, updating `Documentation/Performance` once complete. 【F:DOCS/INPROGRESS/205_T5_4_Performance_Benchmark.md†L48-L55】
