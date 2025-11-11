# Next Tasks

- [ ] Run the lenient-versus-strict benchmark on macOS hardware with Combine enabled using the 1 GiB fixture:
  - Export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`.
  - Invoke `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`.
  - Archive the printed runtime and RSS metrics under `Documentation/Performance/` alongside the existing 32 MiB results.
  - Cross-check results against the archived Linux baseline in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log` and note deviations in the summary log.
