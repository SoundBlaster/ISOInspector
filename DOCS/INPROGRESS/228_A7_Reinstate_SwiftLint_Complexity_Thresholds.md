# A7 — Reinstate SwiftLint Complexity Thresholds

## 🎯 Objective

Restore and enforce SwiftLint complexity thresholds across the ISOInspector codebase to prevent code quality regressions. This task hardifies quality gates by configuring cyclomatic complexity, function body length, nesting depth, and type body length limits in `.swiftlint.yml` and integrating them into the pre-commit hook and CI pipeline.

## 🧩 Context

- **Phase:** A — Foundations & Infrastructure
- **Dependencies:** A2 ✅ (CI pipeline configured)
- **Related:** A2, A6 (SwiftFormat enforcement), A8 (Test Coverage Gate), A10 (Duplication Detection)
- **Blocking:** None — can proceed immediately
- **Master PRD Reference:** [ISOInspector_Master_PRD.md](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- **Workplan Reference:** [04_TODO_Workplan.md](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md), Phase A, Task A7

## ✅ Success Criteria

The task is complete when:

1. ✅ `.swiftlint.yml` is updated with complexity threshold rules:
   - `cyclomatic_complexity` (default ~10 nesting levels)
   - `function_body_length` (default ~200 lines)
   - `type_body_length` (default ~200 lines)
   - `nesting` depth limits
   - All thresholds tuned to current codebase state

2. ✅ Pre-commit hook (`.githooks/pre-push`) runs `swiftlint lint --strict` to fail pushes on violations

3. ✅ CI workflow (`.github/workflows/ci.yml`) includes a SwiftLint analyzer step that:
   - Runs `swiftlint lint --strict`
   - Publishes analyzer report artifact on violation
   - Fails the workflow when thresholds exceeded

4. ✅ All existing code in `Sources/` and `Tests/` passes the reinstated thresholds (no violations)

5. ✅ Documentation updated:
   - README.md or CONTRIBUTING.md reflects complexity limits and how to check locally
   - Clear guidance on exceeding thresholds (refactoring strategy, exceptions)

6. ✅ Verification:
   - Run `swiftlint lint --strict` locally; zero violations
   - Trigger CI workflow; SwiftLint step passes

## 🔧 Implementation Notes

### Step 1: Audit Current Codebase Complexity
- Run `swiftlint` with permissive thresholds to identify any existing violations
- Capture metrics for `cyclomatic_complexity`, `function_body_length`, `nesting`, `type_body_length`
- Choose thresholds that allow 95%+ of existing code to pass without refactoring

### Step 2: Update `.swiftlint.yml`
- Enable/restore the four complexity rules with chosen thresholds
- Set `enabled_rules` and `disabled_rules` appropriately
- Verify rule syntax against SwiftLint documentation (v0.52+)

### Step 3: Wire into Pre-Commit & CI
- Update `.githooks/pre-push` to include:
  ```bash
  swiftlint lint --strict
  ```
- Update `.github/workflows/ci.yml` to add a new step:
  ```yaml
  - name: SwiftLint Complexity Check
    run: swiftlint lint --strict --reporter sarif > swiftlint-report.sarif
  - name: Upload SwiftLint Artifact
    if: failure()
    uses: actions/upload-artifact@v4
    with:
      name: swiftlint-report
      path: swiftlint-report.sarif
  ```

### Step 4: Refactor Any Violations
- If existing code violates thresholds, apply targeted refactorings:
  - Extract helper functions for high cyclomatic complexity
  - Break long functions/types into smaller units
  - Document any exceptions with `swiftlint:disable` pragmas with rationale

### Step 5: Verification & Docs
- Confirm `swift build` and `swift test` pass locally
- Document threshold values and refactoring guidance in README/CONTRIBUTING
- Create a summary note for future maintainers

## 🧠 Source References

- [Execution Workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Phase A, Task A7
- [Task Selection Rules](../RULES/03_Next_Task_Selection.md)
- [TDD/XP Workflow](../RULES/02_TDD_XP_Workflow.md)
- [Master PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [Root TODO List](../../todo.md) — CI/CD & Quality Gates section
- SwiftLint Official Docs: https://realm.github.io/SwiftLint/

---

**Task Status:** 🔄 **IN PROGRESS** — Ready to begin implementation
**Created:** 2025-11-16
**Session Branch:** `claude/implement-select-next-013qt8JNRVw9RP4XW66DGHeJ`
