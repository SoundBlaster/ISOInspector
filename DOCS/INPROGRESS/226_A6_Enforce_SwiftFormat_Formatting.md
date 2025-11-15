# A6 — Enforce SwiftFormat Formatting

## 🎯 Objective

Integrate SwiftFormat enforcement into the project's pre-push hook and GitHub Actions CI workflow to maintain consistent code style across all Swift sources, ensuring automated formatting and lint-on-diff validation to prevent style drift and reduce code review friction.

## 🧩 Context

The project has established a foundation for automation infrastructure via Task A2 (Configure CI Pipeline), which set up GitHub Actions and pre-commit hooks. Task A6 extends this infrastructure by adding SwiftFormat as an automated code formatter:

- **Pre-commit hook**: `swift format --in-place` on staged Swift files to auto-format before commits
- **CI validation**: `swift format --mode lint` to detect formatting violations and fail the workflow if unformatted code is detected
- **Documentation**: Updates to `README.md` tooling section to guide developers on formatting expectations

**Related tasks**:
- Task A2 (completed ✅) — CI pipeline foundation and pre-commit infrastructure
- Tasks A7, A8, A10 — Sibling automation tasks (complexity, coverage, duplication)

**Reference materials**:
- [Execution Workplan — Phase A](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md#phase-a--foundations--infrastructure)
- [TDD & XP Workflow Rules](../RULES/02_TDD_XP_Workflow.md)
- [Task Selection Rules](../RULES/03_Next_Task_Selection.md)

## ✅ Success Criteria

- ✅ SwiftFormat integration added to `.pre-commit-config.yaml` with the `swift-format` hook
- ✅ SwiftFormat hook runs `swift format --in-place` on staged Swift files before commit
- ✅ GitHub Actions workflow includes a `swift format --mode lint` step that:
  - Checks all Swift files for formatting violations
  - Fails the workflow if unformatted code is detected
  - Provides diff output for debugging
- ✅ All existing Swift sources pass the formatting check (format entire codebase if needed)
- ✅ `README.md` updated with SwiftFormat tooling section explaining:
  - How to run formatting locally
  - What the pre-commit hook does
  - CI behavior for unformatted code
- ✅ CI workflow logs show successful `swift format --mode lint` pass on sample PRs/pushes
- ✅ Documentation is consistent with project markdown standards

## 🔧 Implementation Notes

### Pre-commit Hook Setup
1. Verify `.pre-commit-config.yaml` exists and contains the necessary hook configuration
2. Add/update the SwiftFormat hook to run `swift format --in-place` on `*.swift` files
3. Test locally: `pre-commit run --all-files` to validate hook execution
4. Ensure hook does not break existing pre-push flow (e.g., swiftlint, build checks)

### GitHub Actions Workflow Update
1. Identify the main CI workflow file (likely `.github/workflows/build.yml` or similar)
2. Add a new job or step after build/test that runs:
   ```bash
   swift format --mode lint --parallel <path>
   ```
3. Fail the workflow if formatting violations are found (non-zero exit code)
4. Optionally upload diff artifact for debugging

### Codebase Formatting
1. Run `swift format --in-place --recursive Sources Tests` (or similar) to format entire codebase
2. Commit formatting changes separately or as part of this task
3. Ensure no functional code changes—only whitespace/style adjustments

### Documentation Updates
1. Update `README.md` tooling section with:
   - SwiftFormat installation instructions (if needed)
   - Local formatting command: `swift format --in-place --recursive Sources Tests`
   - Pre-commit hook automation details
   - CI lint behavior and troubleshooting
2. Cross-reference `DOCS/RULES/02_TDD_XP_Workflow.md` for consistency

### Testing & Validation
1. Test pre-commit hook locally by:
   - Staging a Swift file with misaligned formatting
   - Running `pre-commit run --all-files`
   - Verifying file is reformatted before commit
2. Verify CI lint step:
   - Create a test PR with intentionally misformatted code
   - Confirm CI workflow fails at the formatting check
   - Fix formatting and re-push; confirm CI passes
3. Run full test suite to ensure no regressions from formatting changes

## 🧠 Source References

- [Execution Workplan — Phase A](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md#phase-a--foundations--infrastructure) (line 11)
- [Task Selection Rules](../RULES/03_Next_Task_Selection.md)
- [TDD & XP Workflow Rules](../RULES/02_TDD_XP_Workflow.md)
- [Swift Formatting Standards](https://github.com/apple/swift-format)
- Task A2 archive: `DOCS/TASK_ARCHIVE/01_A2_Configure_CI_Pipeline/` (dependency reference)
