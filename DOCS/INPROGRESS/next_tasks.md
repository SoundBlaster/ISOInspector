# Next Tasks Queue

_Last updated: 2025-11-19 (UTC). Maintainers should update this file whenever task priorities change or blockers are resolved._

## 0. FoundationUI Navigation Architecture (NEW)

> **Note:** Tasks 240, 241, and 242 have been completed and archived to `DOCS/TASK_ARCHIVE/234_Resolved_Tasks_Batch/` (2025-11-19). See ARCHIVE_SUMMARY.md for details.

1. **Task 243 – Reorganize NavigationSplitView: Selection Details & Integrity Summary in Inspector** _(Ready for implementation — `DOCS/INPROGRESS/243_Reorganize_Navigation_SplitView_Inspector_Panel.md`)_
   - Move Selection Details content (metadata, corruption, encryption, notes, fields, validation, hex) to third column (Inspector)
   - Move Integrity Summary to Inspector panel with toggle button in Box Tree panel header
   - Refactor ParseTreeDetailView into sub-components for better composability
   - Add toggle UI in Box Tree panel to switch between Selection Details and Integrity Summary views
   - Ensure responsive layout across macOS (3 columns), iPad (adaptive), iPhone (compact)
   - Implement keyboard shortcuts (⌘⌥I for inspector toggle) and VoiceOver labels
   - Create 25-30 unit tests, 10-15 integration tests, 4+ UI snapshot tests
   - Effort: ~4.5 days
   - Ready: 2025-11-19

---

## 1. Automation & Quality Gates

1. **Task A8 – Test Coverage Gate** ✅ _(Completed — `DOCS/INPROGRESS/A8_Test_Coverage_Gate.md`)_
   - `coverage_analysis.py --threshold 0.67` now runs in `.githooks/pre-push` after `swift test --enable-code-coverage` (macOS-only due to SwiftUI dependency) and blocks pushes on coverage failures.
   - CI `coverage-gate` job executes the same workflow on macOS runners and publishes logs/reports under `Documentation/Quality/`.
   - `todo.md` and the Execution Workplan have been updated to reflect the enforced gate and artifact locations.

2. **Task A10 – Swift Duplication Detection** _(Ready)_
   - Add `.github/workflows/swift-duplication.yml` that runs `scripts/run_swift_duplication_check.sh` (wrapper around `npx jscpd@3.5.10`).
   - Fail the workflow when duplicated lines exceed 1% or when any repeated block is >45 lines, and upload the console log artifact for review.
   - Link the rollout summary back to `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md` once complete.

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
