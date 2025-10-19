# Summary of Work

## Completed

- **H4 — Performance Benchmark Validation**
  - Executed `LargeFileBenchmarkTests` with the default CI intensity and the developer-focused `ISOINSPECTOR_BENCHMARK_INTENSITY=local` profile to validate CLI throughput and random slice readers against `PerformanceBenchmarkConfiguration` budgets.
  - Confirmed CLI validation stays within configured budgets (0.067 s ≤ 0.527 s in CI, 0.083 s ≤ 0.844 s at local intensity) and that both `ChunkedFileReader` and `MappedReader` returned the exact expected byte totals for every random slice scenario.
  - Archived raw XCTest logs for both intensities under `Documentation/Performance/` and produced a Markdown summary so release reviewers can audit the captured metrics alongside future runs.

## Metrics Snapshot

| Intensity | Payload | Iterations | CLI Duration (s) | Budget (s) | Chunked Reader Random Slice (s) | Mapped Reader Random Slice (s) |
| --- | --- | --- | --- | --- | --- | --- |
| CI (default) | 32 MiB | 3 | 0.067 | 0.527 | 5.285 | 0.412 |
| Local | 64 MiB | 5 | 0.083 | 0.844 | 8.751 | 0.771 |

- UI latency benchmark remains skipped on Linux because Combine is unavailable; the macOS follow-up task continues to track the required hardware run.
- Random slice scenarios transfer 67,046 bytes (small), 8,430,601 bytes (medium), and 36,284,892 bytes (large) per iteration; logs confirm identical coverage for both readers at each intensity.

## Verification

- `swift test --filter LargeFileBenchmarkTests`
- `ISOINSPECTOR_BENCHMARK_INTENSITY=local swift test --filter LargeFileBenchmarkTests`

## Follow-up

- Execute the Combine-driven UI latency benchmark on macOS hardware once runners are available, capturing matching metrics for archive.
- Schedule the macOS CLI/UI benchmark protocol (Task R4) so the release runbook includes cross-platform throughput comparisons.
