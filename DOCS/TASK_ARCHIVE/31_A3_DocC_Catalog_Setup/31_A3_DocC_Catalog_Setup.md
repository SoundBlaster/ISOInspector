# A3 — Set Up DocC Catalog and Publishing Workflow

## 🎯 Objective

Establish DocC catalogs and an automated publishing path so the ISOInspector modules ship with browsable developer
documentation from the outset.

## 🧩 Context

- Phase A3 in the execution workplan calls for configuring DocC builds once the SwiftPM workspace exists, keeping

  documentation progress aligned with foundational
  infrastructure.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L6-L15】

- The master PRD lists DocC deliverables as a core artifact alongside the library, CLI, and app, reinforcing the need

  for official API coverage early in
  development.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L3-L20】

- The dedicated documentation PRD outlines expectations for DocC catalogs, hosting, and coverage targets that this setup

  must enable.【F:DOCS/AI/ISOViewer/ISOInspector_Extra_PRDs/ISOInspectorDocs_PRD.md†L1-L33】

## ✅ Success Criteria

- Create DocC catalogs (e.g., `ISOInspectorKit.docc`, `ISOInspectorApp.docc`) added to the SwiftPM package so that `swift package generate-documentation` succeeds without warnings.
- Configure build scripts or CI steps to produce DocC archives (`.doccarchive`) and publishable HTML artifacts accessible to the team.
- Provide README/DocC landing page entries that cross-link to core modules and reference guides, ensuring developer

  onboarding material has a single entry point.

- Document the command(s) needed to regenerate the docs locally (`xcodebuild docbuild` or SwiftPM equivalents) and ensure they run successfully on current fixtures.

## 🔧 Implementation Notes

- Reuse existing package structure to register DocC resources for both CLI/App targets; ensure conditional compilation

  flags match platform availability.

- Integrate DocC generation into the existing CI pipeline (or create a manual script) while respecting repository

  constraints (no external hosting yet).

- Seed initial DocC articles with architecture overviews and module indices drawn from the master PRD and execution

  guide so later tasks can expand API details.

- Validate the generated documentation for broken links/anchors and add guidance for extending DocC coverage as new

  modules appear.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
