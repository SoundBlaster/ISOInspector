# Next Tasks Queue

_Last updated: 2025-12-12 (UTC). Maintainers should update this file whenever task priorities change or blockers are resolved._

_No active items beyond the open NavigationSplitView width bug. Select the next task per `DOCS/COMMANDS/SELECT_NEXT.md`._

---

## 1. UI Defects & Experience Fixes

1. **Bug #234 – Remove Recent File from Sidebar** _(Resolved — see `DOCS/INPROGRESS/234_Remove_Recent_File_From_Sidebar.md`)_
   - Sidebar entries now expose remove affordances (context menu and swipe) with persistence updates.
2. **Bug #235 – Smoke tests blocked by Sendable violations** _(Resolved — `DOCS/INPROGRESS/235_Sendable_SmokeTest_Build_Failure.md`)_
   - Strict-concurrency build now passes after sendable annotations and document-loading refactor; smoke filters are green.
3. **Bug #246 – NavigationSplitView width overflow** _(In Discovery — `DOCS/INPROGRESS/246_Bug_NavigationSplit_Width_Overflow.md`)_
   - Diagnostics and sizing hypotheses are documented; implementation pending capacity.

## 2. Blocked but High Priority

- **Task T5.4 – macOS 1 GiB Lenient-vs-Strict Benchmark** _(Blocked — see `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/blocked.md`)_
  - Hardware requirement: a macOS host (Sonoma/Xcode 16.x) with the 1 GiB benchmark fixture accessible locally; Linux CI cannot execute this run.
  - Once hardware is available, export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, run `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`, and archive runtime/RSS metrics under `Documentation/Performance/`.
  - Keep the corresponding `todo.md` item open until the macOS execution completes and artifacts are published.

---

**How to use this queue:** Pull the highest-priority unblocked item, confirm no new blockers exist, and update this file (and any referenced planning docs) after changes land so downstream automation (`DOCS/COMMANDS/SELECT_NEXT.md`) has accurate context.
