# PRD: A11 — Fix Shellcheck Style Warnings in GitHub Actions Workflows

**Status:** Backlog
**Priority:** Low-Medium
**Effort:** 0.5-1 day
**Track:** Automation (A-series)

---

## Problem Statement

During implementation of comprehensive workflow validation infrastructure, actionlint integration with shellcheck discovered multiple style warnings across existing GitHub Actions workflow files. These warnings are currently suppressed via the `-shellcheck=""` flag to prevent blocking the validation system rollout.

While these are non-critical style recommendations rather than functional errors, addressing them will:
- Improve shell script code quality
- Align with shellcheck best practices
- Enable full actionlint validation including shellcheck
- Prevent accumulation of technical debt

### Discovered Issues

**Primary Warning Types:**

1. **SC2181** - Indirect exit code checking
   - Current pattern: `command; if [ $? -ne 0 ]; then`
   - Recommended: `if ! command; then`
   - Impact: Code clarity and error handling robustness

2. **SC2129** - Multiple redirects to same file
   - Current pattern: Multiple `echo >> file` statements
   - Recommended: Command grouping with single redirect
   - Impact: Performance and code readability

**Affected Files:**
- `.github/workflows/ci.yml` (SC2181)
- `.github/workflows/foundationui-coverage.yml` (SC2129)
- Additional workflows TBD during audit phase

---

## Goals

### Primary Goals

1. **Eliminate all shellcheck style warnings** from GitHub Actions workflows
2. **Re-enable shellcheck in actionlint** by removing `-shellcheck=""` flag
3. **Maintain workflow functionality** - zero regressions
4. **Improve code quality** following shell scripting best practices

### Secondary Goals

1. Document common shellcheck patterns and fixes for future reference
2. Establish guidelines for writing shellcheck-compliant workflow scripts
3. Create awareness of shellcheck recommendations among contributors

---

## Non-Goals

- This task **does not** aim to:
  - Fix shellcheck warnings in non-workflow shell scripts
  - Implement new workflow functionality
  - Change workflow behavior (only style improvements)
  - Add new validation beyond existing actionlint

---

## Solution Design

### Phase 1: Audit (0.25 day)

**Objective:** Catalog all shellcheck warnings across workflows

