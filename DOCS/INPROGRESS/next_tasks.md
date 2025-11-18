# Next Tasks Queue

_Last updated: 2025-11-18 (UTC). Maintainers should update this file whenever task priorities change or blockers are resolved._

## 0. FoundationUI Navigation Architecture (NEW)

1. **Task 240 – NavigationSplitViewKit Integration** _(Ready for Implementation — `DOCS/INPROGRESS/240_NavigationSplitViewKit_Integration.md`)_
   - Add `NavigationSplitViewKit` SPM dependency to `FoundationUI/Package.swift` with proper version pinning (≥1.0.0)
   - Mirror dependency in Tuist manifests (`FoundationUI/Project.swift`) and regenerate lockfiles
   - Update CI workflows to cache the new dependency and monitor build time impact
   - Verify all targets (Examples, Tests) link `NavigationSplitViewKit` correctly
   - Effort: ~3 days; unblocked and ready to start immediately

2. **Task 241 – NavigationSplitScaffold Pattern** _(Pending Task 240 — `DOCS/INPROGRESS/241_NavigationSplitScaffold_Pattern.md`)_
   - Create wrapper pattern that applies Composable Clarity tokens to `NavigationSplitViewKit`
   - Provide environment key for downstream patterns to access navigation state
   - Implement DS-driven appearance with zero magic numbers
   - Author 35+ unit/integration tests covering three/two/single-column behavior across all platforms
   - Create 6+ SwiftUI Previews with real-world ISO Inspector mockup
   - Effort: ~4 days; depends on task 240

3. **Task 242 – Update Existing Patterns** _(Pending Tasks 240 + 241)_
   - Refactor `SidebarPattern`, `InspectorPattern`, `ToolbarPattern` previews/tests to adopt `NavigationSplitScaffold`
   - Ensure column visibility controls expose accessibility shortcuts and VoiceOver labels
   - Update agent YAML schemas to surface navigation bindings
   - Create 6+ integration tests verifying NavigationModel synchronization
   - Effort: ~2 days; depends on tasks 240 + 241

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

1. **Bug #232 – UI blank after selecting a file** _(Critical — `DOCS/INPROGRESS/232_UI_Content_Not_Displayed_After_File_Selection.md`)_
   - Reconnect `DocumentSessionController`/`WindowSessionController` bindings so the parse tree and report panes refresh when a file loads.
   - Add regression tests (UI snapshot or integration) to ensure the tree/report render after selecting files on macOS and iPadOS.

2. **Bug #234 – Remove Recent File from Sidebar** _(Ready for implementation — `DOCS/INPROGRESS/234_Remove_Recent_File_From_Sidebar.md`)_
   - Add the MRU removal affordance in the sidebar along with analytics/logging hooks described in the spec.
   - Ensure recents persistence updates and DocumentSessionController wiring reflect removals immediately.

## 3. Blocked but High Priority

- **Task T5.4 – macOS 1 GiB Lenient-vs-Strict Benchmark** _(Blocked — see `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/blocked.md`)_
  - Hardware requirement: a macOS host (Sonoma/Xcode 16.x) with the 1 GiB benchmark fixture accessible locally; Linux CI cannot execute this run.
  - Once hardware is available, export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, run `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`, and archive runtime/RSS metrics under `Documentation/Performance/`.
  - Keep the corresponding `todo.md` item open until the macOS execution completes and artifacts are published.

---

**How to use this queue:** Pull the highest-priority unblocked item, confirm no new blockers exist, and update this file (and any referenced planning docs) after changes land so downstream automation (`DOCS/COMMANDS/SELECT_NEXT.md`) has accurate context.
