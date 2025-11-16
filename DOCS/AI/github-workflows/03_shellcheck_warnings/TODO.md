# TODO — A11: Fix Shellcheck Style Warnings in GitHub Actions Workflows

## Context

During implementation of workflow validation infrastructure (PR `claude/fix-workflow-yaml-syntax-01Wh36PMoxo8BMrTubpDMpKT`), actionlint discovered shellcheck style warnings in existing workflow files. These warnings are currently suppressed via `-shellcheck=""` flag to allow validation to pass. This task addresses those warnings properly.

## Related Work

- **Depends on:** Workflow validation PR must be merged first
- **References:** `DOCS/INPROGRESS/Summary_Workflow_YAML_Validation.md`
- **Commit:** 343212c (disabled shellcheck in actionlint temporarily)

## Puzzles

### #SCW-1 — Audit and Catalog Warnings
- [ ] Re-enable shellcheck in actionlint temporarily to capture all warnings
- [ ] Document all shellcheck issues with:
  - File location
  - Warning code (SC####)
  - Severity level
  - Current code pattern
  - Recommended fix
- [ ] Create tracking spreadsheet or markdown table
- [ ] Prioritize warnings by severity and impact

### #SCW-2 — Fix SC2181 Warnings (Exit Code Checks)
- [ ] Identify all instances of indirect `$?` checking
- [ ] Replace patterns like:
  ```bash
  # Before (SC2181)
  command
  if [ $? -ne 0 ]; then
    echo "Failed"
  fi

  # After (correct)
  if ! command; then
    echo "Failed"
  fi
  ```
- [ ] Test each modified workflow locally or via workflow_dispatch

### #SCW-3 — Fix SC2129 Warnings (Redirect Grouping)
- [ ] Identify all instances of multiple redirects to same file
- [ ] Replace patterns like:
  ```bash
  # Before (SC2129)
  echo "line1" >> file.txt
  echo "line2" >> file.txt
  echo "line3" >> file.txt

  # After (correct)
  {
    echo "line1"
    echo "line2"
    echo "line3"
  } >> file.txt
  ```
- [ ] Verify GITHUB_OUTPUT writes are grouped efficiently

### #SCW-4 — Fix Other Style Warnings
- [ ] Address any additional shellcheck warnings discovered
- [ ] Follow shellcheck recommendations for:
  - Quoting variables
  - Array handling
  - Command substitution
  - Glob expansion
- [ ] Document any intentional shellcheck suppressions with `# shellcheck disable=SC####`

### #SCW-5 — Re-enable Shellcheck in Actionlint
- [ ] Remove `-shellcheck=""` flag from `.github/workflows/validate-workflows.yml`
- [ ] Verify all workflows pass actionlint with shellcheck enabled
- [ ] Update workflow validation documentation

### #SCW-6 — Update Documentation
- [ ] Update `DOCS/INPROGRESS/Summary_Workflow_YAML_Validation.md` with:
  - Shellcheck fixes summary
  - Before/after examples
  - Validation status update
- [ ] Update `.github/WORKFLOW_VALIDATION.md`:
  - Remove note about disabled shellcheck
  - Add section on shellcheck best practices
  - Document common patterns and fixes
- [ ] Add entry to `DOCS/INPROGRESS/next_tasks.md` completed section

## Success Criteria

- [ ] All shellcheck warnings resolved or explicitly suppressed with justification
- [ ] Shellcheck re-enabled in actionlint (no `-shellcheck=""` flag)
- [ ] All workflows pass validation with shellcheck enabled
- [ ] No regression in workflow functionality
- [ ] Documentation updated to reflect changes

## Estimated Effort

**Priority:** Low-Medium
**Effort:** 0.5-1 day
**Dependencies:** Workflow validation PR merge

## Testing Strategy

1. **Local validation:** Run actionlint with shellcheck on each modified file
2. **Workflow dispatch:** Trigger affected workflows manually to verify functionality
3. **PR validation:** Ensure validate-workflows.yml passes with shellcheck enabled
4. **Regression check:** Confirm no workflows are broken by style fixes

## Notes

- These are **style warnings**, not critical errors
- Fixes improve code quality but don't affect functionality
- Can be done incrementally (one warning type at a time)
- Consider creating separate commits per warning type for easy review