**Actions:**
1. Temporarily re-enable shellcheck in actionlint locally
2. Run actionlint on all workflow files
3. Document each warning with:
   - File and line number
   - Warning code (SC####)
   - Current code snippet
   - Recommended fix
   - Risk assessment

**Deliverable:** Audit report (markdown table or spreadsheet)

### Phase 2: Fix SC2181 Warnings (0.25 day)

**Objective:** Replace indirect exit code checks with direct command checks

**Pattern:**
```bash
# ❌ Before (SC2181)
xcodebuild build
if [ $? -ne 0 ]; then
  echo "Build failed"
  exit 1
fi

# ✅ After
if ! xcodebuild build; then
  echo "Build failed"
  exit 1
fi
```

**Testing:** Trigger affected workflows via `workflow_dispatch` to verify behavior

### Phase 3: Fix SC2129 Warnings (0.25 day)

**Objective:** Group multiple redirects into single command block

**Pattern:**
```bash
# ❌ Before (SC2129)
echo "key1=value1" >> $GITHUB_OUTPUT
echo "key2=value2" >> $GITHUB_OUTPUT
echo "key3=value3" >> $GITHUB_OUTPUT

# ✅ After
{
  echo "key1=value1"
  echo "key2=value2"
  echo "key3=value3"
} >> $GITHUB_OUTPUT
```

**Testing:** Verify output variables are correctly set in downstream steps

### Phase 4: Fix Additional Warnings (0.125 day)

**Objective:** Address any remaining shellcheck recommendations

**Common Patterns:**
- Quote variable expansions: `"$var"` instead of `$var`
- Use `[[ ]]` instead of `[ ]` for string comparisons in bash
- Proper array handling

**Strategy:** Fix incrementally, test each change

### Phase 5: Re-enable Shellcheck (0.0625 day)

**Objective:** Enable full actionlint validation

**Actions:**
1. Remove `-shellcheck=""` flag from `.github/workflows/validate-workflows.yml`
2. Commit and verify all workflows pass
3. Update documentation

### Phase 6: Documentation (0.125 day)

**Objective:** Update project documentation

**Updates:**
1. **Summary_Workflow_YAML_Validation.md:**
   - Add shellcheck fixes section
   - Include before/after examples
   - Document re-enabling process

2. **WORKFLOW_VALIDATION.md:**
   - Remove temporary shellcheck disable note
   - Add shellcheck best practices section
   - Document common patterns

3. **next_tasks.md:**
   - Move A11 to completed section
   - Add summary and archive reference

---

## Success Metrics

### Quantitative

- ✅ **Zero shellcheck warnings** when running actionlint
- ✅ **Zero workflow regressions** - all workflows function as before
- ✅ **100% shellcheck coverage** - no `-shellcheck=""` suppressions

### Qualitative

- ✅ Improved code readability in workflow scripts
- ✅ Alignment with industry best practices
- ✅ Better maintainability for future workflow changes
- ✅ Contributor awareness of shellcheck guidelines

---

## Implementation Plan

### Commit Strategy

Create separate commits per warning type for easier review:

1. `docs: Audit shellcheck warnings in GitHub Actions workflows`
2. `fix: Replace indirect exit code checks (SC2181) in workflows`
3. `fix: Group redirect operations (SC2129) in workflows`
4. `fix: Address additional shellcheck warnings in workflows`
5. `feat: Re-enable shellcheck in actionlint validation`
6. `docs: Update workflow validation documentation for shellcheck`

### Testing Approach

**Per-fix validation:**
- Run actionlint locally on modified file
- Use `workflow_dispatch` to trigger workflow manually
- Verify outputs and behavior unchanged

**Pre-merge validation:**
- Ensure `validate-workflows.yml` passes with shellcheck enabled
- Review all workflow runs for any unexpected failures
- Spot-check critical workflows (CI, test coverage, etc.)

---

## Dependencies

### Required

- **Workflow validation PR merged** (`claude/fix-workflow-yaml-syntax-01Wh36PMoxo8BMrTubpDMpKT`)
  - Provides validation infrastructure
  - Includes actionlint setup
  - Documents current shellcheck suppression

### Optional

- None

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Workflow regression from fixes | High | Low | Thorough testing, incremental commits, easy rollback |
| New shellcheck warnings introduced | Medium | Low | Pre-commit hooks catch future issues |
| Incorrect shellcheck fix breaking logic | High | Very Low | Careful review, test each fix independently |
| Time overrun from unexpected warnings | Low | Medium | Phase 4 buffer for additional findings |

---

## Future Considerations

### Post-A11 Enhancements

1. **Add shellcheck to pre-commit hooks** for workflow files
2. **Create workflow script template** with shellcheck best practices
3. **Enable additional shellcheck severity levels** if valuable
4. **Extend to non-workflow shell scripts** in future task

### Related Tasks

- **A6** — Enforce SwiftFormat (in progress)
- **A7** — Reinstate SwiftLint Thresholds (backlog)
- **A10** — Add Swift Duplication Detection (backlog)

---

## References

- [Shellcheck Wiki](https://www.shellcheck.net/wiki/)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/learn-github-actions/best-practices-for-writing-workflows)
- [actionlint Documentation](https://github.com/rhysd/actionlint)
- Internal: `DOCS/INPROGRESS/Summary_Workflow_YAML_Validation.md`
- Internal: `.github/WORKFLOW_VALIDATION.md`

---

## Appendix: Common Shellcheck Patterns

### Pattern 1: Exit Code Checking (SC2181)

**Bad:**
```bash
some_command
if [ $? -eq 0 ]; then
  echo "Success"
fi
```

**Good:**
```bash
if some_command; then
  echo "Success"
fi
```

### Pattern 2: Redirect Grouping (SC2129)

**Bad:**
```bash
echo "line1" >> file.txt
echo "line2" >> file.txt
```

**Good:**
```bash
{
  echo "line1"
  echo "line2"
} >> file.txt
```

### Pattern 3: Variable Quoting (SC2086)

**Bad:**
```bash
cp $file $dest
```

**Good:**
```bash
cp "$file" "$dest"
```

### Pattern 4: Command Substitution (SC2006)

**Bad:**
```bash
result=`command`
```

**Good:**
```bash
result=$(command)
```

---

**Document Version:** 1.0
**Last Updated:** 2025-11-16
**Author:** Generated via DOCS/COMMANDS/NEW.md
