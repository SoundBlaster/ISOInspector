# TODO — Swift Duplication Workflow

## Puzzles
- [ ] **#SDW-1 — Script Wrapper**  
  - Create `scripts/run_swift_duplication_check.sh` with executable bit.  
  - Install `jscpd` via `npx` and pass repository-specific ignore globs (Derived, Documentation, .build, DocC artifacts).  
  - Exit with the `jscpd` status code so pre-push hooks can reuse it later.
- [ ] **#SDW-2 — GitHub Actions Job**  
  - Add `.github/workflows/swift-duplication.yml` using `actions/setup-node@v4`.  
  - Reuse the wrapper script from #SDW-1.  
  - Upload the console log as `swift-duplication-report.txt` artifact.  
  - Gate on `pull_request` + `push` to `main` with `paths` filter for `*.swift`, `.swiftlint.yml`, `.swiftpm`, and the wrapper script itself.
- [ ] **#SDW-3 — Documentation Hooks**  
  - Update `todo.md` CI/CD checklist with the duplication gate.  
  - Add backlog mention to `DOCS/INPROGRESS/next_tasks.md` under "Candidate Tasks".  
  - Insert new workplan row (A10) plus `NFR-MAINT-005` row referencing this folder's `prd.md`.  
  - Link to workflow instructions from `DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md` and `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` footnotes.
- [ ] **#SDW-4 — Local Developer Experience (Follow-Up)**  
  - Wire the wrapper into `.githooks/pre-push` once the CI workflow stabilizes.  
  - Document remediation steps in `README.md` tooling section.
