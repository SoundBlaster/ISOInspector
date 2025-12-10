# A8 — Test Coverage Gate

## 🎯 Objective
Add automated coverage enforcement so pushes and CI runs fail when overall Swift test coverage drops below the 0.67 threshold, and publish coverage artifacts for inspection.

## 🧩 Context
- Ranked as a Phase A infrastructure task with Medium priority and dependency on A2 (CI pipeline) already satisfied. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L24】
- Listed in the root TODO as a pending quality gate to wire into pre-push hooks and CI. 【F:todo.md†L14-L27】
- No active blockers recorded in `DOCS/INPROGRESS/blocked.md` or the BLOCKED archive directory as of selection.

## ✅ Success Criteria
- `.githooks/pre-push` runs `coverage_analysis.py --threshold 0.67` after `swift test --enable-code-coverage` and blocks pushes when coverage is below the threshold.
- `.github/workflows/ci.yml` runs the same coverage gate post-tests and fails the workflow when the threshold is not met.
- Coverage report artifacts (HTML or JSON) are uploaded under `Documentation/Quality/` for CI runs.
- Planning files (`todo.md`, Execution Workplan) are updated to reflect the enforced gate once implemented.

## 🔧 Implementation Notes
- Reuse the existing `coverage_analysis.py` utility; verify its invocation path matches repository layout.
- Ensure pre-push hook changes preserve executable permissions and are mirrored in CI to avoid divergence.
- If coverage artifacts are large, consider pruning history or compressing before upload to keep CI artifacts lightweight.
- Validate coverage data paths for both SwiftPM packages and workspace targets to avoid missing modules.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

## ✅ Resolution Notes — 2025-12-12

- **Pre-push enforcement:** `.githooks/pre-push` now runs `swift test --package-path FoundationUI --enable-code-coverage` followed by `coverage_analysis.py --threshold 0.67` (reporting to `Documentation/Quality/`). Pushes fail if either the coverage test run or threshold check fails. Threshold respects `ISOINSPECTOR_MIN_TEST_COVERAGE` when set.
- **CI enforcement:** `.github/workflows/ci.yml` adds a macOS `coverage-gate` job that executes the same FoundationUI coverage test run, invokes the coverage analysis with a 0.67 threshold, and uploads logs/reports from `Documentation/Quality/` as CI artifacts.
- **Artifacts:** Coverage logs and reports are stored under `Documentation/Quality/` for both local hooks and CI, providing a consistent audit trail for regressions.
