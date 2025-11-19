# Next Tasks Queue

_Last updated: 2025-11-21 (UTC). Maintainers should update this file whenever task priorities change or blockers are resolved._

## 0. FoundationUI Navigation Architecture (NEW)

1. **Task 240 – NavigationSplitViewKit Integration** ✅ _(Completed — `DOCS/INPROGRESS/Summary_of_Work_Task_240.md`)_
   - Added `NavigationSplitViewKit` SPM dependency to `FoundationUI/Package.swift` with version ≥1.0.0
   - Mirrored dependency in Tuist manifests (`FoundationUI/Project.swift`)
   - Updated CI workflows with SPM dependency caching
   - Verified all targets link NavigationSplitViewKit correctly
   - Completed: 2025-11-18

2. **Task 241 – NavigationSplitScaffold Pattern** ✅ _(Completed — `DOCS/INPROGRESS/Summary_of_Work_Task_241.md`)_
   - Created NavigationSplitScaffold wrapper pattern with Composable Clarity tokens
   - Implemented environment key for downstream patterns to access navigation state
   - All layout uses DS tokens (zero magic numbers)
   - Authored 35 comprehensive unit/integration tests
   - Created 6 SwiftUI Previews including ISO Inspector reference implementation
   - Completed: 2025-11-18

3. **Task 242 – Update Existing Patterns** ✅ _(Completed — `DOCS/INPROGRESS/Summary_of_Work_Task_242.md`)_
   - Refactor `SidebarPattern`, `InspectorPattern`, `ToolbarPattern` to integrate with `NavigationSplitScaffold`
   - Add environment-based navigation model access with backward compatibility
   - Ensure column visibility controls expose accessibility shortcuts and VoiceOver labels
   - Update agent YAML schemas to surface navigation bindings
   - Create 9+ unit tests and 6+ integration tests verifying NavigationModel synchronization
   - Completed: 2025-11-19

4. **Task 243 – Reorganize NavigationSplitView: Selection Details & Integrity Summary in Inspector** _(Ready for implementation — `DOCS/INPROGRESS/243_Reorganize_Navigation_SplitView_Inspector_Panel.md`)_
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

1. **Task A7 – SwiftLint Complexity Thresholds** _(In Progress — `DOCS/INPROGRESS/A7_SwiftLint_Complexity_Thresholds.md`)_
   - Finish the three #A7 refactors called out in `todo.md` so `JSONParseTreeExporter`, `BoxValidator`, and `DocumentSessionController` meet `type_body_length` and `nesting_level` targets.
   - Re-enable strict `swiftlint lint --strict` locally and in `.github/workflows/swiftlint.yml`, ensuring the analyzer artifact upload remains intact.
   - Document the workflow in `README.md` once the thresholds stay green across ISOInspectorKit, ISOInspectorApp, and the CLI.

2. **Task A8 – Test Coverage Gate** _(Ready — depends on A7)_
   - Wire `coverage_analysis.py --threshold 0.67` into `.githooks/pre-push` and `.github/workflows/ci.yml` immediately after `swift test --enable-code-coverage`.
   - Publish the HTML or JSON coverage artifacts under `Documentation/Quality/` so regressions have concrete data.
   - Update `todo.md` and `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` once the hook and CI gate are enforced.

3. **Task A10 – Swift Duplication Detection** _(Ready)_
   - Add `.github/workflows/swift-duplication.yml` that runs `scripts/run_swift_duplication_check.sh` (wrapper around `npx jscpd@3.5.10`).
   - Fail the workflow when duplicated lines exceed 1% or when any repeated block is >45 lines, and upload the console log artifact for review.
   - Link the rollout summary back to `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md` once complete.

## 2. UI Defects & Experience Fixes

1. **Bug #234 – Remove Recent File from Sidebar** _(Ready for implementation — `DOCS/INPROGRESS/234_Remove_Recent_File_From_Sidebar.md`)_
   - Add the MRU removal affordance in the sidebar along with analytics/logging hooks described in the spec.
   - Ensure recents persistence updates and DocumentSessionController wiring reflect removals immediately.

## 3. Blocked but High Priority

- **Task T5.4 – macOS 1 GiB Lenient-vs-Strict Benchmark** _(Blocked — see `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/blocked.md`)_
  - Hardware requirement: a macOS host (Sonoma/Xcode 16.x) with the 1 GiB benchmark fixture accessible locally; Linux CI cannot execute this run.
  - Once hardware is available, export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, run `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`, and archive runtime/RSS metrics under `Documentation/Performance/`.
  - Keep the corresponding `todo.md` item open until the macOS execution completes and artifacts are published.

---

**How to use this queue:** Pull the highest-priority unblocked item, confirm no new blockers exist, and update this file (and any referenced planning docs) after changes land so downstream automation (`DOCS/COMMANDS/SELECT_NEXT.md`) has accurate context.
