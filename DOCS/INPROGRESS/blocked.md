# Blocked Tasks Log

The following efforts cannot proceed until their upstream dependencies are resolved. Update this log whenever blockers change to maintain day-to-day visibility.

## Real-World Assets Acquisition

- **Blocking issue:** Licensing approvals for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures are still pending.
- **Next step once unblocked:** Import the licensed assets and refresh regression baselines so tolerant parsing and export scenarios can validate against real-world payloads.
- **Notes:** Review the permanent blockers stored under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) to avoid duplicating retired work.

## macOS Benchmark Execution

- **Blocking issue:** macOS hardware with the 1 GiB performance fixture is unavailable in the current automation environment, precluding the lenient-versus-strict benchmark run documented in `DOCS/INPROGRESS/next_tasks.md`.
- **Next step once unblocked:** Execute the benchmark with `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, collect runtime and RSS metrics, and archive them under `Documentation/Performance/`.
- **Notes:** Keep `todo.md` entry "Execute the macOS 1 GiB lenient-vs-strict benchmark" open until the run completes and metrics are published.
