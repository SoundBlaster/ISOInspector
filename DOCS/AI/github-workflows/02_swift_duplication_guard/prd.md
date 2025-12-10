# PRD: Swift Code Duplication Guard Workflow

## 1. Purpose
Prevent copy‑paste regressions across ISOInspector's Swift targets by adding an automated GitHub Actions workflow that fails when duplicated Swift code exceeds the agreed allowance. The workflow keeps the codebase maintainable in line with the Phase A infrastructure goals (`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`) and extends the CI coverage that was introduced by Task A2 and reinforced through the SwiftLint (`A7`) and DocC (`F7`) gates.

## 2. Background & Research
- **Prior automation:** Task A2 established the CI skeleton (`.github/workflows/ci.yml`). Follow-up gates (SwiftFormat A6, SwiftLint A7, coverage enforcement A8) ensure style and quality but do not watch for structural duplication.
- **Related docs:**
  - `todo.md` already lists work to re-enable SwiftFormat, SwiftLint, coverage, DocC, and strict concurrency. None cover duplicated code.
  - `DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md` tracks maintainability NFRs but lacks an explicit duplication guard.
  - `DOCS/TASK_ARCHIVE/101_Summary_of_Work_2025-10-19_SwiftLint_Cleanup.md` shows SwiftLint-based automation patterns we can reuse for reporting/artifacts.
- **Tooling survey:** SwiftLint lacks a general-purpose duplication rule, so we will rely on [`jscpd`](https://github.com/kucherenko/jscpd), which supports Swift analysis and integrates cleanly into GitHub Actions via Node. Runners already install Node for DocC and lint workflows, so no additional base image work is needed.

## 3. Scope
### Included
- Add `.github/workflows/swift-duplication.yml` that runs on `pull_request` and `push` to `main` when Swift sources change.
- Use `actions/setup-node` to provision Node 20 and execute `npx jscpd@3.5.10` across `Sources/`, `Tests/`, `Examples/`, and `FoundationUI/` Swift files.
- Configure detection thresholds: `--min-tokens 120`, fail when duplicated percentage >1.0% or when any block larger than 45 lines repeats.
- Upload the console report as an artifact for historical tracking.
- Document invocation + remediation guidance inside the repository docs.

### Excluded
- Automatic refactoring or PR annotations—scope limited to detection.
- Non-Swift languages (Shell, Python, Markdown) for this task.
- Runner caching optimizations (follow-up optional).

## 4. Workflow Design
1. **Triggers**
   - `pull_request` for all branches.
   - `push` to `main` so regressions are caught on direct pushes.
2. **Job `swift-duplication`**
   - `runs-on: ubuntu-22.04` (matches other CI jobs).
   - Steps:
     1. `actions/checkout@v4` with fetch-depth 1.
     2. `actions/setup-node@v4` with `node-version: '20'` and `cache: 'npm'` to reuse downloads between runs.
    3. Run `npx jscpd@3.5.10 --format swift --pattern "**/*.swift" --reporters console --min-tokens 120 --threshold 1 --max-lines 45 --ignore "**/Derived/**" "**/Documentation/**" "**/.build/**" "**/TestResults-*"` to scope detection strictly to Swift sources and fail on >1% or ≥45-line clones.
     4. Pipe the output to `tee artifacts/swift-duplication-report.txt` and upload via `actions/upload-artifact@v4`.
   - The job fails automatically when `jscpd` exits with status 1 (duplicates detected over threshold).

## 5. Implementation Plan
1. **Script Wrapper (optional but recommended)**
   - Add `scripts/run_swift_duplication_check.sh` to wrap the `jscpd` invocation (shared by CI and developers).
2. **Workflow Authoring**
   - Create `.github/workflows/swift-duplication.yml` per §4.
   - Reference the script wrapper to keep CLI parity.
3. **Documentation Updates**
   - Document the new gate in `todo.md` and `DOCS/INPROGRESS/next_tasks.md` backlog sections.
   - Add maintainability requirement `NFR-MAINT-005` in `DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md`.
   - Link the workplan row (A10) back to this PRD.
4. **Local Tooling**
  - Extend `.githooks/pre-push` to invoke the wrapper so local pushes mirror CI results (Node 20, Swift-only scope, same ignore list).

## 6. Acceptance Criteria
- Workflow runs automatically for the configured triggers and fails when duplicates exceed thresholds.
- Console output clearly lists file paths, line ranges, and duplicate percentages.
- Artifact contains raw report for offline review.
- Documentation reflects the new quality gate, referencing this PRD.

## 10. Deployment Status & Remediation (2025-12-18)
- **Deployment:** `.github/workflows/swift-duplication.yml` now provisions Node 20, runs `scripts/run_swift_duplication_check.sh` (wrapper around `npx jscpd@3.5.10` with Swift-only pattern), and uploads `swift-duplication-report.txt` artifacts for 30 days.
- **Run locally:** Execute `scripts/run_swift_duplication_check.sh` (set `REPORT_PATH=/tmp/swift-duplication-report.txt` to avoid creating repo-local artifacts). Ensure Node 20 is available. `.githooks/pre-push` invokes the same wrapper and stores reports under `Documentation/Quality/`.
- **Remediation:** Refactor repeated blocks to keep clones <45 lines and total duplication <1%. For generated outputs, adjust the ignore list in the wrapper + workflow with justification in commit messages and docs rather than raising thresholds. Re-run the script to confirm a zero-violation exit before pushing.

## 7. Metrics & Reporting
| Metric | Target | Source |
|--------|--------|--------|
| Duplicated lines (%) | ≤ 1.0% | `jscpd` summary line |
| Largest duplicate block | < 45 lines | `jscpd` violation entries |
| Run duration | ≤ 2 minutes | GitHub Actions timing |

## 8. Dependencies & Risks
- **Dependencies:** Node toolchain availability on runners; Git LFS checkout for fixtures (already handled by existing workflows).
- **Risks:** False positives if generated code shares large templates. Mitigation: ignore lists for generated directories (Derived, DocC, `.build`, etc.) and adjust `--min-tokens` as needed.

## 9. Open Questions / Follow-Ups
- Should we add PR annotations via the Checks API? (Deferred.)
- Should the duplication check gate merges when `jscpd` is unreachable? Proposed behavior: treat tool failures as CI failures to avoid silent skips.
- Future improvement: add SARIF output for integration with GitHub code scanning.
