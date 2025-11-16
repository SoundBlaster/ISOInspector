# A7 — Reinstate SwiftLint Complexity Thresholds

## 🎯 Objective
Restore SwiftLint's complexity-related rules (cyclomatic complexity, function/type body length, and nesting) so both local hooks and CI block merges when the limits are exceeded, re-establishing guardrails on parser and UI code growth.

## 🧩 Context
- Task A7 from the Execution Workplan focuses on re-enabling the complexity thresholds removed during the Swift 6 migration cleanup. The work depends on Task A2 (CI pipeline) which is already complete.  
- The root `todo.md` file and the Phase A workplan both call out that `.swiftlint.yml` must restore the thresholds while `swiftlint lint --strict` runs during pre-commit and CI publishes analyzer artifacts.  
- `DOCS/TASK_ARCHIVE/228_A7_A8_SwiftLint_and_Coverage_Gates/next_tasks.md` flagged this as the next automation-track follow-up after the SwiftFormat enforcement landed.

## ✅ Success Criteria
- `.swiftlint.yml` re-introduces the agreed `cyclomatic_complexity`, `function_body_length`, `type_body_length`, and `nesting` thresholds with any necessary per-target overrides documented inline.
- `.githooks/pre-push` executes `swiftlint lint --strict` (or the shared lint helper) so contributors cannot push when complexity rules fail.
- `.github/workflows/swiftlint.yml` (and any aggregated CI workflow) surfaces the same rule set and publishes the analyzer artifact to PRs.
- Documentation or developer notes mention how to adjust thresholds when parser generators expand, keeping the design tokens and FoundationUI workstreams aware of the guardrail.

## 🔧 Implementation Notes
- Audit `DOCS/TASK_ARCHIVE/101_Summary_of_Work_2025-10-19_SwiftLint_Cleanup.md` and `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/blocked.md` for prior justifications behind disabling these checks during Swift 6 bring-up; replicate any `swiftlint` command wrappers those tasks introduced.
- Verify SwiftLint is installed on CI images; if not, document the bootstrap steps in `scripts/bootstrap_swiftlint.sh` (mirroring SwiftFormat's helper) and add caching to keep the workflow within timeout limits.
- Extend `.swiftlint.yml` comments so downstream tasks (A8, A10) understand why the thresholds differ between app and CLI targets, and note how the analyzer artifact gets attached (e.g., via `actions/upload-artifact`).
- Coordinate with the design-system backlog to ensure complexity warnings in FoundationUI modules do not regress the color token migration work that was recently archived.

## 🧠 Source References
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`todo.md`](../../todo.md)
- [`DOCS/TASK_ARCHIVE/228_A7_A8_SwiftLint_and_Coverage_Gates/next_tasks.md`](../TASK_ARCHIVE/228_A7_A8_SwiftLint_and_Coverage_Gates/next_tasks.md)
- [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md)
