# A9 — Automate Strict Concurrency Checks

## 🎯 Objective

Establish automated strict concurrency checking via Swift's `--strict-concurrency=complete` flag across the build and test phases, enforcing thread-safe concurrent design patterns through both pre-push hooks and GitHub Actions CI. This ensures the codebase remains prepared for Swift 6's concurrency model and eliminates data race vulnerabilities at compile-time.

## 🧩 Context

The Swift ecosystem is moving toward strict concurrency enforcement, and ISOInspector's Store architecture (particularly `ParseIssueStore` in `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift`) currently relies on Grand Central Dispatch (GCD) with manual synchronization via `DispatchQueue.sync/async` and `@unchecked Sendable` conformance. While functional, this pattern is error-prone and cannot leverage compiler-enforced thread safety.

**Related Documentation:**
- **Swift Strict Concurrency PRD:** [`DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`](../AI/PRD_SwiftStrictConcurrency_Store.md) — comprehensive migration plan
- **Execution Workplan:** [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) (Task A9)
- **Current Build Infrastructure:** `.github/workflows/ci.yml` (already in place from Task A2)
- **Local Hook Setup:** `.githooks/pre-push` (existing infrastructure)
- **Related Task:** Task A9 gates future Store refactoring; Phase A infrastructure tasks (A1–A10) must stabilize before downstream phases depend on concurrency safety

## ✅ Success Criteria

- ✅ **Pre-Push Hook Integration:** `.githooks/pre-push` executes `swift build --strict-concurrency=complete` and `swift test --strict-concurrency=complete` before allowing pushes; logs are published to `Documentation/Quality/` with timestamps
- ✅ **CI Workflow Integration:** `.github/workflows/ci.yml` runs the same strict concurrency checks on every pull request and push to `main`; workflow fails if either build or test command returns a non-zero exit code
- ✅ **Zero Warnings:** Build and test logs show zero strict concurrency diagnostics (suppressed diagnostics do not count; all must be resolved)
- ✅ **Artifact Publishing:** CI uploads concurrency logs as workflow artifacts for historical tracking and failure investigation
- ✅ **Documentation:** `DOCS/AI/PRD_SwiftStrictConcurrency_Store.md` is updated with:
  - Links to the passing logs from first successful run
  - Status transition from "Proposed" to "Automation Gate Established"
  - Any deviations or special exemptions noted with justification
- ✅ **Rollout Checklist:** All open items in the PRD's "Automation Alignment" section are resolved
- ✅ **No Regressions:** All existing CI gates (from A2, A6, A7, A8) remain operational; no breaking changes to build matrix or timeout settings

## 🔧 Implementation Notes

### Phase 1: Pre-Push Hook Integration (0.5 days)

1. **Update `.githooks/pre-push`:**
   - Add `swift build --strict-concurrency=complete` invocation
   - Capture output to `Documentation/Quality/strict-concurrency-build-$(date +%Y%m%d-%H%M%S).log`
   - Add `swift test --strict-concurrency=complete` invocation
   - Capture output to `Documentation/Quality/strict-concurrency-test-$(date +%Y%m%d-%H%M%S).log`
   - Exit with status 1 if either command fails
   - Print human-readable summary (e.g., "✅ Strict concurrency checks passed" or "❌ Concurrency violations detected")

2. **Log Retention:**
   - Logs are optional but recommended for local developer debugging
   - Consider adding `.gitignore` entry for logs if they should not be committed (or commit a sample log for CI variance tracking)

### Phase 2: GitHub Actions Workflow Integration (0.3 days)

1. **Extend `.github/workflows/ci.yml`:**
   - After the default `swift build` job, add a new job `strict-concurrency-build`:
     ```yaml
     - name: Check strict concurrency (build)
       run: swift build --strict-concurrency=complete

     - name: Check strict concurrency (test)
       run: swift test --strict-concurrency=complete
     ```
   - Ensure the job runs on the same matrix as the main CI (ubuntu-22.04 and macOS runners as configured)
   - Upload logs via `actions/upload-artifact@v4` with name `strict-concurrency-logs`

2. **Failure Handling:**
   - Job fails automatically if either command exits non-zero
   - Workflow failure blocks PR merge (per existing branch protection rules)
   - Add a step that links to `DOCS/AI/PRD_SwiftStrictConcurrency_Store.md` in the CI summary comment or failure notification

### Phase 3: Documentation & Rollout (0.2 days)

1. **Update PRD Status:**
   - Mark the "Reality Check" section as resolved once the first successful run completes
   - Record the date and CI run URL
   - Transition "Status" from "Proposed" to "Automation Gate Established"

2. **Update `todo.md`:**
   - Mark the strict concurrency item as **Completed** with a link to the CI artifact

3. **Verification:**
   - Run a trial push to a feature branch to confirm pre-push hook executes
   - Create a test PR to confirm CI workflow runs and passes
   - Confirm logs are uploaded as artifacts and are accessible

### Known Constraints & Dependencies

- **Swift Version:** Requires Swift 5.9+ for `--strict-concurrency=complete` (current toolchain should support)
- **Dependency on A2:** CI infrastructure must be fully operational (dependency satisfied ✅)
- **Future Store Migration:** This automation gate does **not** refactor the existing Store; it only enforces that future changes maintain thread safety. The Store migration (actor adoption, async/await) is a separate, follow-up task planned for the "Concurrency Foundations" phase
- **Suppression Precedent:** If legitimate use cases emerge (e.g., bridging external APIs), document exemptions with comments like `// @swift-concurrency-exemption: <reason>` so they remain visible in logs and can be tracked for eventual resolution

## 🧠 Source References

- **Swift Strict Concurrency PRD:** [`DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`](../AI/PRD_SwiftStrictConcurrency_Store.md)
- **Execution Workplan:** [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md#a9`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- **CI Workflow Template:** `.github/workflows/ci.yml` (Task A2 baseline)
- **Pre-Push Hook Template:** `.githooks/pre-push` (existing setup)
- **Related Quality Gates:**
  - Task A6: SwiftFormat enforcement
  - Task A7: SwiftLint complexity thresholds
  - Task A8: Test coverage gate
  - Task A10: Swift duplication detection
- **Product Requirements:** [`DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md`](../AI/ISOInspector_Execution_Guide/02_Product_Requirements.md)
- **Technical Spec:** [`DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)

---

## 📝 Status

- **Created:** 2025-11-15
- **Priority:** High (P1)
- **Estimated Effort:** 1 day (0.5 + 0.3 + 0.2 phases)
- **Dependencies:** A2 ✅ (CI infrastructure complete)
- **Blocked By:** None
- **Next Milestone:** Complete all three phases and verify zero warnings across build + test
