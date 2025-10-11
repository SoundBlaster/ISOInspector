# Add DocC publishing to CI

## 🎯 Objective

Automate generation and upload of DocC documentation archives within the continuous integration pipeline so reviewers
can download the latest documentation from each build.

## 🧩 Context

- Task F6 in the execution workplan targets CI automation for DocC artifacts once the catalog setup (A3) is complete and

  CI basics are configured.

- Root TODO item #12 tracks enabling DocC publishing after storage and hosting requirements are validated.
- Prior DocC catalog and tutorial work is archived under the A3 tasks, so this effort builds on those assets.

## ✅ Success Criteria

- CI workflow job invokes the existing documentation generation script and succeeds without manual intervention.
- Generated DocC archive is uploaded as a persistent artifact (or equivalent) and exposed for download on each CI run.
- Pipeline updates pass the existing CI checks and integrate with the established GitHub Actions workflow.

## 🔧 Implementation Notes

- Reuse `scripts/generate_documentation.sh` for consistent builds; ensure caching or cleanup keeps runs performant.
- Validate storage limits or retention policies for artifact hosting to meet project distribution expectations.
- Coordinate with documentation owners to confirm artifact naming, retention duration, and any additional publishing

  hooks.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
