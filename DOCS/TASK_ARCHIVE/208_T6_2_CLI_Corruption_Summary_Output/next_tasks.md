# Next Tasks

- [ ] Run the lenient-versus-strict benchmark on macOS hardware with Combine enabled using the 1 GiB fixture:
  - Export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`.
  - Invoke `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`.
  - Archive the printed runtime and RSS metrics under `Documentation/Performance/` alongside the existing 32 MiB results.
  - Cross-check results against the archived Linux baseline in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log` and note deviations in the summary log.
  - _Status after archival:_ Carried forward to the active checklist at `DOCS/INPROGRESS/next_tasks.md` while macOS hardware remains unavailable.

- [x] Extend CLI output to show corruption summary metrics (Task T6.2):
  - _Status after archival:_ Completed in this folder — see `208_T6_2_CLI_Corruption_Summary_Output.md` and `Summary_of_Work.md` for implementation notes and verification logs.
  - Depends on Task T2.3 metrics aggregation (`ParseIssueStore.metricsSnapshot()` / `makeIssueSummary()`) now available.
  - Capture CLI snapshot tests covering strict success, lenient without issues, and lenient with mixed-severity issues.
