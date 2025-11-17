# A8 — Gate Test Coverage Using `coverage_analysis.py`

## 🎯 Objective

Ensure test coverage stays above the agreed **67% threshold** by running `coverage_analysis.py --threshold 0.67` in both the **pre-push hook** and **GitHub Actions workflow**, blocking merges or pushes that fall below the target and publishing the report artifact.

## 🧩 Context

**Phase A infrastructure tasks** A1–A7 established CI, formatting, and lint guardrails. Task **A2** (CI pipeline) is complete, so coverage gating can hook into existing workflows.

- `coverage_analysis.py` already lives at the repo root and enumerates sources/tests to calculate a ratio, but it is **not currently enforced** anywhere.
- The execution workplan (`04_TODO_Workplan.md`) calls for integrating this script post-A2 so test debt is caught early.
- `next_tasks.md` in the archive lists it as the highest-priority automation follow-up after A7.
- **No blockers** identified in `blocked.md`.

**Dependencies satisfied:**
- ✅ A1 — SwiftPM workspace initialized
- ✅ A2 — CI pipeline configured (GitHub Actions)
- ✅ A7 — SwiftLint complexity thresholds reinstated

## ✅ Success Criteria

- [ ] `coverage_analysis.py --threshold 0.67` runs automatically **after** `swift test --enable-code-coverage` in the **pre-push hook**.
- [ ] Pushes **abort with a clear error** if the coverage ratio drops below 67%.
- [ ] GitHub Actions adds a **coverage job** that:
  - Executes the script against generated `.build/debug/codecov/` data.
  - **Fails the workflow** when coverage <67%.
  - **Uploads the textual report** under `Documentation/Quality/` as an artifact.
- [ ] Documentation (README tooling or Docs/Guides coverage section) explains how to:
  - Run the script locally.
  - Interpret the output.
  - Update thresholds if requirements change.
- [ ] The task is **removed from `next_tasks.md`** candidates and archived once complete.

## 🔧 Implementation Notes

### 1. Fix Dynamic Path Resolution in `coverage_analysis.py`

**Current issue:** Script has hardcoded path `/home/user/ISOInspector/FoundationUI`.

**Fix:**
- Make paths **repository-relative** using `__file__` or `cwd`.
- Update source/test discovery to work from repo root.
- Document path resolution strategy in script comments.

### 2. Extend Pre-Push Hook Integration

**Location:** `.git/hooks/pre-push` (or equivalent automation script).

**Steps:**
- Run `swift test --enable-code-coverage` before hook check.
- Invoke `python3 coverage_analysis.py --threshold 0.67`.
- Capture exit code; abort push if code ≠ 0.
- Emit clear error message with:
  - Current coverage percentage.
  - Threshold (67%).
  - Link to remediation guidance.
- Document hook setup in:
  - `README.md` (tooling section).
  - `Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md`.

### 3. Create/Extend GitHub Actions Coverage Workflow

**Workflow file:** `.github/workflows/coverage.yml` (new) or extend `ci.yml`.

**Steps:**
- Cache `.build/debug/codecov/` across runs.
- Run `swift test --enable-code-coverage`.
- Execute `python3 coverage_analysis.py --threshold 0.67 --report Documentation/Quality/coverage-<run>.txt`.
- **Fail workflow** if exit code ≠ 0.
- **Upload artifact** with coverage report.

**Environment variable parameterization:**
- Consider `ISOINSPECTOR_MIN_TEST_COVERAGE=0.67` for future flexibility.

### 4. Documentation

Update or create:
- README.md — brief overview of coverage gating.
- `Documentation/ISOInspector.docc/Guides/TestingAndCoverage.md` (new) — detailed guide:
  - How to run locally.
  - How to interpret `coverage_analysis.py` output.
  - Threshold change procedure.
  - Artifact location in CI runs.

### 5. Verification & Archival

**Capture evidence:**
- Links to successful CI runs with coverage reports.
- Screenshots of pre-push hook output.
- Test logs showing coverage enforcement.

**Condition for archival:**
- All success criteria met.
- A8 removed from `next_tasks.md`.
- New task document archived to `DOCS/TASK_ARCHIVE/230_A8_Gate_Test_Coverage/`.

## 🧠 Source References

- [`04_TODO_Workplan.md`](../../DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_Master_PRD.md`](../../DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`ISOInspector_PRD_TODO.md`](../../DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../../DOCS/RULES)
- [`coverage_analysis.py`](../../coverage_analysis.py)
- [`229_A8_Gate_Test_Coverage.md`](../../DOCS/TASK_ARCHIVE/228_A7_A8_SwiftLint_and_Coverage_Gates/229_A8_Gate_Test_Coverage.md) (Previous PRD)
- [`DeveloperOnboarding.md`](../../Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md)
