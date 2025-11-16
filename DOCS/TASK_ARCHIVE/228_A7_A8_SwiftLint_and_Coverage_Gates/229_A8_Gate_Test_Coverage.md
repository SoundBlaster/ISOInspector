# A8 — Gate Test Coverage Using `coverage_analysis.py`

## 🎯 Objective
Ensure test coverage stays above the agreed 67% threshold by running `coverage_analysis.py --threshold 0.67` in both the pre-push hook and GitHub Actions workflow, blocking merges or pushes that fall below the target and publishing the report artifact.

## 🧩 Context
- Phase A infrastructure tasks A1–A7 established CI, formatting, and lint guardrails; A2 (CI pipeline) is complete, so coverage gating can hook into existing workflows.
- `coverage_analysis.py` already lives at the repo root and enumerates FoundationUI sources/tests to calculate a ratio, but it is not currently enforced anywhere.
- The execution workplan (`04_TODO_Workplan.md`) calls for integrating this script post-A2 so test debt is caught early, and `next_tasks.md` lists it as the highest-priority automation follow-up after A7.
- No blockers are listed in `blocked.md`, and the task is not archived as permanently blocked.

## ✅ Success Criteria
- `coverage_analysis.py --threshold 0.67` runs automatically after `swift test --enable-code-coverage` in the pre-push hook; pushes abort with a clear error if the ratio drops below 67%.
- GitHub Actions adds a coverage job that executes the script against generated `.build/debug/codecov/` data, fails the workflow when coverage <67%, and uploads the textual report under `Documentation/Quality/` as an artifact.
- Documentation (README tooling or Docs/Guides coverage section) explains how to run the script locally, interpret the output, and update thresholds if requirements change.
- The task is removed from `next_tasks.md` candidates and tracked by this document until archived.

## 🔧 Implementation Notes
- Update or create automation scripts so `coverage_analysis.py` reads repo-relative paths (current hardcoded `/home/user/ISOInspector/FoundationUI` needs to be made dynamic).
- Extend `.git/hooks/pre-push` (or equivalent script) to run `swift test --enable-code-coverage` followed by the Python coverage gate. Ensure the hook is documented for contributors via `README.md` or `Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md`.
- Create/modify a GitHub Actions workflow (likely `ci.yml`) to cache build artifacts, invoke tests with coverage flags, run the script with `python3 coverage_analysis.py --threshold 0.67 --report Documentation/Quality/coverage-<run>.txt`, and upload the report as an artifact.
- Consider parameterizing the threshold via environment variable (`ISOINSPECTOR_MIN_TEST_COVERAGE=0.67`) so future adjustments do not require script changes.
- Capture verification evidence (logs, artifact links) for archival once work is complete.

## 🧠 Source References
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`coverage_analysis.py`](../../coverage_analysis.py)
