# Quality Assurance Logs

This directory contains logs from quality assurance checks, including strict concurrency compliance verification.

## Strict Concurrency Logs

Local pre-push hooks and CI workflows generate logs here to track compliance with Swift's strict concurrency model:

- `strict-concurrency-build-*.log` — Build logs with strict concurrency checking enabled
- `strict-concurrency-test-*.log` — Test logs with strict concurrency checking enabled

**Note:** Logs are excluded from version control (`.gitignore`) but are uploaded as CI artifacts for historical tracking.

## CI Artifacts

When strict concurrency checks run in GitHub Actions, logs are uploaded as workflow artifacts:

- **Artifact name:** `strict-concurrency-logs`
- **Retention:** 14 days
- **Location:** GitHub Actions workflow run artifacts

## Related Documentation

- [PRD: Swift Strict Concurrency for Store Architecture](../AI/PRD_SwiftStrictConcurrency_Store.md)
- [Task A9: Automate Strict Concurrency Checks](../INPROGRESS/224_A9_Automate_Strict_Concurrency_Checks.md)
