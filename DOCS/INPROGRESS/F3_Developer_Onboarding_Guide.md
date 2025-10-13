# F3 — Developer Onboarding Guide & API Reference

## 🎯 Objective
Create comprehensive onboarding materials that help new contributors set up the ISOInspector workspace, run the full SwiftPM test suite, and understand core architecture boundaries alongside an API reference outline for ISOInspectorKit and the UI surfaces.

## 🧩 Context
- Execution workplan task **F3** calls for developer-facing documentation once DocC scaffolding and major features are in place.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L51-L53】
- The master PRD lists documentation as a core deliverable, highlighting the need for a maintained developer guide and reference docs across all targets.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L6-L18】
- XP workflow rules expect onboarding instructions to evolve with build and deployment processes, so this effort must align with the established TDD and CI practices.【F:DOCS/RULES/02_TDD_XP_Workflow.md†L1-L62】

## ✅ Success Criteria
- Step-by-step setup guide covering toolchains, repository bootstrap, and SwiftPM workflows validated on supported Apple platforms.
- Clear explanation of package targets (core parser, UI, CLI, app) with diagrams or tables linking to DocC catalogs and relevant tests.
- API reference outline describing primary entry points (parsers, validation, exporters, UI stores) and where detailed DocC articles live or need to be authored.
- Contribution checklist documenting coding standards, test expectations, and documentation update requirements in line with XP workflow guidance.

## 🔧 Implementation Notes
- Leverage existing DocC catalogs and archived task notes for authoritative descriptions of modules and workflows.
- Highlight dependencies resolved by tasks A3, B6, and C3 to guide readers toward existing documentation assets and source code examples.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L34】【F:DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/Summary_of_Work.md†L5-L19】
- Capture environment prerequisites (Swift toolchain version, platform-specific requirements) and CI expectations so contributors can mirror release readiness locally.
- Outline future DocC expansions or TODOs uncovered during documentation review to feed back into the backlog once this task is complete.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
