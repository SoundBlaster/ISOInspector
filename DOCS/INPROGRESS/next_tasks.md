# Next Tasks

- [ ] Run the lenient-versus-strict benchmark on macOS hardware with Combine enabled using the 1 GiB fixture:
  - Export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`.
  - Invoke `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`.
  - Archive the printed runtime and RSS metrics under `Documentation/Performance/` alongside the existing 32 MiB results.
