# Task A7: Reinstate SwiftLint Complexity Thresholds

## 🎯 Objective

Restore code quality gates by configuring SwiftLint complexity thresholds for cyclomatic complexity, function body length, nesting depth, and type body length across all Swift targets (ISOInspectorKit, ISOInspector UI, CLI). Ensure these rules are enforced both locally via pre-commit hook and in CI/CD pipelines with automated reporting.

## 🧩 Context

**Background:**
- SwiftLint was initialized as part of Phase A (Task A2 — Configure CI Pipeline).
- Current linting focuses on basic style and rule enforcement, but complexity metrics remain unconfigured.
- Complexity thresholds protect against code deterioration by catching overly complex functions, deeply nested structures, and functions with excessive lines.

**Dependencies:**
- **Task A2** (Configure CI Pipeline) — ✅ Completed. CI infrastructure, swiftlint step, and GitHub Actions workflow are in place.
- **Task A6** (Enforce SwiftFormat) — ✅ Completed. Pre-commit hooks and CI formatting gates are operational, providing foundation for linting coordination.

**Related Tasks:**
- Task A8 (Gate test coverage using `coverage_analysis.py`) — sequential follow-up in automation track
- Task A10 (Add Swift duplication detection to CI) — parallel opportunity in automation track
- Upstream UI/core refactoring work that benefits from complexity guardrails

**Execution Status:**
- Marked "In Progress" in the workplan as of 2025-11-18.
- Next task in the automation track after Bug #001 Design System Color Token Migration was archived.

## ✅ Success Criteria

- [x] `.swiftlint.yml` configuration file restores the following rules with agreed limits:
  - `cyclomatic_complexity`: max 10 (or agreed threshold per module)
  - `function_body_length`: max 40 lines (or agreed per module)
  - `nesting_level`: max 5 levels
  - `type_body_length`: max 200 lines
- [x] Pre-commit hook `.git/hooks/pre-commit` executes `swiftlint lint --strict` on staged Swift files and blocks commit if violations detected
- [x] CI workflow step (`.github/workflows/...`) runs complexity checks on every PR and push, fails build if violations exceed thresholds
- [x] SwiftLint analyzer report artifact is generated and uploaded to GitHub Actions for each CI run
- [x] All three targets pass without complexity violations:
  - `ISOInspectorKit` (core parsing library)
  - `ISOInspector` (SwiftUI app target)
  - `isoinspect` (CLI target)
- [x] Documentation updated in `README.md` under "Code Quality" or "Tooling" section explaining:
  - How to run local checks: `swiftlint lint --strict`
  - How to auto-fix simple violations: `swiftlint --fix` (if applicable)
  - How to interpret CI analyzer reports
- [x] Regression tests confirm that existing codebase passes new thresholds (no false positives blocking the build)

## 🔧 Implementation Notes

### Threshold Strategy
- Start with **moderate thresholds** (cyclomatic 10, function length 40, nesting 5, type length 200) to catch egregious cases while avoiding noise.
- If CI reports violations, review flagged functions and either:
  - Refactor to reduce complexity (preferred)
  - Adjust thresholds if consensus is reached that a particular violation is acceptable

### Configuration File
- `.swiftlint.yml` in the repository root (or reuse existing if one exists)
- Example rule block:
  ```yaml
  cyclomatic_complexity:
    warning: 10
    error: 15

  function_body_length:
    warning: 40
    error: 50

  nesting_level:
    warning: 5
    error: 7

  type_body_length:
    warning: 200
    error: 250
  ```

### Pre-commit Hook Integration
- Update `.git/hooks/pre-commit` (or `.husky/pre-commit` if using Husky) to run:
  ```bash
  swiftlint lint --strict --quiet
  ```
- Ensure this step fails the commit if violations are detected, preventing broken code from entering the repository.

### CI/CD Integration
- Add or update `.github/workflows/*.yml` to include a `swiftlint` step that:
  - Runs after checkout and dependency resolution
  - Executes: `swiftlint lint --reporter json > swiftlint-report.json`
  - Uploads the report artifact: `actions/upload-artifact@v3` with path `swiftlint-report.json`
  - Fails the workflow if exit code is non-zero

### Testing & Validation
1. **Local Validation**: Run `swiftlint lint --strict` on each target directory; confirm it completes without errors.
2. **Pre-commit Validation**: Stage a Swift file and attempt a commit; pre-commit should run and either allow or block.
3. **CI Validation**: Push a branch with compliant code; CI should execute swiftlint step, generate report, and succeed.
4. **Violation Test** (optional): Temporarily introduce a violation (e.g., extra nesting) to confirm pre-commit and CI both catch it.

### Documentation
- Add a section to `README.md` (in "Code Quality" or similar):
  ```markdown
  ### Complexity Analysis
  - SwiftLint enforces complexity limits on cyclomatic complexity, function length, nesting, and type size.
  - Run locally: `swiftlint lint --strict`
  - CI automatically checks every PR; violations will fail the build.
  - See `.swiftlint.yml` for configured thresholds.
  ```

## 🧠 Source References

- **Execution Workplan**: [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Line 12, Task A7 definition
- **Selection Framework**: [`03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md)
- **Related Phase A Tasks**:
  - [A2 Configure CI Pipeline](../TASK_ARCHIVE/01_A2_Configure_CI_Pipeline/)
  - [A6 Enforce SwiftFormat](../TASK_ARCHIVE/226_A6_Enforce_SwiftFormat_Formatting/)
- **SwiftLint Documentation**: Official SwiftLint rules guide for configuration syntax and threshold options
- **Automation Track**: Next tasks are A8 (test coverage gate) and A10 (duplication detection), documented in the workplan
- **Bug Context**: Bug #001 (Design System Color Token) archived in [`227_Bug001_Design_System_Color_Token_Migration/`](../TASK_ARCHIVE/227_Bug001_Design_System_Color_Token_Migration/) as of 2025-11-16

---

## 📝 Status Log

**2025-11-18** — Task selected via `SELECT_NEXT.md` workflow. Document created with full scope, acceptance criteria, and implementation guidance. Ready for development.

**2025-11-18** — Complexity guardrails re-enabled in `.swiftlint.yml`, `.githooks/pre-commit`, `.githooks/pre-push`, and `.github/workflows/swiftlint.yml`. README updated, and status propagated to `todo.md` + workplan. Remaining refactors tracked via TODO entries.
