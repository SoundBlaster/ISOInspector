# 2025-10-19 Large File Benchmark Summary

## Environment

- **Date:** 2025-10-19
- **Host:** Linux (x86_64, Swift Package Manager toolchain 6.0.1)
- **Command Harness:** `swift test --filter LargeFileBenchmarkTests`
- **Configuration Profiles:**
  - CI defaults (`PerformanceBenchmarkConfiguration` intensity `.ci`)
  - Local stress profile (`ISOINSPECTOR_BENCHMARK_INTENSITY=local`)

## Configuration Budgets

| Intensity | Payload | Iterations | Slack Multiplier | CLI Budget (s) | UI Latency Budget (s) |
| --- | --- | --- | --- | --- | --- |
| CI (default) | 32 MiB | 3 | 1.5× | 0.527 | 0.300 |
| Local | 64 MiB | 5 | 1.2× | 0.844 | 0.240 |

Budgets derive from `PerformanceBenchmarkConfiguration` and the 4 GiB / 45 s reference throughput target.

## Results Overview

| Intensity | CLI Duration (s) | Within Budget? | Chunked Reader Random Slice (s) | Mapped Reader Random Slice (s) | Notes |
| --- | --- | --- | --- | --- | --- |
| CI (default) | 0.067 | ✅ | 5.285 | 0.412 | Random slice scenarios consumed 67,046 / 8,430,601 / 36,284,892 bytes per iteration and matched expected totals. |
| Local | 0.083 | ✅ | 8.751 | 0.771 | Larger 64 MiB payload maintained parity between readers; CLI stayed below 0.844 s budget. |

- The Combine-backed UI latency benchmark remains skipped on Linux due to unavailable framework support. macOS hardware follow-up continues to track the outstanding measurement.

## Raw Logs

- [`2025-10-19-benchmark-ci.log`](2025-10-19-benchmark-ci.log)
- [`2025-10-19-benchmark-local.log`](2025-10-19-benchmark-local.log)

Logs capture the full XCTest output, including per-test durations and scenario summaries for `ChunkedFileReader` and `MappedReader`.

## Reproduction Steps

1. Ensure Swift toolchain dependencies are fetched: `swift build`
2. Run CI-profile benchmarks: `swift test --filter LargeFileBenchmarkTests`
3. Run local stress benchmarks: `ISOINSPECTOR_BENCHMARK_INTENSITY=local swift test --filter LargeFileBenchmarkTests`
4. Collect the resulting logs from the terminal output or redirect them to files alongside this summary.

## Follow-Up Actions

- Schedule macOS Combine/UI latency benchmarks when hardware runners become available and store resulting logs next to this report.
- Incorporate future benchmark runs into release QA packages referenced by the Release Readiness runbook.
