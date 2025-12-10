# A10 — Swift Duplication Detection

**Status**: COMPLETED

## 🎯 Objective
Ship the Swift duplication guard workflow so CI fails whenever duplicated Swift code exceeds 1% or any single clone surpasses 45 lines, keeping the codebase maintainable alongside the existing lint, format, and coverage gates.

## 🧩 Context
- Phase A automation follow-up after completing A7 (SwiftLint guard) and A8 (coverage gate); execution workplan lists A10 as the next unblocked infrastructure task.
- PRD `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md` defines the workflow scope, thresholds, and documentation touch points.
- Current CI lacks duplication enforcement, so regressions risk slipping through while other gates are green.
- Requires only existing CI capabilities (Node 20 already available); no blockers recorded in `next_tasks.md` or workplan.

## ✅ Success Criteria
- `.github/workflows/swift-duplication.yml` runs on `push` to `main` and `pull_request`, executing `scripts/run_swift_duplication_check.sh`.
- Workflow provisions Node 20, runs `npx jscpd@3.5.10` against Swift sources, and fails when duplicated percentage exceeds 1.0% or any block is ≥45 lines.
- Console report saved to `artifacts/swift-duplication-report.txt` (or similar) and uploaded via `actions/upload-artifact` for each CI run.
- Pre-push integration implemented: the pre-push hook invokes the duplication check via the wrapper and stores its report under `Documentation/Quality/`, so developers can check duplication before pushing.
- Documentation updated (`todo.md`, Execution Workplan row A10, and refs inside the PRD) to indicate both the CI gate and pre-push hook are live with remediation guidance.

## 📦 Delivery Notes (2025-12-18)
- Added `scripts/run_swift_duplication_check.sh` wrapper for `npx jscpd@3.5.10` with the Phase A thresholds (≤1% overall, <45-line clones) and ignores for generated artifacts/Derived/.build/TestResults. Console output is mirrored to `artifacts/swift-duplication-report.txt`, scoped to Swift files only.
- Introduced `.github/workflows/swift-duplication.yml` that provisions Node 20, runs the wrapper on PRs and pushes to `main`, and uploads the `swift-duplication-report` artifact with 30-day retention.
- Updated documentation touchpoints (`todo.md`, `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`, `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md`) with live-gate status and remediation guidance; pre-push hook now invokes the wrapper and stores reports under `Documentation/Quality/`.
- Deduplicated the shared `InMemoryRandomAccessReader` helper into `Sources/ISOInspectorKit/TestSupport/` to clear the last in-repo clone and keep test support centralized.

## 🔧 Implementation Notes
- Add helper script `scripts/run_swift_duplication_check.sh` that wraps the exact `jscpd` invocation so developers can run it locally; ensure executable bit set and path used by CI workflow.
- `jscpd` flags per PRD: `--format swift --pattern "**/*.swift" --reporters console --min-tokens 120 --threshold 1 --max-lines 45 --ignore "**/Derived/**" "**/Documentation/**" "**/.build/**" "**/TestResults-*"` (adjust ignore list if needed for generated artifacts).
- Use `actions/setup-node@v4` with caching to reduce install time; rely on `npm config set fund false` to keep logs quiet if needed.
- Artifact upload should retain at least 30 days to match other CI logs; align naming with coverage/SARIF artifacts for consistency.
- Update `DOCS/INPROGRESS/next_tasks.md` to mark A10 as in progress and remove it from the queue of ready items.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`PRD: Swift Duplication Guard`](../AI/github-workflows/02_swift_duplication_guard/prd.md)
