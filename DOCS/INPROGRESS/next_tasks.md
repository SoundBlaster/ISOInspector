# Next Tasks Queue

_Last updated: 2025-11-19 (UTC). Maintainers should update this file whenever task priorities change or blockers are resolved._

## 0. FoundationUI Navigation Architecture (NEW)

> **Note:** Tasks 240, 241, and 242 have been completed and archived to `DOCS/TASK_ARCHIVE/234_Resolved_Tasks_Batch/` (2025-11-19). See ARCHIVE_SUMMARY.md for details.

_No active items in this queue. Select the next task per `DOCS/COMMANDS/SELECT_NEXT.md`._

---

## 1. Automation & Quality Gates

1. **Task A8 – Test Coverage Gate** ✅ _(Completed — `DOCS/INPROGRESS/A8_Test_Coverage_Gate.md`)_
   - `coverage_analysis.py --threshold 0.67` now runs in `.githooks/pre-push` after `swift test --enable-code-coverage` (macOS-only due to SwiftUI dependency) and blocks pushes on coverage failures.
   - CI `coverage-gate` job executes the same workflow on macOS runners and publishes logs/reports under `Documentation/Quality/`.
   - `todo.md` and the Execution Workplan have been updated to reflect the enforced gate and artifact locations.

2. **Task A10 – Swift Duplication Detection** ✅ _(Completed — `DOCS/INPROGRESS/A10_Swift_Duplication_Detection.md`)_
   - `.github/workflows/swift-duplication.yml` runs `scripts/run_swift_duplication_check.sh` (Node 20 + `npx jscpd@3.5.10`) on PR/main pushes with 30-day artifact retention.
   - Thresholds enforced: >1% overall duplication or ≥45-line clones fail the job; report saved as `swift-duplication-report.txt`. Pre-push runs the same gate and writes reports under `Documentation/Quality/`.

## 2. UI Defects & Experience Fixes

1. **Bug #234 – Remove Recent File from Sidebar** _(Ready for implementation — `DOCS/INPROGRESS/234_Remove_Recent_File_From_Sidebar.md`)_
   - Add the MRU removal affordance in the sidebar along with analytics/logging hooks described in the spec.
   - Ensure recents persistence updates and DocumentSessionController wiring reflect removals immediately.
3. **Bug #235 – Smoke tests blocked by Sendable violations** _(Resolved — `DOCS/INPROGRESS/235_Sendable_SmokeTest_Build_Failure.md`)_
   - Strict-concurrency build now passes after sendable annotations and document-loading refactor; smoke filters are green.

## 3. Blocked but High Priority

- **Task T5.4 – macOS 1 GiB Lenient-vs-Strict Benchmark** _(Blocked — see `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/blocked.md`)_
  - Hardware requirement: a macOS host (Sonoma/Xcode 16.x) with the 1 GiB benchmark fixture accessible locally; Linux CI cannot execute this run.
  - Once hardware is available, export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, run `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`, and archive runtime/RSS metrics under `Documentation/Performance/`.
  - Keep the corresponding `todo.md` item open until the macOS execution completes and artifacts are published.

---

**How to use this queue:** Pull the highest-priority unblocked item, confirm no new blockers exist, and update this file (and any referenced planning docs) after changes land so downstream automation (`DOCS/COMMANDS/SELECT_NEXT.md`) has accurate context.
